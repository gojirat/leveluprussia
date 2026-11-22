import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levelup_english/models/learning_models.dart';
import 'package:levelup_english/screens/home_screen.dart';
import 'package:levelup_english/screens/learn_screen.dart';
import 'package:levelup_english/screens/quiz_screen.dart';
import 'package:levelup_english/screens/words_screen.dart';
import 'package:levelup_english/screens/progress_screen.dart';
import 'package:levelup_english/state/app_state.dart';
import 'package:levelup_english/theme/app_theme.dart';

Future<void> _loadRealFonts() async {
  // Load Apple San Francisco (Cyrillic + Latin + IPA) under both SFPro and
  // Flutter's default fallback families so AppBar/Button text styles also render crisply.
  final sfBytes = await File('/System/Library/Fonts/SFNS.ttf').readAsBytes();
  for (final family in [
    'SFPro',
    'Ahem',
    'FlutterTest',
    'Roboto',
    '.AppleSystemUIFont',
    'CupertinoSystemText',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(sfBytes)));
    await loader.load();
  }

  // Load Material Icons font
  final iconBytes = await File(
    '/Users/macbookpro/Development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(iconBytes)));
  await iconLoader.load();
}

Future<AppState> _createSeededState(WidgetTester tester) async {
  final now = DateTime.now();
  final today =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // Seed realistic demo progress so screenshots look rich and authentic
  final progressMap = <String, dynamic>{};
  for (int i = 1; i <= 145; i++) {
    progressMap['a1_$i'] = {
      'wordId': 'a1_$i',
      'correctCount': i <= 65 ? 3 : 1,
      'incorrectCount': 0,
      'lastReviewed': now.toIso8601String(),
    };
  }
  for (int i = 709; i <= 790; i++) {
    progressMap['a2_$i'] = {
      'wordId': 'a2_$i',
      'correctCount': i <= 740 ? 3 : 1,
      'incorrectCount': 0,
      'lastReviewed': now.toIso8601String(),
    };
  }
  for (int i = 1586; i <= 1630; i++) {
    progressMap['b1_$i'] = {
      'wordId': 'b1_$i',
      'correctCount': 1,
      'incorrectCount': 0,
      'lastReviewed': now.toIso8601String(),
    };
  }

  SharedPreferences.setMockInitialValues({
    '@english_words_welcome_shown': true,
    '@english_words_progress': jsonEncode(progressMap),
    '@english_words_favorites': ['a1_3', 'a1_5', 'a1_12', 'a2_710', 'b1_1587'],
    '@english_words_streak': jsonEncode({
      'currentStreak': 7,
      'bestStreak': 12,
      'lastActivityDate': today,
    }),
    '@english_words_daily_stats': jsonEncode({
      today: {
        'date': today,
        'wordsReviewed': 25,
        'correctAnswers': 23,
        'totalAnswers': 25,
        'durationSeconds': 1420,
      },
    }),
    '@english_words_sessions': jsonEncode([
      {
        'id': '1',
        'mode': 'flashcard',
        'level': 'A1',
        'totalWords': 10,
        'correctCount': 9,
        'durationSeconds': 180,
        'maxCorrectStreak': 7,
        'completedAt': now.toIso8601String(),
      },
      {
        'id': '2',
        'mode': 'quiz_choice',
        'level': 'A2',
        'totalWords': 15,
        'correctCount': 14,
        'durationSeconds': 240,
        'maxCorrectStreak': 11,
        'completedAt': now.toIso8601String(),
      },
    ]),
    '@english_words_achievements': jsonEncode({
      'first_word': now.toIso8601String(),
      'words_10': now.toIso8601String(),
      'words_50': now.toIso8601String(),
      'words_100': now.toIso8601String(),
      'streak_3': now.toIso8601String(),
      'streak_7': now.toIso8601String(),
      'accuracy_80': now.toIso8601String(),
      'streak_correct_10': now.toIso8601String(),
    }),
  });

  final state = AppState();
  await tester.runAsync(() => state.init());
  return state;
}

class _DeviceSpec {
  final String folder;
  final double logicalWidth;
  final double logicalHeight;
  final double dpr;

  const _DeviceSpec(
    this.folder,
    this.logicalWidth,
    this.logicalHeight,
    this.dpr,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const devices = [
    // iPhone 6.1" -> 393 * 3 = 1179, 852 * 3 = 2556
    _DeviceSpec('iphone_6_1', 393, 852, 3.0),
    // iPad 12.9" -> 1024 * 2 = 2048, 1366 * 2 = 2732
    _DeviceSpec('ipad_12_9', 1024, 1366, 2.0),
    // iPhone Duo -> 669 * 3 = 2007, 951 * 3 = 2853
    _DeviceSpec('iphone_duo', 669, 951, 3.0),
  ];

  testWidgets('Generate App Store screenshots for all devices', (tester) async {
    await tester.runAsync(_loadRealFonts);
    final appState = await _createSeededState(tester);

    final baseTheme = AppTheme.darkTheme;
    final screenshotTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'SFPro'),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'SFPro'),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'SFPro',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'SFPro',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'SFPro',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    Widget wrapWithNav(Widget body, int selectedTab) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: screenshotTheme,
        home: Scaffold(
          body: body,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: NavigationBar(
              selectedIndex: selectedTab,
              onDestinationSelected: (_) {},
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Главная',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Словарь',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Избранное',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Прогресс',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Профиль',
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sampleWords = appState.wordsForLevel('B1').take(10).toList();

    for (final d in devices) {
      tester.view.devicePixelRatio = d.dpr;
      tester.view.physicalSize = Size(
        d.logicalWidth * d.dpr,
        d.logicalHeight * d.dpr,
      );
      tester.view.viewPadding = FakeViewPadding(
        top: 44 * d.dpr,
        bottom: 20 * d.dpr,
      );

      Future<void> capture(Widget widget, String name) async {
        await tester.pumpWidget(widget);
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../screenshots/${d.folder}/$name.png'),
        );
      }

      // 1. Home
      await capture(wrapWithNav(HomeScreen(appState: appState), 0), '01_home');

      // 2. Flashcards
      await capture(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: screenshotTheme,
          home: LearnScreen(
            appState: appState,
            levelCode: 'B1',
            initialWords: sampleWords,
            reverseMode: false,
            favoritesOnly: false,
            requestedCount: 10,
          ),
        ),
        '02_flashcard',
      );

      // 3. Quiz
      await capture(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: screenshotTheme,
          home: QuizScreen(
            appState: appState,
            levelCode: 'B1',
            initialWords: sampleWords,
            quizMode: QuizMode.multipleChoice,
            favoritesOnly: false,
            requestedCount: 10,
          ),
        ),
        '03_quiz',
      );

      // 4. Dictionary
      await capture(
        wrapWithNav(WordsScreen(appState: appState), 1),
        '04_dictionary',
      );

      // 5. Progress & Achievements
      await capture(
        wrapWithNav(ProgressScreen(appState: appState), 3),
        '05_progress',
      );
    }

    addTearDown(tester.view.reset);
  });
}
