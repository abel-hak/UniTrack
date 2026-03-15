import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'widgets/app_footer.dart';

Future<void> setOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('unitrack_onboarding_seen', true);
}

/// First-run onboarding: value prop and Get started.
class OnboardingPage extends StatelessWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final colors = UniTrackColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.school_rounded,
                size: 72,
                color: primary.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 24),
              Text(
                'UniTrack',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your courses, assignments, exams, and announcements in one place. '
                'See what’s due, track grades, and get a focused plan for today.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: colors.mutedForeground,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await setOnboardingSeen();
                    if (context.mounted) onComplete();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Get started', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 24),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
