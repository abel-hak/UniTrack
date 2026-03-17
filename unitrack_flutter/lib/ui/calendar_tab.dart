import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../main.dart';
import '../features/timeline/models.dart';

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final timelineAsync = ref.watch(timelineProvider);

    return timelineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('Failed to load', style: text.bodyMedium),
      ),
      data: (bundle) {
        final events = _buildEventMap(bundle);
        final selectedEvents = _selectedDay != null
            ? (events[_selectedDay] ?? [])
            : <_CalendarEvent>[];

        return Column(
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_focusedMonth),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded, size: 24),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded, size: 24),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: text.labelSmall?.copyWith(
                                color: colors.mutedForeground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 4),

            // Calendar grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCalendarGrid(context, events),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: colors.border),

            // Selected day events
            Expanded(
              child: selectedEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded,
                              size: 40, color: colors.mutedForeground.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDay != null
                                ? 'Nothing on ${DateFormat('MMM d').format(_selectedDay!)}'
                                : 'Select a day',
                            style: text.bodyMedium?.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: selectedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final ev = selectedEvents[i];
                        return _EventRow(event: ev);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarGrid(
      BuildContext context, Map<DateTime, List<_CalendarEvent>> events) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    final firstOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    // Monday = 1
    final startWeekday = firstOfMonth.weekday;
    final leadingBlanks = startWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - leadingBlanks + 1;

            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final date = DateTime(
                _focusedMonth.year, _focusedMonth.month, dayNum);
            final isToday = date == todayDay;
            final isSelected = date == _selectedDay;
            final dayEvents = events[date] ?? [];
            final hasAssignment = dayEvents.any((e) => e.type == _EventType.assignment);
            final hasExam = dayEvents.any((e) => e.type == _EventType.exam);
            final hasAnnouncement = dayEvents.any((e) => e.type == _EventType.announcement);

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : (isToday
                            ? primary.withValues(alpha: 0.08)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: text.bodySmall?.copyWith(
                          fontWeight:
                              isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? primary
                                  : Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasAssignment)
                            _dot(isSelected ? Colors.white : primary),
                          if (hasExam)
                            _dot(isSelected ? Colors.white70 : const Color(0xFFD97706)),
                          if (hasAnnouncement)
                            _dot(isSelected ? Colors.white54 : colors.mutedForeground),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Map<DateTime, List<_CalendarEvent>> _buildEventMap(TimelineBundle bundle) {
    final map = <DateTime, List<_CalendarEvent>>{};

    for (final a in bundle.assignments) {
      final day = DateTime(a.dueAt.year, a.dueAt.month, a.dueAt.day);
      (map[day] ??= []).add(_CalendarEvent(
        type: _EventType.assignment,
        title: a.title,
        subtitle: '${a.course.title} · ${a.type}',
        time: DateFormat('h:mm a').format(a.dueAt),
        colorKey: a.course.colorKey,
      ));
    }

    for (final an in bundle.announcements) {
      final day = DateTime(an.createdAt.year, an.createdAt.month, an.createdAt.day);
      (map[day] ??= []).add(_CalendarEvent(
        type: _EventType.announcement,
        title: an.title,
        subtitle: 'By ${an.authorName}',
        time: DateFormat('h:mm a').format(an.createdAt),
      ));
    }

    for (final ex in bundle.exams) {
      final day = DateTime(ex.startsAt.year, ex.startsAt.month, ex.startsAt.day);
      (map[day] ??= []).add(_CalendarEvent(
        type: _EventType.exam,
        title: '${ex.course.title} · ${ex.kind}',
        subtitle: ex.location ?? '',
        time: DateFormat('h:mm a').format(ex.startsAt),
        colorKey: ex.course.colorKey,
      ));
    }

    return map;
  }
}

// ─── Models ──────────────────────────────────────────────────

enum _EventType { assignment, exam, announcement }

class _CalendarEvent {
  final _EventType type;
  final String title;
  final String subtitle;
  final String time;
  final String? colorKey;

  const _CalendarEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.colorKey,
  });
}

// ─── Event row widget ────────────────────────────────────────

class _EventRow extends StatelessWidget {
  final _CalendarEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (icon, accentColor, label) = switch (event.type) {
      _EventType.assignment => (
          Icons.assignment_rounded,
          primary,
          'Assignment',
        ),
      _EventType.exam => (
          Icons.menu_book_rounded,
          const Color(0xFFD97706),
          'Exam',
        ),
      _EventType.announcement => (
          Icons.campaign_rounded,
          colors.mutedForeground,
          'Announcement',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: colors.border.withValues(alpha: 0.5)) : null,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: text.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: text.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.time,
                style: text.labelSmall?.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
