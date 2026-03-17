import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/notifications/notification_service.dart';
import '../core/providers.dart';
import '../features/announcements_exams/models.dart';
import '../main.dart';
import 'widgets/empty_state.dart';
import 'widgets/skeleton_loading.dart';
import 'widgets/styled_dialog.dart';

class AnnouncementsExamsPage extends ConsumerWidget {
  const AnnouncementsExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final authState = ref.watch(authStateNotifierProvider);
    if (!authState.isAuthed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Announcements & Exams',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Announcements'),
              Tab(text: 'Exams'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (fabContext) {
            return FloatingActionButton(
              onPressed: () => _openFabSheet(fabContext, ref),
              child: const Icon(Icons.add),
            );
          },
        ),
        body: const TabBarView(
          children: [
            _AnnouncementsTab(),
            _ExamsTab(),
          ],
        ),
      ),
    );
  }

  void _openFabSheet(BuildContext context, WidgetRef ref) {
    final controller = DefaultTabController.maybeOf(context);
    final tabIndex = controller?.index ?? 0;
    final auth = ref.read(authStateNotifierProvider).user!;
    final canPostAnnouncements = auth.role == 'admin' || auth.role == 'publisher';

    if (tabIndex == 0) {
      // Announcements tab: open announcement sheet or tell student they can't
      if (canPostAnnouncements) {
        _openAnnouncementSheet(context, ref);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admins and publishers can post announcements.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Exams tab: open exam sheet
      _openExamSheet(context, ref);
    }
  }

  Future<void> _openAnnouncementSheet(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = UniTrackColors.of(ctx);
        final text = Theme.of(ctx).textTheme;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
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
                            'New announcement',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              final body = bodyController.text.trim();
                              if (title.isEmpty || body.isEmpty) return;
                              setState(() => saving = true);
                              final auth =
                                  ref.read(authStateNotifierProvider).user!;
                              await ref
                                  .read(announcementsExamsRepositoryProvider)
                                  .createAnnouncement(
                                    batchId: auth.batchId,
                                    title: title,
                                    body: body,
                                  );
                              ref.invalidate(announcementsProvider);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openExamSheet(BuildContext context, WidgetRef ref) async {
    final courses = ref.read(coursesProvider).valueOrNull ?? const [];
    if (courses.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least one course first to schedule an exam.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    String courseId = courses.first.id;
    String kind = 'midterm';
    DateTime startsAt = DateTime.now().add(const Duration(days: 7));
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = UniTrackColors.of(ctx);
        final text = Theme.of(ctx).textTheme;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickDate() async {
              final d = await showDatePicker(
                context: context,
                initialDate: startsAt,
                firstDate:
                    DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d == null) return;
              setState(() {
                startsAt = DateTime(d.year, d.month, d.day,
                    startsAt.hour, startsAt.minute);
              });
            }

            Future<void> pickTime() async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(startsAt),
              );
              if (t == null) return;
              setState(() {
                startsAt = DateTime(startsAt.year, startsAt.month,
                    startsAt.day, t.hour, t.minute);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
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
                            'New exam',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: courseId,
                      items: courses
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.title),
                              ))
                          .toList(),
                      onChanged: saving
                          ? null
                          : (v) => setState(() => courseId = v!),
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: kind,
                      items: const [
                        DropdownMenuItem(
                            value: 'midterm', child: Text('Midterm')),
                        DropdownMenuItem(
                            value: 'final', child: Text('Final')),
                        DropdownMenuItem(
                            value: 'quiz', child: Text('Quiz')),
                        DropdownMenuItem(
                            value: 'practical', child: Text('Practical')),
                      ],
                      onChanged: saving
                          ? null
                          : (v) => setState(() => kind = v!),
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : pickDate,
                            child: Text(
                              DateFormat('EEE, MMM d').format(startsAt),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : pickTime,
                            child: Text(
                              DateFormat('h:mm a').format(startsAt),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setState(() => saving = true);
                              final auth =
                                  ref.read(authStateNotifierProvider).user!;
                              await ref
                                  .read(announcementsExamsRepositoryProvider)
                                  .createExam(
                                    batchId: auth.batchId,
                                    courseId: courseId,
                                    kind: kind,
                                    startsAt: startsAt,
                                    location:
                                        locationController.text.trim(),
                                    notes: notesController.text.trim(),
                                  );
                              final course = courses.firstWhere(
                                  (c) => c.id == courseId);
                              NotificationService().scheduleExamReminder(
                                id: startsAt.millisecondsSinceEpoch ~/
                                    1000,
                                courseCode: course.title,
                                kind: kind,
                                startsAt: startsAt,
                              );
                              ref.invalidate(examsProvider);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Schedule',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Announcements Tab ───────────────────────────────────────

class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementsProvider);
    final isPrivileged = _isPrivileged(ref);

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No announcements yet',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(announcementsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final a = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnnouncementCard(
                  item: a,
                  canDelete: isPrivileged,
                  onDelete: () => _deleteAnnouncement(context, ref, a),
                ),
              );
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: TimelineCardSkeleton(),
        ),
      ),
      error: (_, __) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load announcements.',
        action: TextButton(
          onPressed: () => ref.invalidate(announcementsProvider),
          child: const Text('Retry'),
        ),
      ),
    );
  }

  Future<void> _deleteAnnouncement(
      BuildContext context, WidgetRef ref, Announcement a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: Text('Delete "${a.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final auth = ref.read(authStateNotifierProvider).user!;
    await ref
        .read(announcementsExamsRepositoryProvider)
        .deleteAnnouncement(batchId: auth.batchId, id: a.id);
    ref.invalidate(announcementsProvider);
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement item;
  final bool canDelete;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.item,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: colors.border.withValues(alpha: 0.5)) : null,
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
            margin: const EdgeInsets.only(left: 10, top: 12, bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.campaign_rounded, size: 18, color: primary),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.mutedForeground.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Announcement',
                      style: text.labelSmall?.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      if (canDelete)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: Colors.red.shade300),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                  item.body,
                  style: text.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By ${item.authorName} · ${DateFormat('EEE, MMM d').format(item.createdAt)}',
                  style: text.labelSmall?.copyWith(
                    color: colors.mutedForeground.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showSummaryDialog(context, item),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('AI TL;DR'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                        foregroundColor: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            colors.mutedForeground.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'AI',
                        style: text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSummaryDialog(
      BuildContext context, Announcement announcement) async {
    final ref = ProviderScope.containerOf(context, listen: false);
    final auth = ref.read(authStateNotifierProvider).user;
    if (auth == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final colors = UniTrackColors.of(ctx);
        final text = Theme.of(ctx).textTheme;

        return FutureBuilder<
            ({String summary, List<String> keyPoints, List<String> dates})?>(
          future: ref
              .read(announcementsExamsRepositoryProvider)
              .summarizeAnnouncement(
                batchId: auth.batchId,
                id: announcement.id,
              ),
          builder: (context, snapshot) {
            Widget body;
            if (snapshot.connectionState == ConnectionState.waiting) {
              body = const SizedBox(
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            } else if (snapshot.hasError || snapshot.data == null) {
              body = Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Unable to generate a summary right now.',
                  style: text.bodyMedium?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              );
            } else {
              final result = snapshot.data!;
              body = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (result.summary.isNotEmpty) ...[
                    Text(
                      result.summary,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (result.keyPoints.isNotEmpty) ...[
                    Text(
                      'Key points',
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...result.keyPoints.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                              child: Text(
                                p,
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (result.dates.isNotEmpty) ...[
                    Text(
                      'Important dates',
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...result.dates.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          d,
                          style: text.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }

            return StyledDialog(
              titleIcon: Icons.auto_awesome,
              title: const Text('AI summary'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  body,
                ],
              ),
              actionLabel: 'Close',
              onAction: () => Navigator.of(ctx).pop(),
            );
          },
        );
      },
    );
  }
}

// ─── Exams Tab ───────────────────────────────────────────────

class _ExamsTab extends ConsumerWidget {
  const _ExamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(examsProvider);

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No exams scheduled',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(examsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExamCard(
                  item: e,
                  canDelete: true,
                  onDelete: () => _deleteExam(context, ref, e),
                ),
              );
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: TimelineCardSkeleton(),
        ),
      ),
      error: (_, __) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load exams.',
        action: TextButton(
          onPressed: () => ref.invalidate(examsProvider),
          child: const Text('Retry'),
        ),
      ),
    );
  }

  Future<void> _deleteExam(
      BuildContext context, WidgetRef ref, Exam e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exam?'),
        content: Text(
            'Delete "${e.course.title} ${_capLocal(e.kind)}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final auth = ref.read(authStateNotifierProvider).user!;
    await ref
        .read(announcementsExamsRepositoryProvider)
        .deleteExam(batchId: auth.batchId, id: e.id);
    ref.invalidate(examsProvider);
  }
}

