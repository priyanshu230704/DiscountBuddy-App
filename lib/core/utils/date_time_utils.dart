import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Single place for **display** formatting (intl). Avoid ad-hoc [DateFormat] in widgets.
///
/// **API** → [DateTime] is usually UTC; use [format24h] / [formatDateTime24h] (they call
/// [DateTime.toLocal] before formatting).
///
/// **Pickers** → [DateTime] / [TimeOfDay] is already local; use [formatDateOnly],
/// [formatTimeOfDay24h], or [formatShortWeekday] — they do **not** call [toLocal].
class DateTimeUtils {
  DateTimeUtils._();

  /// Pinned for stable month/weekday output; [initializeDateFormatting] in [main] must run first.
  static const _appLocale = 'en_US';

  static final DateFormat _f24h = DateFormat('HH:mm', _appLocale);
  static final DateFormat _fDateTime24h = DateFormat('dd MMM yyyy, HH:mm', _appLocale);
  static final DateFormat _fDateOnly = DateFormat('dd MMM yyyy', _appLocale);
  static final DateFormat _fShortWeekday = DateFormat('E', _appLocale);

  /// Tries ISO-8601 first, then common English **push/FCM** strings (e.g. "April 24, 2026 at 07:30 AM").
  ///
  /// Our API stores `booking_date` as **UTC**; the REST payload uses a `Z` suffix so [DateTime.tryParse]
  /// is correct. Preformatted FCM text usually repeats that **same UTC clock** (7:30) in 12h English.
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

  /// Request body: UTC ISO-8601 with `Z`.
  static String toApiUtcIso(DateTime instant) {
    return instant.toUtc().toIso8601String();
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
