import 'image_variants.dart';

/// Cuisine model
class Cuisine {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  Cuisine({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'icon': icon};
  }
}

/// Restaurant Category model
class RestaurantCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  RestaurantCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory RestaurantCategory.fromJson(Map<String, dynamic> json) {
    return RestaurantCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'icon': icon};
  }
}

/// Google-Maps-style formatting for opening times.
///
/// Kept separate from the widgets so the customer detail page, merchant editor
/// and booking modal all label windows identically.
class OpeningHoursFormat {
  OpeningHoursFormat._();

  static const List<String> dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const List<String> dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Parses `"19:00"` or `"19:00:00"` into minutes since midnight.
  static int? minutesOf(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 24 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  /// `15:00` -> `3 pm`, `22:45` -> `10:45 pm`. Minutes are dropped on the hour.
  static String clockLabel(String raw) {
    final minutes = minutesOf(raw);
    if (minutes == null) return raw.trim();
    return clockLabelFromMinutes(minutes);
  }

  static String clockLabelFromMinutes(int minutes) {
    final normalized = minutes % (24 * 60);
    final hour24 = normalized ~/ 60;
    final minute = normalized % 60;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final meridiem = hour24 < 12 ? 'am' : 'pm';
    if (minute == 0) return '$hour $meridiem';
    return '$hour:${minute.toString().padLeft(2, '0')} $meridiem';
  }

  /// `11 am–3 pm`, and `7–10:45 pm` when both ends share a meridiem.
  static String rangeLabel(String opening, String closing) {
    final openMinutes = minutesOf(opening);
    final closeMinutes = minutesOf(closing);
    if (openMinutes == null || closeMinutes == null) {
      return '${opening.trim()} - ${closing.trim()}';
    }
    if (openMinutes == closeMinutes) return 'Open 24 hours';

    var start = clockLabelFromMinutes(openMinutes);
    final end = clockLabelFromMinutes(closeMinutes);

    final sameMeridiem = (openMinutes < 12 * 60) == (closeMinutes < 12 * 60);
    if (sameMeridiem) {
      start = start.replaceAll(' am', '').replaceAll(' pm', '');
    }
    return '$start\u2013$end';
  }

  /// 24-hour clock label, e.g. `15:00`, `22:45`.
  static String clockLabel24h(String raw) {
    final minutes = minutesOf(raw);
    if (minutes == null) return raw.trim();
    return clockLabel24hFromMinutes(minutes);
  }

  static String clockLabel24hFromMinutes(int minutes) {
    final normalized = minutes % (24 * 60);
    final hour24 = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 24-hour range label, e.g. `11:00\u201315:00`.
  static String rangeLabel24h(String opening, String closing) {
    final openMinutes = minutesOf(opening);
    final closeMinutes = minutesOf(closing);
    if (openMinutes == null || closeMinutes == null) {
      return '${opening.trim()}\u2013${closing.trim()}';
    }
    if (openMinutes == closeMinutes) return '24 hours';
    return '${clockLabel24h(opening)}\u2013${clockLabel24h(closing)}';
  }

  /// Compact summary for a merchant day row, e.g. `11:00\u201315:00, 19:00\u201322:45`.
  static String daySummary24h(List<String> ranges) {
    if (ranges.isEmpty) return 'Closed';
    return ranges
        .map((range) {
          final parts = range.split('-');
          if (parts.length != 2) return range;
          return rangeLabel24h(parts[0], parts[1]);
        })
        .join(', ');
  }
}

/// One opening window for one weekday.
///
/// A weekday may have several slots, which is how split shifts such as
/// `11 am–3 pm` plus `7–10:45 pm` are represented.
class OpeningSlot {
  final int? id;
  final int? dayOfWeek;
  final String dayName;
  final String openingTime;
  final String closingTime;
  final bool isClosed;

  /// Server-rendered label. Falls back to local formatting when absent.
  final String? _displayRange;

  const OpeningSlot({
    this.id,
    this.dayOfWeek,
    required this.dayName,
    required this.openingTime,
    required this.closingTime,
    required this.isClosed,
    String? displayRange,
  }) : _displayRange = displayRange;

  factory OpeningSlot.fromJson(Map<String, dynamic> json) {
    final dayOfWeek = _parseInt(json['day_of_week']);
    final dayName =
        json['day_name'] as String? ??
        (dayOfWeek != null && dayOfWeek >= 0 && dayOfWeek < 7
            ? OpeningHoursFormat.dayNames[dayOfWeek]
            : '');

    return OpeningSlot(
      id: _parseInt(json['id']),
      dayOfWeek: dayOfWeek,
      dayName: dayName,
      openingTime: json['opening_time'] as String? ?? '',
      closingTime: json['closing_time'] as String? ?? '',
      isClosed: json['is_closed'] as bool? ?? false,
      displayRange: json['display_range'] as String?,
    );
  }

  String get displayRange {
    if (_displayRange != null && _displayRange.isNotEmpty) return _displayRange;
    if (isClosed) return 'Closed';
    return OpeningHoursFormat.rangeLabel(openingTime, closingTime);
  }

  /// True when the window runs past midnight, e.g. `22:00`-`02:00`.
  bool get spansMidnight {
    final open = OpeningHoursFormat.minutesOf(openingTime);
    final close = OpeningHoursFormat.minutesOf(closingTime);
    if (open == null || close == null) return false;
    return close < open;
  }

  bool get isOpenAllDay {
    final open = OpeningHoursFormat.minutesOf(openingTime);
    final close = OpeningHoursFormat.minutesOf(closingTime);
    return open != null && open == close;
  }

  /// Weekday index (Monday = 0), resolved from either field the API may send.
  int? get dayIndex {
    if (dayOfWeek != null && dayOfWeek! >= 0 && dayOfWeek! <= 6) {
      return dayOfWeek;
    }
    final index = OpeningHoursFormat.dayNames.indexWhere(
      (name) => name.toLowerCase() == dayName.toLowerCase(),
    );
    return index >= 0 ? index : null;
  }

  bool get isUsable =>
      !isClosed &&
      OpeningHoursFormat.minutesOf(openingTime) != null &&
      OpeningHoursFormat.minutesOf(closingTime) != null &&
      dayIndex != null;

  /// Whether [minutes] past midnight falls inside this window.
  ///
  /// [startedYesterday] checks only the part of an overnight window that spills
  /// past midnight, so a Tuesday 22:00-02:00 slot still counts at 00:30 Wednesday.
  bool containsMinutes(int minutes, {bool startedYesterday = false}) {
    final open = OpeningHoursFormat.minutesOf(openingTime);
    final close = OpeningHoursFormat.minutesOf(closingTime);
    if (open == null || close == null || isClosed) return false;

    if (open == close) return !startedYesterday;
    if (close < open) {
      return startedYesterday ? minutes < close : minutes >= open;
    }
    return startedYesterday ? false : (minutes >= open && minutes < close);
  }

  /// Builds slots from the legacy `opening_hours` map.
  ///
  /// Each day accepts a single `"11:00-15:00"` string, a comma-separated list, or
  /// a JSON array, so split shifts survive the fallback path too.
  static List<OpeningSlot> fromHoursMap(Map<String, dynamic>? hoursMap) {
    if (hoursMap == null || hoursMap.isEmpty) return [];

    final slots = <OpeningSlot>[];

    for (var dayIndex = 0; dayIndex < OpeningHoursFormat.dayKeys.length; dayIndex++) {
      final dayKey = OpeningHoursFormat.dayKeys[dayIndex];
      final dayName = OpeningHoursFormat.dayNames[dayIndex];
      final ranges = parseDayRanges(hoursMap[dayKey]);

      if (ranges.isEmpty) {
        slots.add(
          OpeningSlot(
            dayOfWeek: dayIndex,
            dayName: dayName,
            openingTime: '',
            closingTime: '',
            isClosed: true,
          ),
        );
        continue;
      }

      for (final range in ranges) {
        slots.add(
          OpeningSlot(
            dayOfWeek: dayIndex,
            dayName: dayName,
            openingTime: range.$1,
            closingTime: range.$2,
            isClosed: false,
          ),
        );
      }
    }

    return slots;
  }

  /// Extracts every `(opening, closing)` window from one day's raw value.
  static List<(String, String)> parseDayRanges(Object? dayValue) {
    if (dayValue == null) return const [];

    final candidates = <Object?>[];
    if (dayValue is List) {
      candidates.addAll(dayValue);
    } else if (dayValue is String) {
      candidates.addAll(dayValue.split(RegExp(r'[,;&|]')));
    } else {
      candidates.add(dayValue);
    }

    final ranges = <(String, String)>[];
    for (final candidate in candidates) {
      final range = _parseSingleRange(candidate);
      if (range != null && !ranges.contains(range)) ranges.add(range);
    }

    ranges.sort(
      (a, b) => (OpeningHoursFormat.minutesOf(a.$1) ?? 0)
          .compareTo(OpeningHoursFormat.minutesOf(b.$1) ?? 0),
    );
    return ranges;
  }

  static (String, String)? _parseSingleRange(Object? candidate) {
    String? opening;
    String? closing;

    if (candidate is Map) {
      opening = (candidate['open'] ?? candidate['opening'])?.toString();
      closing = (candidate['close'] ?? candidate['closing'])?.toString();
    } else if (candidate is String) {
      final value = candidate.trim();
      if (!value.contains('-')) return null;
      final separator = value.indexOf('-');
      opening = value.substring(0, separator);
      closing = value.substring(separator + 1);
    } else {
      return null;
    }

    final openTrimmed = opening?.trim() ?? '';
    final closeTrimmed = closing?.trim() ?? '';
    if (OpeningHoursFormat.minutesOf(openTrimmed) == null) return null;
    if (OpeningHoursFormat.minutesOf(closeTrimmed) == null) return null;

    return (openTrimmed, closeTrimmed);
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      'day_name': dayName,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'is_closed': isClosed,
    };
  }
}

/// The status line shown next to a restaurant name, e.g. `Open · Closes 3 pm`.
///
/// Computed by the backend in the restaurant's timezone so every client agrees.
class OpeningStatus {
  final bool isOpen;

