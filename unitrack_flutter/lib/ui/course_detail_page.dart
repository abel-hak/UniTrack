import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../main.dart';
import '../features/courses/models.dart';
import '../features/timeline/models.dart';

class CourseDetailPage extends ConsumerWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = _courseDotColor(context, course.colorKey);

    final timelineAsync = ref.watch(timelineProvider);
    final courseGrades = ref.watch(courseGradesProvider);

    final gradeEntry = courseGrades.where((g) => g.course.id == course.id).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.title,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text('Failed to load', style: text.bodyMedium),
              ),
              data: (bundle) {
                final assignments = bundle.assignments
                    .where((a) => a.course.id == course.id)
                    .toList()
                  ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
                final exams = bundle.exams
                    .where((e) => e.course.id == course.id)
                    .toList()
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

                final graded = assignments.where((a) => a.gradePct != null).toList();
                final pending = assignments.where((a) => a.gradePct == null).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // ── Course info card ──
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
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.school_rounded,
                                size: 24, color: dotColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.code,
                                  style: text.labelMedium?.copyWith(
                                    color: colors.mutedForeground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  course.title,
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${course.credits} credits',
                                  style: text.bodySmall?.copyWith(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (gradeEntry != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${gradeEntry.percent.toStringAsFixed(0)}%',
                                    style: text.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                    ),
                                  ),
                                  Text(
                                    _pctToLetter(gradeEntry.percent),
                                    style: text.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Stats row ──
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.assignment_rounded,
                          value: '${assignments.length}',
                          label: 'Assignments',
                          color: primary,
                          context: context,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          icon: Icons.menu_book_rounded,
                          value: '${exams.length}',
                          label: 'Exams',
                          color: const Color(0xFFD97706),
                          context: context,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          icon: Icons.check_circle_rounded,
                          value: '${graded.length}',
                          label: 'Graded',
                          color: const Color(0xFF16A34A),
                          context: context,
                        ),
                      ],
                    ),

                    // ── Upcoming assignments ──
                    if (pending.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Upcoming', count: pending.length),
                      const SizedBox(height: 10),
                      ...pending.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AssignmentRow(assignment: a),
                          )),
                    ],

                    // ── Graded assignments ──
                    if (graded.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Graded', count: graded.length),
                      const SizedBox(height: 10),
                      ...graded.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AssignmentRow(assignment: a),
                          )),
                    ],

                    // ── Exams ──
                    if (exams.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Exams', count: exams.length),
                      const SizedBox(height: 10),
                      ...exams.map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ExamRow(exam: ex),
                          )),
                    ],

                    if (assignments.isEmpty && exams.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 48,
                                  color: colors.mutedForeground.withValues(alpha: 0.3)),
                              const SizedBox(height: 8),
                              Text(
                                'No items for this course yet',
                                style: text.bodyMedium?.copyWith(
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static Color _courseDotColor(BuildContext context, String colorKey) {
    final colors = UniTrackColors.of(context);
    return switch (colorKey) {
      'yellow' => colors.courseYellow,
      'teal' => colors.courseTeal,
      'terracotta' => colors.courseTerracotta,
      'slate' => colors.courseSlate,
      _ => colors.courseTeal,
    };
  }

  static String _pctToLetter(double pct) {
    if (pct >= 93) return 'A';
    if (pct >= 90) return 'A-';
    if (pct >= 87) return 'B+';
    if (pct >= 83) return 'B';
    if (pct >= 80) return 'B-';
    if (pct >= 77) return 'C+';
    if (pct >= 73) return 'C';
    if (pct >= 70) return 'C-';
    if (pct >= 67) return 'D+';
    if (pct >= 60) return 'D';
    return 'F';
  }
}

// ─── Widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = UniTrackColors.of(context);
    return Row(
      children: [
        Text(
          title,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.mutedForeground.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: text.labelSmall?.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final BuildContext context;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.context,
  });

  @override
  Widget build(BuildContext outerContext) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final TimelineAssignment assignment;
  const _AssignmentRow({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGraded = assignment.gradePct != null;
    final now = DateTime.now();
    final isPast = assignment.dueAt.isBefore(now) && !isGraded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: colors.border.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowCard,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: isGraded
                  ? const Color(0xFF16A34A)
                  : (isPast ? const Color(0xFFE11D48) : primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_cap(assignment.type)}${assignment.weight != null ? ' · ${assignment.weight}%' : ''} · ${DateFormat('MMM d').format(assignment.dueAt)}',
                  style: text.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isGraded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${assignment.gradePct}%',
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            )
          else
            Text(
              DateFormat('h:mm a').format(assignment.dueAt),
              style: text.labelSmall?.copyWith(
                color: isPast ? const Color(0xFFE11D48) : colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _ExamRow extends StatelessWidget {
  final TimelineExam exam;
  const _ExamRow({required this.exam});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const amber = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: colors.border.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowCard,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: amber,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cap(exam.kind),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('MMM d').format(exam.startsAt)}${exam.location != null ? ' · ${exam.location}' : ''}',
                  style: text.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('h:mm a').format(exam.startsAt),
            style: text.labelSmall?.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
