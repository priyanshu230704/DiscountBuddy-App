import 'package:flutter_test/flutter_test.dart';

import 'package:discount_buddy/models/restaurant.dart';

/// Mirrors the backend rules in `restaurants/opening_hours.py` so the local
/// fallback stays in step with the server-computed status.
void main() {
  group('OpeningHoursFormat', () {
    test('drops minutes on the hour', () {
      expect(OpeningHoursFormat.clockLabel('15:00'), '3 pm');
      expect(OpeningHoursFormat.clockLabel('11:00'), '11 am');
    });

    test('keeps minutes when present', () {
      expect(OpeningHoursFormat.clockLabel('22:45'), '10:45 pm');
    });

    test('handles midnight and noon', () {
      expect(OpeningHoursFormat.clockLabel('00:00'), '12 am');
      expect(OpeningHoursFormat.clockLabel('12:00'), '12 pm');
    });

    test('tolerates seconds from the API', () {
      expect(OpeningHoursFormat.clockLabel('19:00:00'), '7 pm');
    });

    test('keeps both meridiems when they differ', () {
      expect(OpeningHoursFormat.rangeLabel('11:00', '15:00'), '11 am\u20133 pm');
    });

    test('drops the leading meridiem when both match', () {
      expect(OpeningHoursFormat.rangeLabel('19:00', '22:45'), '7\u201310:45 pm');
    });

    test('equal times mean open all day', () {
      expect(OpeningHoursFormat.rangeLabel('00:00', '00:00'), 'Open 24 hours');
    });

    test('24-hour labels', () {
      expect(OpeningHoursFormat.clockLabel24h('15:00'), '15:00');
      expect(OpeningHoursFormat.clockLabel24h('22:45'), '22:45');
      expect(OpeningHoursFormat.rangeLabel24h('11:00', '15:00'), '11:00\u201315:00');
      expect(
        OpeningHoursFormat.daySummary24h(['11:00-15:00', '19:00-22:45']),
        '11:00\u201315:00, 19:00\u201322:45',
      );
    });
  });

  group('OpeningSlot.parseDayRanges', () {
    test('parses a list of range strings', () {
      expect(OpeningSlot.parseDayRanges(['11:00-15:00', '19:00-22:45']), [
        ('11:00', '15:00'),
        ('19:00', '22:45'),
      ]);
    });

    test('parses a list of maps', () {
      expect(
        OpeningSlot.parseDayRanges([
          {'open': '11:00', 'close': '15:00'},
          {'open': '19:00', 'close': '22:45'},
        ]),
        [('11:00', '15:00'), ('19:00', '22:45')],
      );
    });

    test('parses a comma separated string', () {
      expect(OpeningSlot.parseDayRanges('11:00-15:00, 19:00-22:45'), [
        ('11:00', '15:00'),
        ('19:00', '22:45'),
      ]);
    });

    test('sorts and deduplicates', () {
      expect(
        OpeningSlot.parseDayRanges(['19:00-22:45', '11:00-15:00', '19:00-22:45']),
        [('11:00', '15:00'), ('19:00', '22:45')],
      );
    });

    test('treats closed markers and junk as no ranges', () {
      for (final value in ['', 'closed', 'nonsense', null]) {
        expect(OpeningSlot.parseDayRanges(value), isEmpty, reason: '$value');
      }
    });
  });

  group('OpeningStatus.fromSlots', () {
    // 2026-09-02 is a Wednesday.
    OpeningSlot slot(int day, String open, String close) => OpeningSlot(
      dayOfWeek: day,
      dayName: OpeningHoursFormat.dayNames[day],
      openingTime: open,
      closingTime: close,
      isClosed: false,
    );

    final splitShift = [slot(2, '11:00', '15:00'), slot(2, '19:00', '22:45')];

    test('returns null when there are no usable hours', () {
      expect(OpeningStatus.fromSlots(const [], DateTime(2026, 9, 2, 12)), isNull);
    });

    test('open during lunch reports the lunch closing time', () {
      final status = OpeningStatus.fromSlots(
        splitShift,
        DateTime(2026, 9, 2, 12, 30),
      );
      expect(status!.isOpen, isTrue);
      expect(status.label, 'Open \u00b7 Closes 3 pm');
    });

    test('closed between shifts points at dinner', () {
      final status = OpeningStatus.fromSlots(
        splitShift,
        DateTime(2026, 9, 2, 16),
      );
      expect(status!.isOpen, isFalse);
      expect(status.label, 'Closed \u00b7 Opens 7 pm');
    });

    test('open during dinner reports the dinner closing time', () {
      final status = OpeningStatus.fromSlots(
        splitShift,
        DateTime(2026, 9, 2, 20),
      );
      expect(status!.label, 'Open \u00b7 Closes 10:45 pm');
    });

    test('after the last shift points at the next open day', () {
      final status = OpeningStatus.fromSlots(
        [...splitShift, slot(3, '11:00', '15:00')],
        DateTime(2026, 9, 2, 23),
      );
      expect(status!.label, 'Closed \u00b7 Opens 11 am Thu');
    });

    test('overnight window stays open past midnight', () {
      // 00:30 Thursday is still inside Wednesday's 22:00-02:00 window.
      final status = OpeningStatus.fromSlots(
        [slot(2, '22:00', '02:00')],
        DateTime(2026, 9, 3, 0, 30),
      );
      expect(status!.isOpen, isTrue);
      expect(status.label, 'Open \u00b7 Closes 2 am');
    });

    test('equal times mean open 24 hours', () {
      final status = OpeningStatus.fromSlots(
        [slot(2, '00:00', '00:00')],
        DateTime(2026, 9, 2, 3),
      );
      expect(status!.isOpen, isTrue);
      expect(status.label, 'Open 24 hours');
    });

    test('fromSlots 24h uses wall clock not device timezone', () {
      final status = OpeningStatus.fromSlots(
        [slot(2, '09:00', '13:00')],
        DateTime(2026, 9, 2, 10),
        use24Hour: true,
      );
      expect(status!.label24h, 'Open · Closes 13:00');
    });
  });

  group('OpeningStatus.label24h', () {
    test('converts API detail without using device timezone', () {
      const status = OpeningStatus(
        isOpen: true,
        state: 'open',
        shortLabel: 'Open',
        detail: 'Closes 1 pm',
        label: 'Open · Closes 1 pm',
        nextChangeAt: null,
      );
      expect(status.label24h, 'Open · Closes 13:00');
    });

    test('keeps already-24h detail from slots', () {
      const status = OpeningStatus(
        isOpen: true,
        state: 'open',
        shortLabel: 'Open',
        detail: 'Closes 13:00',
        label: 'Open · Closes 13:00',
      );
      expect(status.label24h, 'Open · Closes 13:00');
    });
  });

  group('OpeningDay.fromSlots', () {
    test('groups split shifts and starts from today', () {
      final slots = [
        OpeningSlot(
          dayOfWeek: 2,
          dayName: 'Wednesday',
          openingTime: '11:00',
          closingTime: '15:00',
          isClosed: false,
        ),
        OpeningSlot(
          dayOfWeek: 2,
          dayName: 'Wednesday',
          openingTime: '19:00',
          closingTime: '22:45',
          isClosed: false,
        ),
      ];

      final week = OpeningDay.fromSlots(slots, 2);

      expect(week.length, 7);
      expect(week.first.dayName, 'Wednesday');
      expect(week.first.isToday, isTrue);
      expect(week.first.ranges, ['11 am\u20133 pm', '7\u201310:45 pm']);
      expect(week.first.label, '11 am\u20133 pm, 7\u201310:45 pm');
      expect(week[1].isClosed, isTrue);
      expect(week[1].label, 'Closed');
    });
  });
}
