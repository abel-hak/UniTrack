import 'package:flutter/material.dart';

/// Dialog with rounded corners, optional leading icon, consistent padding and primary action.
class StyledDialog extends StatelessWidget {
  final Widget title;
  final IconData? titleIcon;
  final Widget content;
  final String actionLabel;
  final VoidCallback? onAction;

  const StyledDialog({
    super.key,
    required this.title,
    this.titleIcon,
    required this.content,
    this.actionLabel = 'Close',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          if (titleIcon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(titleIcon, size: 20, color: primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: title),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      content: SingleChildScrollView(child: content),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAction ?? () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
