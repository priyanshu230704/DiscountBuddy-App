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

  static final DateFormat _f24h = DateFormat('HH:mm');
  static final DateFormat _fDateTime24h = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _fDateOnly = DateFormat('dd MMM yyyy');
  static final DateFormat _fShortWeekday = DateFormat('E');

  /// 24-hour time for an **instant** (e.g. from API / [DateTime.parse] with `Z`).
  static String format24h(DateTime utcTime) {
    return _f24h.format(utcTime.toLocal());
  }

  /// Date + time in 24-hour form for an **instant** (e.g. from API).
  static String formatDateTime24h(DateTime utcTime) {
    return _fDateTime24h.format(utcTime.toLocal());
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
