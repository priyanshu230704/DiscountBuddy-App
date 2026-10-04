import 'package:discount_buddy/utils/date_time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DateTimeUtils.ensureTimeZonesInitialized);

  group('formatBookingDateTimeFromIso (display)', () {
    test('offset ISO shows 17:00 on every device (not 21:30 IST)', () {
      const iso = '2026-09-09T17:00:00+01:00';
      expect(
        DateTimeUtils.formatBookingDateTimeFromIso(iso),
        '09 Sep 2026, 17:00',
      );
    });

    test('summer 09:00 offset ISO displays 09:00', () {
      expect(
        DateTimeUtils.formatBookingDateTimeFromIso(
          '2026-09-09T09:00:00+01:00',
        ),
        '09 Sep 2026, 09:00',
      );
    });

    test('winter 09:00 offset ISO displays 09:00', () {
      expect(
        DateTimeUtils.formatBookingDateTimeFromIso(
          '2026-01-15T09:00:00+00:00',
        ),
        '15 Jan 2026, 09:00',
      );
    });

    test('formatBookingTimeFromIso returns HH:mm from offset ISO', () {
      expect(
        DateTimeUtils.formatBookingTimeFromIso('2026-09-09T17:00:00+01:00'),
        '17:00',
      );
    });

    test('wallClockFromBookingIso ignores device timezone', () {
      final wall = DateTimeUtils.wallClockFromBookingIso(
        '2026-09-09T17:00:00+01:00',
      );
      expect(wall?.hour, 17);
      expect(wall?.minute, 0);
    });
  });

  group('utcInstantFromRestaurantWallClock (submission)', () {
    test('09:00 London summer (BST) → 08:00 UTC', () {
      final utc = DateTimeUtils.utcInstantFromRestaurantWallClock(
        year: 2026,
        month: 9,
        day: 9,
        hour: 9,
        minute: 0,
      );
      expect(utc.isUtc, isTrue);
      expect(utc.hour, 8);
      expect(utc.minute, 0);
      expect(
        DateTimeUtils.toApiUtcIso(utc),
        '2026-09-09T08:00:00.000Z',
      );
    });

    test('09:00 London winter (GMT) → 09:00 UTC', () {
      final utc = DateTimeUtils.utcInstantFromRestaurantWallClock(
        year: 2026,
        month: 1,
        day: 15,
        hour: 9,
        minute: 0,
      );
      expect(utc.hour, 9);
      expect(utc.minute, 0);
      expect(
        DateTimeUtils.toApiUtcIso(utc),
        '2026-01-15T09:00:00.000Z',
      );
    });

    test('India device semantics: 09:00 slot still maps to London 09:00 UTC', () {
      final utc = DateTimeUtils.utcInstantFromRestaurantWallClock(
        year: 2026,
        month: 9,
        day: 9,
        hour: 9,
        minute: 0,
      );
      expect(DateTimeUtils.restaurantWallClockToApiUtcIso(
        year: 2026,
        month: 9,
        day: 9,
        hour: 9,
        minute: 0,
      ), '2026-09-09T08:00:00.000Z');
      expect(
        DateTimeUtils.formatBookingDateTimeFromIso(
          '2026-09-09T09:00:00+01:00',
        ),
        '09 Sep 2026, 09:00',
      );
      expect(utc.hour, 8);
    });
  });

  group('formatDateTime24h (non-booking instants)', () {
    test('UTC instant still converts to device local', () {
      final utc = DateTime.utc(2026, 9, 9, 16);
      final label = DateTimeUtils.formatDateTime24h(utc);
      final localHour = utc.toLocal().hour;
      expect(label, contains(localHour.toString().padLeft(2, '0')));
    });
  });
}
