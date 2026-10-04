import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/analytics_dashboard.dart';
import '../../../services/admin_service.dart';
import '../../../utils/date_time_utils.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final AdminService _adminService = AdminService();
  final NumberFormat _intFormat = NumberFormat.compact();
  final NumberFormat _moneyFormat = NumberFormat.currency(locale: 'en_GB', symbol: '£', decimalDigits: 2);

  int _days = 30;
  bool _isLoading = true;
  String? _errorMessage;
  AdminAnalyticsDashboard? _dashboard;

  String get _startDate => _days == 7 ? '7daysAgo' : '30daysAgo';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _adminService.getAnalyticsDashboard(startDate: _startDate);
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _setDays(int days) {
    if (_days == days) return;
    setState(() => _days = days);
    _load();
  }

  String _n(int value) => _intFormat.format(value);

  String _money(double value) => _moneyFormat.format(value);

  String _shortDate(String raw) {
    if (raw.length != 8) return raw;
    final parsed = DateTime.tryParse('${raw.substring(0, 4)}-${raw.substring(4, 6)}-${raw.substring(6, 8)}');
    if (parsed == null) return raw;
    return DateTimeUtils.formatDateOnly(parsed).split(' ').take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Analytics',
          style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            Row(
              children: [
                _PeriodChip(label: '7 days', selected: _days == 7, onTap: () => _setDays(7)),
                const SizedBox(width: 8),
                _PeriodChip(label: '30 days', selected: _days == 30, onTap: () => _setDays(30)),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center, style: AppTypography.body),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_dashboard != null)
              ..._buildDashboard(_dashboard!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDashboard(AdminAnalyticsDashboard data) {
    final platforms = data.platforms;
    final platformTotal = platforms.fold<int>(0, (sum, p) => sum + p.activeUsers);
    final android = platforms.where((p) => p.platform.toLowerCase() == 'android').fold<int>(0, (s, p) => s + p.activeUsers);
    final androidPct = platformTotal == 0 ? 0.0 : android / platformTotal;

    const palette = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];
    final engagementMax = data.engagement.fold<int>(0, (m, e) => e.count > m ? e.count : m);

    return [
      _LiveUsersBanner(count: _n(data.realtimeActiveUsers)),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _KpiCard(label: 'Active users', value: _n(data.overview.activeUsers), icon: Icons.people_alt_rounded, color: AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: _KpiCard(label: 'First opens', value: _n(data.behaviour.firstOpens), icon: Icons.waving_hand_rounded, color: const Color(0xFF0EA5E9))),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _KpiCard(label: 'Sessions', value: _n(data.overview.sessions), icon: Icons.timelapse_rounded, color: const Color(0xFF10B981))),
          const SizedBox(width: 10),
          Expanded(child: _KpiCard(label: 'Screen views', value: _n(data.overview.screenViews), icon: Icons.visibility_rounded, color: const Color(0xFFF59E0B))),
        ],
      ),
      const SizedBox(height: 20),
      _ChartCard(
        title: 'Users over time',
        child: data.dailyUsers.isEmpty
            ? _empty('No user trend yet')
            : _UsersOverTimeChart(
                dailyUsers: data.dailyUsers,
                formatDate: _shortDate,
                formatInt: _n,
              ),
      ),
      const SizedBox(height: 16),
      _buildBusinessSection(data.business),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Platforms',
        child: platforms.isEmpty || platformTotal == 0
            ? _empty('No platform split yet')
            : Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        pct: androidPct,
                        color1: const Color(0xFF22C55E),
                        color2: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: platforms.map((p) {
                        final pct = platformTotal == 0 ? 0 : ((p.activeUsers / platformTotal) * 100).round();
                        final color = p.platform.toLowerCase() == 'android' ? const Color(0xFF22C55E) : AppColors.primary;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p.platform, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600))),
                              Text('$pct%', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Engagement',
        child: data.engagement.every((e) => e.count == 0)
            ? _empty('No engagement events yet')
            : Column(
                children: [
                  for (var i = 0; i < data.engagement.length; i++)
                    _EngagementRow(
                      item: data.engagement[i],
                      color: palette[i % palette.length],
                      maxValue: engagementMax == 0 ? 1 : engagementMax,
                    ),
                ],
              ),
      ),
      if (data.appVersions.isNotEmpty) ...[
        const SizedBox(height: 16),
        _ChartCard(
          title: 'App versions',
          child: Column(
            children: data.appVersions.take(5).map((v) {
              final maxVal = data.appVersions.first.activeUsers;
              return _HorizontalBar(
                item: _BarItem(v.version, v.activeUsers, AppColors.primary),
                maxValue: maxVal == 0 ? 1 : maxVal,
              );
            }).toList(),
          ),
        ),
      ],
    ];
  }

  Widget _buildBusinessSection(AdminAnalyticsBusiness business) {
    final top = business.topRestaurants;
    final topMax = top.isEmpty ? 1 : top.first.views;

    return _ChartCard(
      title: 'Business',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _BusinessStat(
                  label: 'Bookings created',
                  value: _n(business.bookingsCreated),
                  icon: Icons.event_available_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BusinessStat(
                  label: 'Redemptions',
                  value: _n(business.redemptions),
                  icon: Icons.local_offer_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BusinessStat(
                  label: 'Confirmed',
                  value: _n(business.bookingsConfirmed),
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BusinessStat(
                  label: 'Savings delivered',
                  value: _money(business.redemptionValue),
                  icon: Icons.savings_outlined,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BusinessChip(label: 'Cancelled', value: business.bookingsCancelled),
              _BusinessChip(label: 'No-shows', value: business.noShows),
              _BusinessChip(label: 'Restaurant views', value: business.restaurantDetailViews),
              _BusinessChip(label: 'Deal views', value: business.dealViews),
            ],
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Top restaurants by views',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            for (final row in top)
              _HorizontalBar(
                item: _BarItem(row.name, row.views, const Color(0xFF6366F1)),
                maxValue: topMax == 0 ? 1 : topMax,
                compact: true,
              ),
          ],
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textSecondary))),
    );
  }
}

