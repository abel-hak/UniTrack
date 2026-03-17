import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/notifications/notification_service.dart';
import 'core/providers.dart';
import 'ui/home_page.dart';
import 'ui/login_page.dart';
import 'ui/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const ProviderScope(child: UniTrackApp()));
}

class UniTrackApp extends ConsumerWidget {
  const UniTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const navy = Color(0xFF1B2A4A);
    final baseTextTheme = ThemeData.light().textTheme;
    final display = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final body = GoogleFonts.interTextTheme(baseTextTheme);

    final mergedText = body.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge,
      titleMedium: display.titleMedium,
      titleSmall: display.titleSmall,
    );

    // ── Light theme: navy-on-white (reference design) ──
    const ltBg = Color(0xFFF0F2F5);
    const ltFg = Color(0xFF1A1F36);
    const ltCard = Colors.white;
    const ltSecondary = Color(0xFFE8EBF0);
    const ltMuted = Color(0xFF6B7280);
    const ltBorder = Color(0xFFDDE1E8);

    final lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ltBg,
      colorScheme: const ColorScheme.light(
        primary: navy,
        onPrimary: Colors.white,
        secondary: ltSecondary,
        onSecondary: ltFg,
        surface: ltCard,
        onSurface: ltFg,
        outline: ltBorder,
      ),
      textTheme: mergedText,
      dividerColor: ltBorder,
      iconTheme: const IconThemeData(color: ltFg),
      appBarTheme: const AppBarTheme(
        backgroundColor: ltCard,
        foregroundColor: ltFg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy, width: 2),
        ),
        focusColor: navy,
        filled: true,
        fillColor: ltCard,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: ltCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[
        const UniTrackColors(
          mutedForeground: ltMuted,
          border: ltBorder,
          shadowCard: Color(0x12000000),
          shadowElevated: Color(0x1A000000),
          shadowFab: Color(0x401B2A4A),
          courseYellow: Color(0xFFF59E0B),
          courseTeal: Color(0xFF0D9488),
          courseTerracotta: Color(0xFFDC6B3A),
          courseSlate: Color(0xFF64748B),
          timelineLine: Color(0xFFD1D5DB),
        ),
      ],
    );

    // ── Dark theme: navy-slate variant ──
    const dkBg = Color(0xFF0F172A);
    const dkFg = Color(0xFFF1F5F9);
    const dkCard = Color(0xFF1E293B);
    const dkElevated = Color(0xFF334155);
    const dkMuted = Color(0xFF94A3B8);
    const dkBorder = Color(0xFF475569);
    const dkPrimary = Color(0xFF60A5FA);

    final darkTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: dkBg,
      colorScheme: const ColorScheme.dark(
        primary: dkPrimary,
        onPrimary: Color(0xFF0F172A),
        secondary: dkElevated,
        onSecondary: dkFg,
        surface: dkCard,
        onSurface: dkFg,
        outline: dkBorder,
      ),
      textTheme: mergedText,
      dividerColor: dkBorder,
      iconTheme: const IconThemeData(color: dkFg),
      appBarTheme: const AppBarTheme(
        backgroundColor: dkCard,
        foregroundColor: dkFg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dkPrimary, width: 2),
        ),
        focusColor: dkPrimary,
        filled: true,
        fillColor: dkCard,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: dkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[
        const UniTrackColors(
          mutedForeground: dkMuted,
          border: dkBorder,
          shadowCard: Color(0x50000000),
          shadowElevated: Color(0x60000000),
          shadowFab: Color(0x503B82F6),
          courseYellow: Color(0xFFFBBF24),
          courseTeal: Color(0xFF2DD4BF),
          courseTerracotta: Color(0xFFFB923C),
          courseSlate: Color(0xFF94A3B8),
          timelineLine: Color(0xFF475569),
        ),
      ],
    );

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'UniTrack',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateNotifierProvider);
    final onboardingAsync = ref.watch(hasSeenOnboardingProvider);

    return onboardingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _AuthOrHome(),
      data: (hasSeen) {
        if (!hasSeen) {
          return OnboardingPage(
            onComplete: () => ref.invalidate(hasSeenOnboardingProvider),
          );
        }
        if (!auth.isAuthed) return const LoginPage();
        return const HomePage();
      },
    );
  }
}

class _AuthOrHome extends ConsumerWidget {
  const _AuthOrHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateNotifierProvider);
    if (!auth.isAuthed) return const LoginPage();
    return const HomePage();
  }
}

@immutable
class UniTrackColors extends ThemeExtension<UniTrackColors> {
  final Color mutedForeground;
  final Color border;
  final Color shadowCard;
  final Color shadowElevated;
  final Color shadowFab;
  final Color courseYellow;
  final Color courseTeal;
  final Color courseTerracotta;
  final Color courseSlate;
  final Color timelineLine;

  const UniTrackColors({
    required this.mutedForeground,
    required this.border,
    required this.shadowCard,
    required this.shadowElevated,
    required this.shadowFab,
    required this.courseYellow,
    required this.courseTeal,
    required this.courseTerracotta,
    required this.courseSlate,
    required this.timelineLine,
  });

  static UniTrackColors of(BuildContext context) =>
      Theme.of(context).extension<UniTrackColors>()!;

  @override
  UniTrackColors copyWith({
    Color? mutedForeground,
    Color? border,
    Color? shadowCard,
    Color? shadowElevated,
    Color? shadowFab,
    Color? courseYellow,
    Color? courseTeal,
    Color? courseTerracotta,
    Color? courseSlate,
    Color? timelineLine,
  }) {
    return UniTrackColors(
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      shadowCard: shadowCard ?? this.shadowCard,
      shadowElevated: shadowElevated ?? this.shadowElevated,
      shadowFab: shadowFab ?? this.shadowFab,
      courseYellow: courseYellow ?? this.courseYellow,
      courseTeal: courseTeal ?? this.courseTeal,
      courseTerracotta: courseTerracotta ?? this.courseTerracotta,
      courseSlate: courseSlate ?? this.courseSlate,
      timelineLine: timelineLine ?? this.timelineLine,
    );
  }

  @override
  ThemeExtension<UniTrackColors> lerp(
    covariant ThemeExtension<UniTrackColors>? other,
    double t,
  ) {
    if (other is! UniTrackColors) return this;
    return UniTrackColors(
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadowCard: Color.lerp(shadowCard, other.shadowCard, t)!,
      shadowElevated: Color.lerp(shadowElevated, other.shadowElevated, t)!,
      shadowFab: Color.lerp(shadowFab, other.shadowFab, t)!,
      courseYellow: Color.lerp(courseYellow, other.courseYellow, t)!,
      courseTeal: Color.lerp(courseTeal, other.courseTeal, t)!,
      courseTerracotta:
          Color.lerp(courseTerracotta, other.courseTerracotta, t)!,
      courseSlate: Color.lerp(courseSlate, other.courseSlate, t)!,
      timelineLine: Color.lerp(timelineLine, other.timelineLine, t)!,
    );
  }
}