  /// One of `open`, `closing_soon` or `closed`.
  final String state;

  /// `Open`, `Closes soon`, `Closed` or `Open 24 hours`.
  final String shortLabel;

  /// `Closes 3 pm` or `Opens 11 am Thu`. Empty when there is nothing to add.
  final String detail;

  /// The two parts already joined for display.
  final String label;
  final bool openTwentyFourHours;

  /// When the restaurant next opens or closes, for callers that want a countdown.
  final DateTime? nextChangeAt;

  const OpeningStatus({
    required this.isOpen,
    required this.state,
    required this.shortLabel,
    required this.detail,
    required this.label,
    this.openTwentyFourHours = false,
    this.nextChangeAt,
  });

  bool get isClosingSoon => state == 'closing_soon';

  /// Status line in 24-hour format, e.g. `Open · Closes 15:00`.
  ///
  /// Uses [detail] (restaurant-local wall clock from the API or slots) and
  /// never converts [nextChangeAt] to the device timezone — that would show
  /// the wrong time for users outside the UK (e.g. 17:30 IST instead of 13:00).
  String get label24h {
    if (openTwentyFourHours) return 'Open 24 hours';

    if (detail.startsWith('Closes ')) {
      final head = isClosingSoon ? 'Closes soon' : (isOpen ? 'Open' : shortLabel);
      final time = _to24hTimeToken(detail.substring('Closes '.length));
      return '$head · Closes $time';
    }
    if (detail.startsWith('Opens ')) {
      final rest = detail.substring('Opens '.length);
      final parts = rest.split(' ');
      final time = _to24hTimeToken(parts.first);
      final suffix = parts.length > 1 ? ' ${parts.sublist(1).join(' ')}' : '';
      return 'Closed · Opens $time$suffix';
    }

    return label;
  }

