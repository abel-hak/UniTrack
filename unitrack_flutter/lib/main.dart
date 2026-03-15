import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/providers.dart';

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
    const primary = Color(0xFF1F3A8A); // Deep blue
    final baseTextTheme = ThemeData.light().textTheme;
    final display = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final body = GoogleFonts.interTextTheme(baseTextTheme);

    const lightBackground = Color(0xFFF7F7F7);
    const lightForeground = Color(0xFF1A1A1A);
    const lightCard = Color(0xFFFFFFFF);
    const lightSecondary = Color(0xFFEBEBEB);
    const lightMuted = Color(0xFF737373);
    const lightBorder = Color(0xFFE0E0E0);

    final lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: lightSecondary,
        onSecondary: lightForeground,
        surface: lightCard,
        onSurface: lightForeground,
        outline: lightBorder,
      ),
      textTheme: body.copyWith(
        displayLarge: display.displayLarge,
        displayMedium: display.displayMedium,
        displaySmall: display.displaySmall,
        headlineLarge: display.headlineLarge,
        headlineMedium: display.headlineMedium,
        headlineSmall: display.headlineSmall,
        titleLarge: display.titleLarge,
        titleMedium: display.titleMedium,
        titleSmall: display.titleSmall,
      ),
      dividerColor: lightBorder,
      iconTheme: const IconThemeData(color: lightForeground),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        focusColor: primary,
        filled: true,
        fillColor: lightCard,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[
        const UniTrackColors(
          mutedForeground: lightMuted,
          border: lightBorder,
          shadowCard: Color(0x0A000000),
          shadowElevated: Color(0x14000000),
          shadowFab: Color(0x591F3A8A),
          courseYellow: Color(0xFFFFC800),
          courseTeal: Color(0xFF4B7D89),
          courseTerracotta: Color(0xFFC05D35),
          courseSlate: Color(0xFF6E7A86),
          timelineLine: Color(0xFFD1D1D1),
        ),
      ],
    );

    // Lighter dark theme: easy to see, good contrast (no near-black)
    const darkBackground = Color(0xFF2D3139);   // Medium dark gray
    const darkForeground = Color(0xFFF0F1F3);   // Bright text
    const darkCard = Color(0xFF3A3F48);         // Lighter cards, clear separation
    const darkSecondary = Color(0xFF454A54);     // Chips, segments
    const darkMuted = Color(0xFFB8BCC4);        // Secondary text, easy to read
    const darkBorder = Color(0xFF50555F);       // Clear borders

    final darkTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B8AFF),   // Lighter deep blue for dark backgrounds
        onPrimary: Color(0xFF0A1628),
        secondary: darkSecondary,
        onSecondary: darkForeground,
        surface: darkCard,
        onSurface: darkForeground,
        outline: darkBorder,
      ),
      textTheme: body.copyWith(
        displayLarge: display.displayLarge,
        displayMedium: display.displayMedium,
        displaySmall: display.displaySmall,
        headlineLarge: display.headlineLarge,
        headlineMedium: display.headlineMedium,
        headlineSmall: display.headlineSmall,
        titleLarge: display.titleLarge,
        titleMedium: display.titleMedium,
        titleSmall: display.titleSmall,
      ),
      dividerColor: darkBorder,
      iconTheme: const IconThemeData(color: darkForeground),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6B8AFF), width: 2),
        ),
        focusColor: const Color(0xFF6B8AFF),
        filled: true,
        fillColor: darkCard,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6B8AFF),
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[
        const UniTrackColors(
          mutedForeground: darkMuted,
          border: darkBorder,
          shadowCard: Color(0x18000000),
          shadowElevated: Color(0x25000000),
          shadowFab: Color(0x506B8AFF),
          courseYellow: Color(0xFFE5B800),
          courseTeal: Color(0xFF5A9AA6),
          courseTerracotta: Color(0xFFD97A5A),
          courseSlate: Color(0xFF8A95A0),
          timelineLine: Color(0xFF5C626E),  // Visible timeline line
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
