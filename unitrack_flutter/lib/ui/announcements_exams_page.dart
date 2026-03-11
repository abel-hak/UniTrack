import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/announcements_exams/models.dart';
import '../main.dart';

class AnnouncementsExamsPage extends ConsumerWidget {
  const AnnouncementsExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authStateNotifierProvider).user!;
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
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authStateNotifierProvider.notifier).logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
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
                              final auth = ref
                                  .read(authStateNotifierProvider)
                                  .user!;
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
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post'),
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
                firstDate: DateTime.now()
                    .subtract(const Duration(days: 1)),
                lastDate:
                    DateTime.now().add(const Duration(days: 365)),
              );
              if (d == null) return;
              setState(() {
                startsAt = DateTime(
                  d.year,
                  d.month,
                  d.day,
                  startsAt.hour,
                  startsAt.minute,
                );
              });
            }

            Future<void> pickTime() async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(startsAt),
              );
              if (t == null) return;
              setState(() {
                startsAt = DateTime(
                  startsAt.year,
                  startsAt.month,
                  startsAt.day,
                  t.hour,
                  t.minute,
                );
              });
            }

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
                              final auth = ref
                                  .read(authStateNotifierProvider)
                                  .user!;
                              await ref
                                  .read(announcementsExamsRepositoryProvider)
                                  .createExam(
                                    batchId: auth.batchId,
                                    courseId: courseId,
                                    kind: kind,
                                    startsAt: startsAt,
                                    location: locationController.text.trim(),
                                    notes: notesController.text.trim(),
                                  );
                              ref.invalidate(examsProvider);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Schedule'),
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

class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementsProvider);
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No announcements yet.',
              style: text.bodyMedium?.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final a = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnnouncementCard(item: a),
            );
          },
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
        child: Text(
          'Failed to load announcements.',
          style: text.bodySmall
              ?.copyWith(color: colors.mutedForeground),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement item;

  const _AnnouncementCard({required this.item});

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
        ],
      ),
    );
  }
}

class _ExamsTab extends ConsumerWidget {
  const _ExamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(examsProvider);
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No exams scheduled.',
              style: text.bodyMedium?.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final e = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExamCard(item: e),
            );
          },
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
        child: Text(
          'Failed to load exams.',
          style: text.bodySmall
              ?.copyWith(color: colors.mutedForeground),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam item;

  const _ExamCard({required this.item});

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
                Text(
                  '${DateFormat('EEE, MMM d').format(item.startsAt)} · '
                  '${DateFormat('h:mm a').format(item.startsAt)}',
                  style: text.labelSmall?.copyWith(
                    color: colors.mutedForeground.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.location != null && item.location!.isNotEmpty)
                  Text(
                    item.location!,
                    style: text.labelSmall?.copyWith(
                      color: colors.mutedForeground.withValues(alpha: 0.9),
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


