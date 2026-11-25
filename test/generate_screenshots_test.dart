import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levelup_english/screens/home_screen.dart';
import 'package:levelup_english/screens/learn_screen.dart';
import 'package:levelup_english/screens/listening_screen.dart';
import 'package:levelup_english/screens/match_game_screen.dart';
import 'package:levelup_english/screens/practice_hub_screen.dart';
import 'package:levelup_english/screens/progress_screen.dart';
import 'package:levelup_english/state/app_state.dart';
import 'package:levelup_english/theme/app_theme.dart';

Future<void> _loadRealFonts() async {
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

  final iconBytes = await File(
    '/Users/macbookpro/Development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(iconBytes)));
  await iconLoader.load();
}

Future<AppState> _createSeededState(WidgetTester tester) async {
  final now = DateTime.now();
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final progressMap = <String, dynamic>{};
  for (int i = 1; i <= 145; i++) {
    progressMap['a1_$i'] = {
      'wordId': 'a1_$i',
      'correctCount': i <= 65 ? 3 : 1,
      'incorrectCount': 0,
      'lastReviewed': now.toIso8601String(),
      'intervalDays': i <= 65 ? 10 : 1,
      'easeFactor': 2.5,
      'nextReviewAt':
          (i <= 18 ? now.subtract(const Duration(hours: 2)) : now.add(const Duration(days: 5)))
              .toIso8601String(),
    };
  }
  for (int i = 709; i <= 790; i++) {
    progressMap['a2_$i'] = {
      'wordId': 'a2_$i',
      'correctCount': i <= 740 ? 3 : 1,
      'incorrectCount': 0,
      'lastReviewed': now.toIso8601String(),
      'intervalDays': 6,
      'easeFactor': 2.5,
      'nextReviewAt': now.add(const Duration(days: 6)).toIso8601String(),
    };
  }

  final daily = <String, dynamic>{};
  const counts = [14, 22, 18, 30, 25, 16, 15];
  for (int i = 0; i < 7; i++) {
    final dt = now.subtract(Duration(days: 6 - i));
    final key = fmt(dt);
    daily[key] = {
      'date': key,
      'wordsReviewed': counts[i],
      'correctAnswers': counts[i] - 1,
      'totalAnswers': counts[i],
      'durationSeconds': counts[i] * 25,
    };
  }

  SharedPreferences.setMockInitialValues({
    '@english_words_welcome_shown': true,
    '@english_words_progress': jsonEncode(progressMap),
    '@english_words_favorites': ['a1_3', 'a1_5', 'a1_12', 'a2_710'],
    '@english_words_best_match_sec': 19,
    '@english_words_streak': jsonEncode({
      'currentStreak': 7,
      'bestStreak': 12,
      'lastActivityDate': fmt(now),
    }),
    '@english_words_daily_stats': jsonEncode(daily),
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
        'mode': 'listening',
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
    _DeviceSpec('iphone_6_1', 393, 852, 3.0),
    _DeviceSpec('ipad_12_9', 1024, 1366, 2.0),
    _DeviceSpec('iphone_duo', 669, 951, 3.0),
  ];

  testWidgets('Generate redesigned App Store screenshots', (tester) async {
    await tester.runAsync(_loadRealFonts);
    final appState = await _createSeededState(tester);

    final baseTheme = AppTheme.lightTheme;
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      navigationRailTheme: baseTheme.navigationRailTheme.copyWith(
        selectedLabelTextStyle: baseTheme
            .navigationRailTheme.selectedLabelTextStyle
            ?.copyWith(fontFamily: 'SFPro'),
        unselectedLabelTextStyle: baseTheme
            .navigationRailTheme.unselectedLabelTextStyle
            ?.copyWith(fontFamily: 'SFPro'),
      ),
      navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'SFPro',
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : const Color(0xFF6B7280),
          );
        }),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        labelStyle: const TextStyle(
          fontFamily: 'SFPro',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    Widget wrapShell(Widget body, int tab, bool isWide) {
      if (isWide) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: screenshotTheme,
          home: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (_) {},
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/app_icon_1024.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school_rounded),
                      label: Text('Обучение'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.fitness_center_outlined),
                      selectedIcon: Icon(Icons.fitness_center_rounded),
                      label: Text('Тренажёры'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: Text('Словарь'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: Text('Прогресс'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          ),
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: screenshotTheme,
        home: Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (_) {},
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Обучение',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center_rounded),
                label: 'Тренажёры',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Словарь',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Прогресс',
              ),
            ],
          ),
        ),
      );
    }

    final sampleWords = appState.wordsForLevel('B1').take(10).toList();

    for (final d in devices) {
      final isWide = d.logicalWidth >= 768;
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

      await capture(wrapShell(HomeScreen(appState: appState), 0, isWide), '01_home');
      await capture(wrapShell(PracticeHubScreen(appState: appState), 1, isWide), '02_practice');
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
        '03_srs_cards',
      );
      await capture(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: screenshotTheme,
          home: ListeningScreen(
            appState: appState,
            levelCode: 'B1',
            initialWords: sampleWords,
          ),
        ),
        '04_listening',
      );
      await capture(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: screenshotTheme,
          home: MatchGameScreen(appState: appState, levelCode: 'A1'),
        ),
        '05_match_game',
      );
      await capture(
        wrapShell(ProgressScreen(appState: appState), 3, isWide),
        '06_progress',
      );
    }

    addTearDown(tester.view.reset);
  });
}
