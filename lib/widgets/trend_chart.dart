// กราฟแท่งคู่รายรับ/รายจ่าย เลือกดูรายเดือนหรือสัปดาห์เต็มจันทร์–อาทิตย์จากรายการจริง
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../utils/date_formatter.dart';
import '../utils/expense_bar_series.dart';
import '../utils/money_format.dart';

class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.transactions,
    required this.month,
    this.today,
  });

  final List<MoneyTransaction> transactions;
  final DateTime month;
  final DateTime? today;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  var _period = ExpenseTrendPeriod.weekly;
  late DateTime _weekAnchor;
  static const _mint = Color(0xFF8ACDB7);
  static const _weekdays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

  @override
  void initState() {
    super.initState();
    _weekAnchor = _initialAnchor();
  }

  DateTime _initialAnchor() {
    final now = widget.today ?? DateTime.now();
    return now.year == widget.month.year && now.month == widget.month.month
        ? DateTime(now.year, now.month, now.day)
        : DateTime(widget.month.year, widget.month.month);
  }

  @override
  void didUpdateWidget(covariant TrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.year != widget.month.year ||
        oldWidget.month.month != widget.month.month) {
      _weekAnchor = _initialAnchor();
    }
  }

  String get _periodLabel =>
      _period == ExpenseTrendPeriod.weekly ? 'รายสัปดาห์' : 'รายเดือน';

  void _moveWeek(int offset) => setState(() {
    // ใช้วันปฏิทินแทนการบวก 24 ชั่วโมง จึงไม่เลื่อนวันเมื่อมีการเปลี่ยนเวลาออมแสง
    _weekAnchor = DateTime(
      _weekAnchor.year,
      _weekAnchor.month,
      _weekAnchor.day + offset * 7,
    );
  });

  String _rangeLabel(ExpenseBarSeries series) {
    final start = series.startDate;
    final end = series.endDate;
    if (start.year == end.year && start.month == end.month) {
      return '${start.day}–${formatThaiDate(end)}';
    }
    final first = formatThaiDate(start);
    return '${start.year == end.year ? first.replaceFirst(' ${start.year}', '') : first} – ${formatThaiDate(end)}';
  }

  Future<void> _showDetails(
    ExpenseBarSeries series,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'ยอดรายวัน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text(
                _rangeLabel(series),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: series.buckets.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bucket = series.buckets[index];
                  final label =
                      '${formatThaiDate(bucket.date)} รายรับ ${formatBaht(bucket.incomeSatang, decimalPlaces: true)} รายจ่าย ${formatBaht(bucket.amountSatang, decimalPlaces: true)}';
                  return Semantics(
                    label: label,
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatThaiDate(bucket.date)),
                          const SizedBox(height: 4),
                          Text(
                            'รายรับ ${formatBaht(bucket.incomeSatang, decimalPlaces: true)}',
                            style: const TextStyle(color: AppColors.income),
                          ),
                          Text(
                            'รายจ่าย ${formatBaht(bucket.amountSatang, decimalPlaces: true)}',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final series = calculateExpenseBarSeries(
      widget.transactions,
      month: widget.month,
      period: _period,
      weekAnchor: _weekAnchor,
      today: widget.today,
    );
    final firstOfMonth = DateTime(widget.month.year, widget.month.month);
    final nextMonth = DateTime(widget.month.year, widget.month.month + 1);
    final nextWeek = DateTime(
      series.startDate.year,
      series.startDate.month,
      series.startDate.day + 7,
    );
    var largest = 0;
    for (final bucket in series.buckets) {
      if (bucket.amountSatang > largest) largest = bucket.amountSatang;
      if (bucket.incomeSatang > largest) largest = bucket.incomeSatang;
    }
    final textScaler = MediaQuery.textScalerOf(context);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                const Text(
                  'แนวโน้มรายรับรายจ่าย',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                PopupMenuButton<ExpenseTrendPeriod>(
                  key: const Key('trend-period-selector'),
                  tooltip: 'เลือกช่วงเวลาแนวโน้ม',
                  initialValue: _period,
                  onSelected: (period) => setState(() {
                    _period = period;
                  }),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: ExpenseTrendPeriod.weekly,
                      child: Text('รายสัปดาห์'),
                    ),
                    PopupMenuItem(
                      value: ExpenseTrendPeriod.monthly,
                      child: Text('รายเดือน'),
                    ),
                  ],
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _periodLabel,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_period == ExpenseTrendPeriod.weekly)
              Row(
                children: [
                  IconButton(
                    tooltip: 'สัปดาห์ก่อนหน้า',
                    onPressed: series.startDate.isAfter(firstOfMonth)
                        ? () => _moveWeek(-1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      _rangeLabel(series),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'สัปดาห์ถัดไป',
                    onPressed: nextWeek.isBefore(nextMonth)
                        ? () => _moveWeek(1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _rangeLabel(series),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            if (!series.hasActivity)
              SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    _period == ExpenseTrendPeriod.weekly
                        ? 'ยังไม่มีรายการในสัปดาห์นี้'
                        : 'ยังไม่มีรายการในเดือนนี้',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) => ExcludeSemantics(
                  child: SizedBox(
                    height: 132 + textScaler.scale(11),
                    child: BarChart(
                      key: const Key('expense-trend-chart'),
                      BarChartData(
                        minY: 0,
                        maxY: largest / 100 * 1.15,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: textScaler.scale(11) + 14,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= series.buckets.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = series.buckets[index].date;
                                // เว้นป้ายท้ายช่วงที่อยู่ติดกัน และลดจำนวนป้ายเมื่อขยายอักษร
                                final largeLabels = textScaler.scale(11) > 16;
                                final regularTick =
                                    date.day % (largeLabels ? 10 : 5) == 0 &&
                                    series.buckets.length - 1 - index >=
                                        (largeLabels ? 5 : 3);
                                final label =
                                    _period == ExpenseTrendPeriod.weekly
                                    ? _weekdays[date.weekday - 1]
                                    : date.day == 1 ||
                                          regularTick ||
                                          index == series.buckets.length - 1
                                    ? '${date.day}'
                                    : '';
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8,
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.primaryDeep,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (_, index, _, rodIndex) =>
                                BarTooltipItem(
                                  '${formatThaiDate(series.buckets[index].date)}\n${rodIndex == 0 ? 'รายรับ' : 'รายจ่าย'} ${formatBaht(rodIndex == 0 ? series.buckets[index].incomeSatang : series.buckets[index].amountSatang, decimalPlaces: true)}',
                                  const TextStyle(
                                    color: AppColors.onPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                          ),
                        ),
                        barGroups: [
                          for (
                            var index = 0;
                            index < series.buckets.length;
                            index++
                          )
                            BarChartGroupData(
                              x: index,
                              barsSpace:
                                  (constraints.maxWidth /
                                          series.buckets.length *
                                          0.1)
                                      .clamp(1.0, 4.0),
                              barRods: [
                                BarChartRodData(
                                  toY: series.buckets[index].incomeSatang / 100,
                                  width:
                                      (constraints.maxWidth /
                                              series.buckets.length *
                                              0.28)
                                          .clamp(1.5, 18.0),
                                  color: _mint,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: series.buckets[index].amountSatang / 100,
                                  width:
                                      (constraints.maxWidth /
                                              series.buckets.length *
                                              0.28)
                                          .clamp(1.5, 18.0),
                                  color: AppColors.primary,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = textScaler.scale(12) > 18;
                final width = stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _total(
                        'รวมรายรับ',
                        series.totalIncomeSatang,
                        _mint,
                        const Key('statistics-trend-income-total'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _total(
                        'รวมรายจ่าย',
                        series.totalSatang,
                        AppColors.primary,
                        const Key('statistics-trend-total'),
                      ),
                    ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showDetails(series),
                child: const Text('ดูยอดรายวัน'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// จุดสีตรงกับชนิดแท่งเสมอ พร้อมป้ายกำกับสำหรับผู้ที่แยกสีได้ยาก
  Widget _total(String label, int satang, Color color, Key valueKey) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const SizedBox(width: 8, height: 8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          formatBaht(satang, decimalPlaces: true),
          key: valueKey,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