class _ExamCard extends StatelessWidget {
  final Exam item;
  final bool canDelete;
  final VoidCallback onDelete;

  const _ExamCard({
    required this.item,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final daysUntil = item.startsAt.difference(now).inDays;
    final isUpcoming = daysUntil >= 0 && daysUntil <= 3;
    const accentExam = Color(0xFFD97706);
    const accentExamBg = Color(0xFFF59E0B);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isUpcoming
            ? Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3))
            : (isDark ? Border.all(color: colors.border.withValues(alpha: 0.5)) : null),
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
            margin: const EdgeInsets.only(left: 10, top: 12, bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: accentExam,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: accentExam.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentExamBg.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentExam.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_book_rounded, size: 18, color: accentExam),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.mutedForeground.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Exam',
                      style: text.labelSmall?.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.course.title} · ${_capLocal(item.kind)}',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (canDelete)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: Colors.red.shade300),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.course.title,
                    style: text.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${DateFormat('EEE, MMM d').format(item.startsAt)} · '
                        '${DateFormat('h:mm a').format(item.startsAt)}',
                        style: text.labelSmall?.copyWith(
                          color: isUpcoming
                              ? const Color(0xFFE11D48)
                              : colors.mutedForeground.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUpcoming) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            daysUntil == 0
                                ? 'Today'
                                : daysUntil == 1
                                    ? 'Tomorrow'
                                    : 'In $daysUntil days',
                            style: text.labelSmall?.copyWith(
                              color: const Color(0xFFE11D48),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.location != null && item.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.location!,
                        style: text.labelSmall?.copyWith(
                          color: colors.mutedForeground.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────

bool _isPrivileged(WidgetRef ref) {
  final auth = ref.watch(authStateNotifierProvider).user;
  if (auth == null) return false;
  return auth.role == 'admin' || auth.role == 'publisher';
}

String _capLocal(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
