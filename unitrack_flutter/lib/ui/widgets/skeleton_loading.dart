import 'package:flutter/material.dart';

import '../../main.dart';

/// Drag handle for bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: colors.mutedForeground.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for skeleton loading.
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final base = colors.border.withValues(alpha: 0.5);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 0.5, 0),
              end: Alignment(_animation.value + 0.5, 0),
              colors: [
                base,
                base.withValues(alpha: 0.3),
                base,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a timeline-style card (left bar + icon + lines).
class TimelineCardSkeleton extends StatelessWidget {
  const TimelineCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerPlaceholder(width: 5, height: 72, borderRadius: BorderRadius.circular(999)),
          const SizedBox(width: 12),
          ShimmerPlaceholder(width: 32, height: 32, borderRadius: BorderRadius.circular(16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                ShimmerPlaceholder(width: 120, height: 12),
                const SizedBox(height: 8),
                ShimmerPlaceholder(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a simple list row (e.g. course chip or grade row).
class ListRowSkeleton extends StatelessWidget {
  final bool showLeading;

  const ListRowSkeleton({super.key, this.showLeading = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (showLeading) ...[
            ShimmerPlaceholder(width: 10, height: 10, borderRadius: BorderRadius.circular(5)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder(width: 80, height: 14),
                const SizedBox(height: 4),
                ShimmerPlaceholder(width: 140, height: 12),
              ],
            ),
          ),
          ShimmerPlaceholder(width: 48, height: 14),
        ],
      ),
    );
  }
}
