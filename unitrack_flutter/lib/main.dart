import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/providers.dart';
import 'ui/home_page.dart';
import 'ui/login_page.dart';

void main() {
  runApp(const ProviderScope(child: UniTrackApp()));
}

class UniTrackApp extends StatelessWidget {
  const UniTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF7F7F7); // hsl(0 0% 96.9%)
    const foreground = Color(0xFF1A1A1A); // hsl(0 0% 10.2%)
    const card = Color(0xFFFFFFFF);
    const secondary = Color(0xFFEBEBEB); // hsl(0 0% 92%)
    const mutedForeground = Color(0xFF737373); // hsl(0 0% 45%)
    const border = Color(0xFFE0E0E0); // hsl(0 0% 88%)
    const primary = Color(0xFF0045AB); // hsl(217 100% 33.5%)

    final baseTextTheme = ThemeData.light().textTheme;
    final display = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final body = GoogleFonts.interTextTheme(baseTextTheme);

    return MaterialApp(
      title: 'UniTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          onSecondary: foreground,
          surface: card,
          onSurface: foreground,
          outline: border,
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
        dividerColor: border,
        iconTheme: const IconThemeData(color: foreground),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),
      ).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          const UniTrackColors(
            mutedForeground: mutedForeground,
            border: border,
            shadowCard: Color(0x0A000000),
            shadowElevated: Color(0x14000000),
            shadowFab: Color(0x590045AB),
            courseYellow: Color(0xFFFFC800),
            courseTeal: Color(0xFF4B7D89),
            courseTerracotta: Color(0xFFC05D35),
            courseSlate: Color(0xFF6E7A86),
            timelineLine: Color(0xFFD1D1D1),
          ),
        ],
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerWidget {
  const _AppEntry();

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