  /// Normalises `"13:00"`, `"1 pm"`, or `"13:00:00"` to `HH:MM`.
  static String _to24hTimeToken(String raw) {
    final trimmed = raw.trim();
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(trimmed)) return trimmed;
    if (RegExp(r'^\d{1,2}:\d{2}:\d{2}$').hasMatch(trimmed)) {
      final parts = trimmed.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    }
    return _tryConvertClockLabelTo24h(trimmed);
  }

  static String _tryConvertClockLabelTo24h(String raw) {
    final normalized = raw.trim().toLowerCase();
    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$').firstMatch(normalized);
    if (match == null) return raw;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2) ?? '0');
    final meridiem = match.group(3)!;

    if (meridiem == 'pm' && hour != 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;

    return OpeningHoursFormat.clockLabel24hFromMinutes(hour * 60 + minute);
  }

  factory OpeningStatus.fromJson(Map<String, dynamic> json) {
    final shortLabel = json['short_label'] as String? ?? '';
    final detail = json['detail'] as String? ?? '';
    final label = json['label'] as String? ??
        [shortLabel, detail].where((part) => part.isNotEmpty).join(' \u00b7 ');

    return OpeningStatus(
      isOpen: json['is_open'] as bool? ?? false,
      state: json['state'] as String? ?? 'closed',
      shortLabel: shortLabel,
      detail: detail,
      label: label,
      openTwentyFourHours: json['open_24_hours'] as bool? ?? false,
      nextChangeAt: DateTime.tryParse(json['next_change_at']?.toString() ?? ''),
    );
  }

  /// Local fallback for backends that do not yet send `opening_status`.
  ///
  /// Mirrors the server rules, including split shifts and overnight windows.
  /// Returns null when no usable hours exist so the caller can hide the status.
  static OpeningStatus? fromSlots(
    List<OpeningSlot> slots,
    DateTime now, {
    bool use24Hour = false,
  }) {
    final usable = slots.where((slot) => slot.isUsable).toList();
    if (usable.isEmpty) return null;

    String clock(String raw) => use24Hour
        ? OpeningHoursFormat.clockLabel24h(raw)
        : OpeningHoursFormat.clockLabel(raw);

    final today = now.weekday - 1;
    final yesterday = (today + 6) % 7;
    final nowMinutes = now.hour * 60 + now.minute;

    List<OpeningSlot> slotsFor(int day) {
      final daySlots = usable.where((slot) => slot.dayIndex == day).toList();
      daySlots.sort(
        (a, b) => OpeningHoursFormat.minutesOf(a.openingTime)!.compareTo(
          OpeningHoursFormat.minutesOf(b.openingTime)!,
        ),
      );
      return daySlots;
    }

    for (final slot in slotsFor(today)) {
      if (slot.containsMinutes(nowMinutes)) {
        if (slot.isOpenAllDay) {
          return const OpeningStatus(
            isOpen: true,
            state: 'open',
            shortLabel: 'Open 24 hours',
            detail: '',
            label: 'Open 24 hours',
            openTwentyFourHours: true,
          );
        }
        final detail = 'Closes ${clock(slot.closingTime)}';
        return OpeningStatus(
          isOpen: true,
          state: 'open',
          shortLabel: 'Open',
          detail: detail,
          label: 'Open \u00b7 $detail',
        );
      }
    }

    for (final slot in slotsFor(yesterday)) {
      if (slot.containsMinutes(nowMinutes, startedYesterday: true)) {
        final detail = 'Closes ${clock(slot.closingTime)}';
        return OpeningStatus(
          isOpen: true,
          state: 'open',
          shortLabel: 'Open',
          detail: detail,
          label: 'Open \u00b7 $detail',
        );
      }
    }

    for (final slot in slotsFor(today)) {
      if (OpeningHoursFormat.minutesOf(slot.openingTime)! > nowMinutes) {
        final detail = 'Opens ${clock(slot.openingTime)}';
        return OpeningStatus(
          isOpen: false,
          state: 'closed',
          shortLabel: 'Closed',
          detail: detail,
          label: 'Closed \u00b7 $detail',
        );
      }
    }

    for (var offset = 1; offset <= 7; offset++) {
      final daySlots = slotsFor((today + offset) % 7);
      if (daySlots.isEmpty) continue;
      final slot = daySlots.first;
      final weekday = OpeningHoursFormat.dayNames[slot.dayIndex!].substring(0, 3);
      final detail = 'Opens ${clock(slot.openingTime)} $weekday';
      return OpeningStatus(
        isOpen: false,
        state: 'closed',
        shortLabel: 'Closed',
        detail: detail,
        label: 'Closed \u00b7 $detail',
      );
    }

    return const OpeningStatus(
      isOpen: false,
      state: 'closed',
      shortLabel: 'Closed',
      detail: '',
      label: 'Closed',
    );
  }
}

