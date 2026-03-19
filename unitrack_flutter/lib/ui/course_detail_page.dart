import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../main.dart';
import '../features/courses/models.dart';
import '../features/timeline/models.dart';
import 'widgets/skeleton_loading.dart';

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

class CourseDetailPage extends ConsumerStatefulWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  Future<void> _editCourse() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCourseSheet(course: widget.course),
    );
    if (result == true && mounted) {
      ref.invalidate(coursesProvider);
      ref.invalidate(timelineProvider);
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        content: const Text(
          'This will also delete all assignments and exams for this course. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(coursesRepositoryProvider).delete(id: widget.course.id);
      ref.invalidate(coursesProvider);
      ref.invalidate(timelineProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
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
        actions: [
          IconButton(
            onPressed: _editCourse,
            icon: const Icon(Icons.edit_rounded, size: 20),
            tooltip: 'Edit course',
          ),
          IconButton(
            onPressed: _deleteCourse,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: 'Delete course',
            color: Colors.red,
          ),
        ],
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

// ─── Edit Course Sheet ───────────────────────────────────────

class _EditCourseSheet extends ConsumerStatefulWidget {
  final Course course;
  const _EditCourseSheet({required this.course});

  @override
  ConsumerState<_EditCourseSheet> createState() => _EditCourseSheetState();
}

class _EditCourseSheetState extends ConsumerState<_EditCourseSheet> {
  late final TextEditingController _title;
  late final TextEditingController _credits;
  late String _colorKey;
  bool _saving = false;

  static const _colorKeys = ['yellow', 'teal', 'terracotta', 'slate'];
  static const _colorLabels = ['Yellow', 'Teal', 'Terracotta', 'Slate'];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.course.title);
    _credits = TextEditingController(text: widget.course.credits.toString());
    _colorKey = widget.course.colorKey;
  }

  @override
  void dispose() {
    _title.dispose();
    _credits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final credits = int.tryParse(_credits.text.trim());
    if (credits == null || credits < 1) return;

    setState(() => _saving = true);
    try {
      await ref.read(coursesRepositoryProvider).update(
            id: widget.course.id,
            title: title != widget.course.title ? title : null,
            credits: credits != widget.course.credits ? credits : null,
            colorKey: _colorKey != widget.course.colorKey ? _colorKey : null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Expanded(
                  child: Text('Edit course',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _credits,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Credits',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _colorKeys.contains(_colorKey) ? _colorKey : _colorKeys.first,
              items: List.generate(
                _colorKeys.length,
                (i) => DropdownMenuItem(
                  value: _colorKeys[i],
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _courseDotColor(context, _colorKeys[i]),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(_colorLabels[i]),
                    ],
                  ),
                ),
              ),
              onChanged: _saving ? null : (v) => setState(() => _colorKey = v!),
              decoration: const InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
