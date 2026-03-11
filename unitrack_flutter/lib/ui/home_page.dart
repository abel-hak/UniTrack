import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../main.dart';
import '../features/courses/models.dart';
import '../features/timeline/models.dart';
import '../core/notifications/notification_service.dart';
import 'announcements_exams_page.dart';
import 'profile_page.dart';

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
    final authState = ref.watch(authStateNotifierProvider);
    if (!authState.isAuthed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final auth = authState.user!;
    final coursesAsync = ref.watch(coursesProvider);
    final isPrivileged = auth.role == 'admin' || auth.role == 'publisher';

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
                          _GpaPill(
                              value: _formatGpa(ref.watch(gpaProvider))),
                          const SizedBox(width: 10),
                          _HeaderMenu(isPrivileged: isPrivileged),
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
                          _TimelineTab(authBatchId: auth.batchId),
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
    final courses =
        ref.read(coursesProvider).valueOrNull ?? const <Course>[];
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

// ─── Header popup menu ───────────────────────────────────────

class _HeaderMenu extends ConsumerWidget {
  final bool isPrivileged;

  const _HeaderMenu({required this.isPrivileged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.menu,
          size: 18,
          color: colors.mutedForeground,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onSelected: (value) {
          switch (value) {
            case 'announcements':
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AnnouncementsExamsPage()),
              );
            case 'courses':
              _openAddCourseSheet(context, ref);
            case 'profile':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            case 'logout':
              ref.read(authStateNotifierProvider.notifier).logout();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'announcements',
            child: Row(
              children: [
                Icon(Icons.campaign_outlined, size: 18),
                SizedBox(width: 10),
                Text('Announcements & Exams'),
              ],
            ),
          ),
          if (isPrivileged)
            const PopupMenuItem(
              value: 'courses',
              child: Row(
                children: [
                  Icon(Icons.school_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Add Course'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18),
                SizedBox(width: 10),
                Text('Profile'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: Colors.red),
                SizedBox(width: 10),
                Text('Sign Out', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAddCourseSheet(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authStateNotifierProvider).user!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCourseSheet(batchId: auth.batchId),
    ).then((_) => ref.invalidate(coursesProvider));
  }
}

// ─── Add Course Sheet ────────────────────────────────────────

class _AddCourseSheet extends ConsumerStatefulWidget {
  final String batchId;
  const _AddCourseSheet({required this.batchId});

  @override
  ConsumerState<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends ConsumerState<_AddCourseSheet> {
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _credits = TextEditingController(text: '3');
  final _instructor = TextEditingController();
  String _colorKey = 'teal';
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _credits.dispose();
    _instructor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _code.text.trim();
    final title = _title.text.trim();
    final credits = int.tryParse(_credits.text.trim());
    if (code.isEmpty || title.isEmpty || credits == null || credits < 1) return;

    setState(() => _saving = true);
    try {
      final inst = _instructor.text.trim();
      await ref.read(coursesRepositoryProvider).create(
            batchId: widget.batchId,
            code: code,
            title: title,
            credits: credits,
            colorKey: _colorKey,
            instructor: inst.isNotEmpty ? inst : null,
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
    final colorOptions = ['teal', 'yellow', 'terracotta', 'slate'];

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
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
                    'Add course',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Course Code (e.g. CS 301)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _credits,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _colorKey,
                    items: colorOptions
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin:
                                        const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _colorForKey(context, c),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(_cap(c)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged:
                        _saving ? null : (v) => setState(() => _colorKey = v!),
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructor,
              decoration: const InputDecoration(
                labelText: 'Instructor (optional)',
                border: OutlineInputBorder(),
              ),
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
                  : const Text('Create Course',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Assignment Sheet ────────────────────────────────────

class _AddAssignmentSheet extends ConsumerStatefulWidget {
  final List<Course> courses;

  const _AddAssignmentSheet({required this.courses});

  @override
  ConsumerState<_AddAssignmentSheet> createState() =>
      _AddAssignmentSheetState();
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
      _dueAt =
          DateTime(d.year, d.month, d.day, _dueAt.hour, _dueAt.minute);
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (t == null) return;
    setState(() {
      _dueAt = DateTime(
          _dueAt.year, _dueAt.month, _dueAt.day, t.hour, t.minute);
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
      final courseName = widget.courses
          .firstWhere((c) => c.id == _courseId)
          .code;
      NotificationService().scheduleAssignmentReminder(
        id: _dueAt.millisecondsSinceEpoch ~/ 1000,
        title: title,
        courseCode: courseName,
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
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
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
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
                  .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.code)))
                  .toList(),
              onChanged:
                  _saving ? null : (v) => setState(() => _courseId = v!),
              decoration: const InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(
                    value: 'assignment', child: Text('Assignment')),
                DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                DropdownMenuItem(
                    value: 'project', child: Text('Project')),
                DropdownMenuItem(value: 'exam', child: Text('Exam')),
              ],
              onChanged:
                  _saving ? null : (v) => setState(() => _type = v!),
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
                    child:
                        Text(DateFormat('EEE, MMM d').format(_dueAt)),
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
                  : const Text('Create',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Assignment Detail Sheet (edit / grade / delete) ─────────

class _AssignmentDetailSheet extends ConsumerStatefulWidget {
  final TimelineAssignment assignment;

  const _AssignmentDetailSheet({required this.assignment});

  @override
  ConsumerState<_AssignmentDetailSheet> createState() =>
      _AssignmentDetailSheetState();
}

class _AssignmentDetailSheetState
    extends ConsumerState<_AssignmentDetailSheet> {
  late String _status;
  late final TextEditingController _grade;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.assignment.status;
    _grade = TextEditingController(
      text: widget.assignment.gradePct?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _grade.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final gradeVal = int.tryParse(_grade.text.trim());
      await ref.read(assignmentsRepositoryProvider).patch(
            id: widget.assignment.id,
            status: _status,
            gradePct: gradeVal,
            clearGrade: _grade.text.trim().isEmpty &&
                widget.assignment.gradePct != null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete assignment?'),
        content:
            const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(assignmentsRepositoryProvider)
          .delete(id: widget.assignment.id);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final a = widget.assignment;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: _courseDotColor(context, a.course.colorKey),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    a.title,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${a.course.code} \u00b7 ${_cap(a.type)}${a.weight != null ? ' \u00b7 ${a.weight}%' : ''}',
              style: text.bodySmall?.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Due ${DateFormat('EEE, MMM d · h:mm a').format(a.dueAt)}',
              style: text.bodySmall?.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'todo', child: Text('To Do')),
                DropdownMenuItem(value: 'done', child: Text('Done')),
                DropdownMenuItem(value: 'late', child: Text('Late')),
              ],
              onChanged:
                  _saving ? null : (v) => setState(() => _status = v!),
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _grade,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Grade % (leave empty if ungraded)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade200),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Text('Save Changes',
                            style:
                                TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grades Tab ──────────────────────────────────────────────

class _GradesTab extends ConsumerWidget {
  const _GradesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    final rows = ref.watch(courseGradesProvider);
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 48,
                color: colors.mutedForeground.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No graded items yet',
              style: text.bodyMedium?.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Grades will appear once you add scores to assignments',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(
                color: colors.mutedForeground.withValues(alpha: 0.7),
              ),
            ),
          ],
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
        final gpaLetter = _pctToLetterGrade(pct);
        final gradeLabel =
            '${pct.toStringAsFixed(0)}% $gpaLetter · ${course.credits}cr';

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: _courseDotColor(context, course.colorKey),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
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

// ─── Timeline Tab ────────────────────────────────────────────

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
                  final selected = isAll
                      ? (activeCourseId == null)
                      : (course.id == activeCourseId);
                  final dotColor = isAll
                      ? Colors.transparent
                      : _courseDotColor(context, course.colorKey);

                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => ref
                        .read(activeCourseIdProvider.notifier)
                        .state = isAll ? null : course.id,
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
                                : Theme.of(context)
                                    .colorScheme
                                    .surface),
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
                                  : Colors.black
                                      .withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Center(
              child: Text(
                'Failed to load courses',
                style: text.bodySmall
                    ?.copyWith(color: colors.mutedForeground),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note_outlined,
                          size: 48,
                          color: colors.mutedForeground
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No upcoming items',
                        style: text.bodyMedium?.copyWith(
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add your first assignment',
                        style: text.bodySmall?.copyWith(
                          color: colors.mutedForeground
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(timelineProvider);
                  ref.invalidate(coursesProvider);
                  ref.invalidate(gpaProvider);
                },
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 92),
                  children: groups,
                ),
              );
            },
            loading: () => const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, __) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade300, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load timeline',
                    style: text.bodySmall
                        ?.copyWith(color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(timelineProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Timeline building ──────────────────────────────────────

List<Widget> _buildTimelineGroups(
    BuildContext context, TimelineBundle bundle) {
  final now = DateTime.now();

  final entries = <({DateTime date, Widget card})>[];

  for (final a in bundle.assignments) {
    final isCountdown =
        a.dueAt.isAfter(now) && a.dueAt.difference(now).inHours <= 24;
    final rightText = a.gradePct != null
        ? '${a.gradePct}%'
        : (isCountdown
            ? _formatCountdown(a.dueAt.difference(now))
            : null);
    final rightAlert = isCountdown && rightText != null;
    final subtitle =
        '${a.course.code} \u00b7 ${_cap(a.type)}${a.weight != null ? ' \u00b7 ${a.weight}%' : ''}';
    final variant = a.gradePct != null
        ? _TimelineVariant.progress
        : (isCountdown
            ? _TimelineVariant.countdown
            : _TimelineVariant.simple);
    final leading =
        a.status == 'done' ? _Leading.check : _Leading.clipboard;

    entries.add((
      date: DateTime(a.dueAt.year, a.dueAt.month, a.dueAt.day),
      card: _TappableAssignmentCard(
        assignment: a,
        child: _TimelineItemCard(
          variant: variant,
          title: a.title,
          subtitle: subtitle,
          rightText: rightText,
          rightTextIsAlert: rightAlert,
          accent: _Accent.primary,
          leading: leading,
          footerRight:
              DateFormat('EEE, MMM d\nh:mm a').format(a.dueAt),
        ),
      ),
    ));
  }

  for (final an in bundle.announcements) {
    final day = DateTime(
        an.createdAt.year, an.createdAt.month, an.createdAt.day);
    entries.add((
      date: day,
      card: _TimelineItemCard(
        variant: _TimelineVariant.announcement,
        title: an.title,
        body: an.body,
        footer:
            'By ${an.authorName} \u00b7 ${DateFormat('EEE, MMM d').format(an.createdAt)}',
        accent: _Accent.neutral,
        leading: _Leading.megaphone,
      ),
    ));
  }

  for (final ex in bundle.exams) {
    final day = DateTime(
        ex.startsAt.year, ex.startsAt.month, ex.startsAt.day);
    final isCountdown =
        ex.startsAt.isAfter(now) &&
            ex.startsAt.difference(now).inHours <= 24;

    entries.add((
      date: day,
      card: _TimelineItemCard(
        variant: isCountdown
            ? _TimelineVariant.countdown
            : _TimelineVariant.simple,
        title: '${ex.course.code} · ${_cap(ex.kind)}',
        subtitle:
            '${ex.course.title}${ex.location != null ? ' · ${ex.location}' : ''}',
        rightText: isCountdown
            ? _formatCountdown(ex.startsAt.difference(now))
            : null,
        rightTextIsAlert: isCountdown,
        accent: _Accent.primary,
        leading: _Leading.book,
        footerRight:
            DateFormat('EEE, MMM d\nh:mm a').format(ex.startsAt),
      ),
    ));
  }

  entries.sort((a, b) => a.date.compareTo(b.date));

  final grouped = <DateTime, List<Widget>>{};
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

// ─── Tappable assignment wrapper ─────────────────────────────

class _TappableAssignmentCard extends ConsumerWidget {
  final TimelineAssignment assignment;
  final Widget child;

  const _TappableAssignmentCard({
    required this.assignment,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final changed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              _AssignmentDetailSheet(assignment: assignment),
        );
        if (changed == true) {
          ref.invalidate(timelineProvider);
        }
      },
      child: child,
    );
  }
}

// ─── Timeline widgets ────────────────────────────────────────

class _TimelineGroup extends StatelessWidget {
  final String label;
  final String week;
  final List<Widget> items;

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
                        color: colors.mutedForeground
                            .withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((e) => Padding(
                    padding:
                        const EdgeInsets.only(left: 18, bottom: 10),
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

    final accentColor =
        accent == _Accent.primary ? primary : colors.border;

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
            margin:
                const EdgeInsets.only(left: 8, top: 10, bottom: 10),
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
                            color: rightTextIsAlert
                                ? const Color(0xFFE11D48)
                                : primary,
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
                        color: colors.mutedForeground
                            .withValues(alpha: 0.9),
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
      child: Icon(icon,
          size: 16, color: Colors.black.withValues(alpha: 0.6)),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────

class _SegmentTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const _SegmentTabs(
      {required this.controller, required this.labels});

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
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

// ─── Helpers ─────────────────────────────────────────────────

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

Color _colorForKey(BuildContext context, String colorKey) =>
    _courseDotColor(context, colorKey);

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

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
  final d = DateTime.utc(date.year, date.month, date.day);
  final thursday =
      d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
  final firstThursday = DateTime.utc(thursday.year, 1, 4);
  final weekNumber =
      1 + ((thursday.difference(firstThursday).inDays) ~/ 7);
  return weekNumber;
}

String _pctToLetterGrade(double pct) {
  if (pct >= 93) return 'A';
  if (pct >= 90) return 'A-';
  if (pct >= 87) return 'B+';
  if (pct >= 83) return 'B';
  if (pct >= 80) return 'B-';
  if (pct >= 77) return 'C+';
  if (pct >= 73) return 'C';
  if (pct >= 70) return 'C-';
  if (pct >= 67) return 'D+';
  if (pct >= 65) return 'D';
  return 'F';
}
