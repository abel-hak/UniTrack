import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../main.dart';
import '../features/courses/models.dart';
import '../features/timeline/models.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authStateNotifierProvider).user!;
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UniTrack',
                                  style: text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DateFormat('MMMM yyyy').format(DateTime.now())} \u00b7 '
                                  '${coursesAsync.maybeWhen(data: (c) => c.length, orElse: () => 0)} courses',
                                  style: text.bodySmall?.copyWith(
                                    color: colors.mutedForeground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _GpaPill(value: _formatGpa(ref.watch(gpaProvider))),
                          const SizedBox(width: 10),
                          _IconButtonSurface(
                            onTap: () => ref
                                .read(authStateNotifierProvider.notifier)
                                .logout(),
                            child: Icon(
                              Icons.settings_outlined,
                              size: 18,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.border),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _SegmentTabs(
                        controller: _tabController,
                        labels: const ['Timeline', 'Grades'],
                      ),
                    ),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _TimelineTab(
                            authBatchId: auth.batchId,
                          ),
                          const _GradesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadowFab,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: () => _openAddAssignmentSheet(context),
                      child: const Icon(Icons.add, size: 26),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddAssignmentSheet(BuildContext context) async {
    final courses = ref.read(coursesProvider).valueOrNull ?? const <Course>[];
    if (courses.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddAssignmentSheet(courses: courses);
      },
    );
    ref.invalidate(timelineProvider);
  }
}

class _AddAssignmentSheet extends ConsumerStatefulWidget {
  final List<Course> courses;

  const _AddAssignmentSheet({required this.courses});

