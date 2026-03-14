import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/notifications/notification_service.dart';
import '../core/providers.dart';
import '../features/announcements_exams/models.dart';
import '../main.dart';

class AnnouncementsExamsPage extends ConsumerWidget {
  const AnnouncementsExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final authState = ref.watch(authStateNotifierProvider);
    if (!authState.isAuthed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final auth = authState.user!;
    final isPublisher = auth.role == 'admin' || auth.role == 'publisher';

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
        floatingActionButton: isPublisher
            ? FloatingActionButton(
                onPressed: () => _openFabSheet(context, ref),
                child: const Icon(Icons.add),
              )
            : null,
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
    final tabIndex = DefaultTabController.of(context).index;
    if (tabIndex == 0) {
      _openAnnouncementSheet(context, ref);
    } else {
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
    if (courses.isEmpty) return;

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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                child: Text(c.code),
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
                                courseCode: course.code,
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
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final isPrivileged = _isPrivileged(ref);

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined,
                    size: 48,
                    color: colors.mutedForeground.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'No announcements yet',
                  style: text.bodyMedium?.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load announcements.',
              style: text.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(announcementsProvider),
              child: const Text('Retry'),
            ),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  size: 16,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 10),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
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

            return AlertDialog(
              title: Row(
                children: [
                  const Text('AI summary'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
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
                ],
              ),
              content: body,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
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
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final isPrivileged = _isPrivileged(ref);

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 48,
                    color: colors.mutedForeground.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'No exams scheduled',
                  style: text.bodyMedium?.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
                  canDelete: isPrivileged,
                  onDelete: () => _deleteExam(context, ref, e),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load exams.',
              style: text.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(examsProvider),
              child: const Text('Retry'),
            ),
          ],
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
            'Delete "${e.course.code} ${_capLocal(e.kind)}"? This cannot be undone.'),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUpcoming ? const Color(0xFFE11D48).withValues(alpha: 0.3) : colors.border,
        ),
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
              color: _courseDotColor(context, item.course.colorKey),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.course.code} · ${_capLocal(item.kind)}',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────

bool _isPrivileged(WidgetRef ref) {
  final auth = ref.watch(authStateNotifierProvider).user;
  if (auth == null) return false;
  return auth.role == 'admin' || auth.role == 'publisher';
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

String _capLocal(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
