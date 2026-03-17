import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../main.dart';
import '../features/courses/models.dart';
import '../features/timeline/models.dart';
import '../core/notifications/notification_service.dart';
import 'announcements_exams_page.dart';
import 'calendar_tab.dart';
import 'course_detail_page.dart';
import 'profile_page.dart';
import 'widgets/empty_state.dart';
import 'widgets/skeleton_loading.dart';
import 'widgets/styled_dialog.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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

    final firstName = auth.name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final courseCount = coursesAsync.maybeWhen(data: (c) => c.length, orElse: () => 0);

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
                    // ── Header ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowCard,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hi $firstName!',
                                      style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      greeting,
                                      style: text.bodyMedium?.copyWith(
                                        color: colors.mutedForeground,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const _ThemeToggle(),
                              const SizedBox(width: 6),
                              const _HeaderMenu(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _GpaPill(value: _formatGpa(ref.watch(gpaProvider))),
                              const SizedBox(width: 12),
                              _StatChip(
                                icon: Icons.school_rounded,
                                label: '$courseCount courses',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Segment tabs ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: _SegmentTabs(
                        controller: _tabController,
                        labels: const ['Timeline', 'Calendar', 'Grades'],
                      ),
                    ),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _TimelineTab(authBatchId: auth.batchId),
                          const CalendarTab(),
                          const _GradesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () => _openAddAssignmentSheet(context),
                    child: const Icon(Icons.add, size: 26),
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
    if (courses.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least one course first'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        final auth = ref.read(authStateNotifierProvider).user;
        if (auth != null) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddCourseSheet(batchId: auth.batchId),
          ).then((_) => ref.invalidate(coursesProvider));
        }
      }
      return;
    }

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

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: () {
          ref.read(themeModeProvider.notifier).state =
              isDark ? ThemeMode.light : ThemeMode.dark;
        },
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 20,
        ),
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.mutedForeground),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.labelMedium?.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMenu extends ConsumerWidget {
  const _HeaderMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 40,
      height: 40,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.grid_view_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        offset: const Offset(0, 48),
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
          PopupMenuItem(
            value: 'announcements',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.campaign_rounded, size: 20, color: primary),
              ),
              title: const Text('Announcements & Exams'),
            ),
          ),
          PopupMenuItem(
            value: 'courses',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school_rounded, size: 20, color: primary),
              ),
              title: const Text('Add Course'),
            ),
          ),
          PopupMenuItem(
            value: 'profile',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.mutedForeground.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_rounded, size: 20, color: colors.mutedForeground),
              ),
              title: const Text('Profile'),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout_rounded, size: 20, color: Colors.red.shade700),
              ),
              title: Text('Sign Out', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
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
    } catch (e) {
      if (mounted) {
        final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Failed to add course';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
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
          .title;
      NotificationService().scheduleAssignmentReminder(
        id: _dueAt.millisecondsSinceEpoch ~/ 1000,
        title: title,
        courseCode: courseName,
        dueAt: _dueAt,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Failed to add assignment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
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
                      DropdownMenuItem(value: c.id, child: Text(c.title)))
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
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
              '${a.course.title} \u00b7 ${_cap(a.type)}${a.weight != null ? ' \u00b7 ${a.weight}%' : ''}',
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
      return const EmptyState(
        icon: Icons.school_outlined,
        title: 'No graded items yet',
        subtitle: 'Grades will appear once you add scores to assignments',
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

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailPage(course: course),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          course.title,
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.code,
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
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.mutedForeground,
                  ),
                ],
              ),
            ),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                    onLongPress: isAll
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CourseDetailPage(course: course),
                              ),
                            ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: (!isAll && selected)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (!isAll && selected)
                              ? Theme.of(context).colorScheme.primary
                              : colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isAll) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isAll ? 'All' : course.title,
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: (!isAll && selected)
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
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
            error: (_, __) => EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load courses',
              action: TextButton(
                onPressed: () => ref.invalidate(coursesProvider),
                child: const Text('Retry'),
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
                return const EmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'No upcoming items',
                  subtitle: 'Tap + to add your first assignment',
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
                  children: [
                    const _TodayPlanCard(),
                    const SizedBox(height: 12),
                    ...groups,
                  ],
                ),
              );
            },
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
              children: const [
                SizedBox(height: 12),
                TimelineCardSkeleton(),
                SizedBox(height: 10),
                TimelineCardSkeleton(),
                SizedBox(height: 10),
                TimelineCardSkeleton(),
              ],
            ),
            error: (e, __) => EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load timeline',
              action: TextButton(
                onPressed: () => ref.invalidate(timelineProvider),
                child: const Text('Retry'),
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
        '${a.course.title} \u00b7 ${_cap(a.type)}${a.weight != null ? ' \u00b7 ${a.weight}%' : ''}';
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
          typeLabel: 'Assignment',
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
        typeLabel: 'Announcement',
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
        typeLabel: 'Exam',
        title: '${ex.course.title} · ${_cap(ex.kind)}',
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

// ─── Staggered animation ─────────────────────────────────────

class _StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeIn({required this.index, required this.child});

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
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

    const lineLeft = 13.0;
    const dotSize = 8.0;
    const cardPaddingLeft = 20.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Stack(
        children: [
          Positioned(
            left: lineLeft,
            top: 22,
            bottom: 0,
            child: Container(width: 2, color: colors.timelineLine),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0, bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: dotSize,
                      height: dotSize,
                      margin: EdgeInsets.only(left: lineLeft - dotSize / 2, right: 10),
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
              ...items.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(left: cardPaddingLeft, bottom: 16),
                    child: _StaggeredFadeIn(index: entry.key, child: entry.value),
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
  final String? typeLabel;
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
    this.typeLabel,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 72,
            margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
            child: _LeadingIcon(leading: leading),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (typeLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel!,
                        style: text.labelSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
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
    final primary = Theme.of(context).colorScheme.primary;
    final (icon, bgColor, iconColor) = switch (leading) {
      _Leading.check => (
          Icons.check_rounded,
          const Color(0xFF22C55E).withValues(alpha: 0.18),
          const Color(0xFF16A34A),
        ),
      _Leading.megaphone => (
          Icons.campaign_rounded,
          primary.withValues(alpha: 0.15),
          primary,
        ),
      _Leading.clipboard => (
          Icons.assignment_rounded,
          primary.withValues(alpha: 0.15),
          primary,
        ),
      _Leading.book => (
          Icons.menu_book_rounded,
          const Color(0xFFF59E0B).withValues(alpha: 0.2),
          const Color(0xFFD97706),
        ),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: iconColor),
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
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: primary,
        unselectedLabelColor: UniTrackColors.of(context).mutedForeground,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 13),
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
    final primary = Theme.of(context).colorScheme.primary;
    final isPlaceholder = value == '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 18,
            color: isPlaceholder ? colors.mutedForeground : primary,
          ),
          const SizedBox(width: 8),
          Text(
            'GPA',
            style: text.labelMedium?.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isPlaceholder ? colors.mutedForeground : primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPlanCard extends ConsumerStatefulWidget {
  const _TodayPlanCard();

  @override
  ConsumerState<_TodayPlanCard> createState() => _TodayPlanCardState();
}

class _TodayPlanCardState extends ConsumerState<_TodayPlanCard> {
  bool _loading = false;

  Future<void> _showPlanDialog(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(timelineRepositoryProvider);
      final result = await repo.todayPlan();

      if (!mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final colors = UniTrackColors.of(ctx);
          final text = Theme.of(ctx).textTheme;

          if (result == null) {
            return StyledDialog(
              titleIcon: Icons.auto_awesome,
              title: const Text('AI plan'),
              content: Text(
                'Unable to generate a plan right now.',
                style: text.bodyMedium
                    ?.copyWith(color: colors.mutedForeground),
              ),
              actionLabel: 'Close',
              onAction: () => Navigator.of(ctx).pop(),
            );
          }

          final items = result.items;
          final note = result.note;

          return StyledDialog(
            titleIcon: Icons.today,
            title: const Text('Plan for today'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.mutedForeground.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'AI-generated',
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    Text(
                      'You have no urgent items in the next week.',
                      style: text.bodyMedium,
                    )
                  else ...[
                    ...items.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                              child: Text(
                                t,
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      note,
                      style: text.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionLabel: 'Close',
            onAction: () => Navigator.of(ctx).pop(),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What should I work on today?',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask AI to turn your upcoming assignments and exams into a short, focused plan for today.',
                  style: text.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _loading ? null : () => _showPlanDialog(context),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ask AI'),
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
