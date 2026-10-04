import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import '../../models/restaurant.dart';
import '../../utils/date_time_utils.dart';
import '../app_gradient_button.dart';
import '../generic_bottom_sheet.dart';

/// Result from editing one weekday in [OpeningHoursDaySheet].
class OpeningHoursDayEditResult {
  final List<String> ranges;
  final bool applyToAllDays;

  const OpeningHoursDayEditResult({
    required this.ranges,
    this.applyToAllDays = false,
  });
}

/// Bottom sheet for editing one weekday's opening windows.
///
/// Merchants pick times in 24-hour format and can add multiple shifts (e.g.
/// lunch 11:00-15:00 and dinner 19:00-22:45).
class OpeningHoursDaySheet extends StatefulWidget {
  final String dayKey;
  final List<String> initialRanges;
  final bool allowCopyToAll;

  const OpeningHoursDaySheet({
    super.key,
    required this.dayKey,
    required this.initialRanges,
    this.allowCopyToAll = false,
  });

  static Future<OpeningHoursDayEditResult?> show(
    BuildContext context, {
    required String dayKey,
    required List<String> initialRanges,
    bool allowCopyToAll = false,
  }) {
    return showModalBottomSheet<OpeningHoursDayEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: OpeningHoursDaySheet(
          dayKey: dayKey,
          initialRanges: List<String>.from(initialRanges),
          allowCopyToAll: allowCopyToAll,
        ),
      ),
    );
  }

  @override
  State<OpeningHoursDaySheet> createState() => _OpeningHoursDaySheetState();
}

class _OpeningHoursDaySheetState extends State<OpeningHoursDaySheet> {
  late bool _isOpen;
  late List<String> _ranges;

  String get _dayLabel {
    final index = OpeningHoursFormat.dayKeys.indexOf(widget.dayKey);
    if (index < 0) {
      return widget.dayKey[0].toUpperCase() + widget.dayKey.substring(1);
    }
    return OpeningHoursFormat.dayNames[index];
  }

  @override
  void initState() {
    super.initState();
    _ranges = List<String>.from(widget.initialRanges);
    _isOpen = _ranges.isNotEmpty;
  }

  void _sortRanges() {
    _ranges.sort(
      (a, b) => (OpeningHoursFormat.minutesOf(a.split('-').first) ?? 0)
          .compareTo(OpeningHoursFormat.minutesOf(b.split('-').first) ?? 0),
    );
  }

  String _formatPicked(TimeOfDay time) =>
      DateTimeUtils.formatTimeOfDay24h(time);

