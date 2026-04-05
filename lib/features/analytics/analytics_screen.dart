import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/shared_widgets.dart';
import '../groups/group_provider.dart';
import 'analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Subscribe to all groups to ensure analytics are accurate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // No longer need to subscribe per group, expenseProvider watches all user expenses at once
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Group'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalAnalytics(context),
          _buildGroupAnalytics(context),
        ],
      ),
    );
  }

  Widget _buildPersonalAnalytics(BuildContext context) {
    final categoryData = ref.watch(personalCategorySpendProvider);
    final monthlyData = ref.watch(personalMonthlySpendProvider);
    final dailyData = ref.watch(personalDailyTrendProvider);
    final thisMonthTotal = ref.watch(personalTotalThisMonthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This month total
          SpendlyCard(
            gradient: SpendlyColors.primaryGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Month',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.currency(thisMonthTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pie Chart - Category Breakdown
          const SectionHeader(title: '📊 Category Breakdown'),
          const SizedBox(height: 12),
          if (categoryData.isEmpty)
            const EmptyState(
                icon: Icons.pie_chart_outline,
                title: 'No data yet',
                subtitle: 'Add expenses to see category breakdown')
          else
            SpendlyCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                              } else {
                                _touchedPieIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              }
                            });
                          },
                        ),
                        sections: categoryData.asMap().entries.map((e) {
                          final isTouched = _touchedPieIndex == e.key;
                          final total = categoryData.fold(
                              0.0, (s, c) => s + c.total);
                          final pct = (e.value.total / total * 100);
                          return PieChartSectionData(
                            color: SpendlyColors.chartColors[
                                e.key % SpendlyColors.chartColors.length],
                            value: e.value.total,
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: isTouched ? 80 : 65,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: categoryData.asMap().entries.map((e) {
                      final color = SpendlyColors
                          .chartColors[e.key % SpendlyColors.chartColors.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${e.value.category.emoji} ${e.value.category.label}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Bar Chart - Monthly Spending
          const SectionHeader(title: '📅 Monthly Spending'),
          const SizedBox(height: 12),
          monthlyData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No monthly data available',
                        style: TextStyle(color: SpendlyColors.neutral400)),
                  ),
                )
              : SpendlyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last 6 Months',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SpendlyColors.neutral500)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: monthlyData.isEmpty
                                ? 100.0
                                : monthlyData
                                        .map((m) => m.total)
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.3,
                            barGroups: monthlyData.asMap().entries.map((e) {
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.total,
                                    gradient: const LinearGradient(
                                      colors: [
                                        SpendlyColors.primaryLight,
                                        SpendlyColors.primary
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 22,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i >= 0 && i < monthlyData.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          monthlyData[i].label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 20),

          // Line Chart - Daily Trend
          const SectionHeader(title: '📈 30-Day Trend'),
          const SizedBox(height: 12),
          dailyData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No trend data available',
                        style: TextStyle(color: SpendlyColors.neutral400)),
                  ),
                )
              : SpendlyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily spending last 30 days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SpendlyColors.neutral500)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: (() {
                                if (dailyData.isEmpty) return 1.0;
                                final maxVal = dailyData
                                    .map((d) => d.total)
                                    .reduce((a, b) => a > b ? a : b);
                                return maxVal > 0 ? maxVal / 4 : 1.0;
                              })(),
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: SpendlyColors.neutral200,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.total);
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: SpendlyColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                SpendlyColors.primary.withAlpha(80),
                                SpendlyColors.primary.withAlpha(0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Categories
          const SizedBox(height: 20),
          const SectionHeader(title: '🏆 Top Categories'),
          const SizedBox(height: 12),
          ...categoryData.take(5).toList().asMap().entries.map((e) {
            final total = categoryData.fold(0.0, (s, c) => s + c.total);
            final pct = e.value.total / total;
            final color = SpendlyColors
                .chartColors[e.key % SpendlyColors.chartColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SpendlyCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(e.value.category.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value.category.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          AppFormatters.currency(e.value.total),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withAlpha(20),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGroupAnalytics(BuildContext context) {
    final categoryData = ref.watch(groupCategorySpendProvider);
    final monthlyData = ref.watch(groupMonthlySpendProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie Chart
          const SectionHeader(title: '📊 Group Category Breakdown'),
          const SizedBox(height: 12),
          if (categoryData.isEmpty)
            const EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No group data',
              subtitle: 'Add group expenses to see analytics',
            )
          else
            SpendlyCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: categoryData.asMap().entries.map((e) {
                          final total = categoryData.fold(
                              0.0, (s, c) => s + c.total);
                          final pct = (e.value.total / total * 100);
                          return PieChartSectionData(
                            color: SpendlyColors.chartColors[
                                e.key % SpendlyColors.chartColors.length],
                            value: e.value.total,
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 65,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: categoryData.asMap().entries.map((e) {
                      final color = SpendlyColors.chartColors[
                          e.key % SpendlyColors.chartColors.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            '${e.value.category.emoji} ${e.value.category.label}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Bar Chart
          const SectionHeader(title: '📅 Monthly Group Spending'),
          const SizedBox(height: 12),
          monthlyData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No group monthly data',
                        style: TextStyle(color: SpendlyColors.neutral400)),
                  ),
                )
              : SpendlyCard(
                  child: SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (monthlyData.isEmpty
                                ? 100.0
                                : monthlyData
                                        .map((m) => m.total)
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.3)
                            .clamp(10, double.infinity),
                        barGroups: monthlyData.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.total,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 22,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i >= 0 && i < monthlyData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      monthlyData[i].label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
