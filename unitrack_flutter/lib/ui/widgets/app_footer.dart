import 'package:flutter/material.dart';

import '../../main.dart';

/// Reusable app footer: version and optional links.
class AppFooter extends StatelessWidget {
  final String version;
  final bool compact;

  const AppFooter({
    super.key,
    this.version = 'UniTrack v1.0.0',
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UniTrackColors.of(context);
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          version,
          style: text.labelSmall?.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
