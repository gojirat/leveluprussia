import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levelup_english/state/app_state.dart';
import 'package:levelup_english/theme/app_theme.dart';
import 'package:levelup_english/screens/welcome_screen.dart';
import 'package:levelup_english/screens/main_tabs_screen.dart';

void main() {
  testWidgets('AppState loads all 4,109 CEFR words and WelcomeScreen renders',
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

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WelcomeScreen(appState: appState, onFinished: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Изучение слов: уровень'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
  });

  testWidgets('MainTabsScreen renders all 5 tabs and CEFR levels',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      '@english_words_welcome_shown': true,
    });
    final appState = AppState();
    await tester.runAsync(() => appState.init());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainTabsScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Словарь'), findsOneWidget);
    expect(find.text('Избранное'), findsOneWidget);
    expect(find.text('Прогресс'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.text('Уровень A1'), findsOneWidget);
  });
}