/// One weekday's opening windows, ready for the detail screen.
class OpeningDay {
  final int dayOfWeek;
  final String dayName;
  final String dayShort;
  final bool isToday;
  final bool isClosed;

  /// Formatted windows, e.g. `['11 am–3 pm', '7–10:45 pm']`.
  final List<String> ranges;

  /// The same windows joined, or `Closed`.
  final String label;

  const OpeningDay({
    required this.dayOfWeek,
    required this.dayName,
    required this.dayShort,
    required this.isToday,
    required this.isClosed,
    required this.ranges,
    required this.label,
  });

  factory OpeningDay.fromJson(Map<String, dynamic> json) {
    final ranges =
        (json['ranges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    return OpeningDay(
      dayOfWeek: _parseInt(json['day_of_week']) ?? 0,
      dayName: json['day_name'] as String? ?? '',
      dayShort: json['day_short'] as String? ?? '',
      isToday: json['is_today'] as bool? ?? false,
      isClosed: json['is_closed'] as bool? ?? ranges.isEmpty,
      ranges: ranges,
      label: json['label'] as String? ??
          (ranges.isEmpty ? 'Closed' : ranges.join(', ')),
    );
  }

  /// Groups slots per weekday when the backend did not send a weekly breakdown.
  ///
  /// Ordered from [todayIndex] so the current day leads, matching the API.
  static List<OpeningDay> fromSlots(
    List<OpeningSlot> slots,
    int todayIndex, {
    bool use24Hour = false,
  }) {
    if (slots.isEmpty) return const [];

    final byDay = <int, List<OpeningSlot>>{};
    for (final slot in slots) {
      if (slot.isClosed) continue;
      final day = slot.dayIndex;
      if (day == null || day < 0 || day > 6) continue;
      byDay.putIfAbsent(day, () => []).add(slot);
    }

    final week = <OpeningDay>[];
    for (var offset = 0; offset < 7; offset++) {
      final day = (todayIndex + offset) % 7;
      final daySlots = List<OpeningSlot>.from(byDay[day] ?? const <OpeningSlot>[]);
      daySlots.sort(
        (a, b) => (OpeningHoursFormat.minutesOf(a.openingTime) ?? 0)
            .compareTo(OpeningHoursFormat.minutesOf(b.openingTime) ?? 0),
      );

      final ranges = daySlots
          .map(
            (slot) => use24Hour
                ? OpeningHoursFormat.rangeLabel24h(
                    slot.openingTime,
                    slot.closingTime,
                  )
                : slot.displayRange,
          )
          .toList();

      week.add(
        OpeningDay(
          dayOfWeek: day,
          dayName: OpeningHoursFormat.dayNames[day],
          dayShort: OpeningHoursFormat.dayNames[day].substring(0, 3),
          isToday: offset == 0,
          isClosed: ranges.isEmpty,
          ranges: ranges,
          label: ranges.isEmpty ? 'Closed' : ranges.join(', '),
        ),
      );
    }

    return week;
  }
}

/// Facility model
class Facility {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final bool isActive;

