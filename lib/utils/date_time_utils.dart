import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Single place for **display** formatting (intl). Avoid ad-hoc [DateFormat] in widgets.
///
/// **Booking appointments** → [formatBookingDateTimeFromIso] reads wall-clock
/// digits from the API string (e.g. `17:00` from `…T17:00:00+01:00`). Never
/// [DateTime.toLocal] — that shows 21:30 IST for a 17:00 London table.
///
/// **Other API instants** (redemptions, timestamps) → [formatDateTime24h] uses
/// [DateTime.toLocal] before formatting.
///
/// **Pickers** → [DateTime] / [TimeOfDay] is already local; use [formatDateOnly],
/// [formatTimeOfDay24h], or [formatShortWeekday] — they do **not** call [toLocal].
class DateTimeUtils {
  DateTimeUtils._();

  /// Default restaurant timezone while the product is UK-only.
  static const restaurantTimeZoneId = 'Europe/London';

  static bool _timeZonesInitialized = false;

  /// Call once at app startup before any booking UTC conversion.
  static void ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) return;
    tz.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  /// Pinned for stable month/weekday output; [initializeDateFormatting] in [main] must run first.
  static const _appLocale = 'en_US';

  static final DateFormat _f24h = DateFormat('HH:mm', _appLocale);
  static final DateFormat _fDateTime24h = DateFormat('dd MMM yyyy, HH:mm', _appLocale);
  static final DateFormat _fDateOnly = DateFormat('dd MMM yyyy', _appLocale);
  static final DateFormat _fShortWeekday = DateFormat('E', _appLocale);

  static final RegExp _bookingIsoWallClock = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})',
  );

  /// Tries ISO-8601 first, then common English **push/FCM** strings (e.g. "April 24, 2026 at 07:30 AM").
  ///
  /// Our API stores `booking_date` as **UTC** and now always sends it with a `Z` suffix in both REST
  /// responses and FCM `data`, so [DateTime.tryParse] handles the normal case.
  ///
  /// The English patterns remain for notifications queued by older backends, which put preformatted
  /// text in `data.booking_date` repeating that **same UTC clock** (7:30) in 12h form.
  /// [DateFormat.parseStrict] without `utc: true` would treat that as **7:30 in the device zone** and
  /// skip the conversion [formatDateTime24h] does for UTC, so a 13:00 local reservation would show as
  /// 07:30 on the merchant side — hence we use [parseStrict] with `utc: true` for these patterns.
  static DateTime? tryParseBookingInstant(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // ICU: literal " at " between date and time is `y' at 'h` (see intl `DateFormat` docs).
    final usPatterns = <String>[
      "MMMM d, y' at 'h:mm a",
      "MMMM d, y' at 'hh:mm a",
      "MMM d, y' at 'h:mm a",
      "MMM d, y' at 'hh:mm a",
    ];
    for (final pattern in usPatterns) {
      try {
        // Second arg: interpret fields as UTC so this matches [booking_date] from the API.
        return DateFormat(pattern, _appLocale).parseStrict(s, true);
      } catch (_) {
        // next pattern
      }
    }
    return null;
  }

  /// Wall-clock [DateTime] from a booking ISO string — no device-TZ conversion.
  ///
  /// `2026-09-09T17:00:00+01:00` → 17:00 on every device.
  /// `2026-09-09T16:00:00Z` → 16:00 (legacy UTC-only payloads).
  static DateTime? wallClockFromBookingIso(Object? value) {
    if (value == null) return null;
    final match = _bookingIsoWallClock.firstMatch(value.toString().trim());
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }

  /// Booking label for UI — same wall clock on India, UK, or any device.
  static String formatBookingDateTimeFromIso(Object? value) {
    if (value == null) return 'N/A';
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == 'N/A') return 'N/A';

    final wall = wallClockFromBookingIso(raw);
    if (wall != null) return _fDateTime24h.format(wall);

    final parsed = tryParseBookingInstant(raw);
    if (parsed == null) return raw;
    return formatDateTime24h(parsed);
  }

  /// Time portion only for booking ISO strings (calendar chips, etc.).
  static String formatBookingTimeFromIso(Object? value) {
    final wall = wallClockFromBookingIso(value);
    if (wall != null) return _f24h.format(wall);
    final parsed = tryParseBookingInstant(value);
    if (parsed == null) return value?.toString() ?? 'N/A';
    return format24h(parsed);
  }

  /// 24-hour time for an **instant** (e.g. from API / [DateTime.parse] with `Z`).
  static String format24h(DateTime instant) {
    final local = instant.isUtc ? instant.toLocal() : instant;
    return _f24h.format(local);
  }

  /// Date + time in 24-hour form for an **instant** (e.g. from API or [tryParseBookingInstant]).
  static String formatDateTime24h(DateTime instant) {
    final local = instant.isUtc ? instant.toLocal() : instant;
    return _fDateTime24h.format(local);
  }

  /// Date only for a **local** [DateTime] (e.g. [showDatePicker] result). No [toLocal].
  static String formatDateOnly(DateTime localTime) {
    return _fDateOnly.format(localTime);
  }

  /// 24-hour text for a [TimeOfDay] from [showTimePicker]. No [toLocal].
  static String formatTimeOfDay24h(TimeOfDay t) {
    return _f24h.format(DateTime(2000, 1, 1, t.hour, t.minute));
  }

  /// Short weekday label for calendar chips; [localTime] should be from local calendar. No [toLocal].
  static String formatShortWeekday(DateTime localTime) {
    return _fShortWeekday.format(localTime);
  }

  /// Converts a restaurant-local wall-clock slot to a UTC [DateTime] instant.
  ///
  /// `09:00` on 2026-09-09 London (BST) → `2026-09-09 08:00 UTC`.
  /// `09:00` on 2026-01-15 London (GMT) → `2026-01-15 09:00 UTC`.
  /// Device timezone is never used.
  static DateTime utcInstantFromRestaurantWallClock({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    String timeZoneId = restaurantTimeZoneId,
  }) {
    ensureTimeZonesInitialized();
    final location = tz.getLocation(timeZoneId);
    final local = tz.TZDateTime(location, year, month, day, hour, minute);
    return local.toUtc();
  }

  /// API body: UTC ISO-8601 with `Z` from a restaurant wall-clock slot.
  static String restaurantWallClockToApiUtcIso({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    String timeZoneId = restaurantTimeZoneId,
  }) {
    return toApiUtcIso(
      utcInstantFromRestaurantWallClock(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        timeZoneId: timeZoneId,
      ),
    );
  }

  /// Request body: UTC ISO-8601 with `Z`.
  static String toApiUtcIso(DateTime instant) {
    final utc = instant.isUtc ? instant : instant.toUtc();
    return utc.toIso8601String();
  }

  static Future<TimeOfDay?> showTimePicker24h({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }
}