class _LiveUsersBanner extends StatelessWidget {
  final String count;
  const _LiveUsersBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text('Active now', style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(count, style: AppTypography.title.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDisabled.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.title.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _UsersOverTimeChart extends StatefulWidget {
  final List<AdminAnalyticsDailyUsers> dailyUsers;
  final String Function(String) formatDate;
  final String Function(int) formatInt;

  const _UsersOverTimeChart({
    required this.dailyUsers,
    required this.formatDate,
    required this.formatInt,
  });

  @override
  State<_UsersOverTimeChart> createState() => _UsersOverTimeChartState();
}

class _UsersOverTimeChartState extends State<_UsersOverTimeChart> {
  int? _selectedIndex;

  int get _index {
    if (widget.dailyUsers.isEmpty) return 0;
    final i = _selectedIndex ?? widget.dailyUsers.length - 1;
    return i.clamp(0, widget.dailyUsers.length - 1);
  }

  void _selectFromDx(double dx, double width) {
    final n = widget.dailyUsers.length;
    if (n <= 1) {
      setState(() => _selectedIndex = 0);
      return;
    }
    final t = (dx / width).clamp(0.0, 1.0);
    setState(() => _selectedIndex = (t * (n - 1)).round());
  }

  List<String> _axisLabels() {
    final rows = widget.dailyUsers;
    if (rows.isEmpty) return const [];
    if (rows.length == 1) return [widget.formatDate(rows.first.date)];
    final indexes = {0, rows.length ~/ 2, rows.length - 1};
    return indexes.map((i) => widget.formatDate(rows[i].date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.dailyUsers;
    final point = rows[_index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.formatDate(point.date),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.formatInt(point.activeUsers),
                          style: AppTypography.title.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text('Active users', style: AppTypography.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.formatInt(point.newUsers),
                          style: AppTypography.title.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                        Text('New users', style: AppTypography.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap or drag on the chart',
          style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _selectFromDx(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) => _selectFromDx(d.localPosition.dx, width),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: _LineChartPainter(
                    active: rows.map((e) => e.activeUsers.toDouble()).toList(),
                    newer: rows.map((e) => e.newUsers.toDouble()).toList(),
                    activeColor: AppColors.primary,
                    newColor: const Color(0xFF0EA5E9),
                    selectedIndex: _index,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _axisLabels()
              .map(
                (label) => Text(
                  label,
                  style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            _LegendDot(color: AppColors.primary, label: 'Active'),
            SizedBox(width: 16),
            _LegendDot(color: Color(0xFF0EA5E9), label: 'New'),
          ],
        ),
      ],
    );
  }
}

class _BusinessStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BusinessStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.body.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BusinessChip extends StatelessWidget {
  final String label;
  final int value;

  const _BusinessChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDisabled.withValues(alpha: 0.15)),
      ),
      child: Text(
        '$label: ${NumberFormat.compact().format(value)}',
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDisabled.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BarItem {
  final String label;
  final int value;
  final Color color;
  const _BarItem(this.label, this.value, this.color);
}

class _EngagementRow extends StatelessWidget {
  final AdminAnalyticsEngagement item;
  final Color color;
  final int maxValue;

  const _EngagementRow({
    required this.item,
    required this.color,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final bar = _HorizontalBar(
      item: _BarItem(item.label, item.count, color),
      maxValue: maxValue,
    );
    if (item.details.isEmpty) return bar;

    final detailMax = item.details.first.count;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 4),
        visualDensity: VisualDensity.compact,
        title: bar,
        children: [
          for (final row in item.details)
            _HorizontalBar(
              item: _BarItem(row.name, row.count, color),
              maxValue: detailMax == 0 ? 1 : detailMax,
              compact: true,
            ),
        ],
      ),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  final _BarItem item;
  final int maxValue;
  final bool compact;

  const _HorizontalBar({
    required this.item,
    required this.maxValue,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxValue == 0 ? 0.0 : item.value / maxValue;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(item.label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600))),
              Text(NumberFormat.compact().format(item.value), style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: item.color.withValues(alpha: 0.12),
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> active;
  final List<double> newer;
  final Color activeColor;
  final Color newColor;
  final int? selectedIndex;

  _LineChartPainter({
    required this.active,
    required this.newer,
    required this.activeColor,
    required this.newColor,
    this.selectedIndex,
  });

  double _y(Size size, double value, double maxVal) {
    return size.height - (value / maxVal) * (size.height - 6) - 3;
  }

  double _x(Size size, int index, int count) {
    if (count <= 1) return size.width / 2;
    return size.width * index / (count - 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (active.isEmpty) return;
    final maxVal = [...active, ...newer].reduce(math.max);
    if (maxVal <= 0) return;

    final grid = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    _drawSeries(canvas, size, active, activeColor, maxVal, fill: true);
    _drawSeries(canvas, size, newer, newColor, maxVal, fill: false);

    final idx = selectedIndex;
    if (idx == null || idx < 0 || idx >= active.length) return;

    final x = _x(size, idx, active.length);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = AppColors.textDisabled.withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );

    void dot(double value, Color color) {
      final y = _y(size, value, maxVal);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }

    dot(active[idx], activeColor);
    if (idx < newer.length) {
      dot(newer[idx], newColor);
    }
  }

  void _drawSeries(Canvas canvas, Size size, List<double> values, Color color, double maxVal, {required bool fill}) {
    if (values.length == 1) {
      final y = _y(size, values.first, maxVal);
      canvas.drawCircle(Offset(size.width / 2, y), 4, Paint()..color = color);
      return;
    }
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = _x(size, i, values.length);
      final y = _y(size, values[i], maxVal);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.12));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.active != active || old.newer != newer || old.selectedIndex != selectedIndex;
}

class _DonutPainter extends CustomPainter {
  final double pct;
  final Color color1;
  final Color color2;

  _DonutPainter({required this.pct, required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeW = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = color2.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * pct.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color1
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2 + 2 * math.pi * pct.clamp(0.0, 1.0),
      2 * math.pi * (1 - pct.clamp(0.0, 1.0)),
      false,
      Paint()
        ..color = color2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.pct != pct;
}