  Facility({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = '',
    this.isActive = true,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'is_active': isActive,
    };
  }
}

/// Restaurant Image model
class RestaurantImage {
  final int id;
  final ImageVariants image;
  final String altText;
  final String imageType; // gallery, menu
  final bool isPrimary;
  final int order;

  RestaurantImage({
    required this.id,
    required this.image,
    this.altText = '',
    this.imageType = 'gallery',
    this.isPrimary = false,
    this.order = 0,
  });

  // Convenience getter for backward compatibility
  String get imageUrl => image.urlFor(fullScreen: false) ?? '';

  factory RestaurantImage.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'] ?? json['image_url'];
    ImageVariants parsedImage;
    if (rawImage is Map<String, dynamic>) {
      parsedImage = ImageVariants.fromJson(rawImage);
    } else if (rawImage is String) {
      parsedImage = ImageVariants(medium: rawImage, large: rawImage);
    } else {
      parsedImage = const ImageVariants();
    }

    return RestaurantImage(
      id: json['id'] as int? ?? 0,
      image: parsedImage,
      altText: json['alt_text'] as String? ?? '',
      imageType: json['image_type'] as String? ?? 'gallery',
      isPrimary: json['is_primary'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image.toJson(),
      'alt_text': altText,
      'image_type': imageType,
      'is_primary': isPrimary,
      'order': order,
    };
  }
}


/// Helper to safely parse a value to double
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Helper to safely parse a value to int
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Restaurant model
class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String cuisine;
  final String? occupancy; // available, busy, full
  final double rating;
  final int reviewCount;
  final double distance; // in km
  final double? distanceMiles; // directly from API
  final Discount discount;
  final List<String> images;
  final String phoneNumber;
  final String website;
  final List<String> openingHours;
  final bool requiresBooking;
  final List<String> restrictions;
  final double leaderboardScore; // 0-100 score
  final String? slug; // Optional slug for API calls
  final int? priceRange; // Price range 1-4
  final String? postcode;
  final String? email;
  final bool isFavourite;
  final bool hasUserReviewed;
  final List<OpeningSlot> openingSlots;

  /// Server-computed `Open · Closes 3 pm` line. Null when no hours are set,
  /// in which case the UI should omit the status entirely.
  final OpeningStatus? openingStatus;

