import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levelup_english/state/app_state.dart';
import 'package:levelup_english/theme/app_theme.dart';
import 'package:levelup_english/screens/welcome_screen.dart';
import 'package:levelup_english/screens/main_tabs_screen.dart';

void main() {
  testWidgets('AppState loads all 4,109 CEFR words and WelcomeScreen completes',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await tester.runAsync(() => appState.init());

    expect(appState.isLoaded, isTrue);
    expect(appState.words.length, greaterThan(4000));
    expect(appState.wordsForLevel('A1').length, 708);
    expect(appState.wordsForLevel('A2').length, 877);
    expect(appState.wordsForLevel('B1').length, 650);
    expect(appState.wordsForLevel('B2').length, 606);
    expect(appState.wordsForLevel('C1').length, 1268);

    bool finished = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: WelcomeScreen(
          appState: appState,
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Изучение слов: уровень'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    await tester.tap(find.text('Продолжить →'));
    await tester.pumpAndSettle();
    expect(find.text('Аудирование и мини-игры'), findsOneWidget);

    await tester.tap(find.text('Продолжить →'));
    await tester.pumpAndSettle();
    expect(find.text('Свой словарь и дневная цель'), findsOneWidget);

    await tester.tap(find.text('Начать обучение'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('MainTabsScreen renders 4 tabs and supports custom personal words',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      '@english_words_welcome_shown': true,
    });
    final appState = AppState();
    await tester.runAsync(() => appState.init());
    await appState.addCustomWord(
      word: 'resilience',
      translation: 'стойкость',
      note: 'personal note',
    );
    expect(appState.customWords.length, 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MainTabsScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Обучение'), findsOneWidget);
    expect(find.text('Тренажёры'), findsOneWidget);
    expect(find.text('Словарь'), findsOneWidget);
    expect(find.text('Прогресс'), findsOneWidget);
    expect(find.text('Уровень A1'), findsOneWidget);
  });
}
