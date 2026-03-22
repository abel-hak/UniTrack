import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/analytics/models.dart';
import '../main.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grade Analytics',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(analyticsOverviewProvider);
                ref.invalidate(analyticsTrendProvider);
                ref.invalidate(analyticsProjectionProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: const [
                  _GpaOverviewCard(),
                  SizedBox(height: 20),
                  _CourseBreakdown(),
                  SizedBox(height: 20),
                  _GpaTrendChart(),
                  SizedBox(height: 20),
                  _TargetCalculator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── GPA Overview Card ──────────────────────────────────────────

class _GpaOverviewCard extends ConsumerWidget {
  const _GpaOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final projectionAsync = ref.watch(analyticsProjectionProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: colors.border.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowElevated,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: overviewAsync.when(
        loading: () => const SizedBox(
          height: 140,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => SizedBox(
          height: 140,
          child: Center(
            child: Text(
              'Failed to load',
              style: text.bodyMedium?.copyWith(color: colors.mutedForeground),
            ),
          ),
        ),
        data: (overview) {
          final gpa = overview.gpa;
          final projection = projectionAsync.valueOrNull;

          return Column(
            children: [
              Row(
                children: [
                  _GpaRing(gpa: gpa, size: 100),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gpa != null ? gpa.toStringAsFixed(2) : '--',
                          style: text.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gpa != null
                              ? 'out of 4.00'
                              : 'No grades yet',
                          style: text.bodySmall?.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _MiniStat(
                              label: 'Credits',
                              value:
                                  '${overview.gradedCredits}/${overview.totalCredits}',
                              color: primary,
                            ),
                            const SizedBox(width: 16),
                            _MiniStat(
                              label: 'Courses',
                              value: overview.courses
                                  .where((c) => c.average != null)
                                  .length
                                  .toString(),
                              color: colors.courseTeal,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (projection != null &&
                  projection.optimistic != null &&
                  projection.pessimistic != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_graph_rounded,
                          size: 16, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        'Projection',
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const Spacer(),
                      _ProjectionChip(
                        label: 'Best',
                        value: projection.optimistic!.toStringAsFixed(2),
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 10),
                      _ProjectionChip(
                        label: 'Worst',
                        value: projection.pessimistic!.toStringAsFixed(2),
                        color: const Color(0xFFE11D48),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GpaRing extends StatelessWidget {
  final double? gpa;
  final double size;
  const _GpaRing({required this.gpa, required this.size});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = UniTrackColors.of(context);
    final fraction = gpa != null ? (gpa! / 4.0).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction,
          activeColor: primary,
          bgColor: colors.border.withValues(alpha: 0.3),
          strokeWidth: 8,
        ),
        child: Center(
          child: Text(
            gpa != null ? _letterFromGpa(gpa!) : '--',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: primary,
                ),
          ),
        ),
      ),
    );
  }

  static String _letterFromGpa(double gpa) {
    if (gpa >= 3.85) return 'A';
    if (gpa >= 3.5) return 'A-';
    if (gpa >= 3.15) return 'B+';
    if (gpa >= 2.85) return 'B';
    if (gpa >= 2.5) return 'B-';
    if (gpa >= 2.15) return 'C+';
    if (gpa >= 1.85) return 'C';
    if (gpa >= 1.5) return 'C-';
    if (gpa >= 1.15) return 'D+';
    if (gpa >= 0.85) return 'D';
    return 'F';
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color activeColor;
  final Color bgColor;
  final double strokeWidth;

  _RingPainter({
    required this.fraction,
    required this.activeColor,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = bgColor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (fraction > 0) {
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = activeColor
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.activeColor != activeColor;
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = UniTrackColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: text.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: text.labelSmall
                ?.copyWith(color: colors.mutedForeground, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ProjectionChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ProjectionChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $value',
          style: text.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Course Breakdown ───────────────────────────────────────────

class _CourseBreakdown extends ConsumerWidget {
  const _CourseBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = UniTrackColors.of(context);
    final overviewAsync = ref.watch(analyticsOverviewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Grades',
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        overviewAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => Text(
            'Failed to load',
            style: text.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
          data: (overview) {
            final graded =
                overview.courses.where((c) => c.average != null).toList();
            if (graded.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No graded courses yet',
                    style: text.bodyMedium
                        ?.copyWith(color: colors.mutedForeground),
                  ),
                ),
              );
            }
            return Column(
              children: graded
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseGradeBar(course: c),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

Color _courseDotColor(BuildContext context, String colorKey) {
  final colors = UniTrackColors.of(context);
  return switch (colorKey) {
    'yellow' => colors.courseYellow,
    'teal' => colors.courseTeal,
    'terracotta' => colors.courseTerracotta,
    'slate' => colors.courseSlate,
    _ => colors.courseTeal,
  };
}

class _CourseGradeBar extends StatelessWidget {
  final AnalyticsCourse course;
  const _CourseGradeBar({required this.course});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = UniTrackColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courseColor = _courseDotColor(context, course.colorKey);
    final pct = course.average ?? 0;
    final fraction = (pct / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: colors.border.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: courseColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${course.code} · ${course.title}',
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.average!.toStringAsFixed(0)}%',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: courseColor,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: courseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.letterGrade ?? '',
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: courseColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: colors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(courseColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${course.gradedCount}/${course.totalCount} graded',
                style: text.labelSmall?.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${course.credits} credits · ${course.gpaPoints?.toStringAsFixed(1)} pts',
                style: text.labelSmall?.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── GPA Trend Chart ────────────────────────────────────────────

class _GpaTrendChart extends ConsumerWidget {
  const _GpaTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = UniTrackColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final trendAsync = ref.watch(analyticsTrendProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GPA Trend',
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        trendAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Failed to load',
                style:
                    text.bodySmall?.copyWith(color: colors.mutedForeground),
              ),
            ),
          ),
          data: (points) {
            if (points.length < 2) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowCard,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart_rounded,
                          size: 36,
                          color:
                              colors.mutedForeground.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'Need at least 2 graded items\nto show trend',
                        textAlign: TextAlign.center,
                        style: text.bodySmall
                            ?.copyWith(color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              );
            }

            final minGpa = points
                .map((p) => p.gpa)
                .reduce((a, b) => a < b ? a : b);
            final maxGpa = points
                .map((p) => p.gpa)
                .reduce((a, b) => a > b ? a : b);
            final yMin = (minGpa - 0.3).clamp(0.0, 4.0);
            final yMax = (maxGpa + 0.3).clamp(0.0, 4.0);

            final spots = List.generate(
              points.length,
              (i) => FlSpot(i.toDouble(), points[i].gpa),
            );

            final isDark =
                Theme.of(context).brightness == Brightness.dark;

            return Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isDark
                    ? Border.all(
                        color: colors.border.withValues(alpha: 0.5))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowCard,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  minY: yMin,
                  maxY: yMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.border.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.5,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: text.labelSmall?.copyWith(
                              color: colors.mutedForeground,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: math.max(
                            1, (points.length / 5).ceilToDouble()),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('M/d')
                                  .format(points[idx].date),
                              style: text.labelSmall?.copyWith(
                                color: colors.mutedForeground,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final pt = points[spot.spotIndex];
                          return LineTooltipItem(
                            '${pt.gpa.toStringAsFixed(2)} GPA\n${pt.label}',
                            text.labelSmall!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: primary,
                          strokeWidth: 2,
                          strokeColor:
                              Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Target Calculator ──────────────────────────────────────────

class _TargetCalculator extends ConsumerStatefulWidget {
  const _TargetCalculator();

  @override
  ConsumerState<_TargetCalculator> createState() => _TargetCalculatorState();
}

class _TargetCalculatorState extends ConsumerState<_TargetCalculator> {
  String? _selectedCourseId;
  double _targetPct = 85;
  TargetResult? _result;
  bool _loading = false;

  Future<void> _calculate() async {
    if (_selectedCourseId == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(analyticsRepositoryProvider);
      final result = await repo.target(
        courseId: _selectedCourseId!,
        targetPct: _targetPct,
      );
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to calculate'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = UniTrackColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overviewAsync = ref.watch(analyticsOverviewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grade Calculator',
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'What do I need on remaining work?',
          style: text.bodySmall?.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: colors.border.withValues(alpha: 0.5))
                : null,
            boxShadow: [
              BoxShadow(
                color: colors.shadowCard,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: overviewAsync.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
              'Failed to load courses',
              style:
                  text.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            data: (overview) {
              final courses = overview.courses
                  .where((c) => c.totalCount > 0)
                  .toList();
              if (courses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No courses with assignments',
                      style: text.bodyMedium
                          ?.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    hint: const Text('Select course'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: courses
                        .map((c) => DropdownMenuItem(
                              value: c.courseId,
                              child: Text('${c.code} · ${c.title}',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCourseId = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Target:',
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_targetPct.toInt()}%',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetPct,
                    min: 50,
                    max: 100,
                    divisions: 50,
                    label: '${_targetPct.toInt()}%',
                    onChanged: (v) => setState(() {
                      _targetPct = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed:
                          _selectedCourseId != null && !_loading
                              ? _calculate
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Calculate',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _TargetResultCard(result: _result!),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TargetResultCard extends StatelessWidget {
  final TargetResult result;
  const _TargetResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = UniTrackColors.of(context);

    final hasUngraded = result.ungradedCount > 0;
    final achievable = result.achievable;

    final bgColor = !hasUngraded
        ? colors.mutedForeground.withValues(alpha: 0.08)
        : achievable
            ? const Color(0xFF16A34A).withValues(alpha: 0.08)
            : const Color(0xFFE11D48).withValues(alpha: 0.08);
    final fgColor = !hasUngraded
        ? colors.mutedForeground
        : achievable
            ? const Color(0xFF16A34A)
            : const Color(0xFFE11D48);
    final icon = !hasUngraded
        ? Icons.info_outline_rounded
        : achievable
            ? Icons.check_circle_rounded
            : Icons.warning_rounded;

    String message;
    if (!hasUngraded) {
      message = 'All assignments in ${result.courseCode} are graded. '
          'Your final average is ${result.currentAverage?.toStringAsFixed(0) ?? "--"}%.';
    } else if (achievable && result.requiredPct != null) {
      message =
          'You need an average of ${result.requiredPct!.toStringAsFixed(1)}% '
          'on your remaining ${result.ungradedCount} item${result.ungradedCount == 1 ? '' : 's'} '
          'to reach ${result.targetPct.toInt()}% in ${result.courseCode}.';
    } else {
      message =
          'Reaching ${result.targetPct.toInt()}% in ${result.courseCode} '
          'is not achievable with perfect scores on remaining work.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fgColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasUngraded && achievable && result.requiredPct != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${result.requiredPct!.toStringAsFixed(1)}%',
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: fgColor,
                      ),
                    ),
                  ),
                Text(
                  message,
                  style: text.bodySmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
