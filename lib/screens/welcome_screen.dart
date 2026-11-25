import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onFinished;

  const WelcomeScreen({
    super.key,
    required this.appState,
    required this.onFinished,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(
      useAppIcon: true,
      icon: Icons.school_rounded,
      color: AppColors.primary,
      title: 'Изучение слов: уровень',
      description:
          'Интервальное повторение SM-2, аудирование с регулировкой скорости и игра «Найди пары» для быстрого запоминания английской лексики.',
    ),
    _SlideData(
      useAppIcon: false,
      icon: Icons.headphones_rounded,
      color: AppColors.accent,
      title: 'Аудирование и мини-игры',
      description:
          'Тренируйте восприятие на слух в обычном и замедленном темпе 0.7×, закрепляйте перевод в игре на скорость и проверяйте правописание.',
    ),
    _SlideData(
      useAppIcon: false,
      icon: Icons.library_books_rounded,
      color: AppColors.emerald,
      title: 'Свой словарь и дневная цель',
      description:
          'Более 4 100 слов по уровням A1–C1 плюс возможность добавлять собственные слова с заметками и отслеживать активность по дням недели.',
    ),
  ];

  Future<void> _complete() async {
    await widget.appState.setWelcomeShown(true);
    widget.onFinished();
  }

  void _handleNext() {
    if (_page >= _slides.length - 1) {
      _complete();
    } else {
      final nextPage = _page + 1;
      setState(() => _page = nextPage);
      if (_controller.hasClients) {
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4),
                    child: TextButton(
                      onPressed: _complete,
                      child: Text(
                        'Пропустить',
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Container(
                              height: 210,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: slide.color.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: slide.color.withValues(alpha: 0.25),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: slide.useAppIcon
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Image.asset(
                                        'assets/images/app_icon_1024.png',
                                        width: 148,
                                        height: 148,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            slide.color.withValues(alpha: 0.18),
                                      ),
                                      child: Icon(
                                        slide.icon,
                                        size: 56,
                                        color: slide.color,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 34),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText(context),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.5,
                                color: AppColors.secondaryText(context),
                                height: 1.5,
                              ),
                            ),
                              ],
                            ),
                          ),
                        );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.cardBorder(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: Text(isLast ? 'Начать обучение' : 'Продолжить →'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final bool useAppIcon;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _SlideData({
    required this.useAppIcon,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