  TimeOfDay _parseTime(String raw, TimeOfDay fallback) {
    final minutes = OpeningHoursFormat.minutesOf(raw);
    if (minutes == null) return fallback;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  Future<void> _pickRange({String? existing, int? editIndex}) async {
    final parts = existing?.split('-');
    final openFallback = TimeOfDay(hour: _ranges.isEmpty ? 9 : 19, minute: 0);
    final closeFallback = TimeOfDay(hour: _ranges.isEmpty ? 17 : 22, minute: 0);

    final start = await DateTimeUtils.showTimePicker24h(
      context: context,
      initialTime: parts != null && parts.length == 2
          ? _parseTime(parts[0], openFallback)
          : openFallback,
    );
    if (start == null || !mounted) return;

    final end = await DateTimeUtils.showTimePicker24h(
      context: context,
      initialTime: parts != null && parts.length == 2
          ? _parseTime(parts[1], closeFallback)
          : closeFallback,
    );
    if (end == null || !mounted) return;

    final range = '${_formatPicked(start)}-${_formatPicked(end)}';

    setState(() {
      if (editIndex != null && editIndex < _ranges.length) {
        _ranges[editIndex] = range;
      } else if (!_ranges.contains(range)) {
        _ranges.add(range);
      }
      _sortRanges();
      _isOpen = _ranges.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GenericBottomSheet(
      title: '$_dayLabel Hours',
      footer: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              if (widget.allowCopyToAll && _isOpen && _ranges.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      OpeningHoursDayEditResult(
                        ranges: List<String>.from(_ranges),
                        applyToAllDays: true,
                      ),
                    ),
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text('Apply these hours to all days'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.merchantIndigo,
                      side: BorderSide(
                        color: AppColors.merchantIndigo.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              AppGradientButton(
                width: double.infinity,
                onPressed: () => Navigator.pop(
                  context,
                  OpeningHoursDayEditResult(
                    ranges: _isOpen ? List<String>.from(_ranges) : <String>[],
                  ),
                ),
                child: Text(
                  'Done',
                  style: AppTypography.button.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Toggle Card
              _buildStatusToggleCard(),

              if (_isOpen) ...[
                const SizedBox(height: 20),

                // Shift Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONFIGURED SHIFTS',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.merchantIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_ranges.length} ${_ranges.length == 1 ? 'shift' : 'shifts'}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.merchantIndigo,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Shift Rows
                for (var i = 0; i < _ranges.length; i++)
                  _ShiftRow(
                    label: OpeningHoursFormat.daySummary24h([_ranges[i]]),
                    onEdit: () =>
                        _pickRange(existing: _ranges[i], editIndex: i),
                    onDelete: _ranges.length > 1
                        ? () => setState(() => _ranges.removeAt(i))
                        : null,
                  ),

                const SizedBox(height: 12),

                // Add Shift Button
                InkWell(
                  onTap: () => _pickRange(),
                  borderRadius: AppRadius.medium,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.merchantIndigo.withValues(alpha: 0.04),
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: AppColors.merchantIndigo.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                          color: AppColors.merchantIndigo,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add another shift',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.merchantIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tip Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.merchantIndigo.withValues(alpha: 0.06),
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: AppColors.merchantIndigo.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: AppColors.merchantIndigo,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tip: Add a second shift for a lunch break (e.g. 11:00-15:00 and 19:00-22:45).',
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.textDarkest.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
  }

  Widget _buildStatusToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _isOpen
            ? AppColors.merchantIndigo.withValues(alpha: 0.05)
            : AppColors.background,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: _isOpen
              ? AppColors.merchantIndigo.withValues(alpha: 0.25)
              : AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isOpen
                  ? AppColors.merchantIndigo.withValues(alpha: 0.12)
                  : AppColors.textDisabled.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isOpen ? Icons.storefront_rounded : Icons.storefront_outlined,
              color: _isOpen
                  ? AppColors.merchantIndigo
                  : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open on $_dayLabel',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isOpen
                      ? OpeningHoursFormat.daySummary24h(_ranges)
                      : 'Restaurant is closed on this day',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOpen,
            activeThumbColor: AppColors.merchantIndigo,
            onChanged: (value) {
              setState(() {
                _isOpen = value;
                if (!value) {
                  _ranges.clear();
                } else if (_ranges.isEmpty) {
                  _ranges.add('09:00-17:00');
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final String label;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ShiftRow({required this.label, required this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: AppColors.merchantIndigo.withValues(alpha: 0.2),
        ),
        boxShadow: AppShadows.low,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.merchantIndigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: AppColors.merchantIndigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.merchantIndigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.merchantIndigo,
              ),
            ),
            tooltip: 'Edit shift',
            onPressed: onEdit,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
              tooltip: 'Remove shift',
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact 7-day list for the merchant create/edit restaurant form.
class OpeningHoursMerchantList extends StatelessWidget {
  final Map<String, List<String>> hours;
  final ValueChanged<Map<String, List<String>>> onChanged;

  const OpeningHoursMerchantList({
    super.key,
    required this.hours,
    required this.onChanged,
  });

  Future<void> _editDay(BuildContext context, String dayKey) async {
    final result = await OpeningHoursDaySheet.show(
      context,
      dayKey: dayKey,
      initialRanges: hours[dayKey] ?? const [],
      allowCopyToAll: dayKey == 'monday',
    );
    if (result == null) return;

    final updated = Map<String, List<String>>.from(hours);
    if (result.applyToAllDays) {
      for (final key in OpeningHoursFormat.dayKeys) {
        updated[key] = List<String>.from(result.ranges);
      }
    } else {
      updated[dayKey] = List<String>.from(result.ranges);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: OpeningHoursFormat.dayKeys.map((dayKey) {
        final ranges = hours[dayKey] ?? const <String>[];
        final index = OpeningHoursFormat.dayKeys.indexOf(dayKey);
        final dayName = OpeningHoursFormat.dayNames[index];
        final summary = OpeningHoursFormat.daySummary24h(ranges);
        final isClosed = ranges.isEmpty;
        final shortDay = dayName.substring(0, 3).toUpperCase();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppColors.surface,
            borderRadius: AppRadius.medium,
            child: InkWell(
              onTap: () => _editDay(context, dayKey),
              borderRadius: AppRadius.medium,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: isClosed
                        ? AppColors.cardBorder
                        : AppColors.merchantIndigo.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Day Badge
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isClosed
                            ? AppColors.background
                            : AppColors.merchantIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          shortDay,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: isClosed
                                ? AppColors.textDisabled
                                : AppColors.merchantIndigo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Day Name & Hours
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: AppTypography.caption.copyWith(
                              fontWeight: isClosed
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: isClosed
                                  ? AppColors.textSecondary
                                  : AppColors.merchantIndigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Pill / Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isClosed
                            ? AppColors.background
                            : AppColors.merchantIndigo.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isClosed ? Icons.add_rounded : Icons.edit_rounded,
                        size: 16,
                        color: isClosed
                            ? AppColors.textSecondary
                            : AppColors.merchantIndigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
