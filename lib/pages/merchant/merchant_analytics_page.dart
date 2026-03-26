import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import '../../services/merchant_service.dart';

/// Merchant Analytics Page — covers all 12 spec sections
class MerchantAnalyticsPage extends StatefulWidget {
  final int? restaurantId;
  final String restaurantName;

  const MerchantAnalyticsPage({
    super.key,
    this.restaurantId,
    this.restaurantName = 'All Restaurants',
  });

  @override
  State<MerchantAnalyticsPage> createState() => _MerchantAnalyticsPageState();
}

class _MerchantAnalyticsPageState extends State<MerchantAnalyticsPage> {
  final MerchantService _service = MerchantService();
  bool _isLoading = true;
  String? _error;
  int _selectedPeriod = 30;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.getMerchantAnalytics(
        restaurantId: widget.restaurantId,
        period: _selectedPeriod,
      );
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _setPeriod(int days) {
    if (_selectedPeriod == days) return;
    setState(() => _selectedPeriod = days);
    _fetchAnalytics();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _get(String key, [Map<String, dynamic>? fallback]) =>
      (_data[key] as Map<String, dynamic>?) ?? (fallback ?? {});

  int _getInt(String key, [int def = 0]) => (_data[key] as num?)?.toInt() ?? def;
  double _getDouble(String key, [double def = 0]) => (_data[key] as num?)?.toDouble() ?? def;
  List _getList(String key) => (_data[key] as List?) ?? [];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildHeader(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.md),
                  _buildPeriodSelector(),
                  const SizedBox(height: AppSpacing.lg),
                  if (_isLoading)
                    const _LoadingState()
                  else if (_error != null)
                    _ErrorState(error: _error!, onRetry: _fetchAnalytics)
                  else ...[
                    _buildKPISection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildConversionFunnel(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRevenueSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeatmapSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDealPerformance(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCustomerBehaviour(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTrafficSource(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRatingBreakdown(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCompetitorInsights(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCustomerAcquisition(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAlerts(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSuggestions(),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ]),
              ),
            ),
          ],
        ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textDarkest,
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics', style: AppTypography.title.copyWith(
            fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDarkest,
          )),
          Text(widget.restaurantName, style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary, fontWeight: FontWeight.w600,
          )),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            onPressed: _fetchAnalytics,
          ),
        ),
      ],
    );
  }

  // ── Period Selector ───────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [7, 30, 90].map((days) {
          final isSelected = _selectedPeriod == days;
          return Expanded(child: GestureDetector(
            onTap: () => _setPeriod(days),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.purpleGradient : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${days}d',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ));
        }).toList(),
      ),
    );
  }

  // ── 1+2. KPI Cards + Demand & Visibility ─────────────────────────────────

  Widget _buildKPISection() {
    final demand = _get('demand_visibility');
    final funnel = _get('conversion_funnel');
    final revenue = _get('revenue');

    final kpis = [
      _KPIData('Total Views', _fmt(demand['total_views'] ?? 0), Icons.visibility_rounded, const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
      _KPIData('Clicks', _fmt(demand['total_clicks'] ?? 0), Icons.touch_app_rounded, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      _KPIData('Bookings', _fmt(funnel['bookings'] ?? 0), Icons.calendar_month_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _KPIData('Redemptions', _fmt(funnel['redemptions'] ?? 0), Icons.confirmation_number_rounded, const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
      _KPIData('Revenue', '£${((revenue['total_revenue'] as num?) ?? 0).toStringAsFixed(0)}', Icons.payments_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _KPIData('Conversion', '${funnel['redemption_rate'] ?? 0}%', Icons.trending_up_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Demand & Visibility', icon: Icons.bar_chart_rounded),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: kpis.length,
          itemBuilder: (_, i) => _KPICard(data: kpis[i]),
        ),
        const SizedBox(height: AppSpacing.md),
        _InfoChip(label: 'Map Visibility', value: _fmt(demand['map_visibility'] ?? 0), icon: Icons.map_rounded, color: const Color(0xFF6366F1)),
      ],
    );
  }

  // ── 2. Conversion Funnel ──────────────────────────────────────────────────

  Widget _buildConversionFunnel() {
    final f = _get('conversion_funnel');
    final steps = [
      _FunnelStep('Views', (f['views'] as num?)?.toInt() ?? 0, const Color(0xFF6366F1)),
      _FunnelStep('Clicks', (f['clicks'] as num?)?.toInt() ?? 0, const Color(0xFF8B5CF6)),
      _FunnelStep('Bookings', (f['bookings'] as num?)?.toInt() ?? 0, const Color(0xFF10B981)),
      _FunnelStep('Redemptions', (f['redemptions'] as num?)?.toInt() ?? 0, const Color(0xFFF59E0B)),
    ];
    final rates = [
      '${f['click_rate'] ?? 0}% click',
      '${f['booking_rate'] ?? 0}% book',
      '${f['redemption_rate'] ?? 0}% redeem',
    ];
    return _AnalyticsCard(
      title: 'Conversion Funnel',
      icon: Icons.filter_alt_rounded,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _FunnelPainter(steps),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: steps.map((s) => Column(
              children: [
                Text(_fmt(s.value), style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w800, color: s.color, fontSize: 16,
                )),
                Text(s.label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            )).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rates.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r, style: AppTypography.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700,
              )),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ── 3. Revenue Section ────────────────────────────────────────────────────

  Widget _buildRevenueSection() {
    final r = _get('revenue');
    final daily = (r['daily_breakdown'] as List?) ?? [];
    final weekly = (r['weekly_breakdown'] as List?) ?? [];

    return _AnalyticsCard(
      title: 'Revenue Impact',
      icon: Icons.payments_rounded,
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _RevenueMetric(label: 'Total Revenue', value: '£${((r['total_revenue'] as num?) ?? 0).toStringAsFixed(2)}', color: const Color(0xFF10B981))),
            Expanded(child: _RevenueMetric(label: 'Per Deal', value: '£${((r['revenue_per_deal'] as num?) ?? 0).toStringAsFixed(2)}', color: const Color(0xFF6366F1))),
            Expanded(child: _RevenueMetric(label: 'Avg Spend', value: '£${((r['avg_spend_per_customer'] as num?) ?? 0).toStringAsFixed(2)}', color: const Color(0xFFF59E0B))),
          ]),
          const SizedBox(height: AppSpacing.md),
          if (daily.isNotEmpty) ...[
            Text('Daily Breakdown', style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700, color: AppColors.textSecondary,
            )),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 100,
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarChartPainter(
                  values: daily.map((d) => ((d['revenue'] as num?) ?? 0).toDouble()).toList(),
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ] else
            const _EmptyState(message: 'No revenue data yet for this period'),
          if (weekly.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Weekly Breakdown', style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700, color: AppColors.textSecondary,
            )),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarChartPainter(
                  values: weekly.map((w) => ((w['revenue'] as num?) ?? 0).toDouble()).toList(),
                  color: const Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. Heatmap ────────────────────────────────────────────────────────────

  Widget _buildHeatmapSection() {
    final hm = _get('time_heatmap');
    final hourly = List<int>.from((hm['hourly'] as List?) ?? List.filled(24, 0));
    final daily = List<int>.from((hm['daily'] as List?) ?? List.filled(7, 0));
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxH = hourly.isEmpty ? 1 : hourly.reduce(math.max);
    final maxD = daily.isEmpty ? 1 : daily.reduce(math.max);

    return _AnalyticsCard(
      title: 'Time-Based Performance',
      icon: Icons.access_time_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hourly Activity (0–23h)', style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700, color: AppColors.textSecondary,
          )),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (i) {
                final intensity = maxH > 0 ? hourly[i] / maxH : 0.0;
                return Expanded(
                  child: Tooltip(
                    message: '${i}h: ${hourly[i]}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 10 + (40 * intensity),
                      decoration: BoxDecoration(
                        color: Color.lerp(const Color(0xFFE0E7FF), const Color(0xFF4F46E5), intensity),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Day of Week', style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700, color: AppColors.textSecondary,
          )),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(7, (i) {
              final intensity = maxD > 0 ? daily[i] / maxD : 0.0;
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Color.lerp(const Color(0xFFF0FDF4), const Color(0xFF10B981), intensity),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('${daily[i]}', style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: intensity > 0.5 ? Colors.white : AppColors.textSecondary,
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(days[i], style: AppTypography.caption.copyWith(
                      fontSize: 10, color: AppColors.textSecondary,
                    )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── 5. Deal Performance ───────────────────────────────────────────────────

  Widget _buildDealPerformance() {
    final deals = _getList('deal_performance');
    return _AnalyticsCard(
      title: 'Deal Performance',
      icon: Icons.local_offer_rounded,
      child: deals.isEmpty
          ? const _EmptyState(message: 'No deals found for this period')
          : Column(
              children: deals.take(6).map((d) {
                final conv = (d['conversion_rate'] as num?)?.toDouble() ?? 0;
                final isActive = d['is_active'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(
                          d['title'] ?? '',
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: AppTypography.caption.copyWith(
                              color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      // Bar for conversion rate
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: conv / 100,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(
                            conv > 50 ? const Color(0xFF10B981) : conv > 20 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DealStat(label: 'Clicks', value: '${d['clicks'] ?? 0}'),
                          _DealStat(label: 'Bookings', value: '${d['bookings'] ?? 0}'),
                          _DealStat(label: 'Redeemed', value: '${d['redemptions'] ?? 0}'),
                          _DealStat(label: 'Revenue', value: '£${((d['revenue'] as num?) ?? 0).toStringAsFixed(0)}'),
                          _DealStat(label: 'Conv.', value: '${conv.toStringAsFixed(1)}%', highlight: true),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── 6. Customer Behaviour ─────────────────────────────────────────────────

  Widget _buildCustomerBehaviour() {
    final cb = _get('customer_behaviour');
    final newC = (cb['new_customers'] as num?)?.toInt() ?? 0;
    final repC = (cb['repeat_customers'] as num?)?.toInt() ?? 0;
    final total = newC + repC;
    final newPct = total > 0 ? newC / total : 0.0;

    return _AnalyticsCard(
      title: 'Customer Behaviour',
      icon: Icons.people_rounded,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutPainter(
                    pct: newPct.toDouble(),
                    color1: const Color(0xFF6366F1),
                    color2: const Color(0xFF10B981),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(total.toString(), style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w900, fontSize: 22,
                        )),
                        Text('Total', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(color: const Color(0xFF6366F1), label: 'New', value: '$newC'),
                    const SizedBox(height: AppSpacing.md),
                    _LegendRow(color: const Color(0xFF10B981), label: 'Repeat', value: '$repC'),
                    const SizedBox(height: AppSpacing.md),
                    _LegendRow(color: const Color(0xFFF59E0B), label: 'Avg Visits', value: '${cb['avg_visit_frequency'] ?? 0}x'),
                    const SizedBox(height: AppSpacing.md),
                    _LegendRow(color: const Color(0xFF8B5CF6), label: 'Group Size', value: '${cb['avg_group_size'] ?? 0} people'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 7. Traffic Source ─────────────────────────────────────────────────────

  Widget _buildTrafficSource() {
    final ts = _get('traffic_source');
    final sources = [
      _SourceData('Near You', (ts['near_you'] as num?)?.toDouble() ?? 0, const Color(0xFF6366F1)),
      _SourceData('Search', (ts['search'] as num?)?.toDouble() ?? 0, const Color(0xFF10B981)),
      _SourceData('Top Rated', (ts['top_rated'] as num?)?.toDouble() ?? 0, const Color(0xFFF59E0B)),
      _SourceData('Notifications', (ts['notifications'] as num?)?.toDouble() ?? 0, const Color(0xFFEF4444)),
    ];

    final totalPct = sources.fold<double>(0, (sum, s) => sum + s.pct);
    if (totalPct == 0) {
      return _AnalyticsCard(
        title: 'Traffic Sources',
        icon: Icons.alt_route_rounded,
        child: const _EmptyState(message: 'No traffic data yet for this period'),
      );
    }

    return _AnalyticsCard(
      title: 'Traffic Sources',
      icon: Icons.alt_route_rounded,
      child: Column(
        children: [
          SizedBox(
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                children: sources.map((s) => Flexible(
                  flex: (s.pct * 10).toInt(),
                  child: Container(color: s.color),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...sources.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(s.label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600))),
              Text('${s.pct.toStringAsFixed(1)}%', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800, color: s.color)),
            ]),
          )),
        ],
      ),
    );
  }

  // ── 8. Rating Breakdown ───────────────────────────────────────────────────

  Widget _buildRatingBreakdown() {
    final rb = _get('rating_breakdown');
    final overall = (rb['overall'] as num?)?.toDouble() ?? 0;

    return _AnalyticsCard(
      title: 'Rating Breakdown',
      icon: Icons.star_rounded,
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 36),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(overall.toStringAsFixed(1), style: AppTypography.headline.copyWith(
                fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDarkest,
              )),
              Text('Overall Rating', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ]),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _RatingBar(label: 'Food', value: (rb['food'] as num?)?.toDouble() ?? 0, maxValue: 100, color: const Color(0xFF10B981)),
          const SizedBox(height: AppSpacing.sm),
          _RatingBar(label: 'Service', value: (rb['service'] as num?)?.toDouble() ?? 0, maxValue: 100, color: const Color(0xFF6366F1)),
          const SizedBox(height: AppSpacing.sm),
          _RatingBar(label: 'Ambience', value: (rb['ambience'] as num?)?.toDouble() ?? 0, maxValue: 100, color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  // ── 9. Competitor Insights ────────────────────────────────────────────────

  Widget _buildCompetitorInsights() {
    final comps = _getList('competitor_insights');
    return _AnalyticsCard(
      title: 'Competitor Insights',
      icon: Icons.compare_arrows_rounded,
      child: comps.isEmpty
          ? const _EmptyState(message: 'No nearby competitors found')
          : Column(
              children: comps.map((c) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.restaurant_rounded, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name'] ?? '', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                      Text(c['city'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _SmallBadge('⭐ ${c['avg_rating'] ?? 0}', const Color(0xFFFEF9C3), const Color(0xFFCA8A04)),
                    const SizedBox(height: 4),
                    _SmallBadge('${c['deal_count'] ?? 0} deals', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                  ]),
                ]),
              )).toList(),
            ),
    );
  }

  // ── 10. Customer Acquisition ──────────────────────────────────────────────

  Widget _buildCustomerAcquisition() {
    final ca = _get('customer_acquisition');
    return _AnalyticsCard(
      title: 'Customer Acquisition',
      icon: Icons.person_add_rounded,
      child: Row(children: [
        Expanded(child: _BigMetric(
          label: 'Total via App',
          value: _fmt(ca['total_customers'] ?? 0),
          icon: Icons.group_rounded,
          color: const Color(0xFF6366F1),
        )),
        Container(width: 1, height: 60, color: AppColors.divider),
        Expanded(child: _BigMetric(
          label: 'This Period',
          value: _fmt(ca['period_customers'] ?? 0),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
        )),
      ]),
    );
  }

  // ── 11. Performance Alerts ────────────────────────────────────────────────

  Widget _buildAlerts() {
    final alerts = _getList('alerts');
    return _AnalyticsCard(
      title: 'Performance Alerts',
      icon: Icons.notifications_active_rounded,
      child: Column(
        children: alerts.map((a) {
          final severity = a['severity'] as String? ?? 'info';
          Color bg, fg, border;
          IconData ico;
          switch (severity) {
            case 'critical': bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626); border = const Color(0xFFFECACA); ico = Icons.error_rounded; break;
            case 'warning': bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706); border = const Color(0xFFFDE68A); ico = Icons.warning_rounded; break;
            case 'success': bg = const Color(0xFFECFDF5); fg = const Color(0xFF059669); border = const Color(0xFFA7F3D0); ico = Icons.check_circle_rounded; break;
            default: bg = const Color(0xFFF0F9FF); fg = const Color(0xFF0284C7); border = const Color(0xFFBAE6FD); ico = Icons.info_rounded;
          }
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(ico, color: fg, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(a['message'] ?? '', style: AppTypography.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w600))),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── 12. Actionable Suggestions ────────────────────────────────────────────

  Widget _buildSuggestions() {
    final suggestions = _getList('suggestions');
    const colors = [Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFF8B5CF6)];
    const icons = [Icons.lightbulb_rounded, Icons.star_rounded, Icons.trending_up_rounded, Icons.people_rounded];

    return _AnalyticsCard(
      title: 'Actionable Suggestions',
      icon: Icons.lightbulb_rounded,
      child: Column(
        children: suggestions.asMap().entries.map((e) {
          final i = e.key % colors.length;
          final s = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors[i].withValues(alpha: 0.08), colors[i].withValues(alpha: 0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors[i].withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors[i].withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icons[i], color: colors[i], size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(
                s['message'] ?? '',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textDarkest,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              )),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Utilities ────────────────────────────────────────────────────────────

  String _fmt(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(title, style: AppTypography.title.copyWith(
        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDarkest,
      )),
    ]);
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _AnalyticsCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6))],
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, icon: icon),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _KPIData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _KPIData(this.label, this.value, this.icon, this.color, this.bg);
}

class _KPICard extends StatelessWidget {
  final _KPIData data;
  const _KPICard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: data.color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: data.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const Spacer(),
          Text(data.value, style: AppTypography.title.copyWith(
            fontSize: 18, fontWeight: FontWeight.w900, color: data.color,
          )),
          Text(data.label, style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _InfoChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: AppTypography.body.copyWith(color: color, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _RevenueMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RevenueMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: AppTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
    ]);
  }
}

class _DealStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _DealStat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: AppTypography.body.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: highlight ? AppColors.primary : AppColors.textDarkest,
      )),
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 9)),
    ]);
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
      Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800, color: color)),
    ]);
  }
}

class _BigMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _BigMetric({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 6),
      Text(value, style: AppTypography.headline.copyWith(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  const _RatingBar({required this.label, required this.value, required this.maxValue, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    return Row(children: [
      SizedBox(width: 70, child: Text(label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('${value.toStringAsFixed(0)}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800, color: color)),
    ]);
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _SmallBadge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: AppTypography.caption.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _SourceData {
  final String label;
  final double pct;
  final Color color;
  const _SourceData(this.label, this.pct, this.color);
}

class _FunnelStep {
  final String label;
  final int value;
  final Color color;
  const _FunnelStep(this.label, this.value, this.color);
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(children: [
        Icon(Icons.analytics_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(60),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text('Failed to load analytics', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(error, style: AppTypography.caption.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          AppGradientButton(
            onPressed: onRetry,
            width: 120,
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Retry'),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Custom Painters ───────────────────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _BarChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(math.max);
    if (maxVal == 0) return;
    final barWidth = (size.width / values.length) * 0.7;
    final gap = (size.width / values.length) * 0.3;
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = i * (barWidth + gap) + gap / 2;
      final barH = (values[i] / maxVal) * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barH, barWidth, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.values != values;
}

class _FunnelPainter extends CustomPainter {
  final List<_FunnelStep> steps;
  const _FunnelPainter(this.steps);

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.isEmpty) return;
    final maxVal = steps.map((s) => s.value).reduce(math.max);
    if (maxVal == 0) return;

    final stepH = size.height / steps.length;
    for (int i = 0; i < steps.length; i++) {
      final pct = steps[i].value / maxVal;
      final topW = (i == 0 ? 1.0 : steps[i - 1].value / maxVal) * size.width;
      final botW = pct * size.width;
      final topX = (size.width - topW) / 2;
      final botX = (size.width - botW) / 2;
      final y = i * stepH;

      final path = Path()
        ..moveTo(topX, y)
        ..lineTo(topX + topW, y)
        ..lineTo(botX + botW, y + stepH - 4)
        ..lineTo(botX, y + stepH - 4)
        ..close();

      canvas.drawPath(path, Paint()..color = steps[i].color.withValues(alpha: 0.85)..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_FunnelPainter old) => old.steps != steps;
}

class _DonutPainter extends CustomPainter {
  final double pct;
  final Color color1;
  final Color color2;
  const _DonutPainter({required this.pct, required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeW = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false,
        Paint()..color = color2.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * pct, false,
        Paint()..color = color1..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * pct, 2 * math.pi * (1 - pct), false,
        Paint()..color = color2..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.pct != pct;
}
