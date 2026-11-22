import 'package:flutter/material.dart';
import 'services/ad_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_tabs_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LevelUpApp());
}

class LevelUpApp extends StatefulWidget {
  const LevelUpApp({super.key});

  @override
  State<LevelUpApp> createState() => _LevelUpAppState();
}

class _LevelUpAppState extends State<LevelUpApp> {
  final AppState _appState = AppState();
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _appState.init();
    if (!mounted) return;
    setState(() {
      _showWelcome = !_appState.welcomeShown;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Изучение слов: уровень',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: !_appState.isLoaded
          ? const _SplashLoadingView()
          : _showWelcome
              ? WelcomeScreen(
                  appState: _appState,
                  onFinished: () => setState(() => _showWelcome = false),
                )
              : MainTabsScreen(appState: _appState),
    );
  }
}

class _SplashLoadingView extends StatelessWidget {
  const _SplashLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/app_icon_1024.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