  @override
  ConsumerState<_AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends ConsumerState<_AddAssignmentSheet> {
  late String _courseId;
  String _type = 'assignment';
  DateTime _dueAt = DateTime.now().add(const Duration(days: 1));
  final _title = TextEditingController();
  final _weight = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courses.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      _dueAt = DateTime(d.year, d.month, d.day, _dueAt.hour, _dueAt.minute);
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (t == null) return;
    setState(() {
      _dueAt = DateTime(_dueAt.year, _dueAt.month, _dueAt.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final w = int.tryParse(_weight.text.trim());

    setState(() => _saving = true);
    try {
      await ref.read(assignmentsRepositoryProvider).create(
            courseId: _courseId,
            title: title,
            type: _type,
            weight: w,
            dueAt: _dueAt,
          );
      if (mounted) Navigator.of(context).pop();
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add assignment',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
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
            DropdownButtonFormField<String>(
              value: _courseId,
              items: widget.courses
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.code)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _courseId = v!),
              decoration: const InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
                DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                DropdownMenuItem(value: 'project', child: Text('Project')),
                DropdownMenuItem(value: 'exam', child: Text('Exam')),
              ],
              onChanged: _saving ? null : (v) => setState(() => _type = v!),
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight % (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _pickDate,
                    child: Text(DateFormat('EEE, MMM d').format(_dueAt)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _pickTime,
                    child: Text(DateFormat('h:mm a').format(_dueAt)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradesTab extends ConsumerWidget {
  const _GradesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    final rows = ref.watch(courseGradesProvider);
    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No graded items yet.',
          style: text.bodyMedium?.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = rows[index];
        final course = row.course;
        final pct = row.percent;
        final gradeLabel = '${pct.toStringAsFixed(0)}% · ${course.credits}cr';
        final dotKey = switch (course.colorKey) {
          'yellow' => _DotColorKey.yellow,
          'teal' => _DotColorKey.teal,
          'terracotta' => _DotColorKey.terracotta,
          'slate' => _DotColorKey.slate,
          _ => _DotColorKey.slate,
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadowCard,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _dotColor(context, dotKey),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.title,
                      style: text.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                gradeLabel,
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineTab extends ConsumerWidget {
  final String authBatchId;

  const _TimelineTab({required this.authBatchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    final coursesAsync = ref.watch(coursesProvider);
    final activeCourseId = ref.watch(activeCourseIdProvider);
    final timelineAsync = ref.watch(timelineProvider);

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: coursesAsync.when(
            data: (courses) {
              final chips = <Course?>[null, ...courses];
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final course = chips[index];
                  final isAll = course == null;
                  final selected =
                      isAll ? (activeCourseId == null) : (course.id == activeCourseId);
                  final dotColor = isAll
                      ? Colors.transparent
                      : _courseDotColor(context, course.colorKey);

                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => ref.read(activeCourseIdProvider.notifier).state =
                        isAll ? null : course.id,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isAll
                            ? Theme.of(context).colorScheme.surface
                            : (selected
                                ? Colors.black.withValues(alpha: 0.88)
                                : Theme.of(context).colorScheme.surface),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isAll) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isAll ? 'All' : course.code,
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: (!isAll && selected)
                                  ? Colors.white
                                  : Colors.black.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Center(
              child: Text(
                'Failed to load courses',
                style: text.bodySmall?.copyWith(color: colors.mutedForeground),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: timelineAsync.when(
            data: (bundle) {
              final groups = _buildTimelineGroups(context, bundle);
              if (groups.isEmpty) {
                return Center(
                  child: Text(
                    'No upcoming items yet.',
                    style: text.bodyMedium?.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                children: groups,
              );
            },
            loading: () => const Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Center(
              child: Text(
                'Failed to load timeline',
                style: text.bodySmall?.copyWith(color: colors.mutedForeground),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<Widget> _buildTimelineGroups(BuildContext context, TimelineBundle bundle) {
  final now = DateTime.now();

  final entries = <({DateTime date, _TimelineItemCard card})>[];

  for (final a in bundle.assignments) {
    final isCountdown = a.dueAt.isAfter(now) && a.dueAt.difference(now).inHours <= 24;
    final rightText = a.gradePct != null
        ? '${a.gradePct}%'
        : (isCountdown ? _formatCountdown(a.dueAt.difference(now)) : null);
    final rightAlert = isCountdown && rightText != null;
    final subtitle =
        '${a.course.code} \u00b7 ${_cap(a.type)}${a.weight != null ? ' \u00b7 ${a.weight}%' : ''}';
    final variant = a.gradePct != null
        ? _TimelineVariant.progress
        : (isCountdown ? _TimelineVariant.countdown : _TimelineVariant.simple);
    final leading = a.gradePct != null ? _Leading.check : _Leading.clipboard;

    entries.add((
      date: DateTime(a.dueAt.year, a.dueAt.month, a.dueAt.day),
      card: _TimelineItemCard(
        variant: variant,
        title: a.title,
        subtitle: subtitle,
        rightText: rightText,
        rightTextIsAlert: rightAlert,
        accent: _Accent.primary,
        leading: leading,
        footerRight: DateFormat('EEE, MMM d\nh:mm a').format(a.dueAt),
      ),
    ));
  }

  for (final an in bundle.announcements) {
    final day = DateTime(an.createdAt.year, an.createdAt.month, an.createdAt.day);
    entries.add((
      date: day,
      card: _TimelineItemCard(
        variant: _TimelineVariant.announcement,
        title: an.title,
        body: an.body,
        footer: 'By ${an.authorName} \u00b7 ${DateFormat('EEE, MMM d').format(an.createdAt)}',
        accent: _Accent.neutral,
        leading: _Leading.megaphone,
      ),
    ));
  }

  entries.sort((a, b) => a.date.compareTo(b.date));

  final grouped = <DateTime, List<_TimelineItemCard>>{};
  for (final e in entries) {
    grouped.putIfAbsent(e.date, () => []).add(e.card);
  }

  final dates = grouped.keys.toList()..sort();
  return dates.map((d) {
    return _TimelineGroup(
      label: _dayLabel(d, now),
      week: 'wk ${_isoWeekNumber(d)}',
      items: grouped[d]!,
    );
  }).toList();
}

class _TimelineGroup extends StatelessWidget {
  final String label;
  final String week;
  final List<_TimelineItemCard> items;

  const _TimelineGroup({
    required this.label,
    required this.week,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 22,
            bottom: 0,
            child: Container(width: 2, color: colors.timelineLine),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: colors.timelineLine,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      label,
                      style: text.labelSmall?.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      week,
                      style: text.labelSmall?.copyWith(
                        color: colors.mutedForeground.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 18, bottom: 10),
                    child: e,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TimelineVariant { progress, announcement, countdown, simple }

enum _Accent { primary, neutral }

enum _Leading { check, megaphone, clipboard, book }

class _TimelineItemCard extends StatelessWidget {
  final _TimelineVariant variant;
  final String title;
  final String? subtitle;
  final String? body;
  final String? footer;
  final String? footerRight;
  final String? rightText;
  final bool rightTextIsAlert;
  final _Accent accent;
  final _Leading leading;

  const _TimelineItemCard({
    required this.variant,
    required this.title,
    this.subtitle,
    this.body,
    this.footer,
    this.footerRight,
    this.rightText,
    this.rightTextIsAlert = false,
    required this.accent,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    final accentColor = accent == _Accent.primary ? primary : colors.border;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 72,
            margin: const EdgeInsets.only(left: 8, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            child: _LeadingIcon(leading: leading),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      if (rightText != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          rightText!,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: rightTextIsAlert ? const Color(0xFFE11D48) : primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: text.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (body != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      body!,
                      style: text.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      footer!,
                      style: text.labelSmall?.copyWith(
                        color: colors.mutedForeground.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (footerRight != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 12),
              child: Text(
                footerRight!,
                textAlign: TextAlign.right,
                style: text.labelSmall?.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final _Leading leading;

  const _LeadingIcon({required this.leading});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final icon = switch (leading) {
      _Leading.check => Icons.check_rounded,
      _Leading.megaphone => Icons.campaign_outlined,
      _Leading.clipboard => Icons.content_paste_rounded,
      _Leading.book => Icons.menu_book_rounded,
    };

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.black.withValues(alpha: 0.6)),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const _SegmentTabs({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.shadowCard,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.black.withValues(alpha: 0.85),
        unselectedLabelColor: Colors.black.withValues(alpha: 0.55),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        tabs: labels.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

class _GpaPill extends StatelessWidget {
  final String value;

  const _GpaPill({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'GPA',
            style: text.labelSmall?.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonSurface extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _IconButtonSurface({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

String _formatGpa(double? gpa) {
  if (gpa == null) return '--';
  return gpa.toStringAsFixed(2);
}

Color _courseDotColor(BuildContext context, String colorKey) {
  final c = UniTrackColors.of(context);
  return switch (colorKey) {
    'yellow' => c.courseYellow,
    'teal' => c.courseTeal,
    'terracotta' => c.courseTerracotta,
    'slate' => c.courseSlate,
    _ => c.courseSlate,
  };
}

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _formatCountdown(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final h = total.inHours;
  final m = total.inMinutes.remainder(60);
  final s = total.inSeconds.remainder(60);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(h)}:${two(m)}:${two(s)}';
}

String _dayLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'TODAY';
  if (diff == 1) return 'TOMORROW';
  if (diff == -1) return 'YESTERDAY';
  return DateFormat('EEEE, MMM d').format(day).toUpperCase();
}

int _isoWeekNumber(DateTime date) {
  // ISO week number algorithm
  final d = DateTime.utc(date.year, date.month, date.day);
  final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
  final firstThursday = DateTime.utc(thursday.year, 1, 4);
  final weekNumber = 1 +
      ((thursday.difference(firstThursday).inDays) ~/ 7);
  return weekNumber;
}

enum _DotColorKey { none, yellow, teal, terracotta, slate }

Color _dotColor(BuildContext context, _DotColorKey key) {
  final c = UniTrackColors.of(context);
  return switch (key) {
    _DotColorKey.none => Colors.transparent,
    _DotColorKey.yellow => c.courseYellow,
    _DotColorKey.teal => c.courseTeal,
    _DotColorKey.terracotta => c.courseTerracotta,
    _DotColorKey.slate => c.courseSlate,
  };
}