  /// Per-weekday windows starting from today.
  final List<OpeningDay> openingHoursDisplay;
  final List<Discount> activeDeals;
  final List<Facility> facilities;
  final String menuType; // structured, image
  final List<RestaurantImage> restaurantImages;
  final List<Cuisine> cuisines;
  final List<RestaurantCategory> categories;
  final bool verified;
  final bool isFeatured;
  final bool loyaltyCardEnabled;
  final int? loyaltyRequiredRedemptions;
  final String? loyaltyRewardDescription;
  final LoyaltyProgram? loyaltyProgram;
  final bool bookingsEnabled;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.cuisine,
    this.occupancy,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    this.distanceMiles,
    required this.discount,
    this.images = const [],
    this.phoneNumber = '',
    this.website = '',
    this.openingHours = const [],
    this.requiresBooking = false,
    this.restrictions = const [],
    this.slug,
    this.priceRange,
    this.postcode,
    this.email,
    this.isFavourite = false,
    this.hasUserReviewed = false,
    this.openingSlots = const [],
    this.openingStatus,
    this.openingHoursDisplay = const [],
    this.activeDeals = const [],
    this.facilities = const [],
    this.leaderboardScore = 0.0,
    this.menuType = 'structured',
    this.restaurantImages = const [],
    this.cuisines = const [],
    this.categories = const [],
    this.verified = false,
    this.isFeatured = false,
    this.loyaltyCardEnabled = false,
    this.loyaltyRequiredRedemptions,
    this.loyaltyRewardDescription,
    this.loyaltyProgram,
    this.bookingsEnabled = true,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final List<Discount> activeDeals =
        (json['active_deals'] as List<dynamic>?)
            ?.map((e) => Discount.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Discount>[];

    final List<Cuisine> cuisines =
        (json['cuisines'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => Cuisine.fromJson(e))
            .toList() ??
        <Cuisine>[];

    final List<RestaurantCategory> categories =
        (json['categories'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => RestaurantCategory.fromJson(e))
            .toList() ??
        <RestaurantCategory>[];

    final List<dynamic> rawImagesList = json['images'] as List<dynamic>? ?? [];
    List<RestaurantImage> parsedRestaurantImages = [];
    List<String> plainStringImages = [];

    for (var raw in rawImagesList) {
      if (raw is Map<String, dynamic>) {
        parsedRestaurantImages.add(RestaurantImage.fromJson(raw));
      } else if (raw is String) {
        plainStringImages.add(raw);
      }
    }

    parsedRestaurantImages.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return a.order.compareTo(b.order);
    });

    final List<String> sortedImageUrls = parsedRestaurantImages
        .map((e) => e.image.urlFor(fullScreen: true) ?? '')
        .where((u) => u.isNotEmpty)
        .toList();

    if (sortedImageUrls.isEmpty && plainStringImages.isNotEmpty) {
      sortedImageUrls.addAll(plainStringImages);
    } else {
      for (var plain in plainStringImages) {
        if (!sortedImageUrls.contains(plain)) {
          sortedImageUrls.add(plain);
        }
      }
    }

    final dynamic rawPrimaryImage =
        json['primary_image'] ?? json['imageUrl'] ?? json['image'] ?? json['image_url'];
    final String fallbackImageUrl = rawPrimaryImage is String ? rawPrimaryImage : '';

    final String primaryImageUrl = sortedImageUrls.isNotEmpty
        ? sortedImageUrls.first
        : fallbackImageUrl;

    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: primaryImageUrl,
      address: json['address'] as String? ?? '',
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
      cuisine:
          json['cuisine'] as String? ??
          (cuisines.isNotEmpty ? cuisines.map((e) => e.name).join(' • ') : ''),
      occupancy: json['occupancy']?.toString(),
      rating:
          _parseDouble(json['average_rating']) ??
          _parseDouble(json['rating']) ??
          0.0,
      reviewCount:
          _parseInt(json['review_count']) ??
          _parseInt(json['reviewCount']) ??
          0,
      distance: _parseDouble(json['distance']) ?? 0.0,
      distanceMiles: _parseDouble(json['distance_miles']),
      activeDeals: activeDeals,
      discount: json['discount'] != null
          ? Discount.fromJson(json['discount'] as Map<String, dynamic>)
          : (activeDeals.isNotEmpty
                ? activeDeals.first
                : Discount(type: 'none', description: '')),
      images: sortedImageUrls,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      website: json['website'] as String? ?? '',
      openingHours:
          (json['openingHours'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      requiresBooking: json['requires_booking'] as bool? ?? false,
      restrictions:
          (json['restrictions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isFavourite: json['is_favourite'] as bool? ?? false,
      cuisines: cuisines,
      hasUserReviewed: json['has_user_reviewed'] as bool? ?? false,
      openingSlots:
          (json['opening_slots'] as List<dynamic>?)
              ?.map((e) => OpeningSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          OpeningSlot.fromHoursMap(
            json['opening_hours'] as Map<String, dynamic>?,
          ),
      openingStatus: json['opening_status'] is Map<String, dynamic>
          ? OpeningStatus.fromJson(json['opening_status'] as Map<String, dynamic>)
          : null,
      openingHoursDisplay:
          (json['opening_hours_display'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => OpeningDay.fromJson(e))
              .toList() ??
          const [],
      facilities:
          (json['facilities'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => Facility.fromJson(e))
              .toList() ??
          [],
      slug: json['slug'] as String?,
      leaderboardScore: _parseDouble(json['leaderboard_score']) ?? 0.0,
      menuType: json['menu_type'] as String? ?? 'structured',
      restaurantImages: parsedRestaurantImages,
      categories: categories,
      verified: json['verified'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      loyaltyCardEnabled: (json['loyalty_card_enabled'] as bool? ?? false) ||
          (json['loyalty_program'] != null &&
              json['loyalty_program']['loyalty_card_enabled'] == true),
      loyaltyRequiredRedemptions:
          _parseInt(json['loyalty_required_redemptions']) ??
          (json['loyalty_program'] != null
              ? _parseInt(json['loyalty_program']['required_redemptions'])
              : null),
      loyaltyRewardDescription:
          (json['loyalty_reward_description'] as String?) ??
          (json['loyalty_program'] != null
              ? json['loyalty_program']['reward_description'] as String?
              : null),
      loyaltyProgram: json['loyalty_program'] != null
          ? LoyaltyProgram.fromJson(
              json['loyalty_program'] as Map<String, dynamic>,
            )
          : null,
      bookingsEnabled: json['bookings_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'cuisine': cuisine,
      if (occupancy != null) 'occupancy': occupancy,
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      if (distanceMiles != null) 'distance_miles': distanceMiles,
      'discount': discount.toJson(),
      'phoneNumber': phoneNumber,
      'website': website,
      'openingHours': openingHours,
      'requiresBooking': requiresBooking,
      'restrictions': restrictions,
      'isFavourite': isFavourite,
      'hasUserReviewed': hasUserReviewed,
      'leaderboard_score': leaderboardScore,
      'facilities': facilities.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'menu_type': menuType,
      'images': restaurantImages.map((e) => e.toJson()).toList(),
      'verified': verified,
      'is_featured': isFeatured,
      'loyalty_card_enabled': loyaltyCardEnabled,
      if (loyaltyRequiredRedemptions != null)
        'loyalty_required_redemptions': loyaltyRequiredRedemptions,
      if (loyaltyRewardDescription != null)
        'loyalty_reward_description': loyaltyRewardDescription,
      if (loyaltyProgram != null) 'loyalty_program': loyaltyProgram!.toJson(),
      if (slug != null) 'slug': slug,
      'bookings_enabled': bookingsEnabled,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? address,
    double? latitude,
    double? longitude,
    String? cuisine,
    String? occupancy,
    double? rating,
    int? reviewCount,
    double? distance,
    double? distanceMiles,
    Discount? discount,
    List<String>? images,
    String? phoneNumber,
    String? website,
    List<String>? openingHours,
    bool? requiresBooking,
    List<String>? restrictions,
    double? leaderboardScore,
    String? slug,
    int? priceRange,
    String? postcode,
    String? email,
    bool? isFavourite,
    bool? hasUserReviewed,
    List<OpeningSlot>? openingSlots,
    List<Discount>? activeDeals,
    List<RestaurantCategory>? categories,
    String? menuType,
    List<RestaurantImage>? restaurantImages,
    bool? verified,
    bool? isFeatured,
    bool? loyaltyCardEnabled,
    int? loyaltyRequiredRedemptions,
    String? loyaltyRewardDescription,
    LoyaltyProgram? loyaltyProgram,
    bool? bookingsEnabled,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cuisine: cuisine ?? this.cuisine,
      occupancy: occupancy ?? this.occupancy,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distance: distance ?? this.distance,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      discount: discount ?? this.discount,
      images: images ?? this.images,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      requiresBooking: requiresBooking ?? this.requiresBooking,
      restrictions: restrictions ?? this.restrictions,
      leaderboardScore: leaderboardScore ?? this.leaderboardScore,
      slug: slug ?? this.slug,
      priceRange: priceRange ?? this.priceRange,
      postcode: postcode ?? this.postcode,
      email: email ?? this.email,
      isFavourite: isFavourite ?? this.isFavourite,
      hasUserReviewed: hasUserReviewed ?? this.hasUserReviewed,
      openingSlots: openingSlots ?? this.openingSlots,
      activeDeals: activeDeals ?? this.activeDeals,
      facilities: facilities,
      categories: categories ?? this.categories,
      menuType: menuType ?? this.menuType,
      restaurantImages: restaurantImages ?? this.restaurantImages,
      cuisines: cuisines,
      verified: verified ?? this.verified,
      isFeatured: isFeatured ?? this.isFeatured,
      loyaltyCardEnabled: loyaltyCardEnabled ?? this.loyaltyCardEnabled,
      loyaltyRequiredRedemptions:
          loyaltyRequiredRedemptions ?? this.loyaltyRequiredRedemptions,
      loyaltyRewardDescription:
          loyaltyRewardDescription ?? this.loyaltyRewardDescription,
      loyaltyProgram: loyaltyProgram ?? this.loyaltyProgram,
      bookingsEnabled: bookingsEnabled ?? this.bookingsEnabled,
    );
  }
}

/// Discount model
class Discount {
  final String type; // '2for1', 'percentage', 'fixed'
  final double? percentage;
  final double? fixedAmount;
  final double? comboPrice;
  final String description;
  final String? shortDescription;
  final String? title;
  final List<String> validDays;
  final String? validTime;
  final int? id;
  final String termsAndConditions;
  final int maxPerUser;
  final double? minimumSpendAmount;

  Discount({
    required this.type,
    this.percentage,
    this.fixedAmount,
    this.comboPrice,
    required this.description,
    this.shortDescription,
    this.title,
    this.validDays = const [],
    this.validTime,
    this.id,
    this.termsAndConditions = '',
    this.maxPerUser = 1,
    this.minimumSpendAmount,
  });

  String get displayText {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    switch (type) {
      case '2for1':
        return '2 FOR 1';
      case 'percentage':
        return '${percentage?.toInt() ?? 0}% OFF';
      case 'fixed':
        if (fixedAmount != null) {
          return '£${fixedAmount!.toStringAsFixed(0)} OFF';
        }
        return description.isNotEmpty ? description : 'Special offer';
      case 'combo':
        if (comboPrice != null) {
          return '£${comboPrice!.toStringAsFixed(0)} COMBO';
        }
        return description.isNotEmpty ? description : 'Combo';
      default:
        return description;
    }
  }

  factory Discount.fromJson(Map<String, dynamic> json) {
    // Handle different API formats
    final type =
        json['type'] as String? ?? json['deal_type'] as String? ?? 'none';
    final percentage =
        _parseDouble(json['percentage']) ??
        _parseDouble(json['discount_percentage']);
    final fixedAmount =
        _parseDouble(json['fixedAmount']) ??
        _parseDouble(json['discount_amount']);
    final comboPrice = _parseDouble(json['combo_price']);
    final title = json['title'] as String?;
    final description = json['description'] as String? ?? '';
    final shortDescription = json['short_description'] as String?;
    final minimumSpendAmount =
        _parseDouble(json['minimumSpendAmount']) ??
        _parseDouble(json['minimum_spend_amount']) ??
        _parseDouble(json['minimum_spend']);

    return Discount(
      type: type,
      percentage: percentage,
      fixedAmount: fixedAmount,
      comboPrice: comboPrice,
      description: description,
      shortDescription: shortDescription,
      title: title,
      validDays:
          (json['validDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      validTime: json['validTime'] as String?,
      id: json['id'] as int?,
      termsAndConditions: json['terms_and_conditions'] as String? ?? '',
      maxPerUser: json['max_per_user'] as int? ?? 1,
      minimumSpendAmount: minimumSpendAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'percentage': percentage,
      'fixedAmount': fixedAmount,
      'combo_price': comboPrice,
      'description': description,
      'short_description': shortDescription,
      'title': title,
      'validDays': validDays,
      'validTime': validTime,
      'minimumSpendAmount': minimumSpendAmount,
    };
  }
}

/// Loyalty Program Model
class LoyaltyProgram {
  final bool loyaltyCardEnabled;
  final int requiredRedemptions;
  final String rewardDescription;
  final int completedRedemptions;
  final int remainingRedemptions;
  final String progressText;
  final double progressPercentage;
  final bool isRewardEligible;
  final String? rewardEligibleAt;
  final int totalLifetimeRedemptions;
  final int rewardsEarned;
  final String? lastRewardClaimedAt;
  final String? rewardCode;
  final String? rewardQrCode;

  LoyaltyProgram({
    required this.loyaltyCardEnabled,
    required this.requiredRedemptions,
    required this.rewardDescription,
    required this.completedRedemptions,
    required this.remainingRedemptions,
    required this.progressText,
    required this.progressPercentage,
    required this.isRewardEligible,
    this.rewardEligibleAt,
    required this.totalLifetimeRedemptions,
    required this.rewardsEarned,
    this.lastRewardClaimedAt,
    this.rewardCode,
    this.rewardQrCode,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      loyaltyCardEnabled: json['loyalty_card_enabled'] as bool? ?? false,
      requiredRedemptions: json['required_redemptions'] as int? ?? 0,
      rewardDescription: json['reward_description'] as String? ?? '',
      completedRedemptions: json['completed_redemptions'] as int? ?? 0,
      remainingRedemptions: json['remaining_redemptions'] as int? ?? 0,
      progressText: json['progress_text'] as String? ?? '',
      progressPercentage: _parseDouble(json['progress_percentage']) ?? 0.0,
      isRewardEligible: json['is_reward_eligible'] as bool? ?? false,
      rewardEligibleAt: json['reward_eligible_at'] as String?,
      totalLifetimeRedemptions: json['total_lifetime_redemptions'] as int? ?? 0,
      rewardsEarned: json['rewards_earned'] as int? ?? 0,
      lastRewardClaimedAt: json['last_reward_claimed_at'] as String?,
      rewardCode: json['reward_code'] as String?,
      rewardQrCode: json['reward_qr_url'] as String? ?? json['reward_qr_code'] as String?,
    );
  }

  factory LoyaltyProgram.empty() {
    return LoyaltyProgram(
      loyaltyCardEnabled: false,
      requiredRedemptions: 0,
      rewardDescription: '',
      completedRedemptions: 0,
      remainingRedemptions: 0,
      progressText: '',
      progressPercentage: 0.0,
      isRewardEligible: false,
      totalLifetimeRedemptions: 0,
      rewardsEarned: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loyalty_card_enabled': loyaltyCardEnabled,
      'required_redemptions': requiredRedemptions,
      'reward_description': rewardDescription,
      'completed_redemptions': completedRedemptions,
      'remaining_redemptions': remainingRedemptions,
      'progress_text': progressText,
      'progress_percentage': progressPercentage,
      'is_reward_eligible': isRewardEligible,
      'reward_eligible_at': rewardEligibleAt,
      'total_lifetime_redemptions': totalLifetimeRedemptions,
      'rewards_earned': rewardsEarned,
      'last_reward_claimed_at': lastRewardClaimedAt,
      if (rewardCode != null) 'reward_code': rewardCode,
      if (rewardQrCode != null) 'reward_qr_code': rewardQrCode,
    };
  }
}
