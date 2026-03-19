import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../main.dart';
import '../features/timeline/models.dart';

class CalendarTab extends ConsumerStatefulWidget {
  final void Function(TimelineAssignment)? onAssignmentTap;
  final void Function(TimelineExam)? onExamTap;
  final void Function(TimelineAnnouncement)? onAnnouncementTap;
  final void Function(DateTime date)? onAddFromDate;

  const CalendarTab({
    super.key,
    this.onAssignmentTap,
    this.onExamTap,
    this.onAnnouncementTap,
    this.onAddFromDate,
  });

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab>
    with SingleTickerProviderStateMixin {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  late final PageController _pageController;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  bool _expanded = true;

  static const _baseMonth = 1200; // center offset for page controller

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _baseMonth);
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  DateTime _monthFromPage(int page) {
    final diff = page - _baseMonth;
    final now = DateTime.now();
    return DateTime(now.year, now.month + diff);
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            // ── Calendar card ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: isDark
                    ? Border.all(color: colors.border.withValues(alpha: 0.4))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowCard,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month nav
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleExpand,
                          child: Row(
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(_focusedMonth),
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _expanded ? 0 : -0.25,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _NavButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                        const SizedBox(width: 2),
                        _NavButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _TodayPill(
                          onTap: () {
                            final now = DateTime.now();
                            setState(() {
                              _focusedMonth = DateTime(now.year, now.month);
                              _selectedDay = DateTime(now.year, now.month, now.day);
                            });
                            _pageController.animateToPage(
                              _baseMonth,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Weekday headers
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Row(
                            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                .map((d) => Expanded(
                                      child: Center(
                                        child: Text(
                                          d,
                                          style: text.labelSmall?.copyWith(
                                            color: colors.mutedForeground,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),

                        // Swipeable calendar grid
                        SizedBox(
                          height: _gridHeight(context),
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (page) {
                              setState(() {
                                _focusedMonth = _monthFromPage(page);
                              });
                            },
                            itemBuilder: (context, page) {
                              final month = _monthFromPage(page);
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 6, 8, 12),
                                child: _CalendarGrid(
                                  month: month,
                                  selectedDay: _selectedDay,
                                  events: events,
                                  onDayTap: (d) =>
                                      setState(() => _selectedDay = d),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Summary strip ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_selectedDay != null) ...[
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedDay!),
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (selectedEvents.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${selectedEvents.length} ${selectedEvents.length == 1 ? 'event' : 'events'}',
                          style: text.labelSmall?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        onPressed: _handleAddFromDate,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Add assignment',
                        style: IconButton.styleFrom(
                          backgroundColor: primary.withValues(alpha: 0.1),
                          foregroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  _LegendDot(color: primary, label: 'Due'),
                  const SizedBox(width: 10),
                  _LegendDot(
                      color: const Color(0xFFD97706), label: 'Exam'),
                  const SizedBox(width: 10),
                  _LegendDot(
                      color: colors.mutedForeground, label: 'News'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Events list ──
            Expanded(
              child: selectedEvents.isEmpty
                  ? _EmptyDay(
                      selectedDay: _selectedDay,
                      onAdd: _handleAddFromDate,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: selectedEvents.length,
                      itemBuilder: (context, i) {
                        final ev = selectedEvents[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EventCard(
                            event: ev,
                            index: i,
                            onTap: () => _handleEventTap(ev),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _handleEventTap(_CalendarEvent ev) {
    final src = ev.source;
    if (src == null) return;
    switch (ev.type) {
      case _EventType.assignment:
        widget.onAssignmentTap?.call(src as TimelineAssignment);
      case _EventType.exam:
        widget.onExamTap?.call(src as TimelineExam);
      case _EventType.announcement:
        widget.onAnnouncementTap?.call(src as TimelineAnnouncement);
    }
  }

  void _handleAddFromDate() {
    if (_selectedDay == null) return;
    widget.onAddFromDate?.call(_selectedDay!);
  }

  double _gridHeight(BuildContext context) {
    // Always allocate for 6 rows (the max any month can have)
    // so page transitions between months never overflow.
    return 6 * 48.0 + 18.0; // 306
  }

  Map<DateTime, List<_CalendarEvent>> _buildEventMap(TimelineBundle bundle) {
    final map = <DateTime, List<_CalendarEvent>>{};

    for (final a in bundle.assignments) {
      final day = DateTime(a.dueAt.year, a.dueAt.month, a.dueAt.day);
      (map[day] ??= []).add(_CalendarEvent(
        type: _EventType.assignment,
        title: a.title,
        subtitle: a.course.title,
        detail: a.type,
        time: DateFormat('h:mm a').format(a.dueAt),
        colorKey: a.course.colorKey,
        gradePct: a.gradePct,
        source: a,
      ));
    }

    for (final an in bundle.announcements) {
      final day =
          DateTime(an.createdAt.year, an.createdAt.month, an.createdAt.day);
      (map[day] ??= []).add(_CalendarEvent(
        type: _EventType.announcement,
        title: an.title,
        subtitle: 'By ${an.authorName}',
        time: DateFormat('h:mm a').format(an.createdAt),
        source: an,
      ));
    }

    for (final ex in bundle.exams) {
      final day =
          DateTime(ex.startsAt.year, ex.startsAt.month, ex.startsAt.day);
      (map[day] ??= []).add(_CalendarEvent(
        type: _EventType.exam,
        title: '${ex.course.title} · ${_cap(ex.kind)}',
        subtitle: ex.location ?? '',
        time: DateFormat('h:mm a').format(ex.startsAt),
        colorKey: ex.course.colorKey,
        source: ex,
      ));
    }

    return map;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ─── Calendar grid ───────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDay;
  final Map<DateTime, List<_CalendarEvent>> events;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.events,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return SizedBox(
          height: 48,
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - leadingBlanks + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox.shrink());
              }

              final date = DateTime(month.year, month.month, dayNum);
              final isToday = date == todayDay;
              final isSelected = date == selectedDay;
              final dayEvents = events[date] ?? [];
              final eventCount = dayEvents.length;
              final hasAssignment =
                  dayEvents.any((e) => e.type == _EventType.assignment);
              final hasExam =
                  dayEvents.any((e) => e.type == _EventType.exam);
              final hasAnnouncement =
                  dayEvents.any((e) => e.type == _EventType.announcement);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(date),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primary,
                                  primary.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isToday
                                ? primary.withValues(alpha: 0.08)
                                : null),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: text.bodySmall?.copyWith(
                              fontWeight: isToday || isSelected || eventCount > 0
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : (isToday
                                      ? primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                            ),
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (hasAssignment)
                                  _Dot(
                                    color:
                                        isSelected ? Colors.white : primary,
                                  ),
                                if (hasExam)
                                  _Dot(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : const Color(0xFFD97706),
                                  ),
                                if (hasAnnouncement)
                                  _Dot(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : colors.mutedForeground,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Small widgets ───────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Today',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: UniTrackColors.of(context).mutedForeground,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────

class _EmptyDay extends StatelessWidget {
  final DateTime? selectedDay;
  final VoidCallback? onAdd;
  const _EmptyDay({required this.selectedDay, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wb_sunny_rounded,
                size: 28,
                color: colors.mutedForeground.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                selectedDay != null
                    ? 'Free day!'
                    : 'Tap a day',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedDay != null
                    ? 'Nothing scheduled for ${DateFormat('MMM d').format(selectedDay!)}'
                    : 'Select a date to see events',
                style: text.bodySmall?.copyWith(
                  color: colors.mutedForeground.withValues(alpha: 0.7),
                ),
              ),
          if (selectedDay != null && onAdd != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add assignment'),
              style: FilledButton.styleFrom(
                backgroundColor: primary.withValues(alpha: 0.1),
                foregroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────

enum _EventType { assignment, exam, announcement }

class _CalendarEvent {
  final _EventType type;
  final String title;
  final String subtitle;
  final String? detail;
  final String time;
  final String? colorKey;
  final int? gradePct;
  final Object? source;

  const _CalendarEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    this.detail,
    required this.time,
    this.colorKey,
    this.gradePct,
    this.source,
  });
}

// ─── Event card ──────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final _CalendarEvent event;
  final int index;
  final VoidCallback? onTap;

  const _EventCard({required this.event, required this.index, this.onTap});

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

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: colors.border.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowCard,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored side strip
            Container(
              width: 4,
              margin: const EdgeInsets.only(left: 0),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(alpha: 0.15),
                            accentColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: accentColor),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  label,
                                  style: text.labelSmall?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              if (event.detail != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  event.detail!,
                                  style: text.labelSmall?.copyWith(
                                    color: colors.mutedForeground,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.title,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
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
                    // Time / grade
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (event.gradePct != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${event.gradePct}%',
                              style: text.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          )
                        else
                          Text(
                            event.time,
                            style: text.labelMedium?.copyWith(
                              color: colors.mutedForeground,
                              fontWeight: FontWeight.w700,
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
      ),
    ),
      ),
    );
  }
}
