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
      image: 'assets/images/app_icon_1024.png',
      title: 'Изучение слов: уровень',
      description:
          'Изучайте английские слова с помощью интерактивных флешкарт и квизов. Отслеживайте прогресс и осваивайте словарный запас в своём темпе.',
    ),
    _SlideData(
      image: 'assets/images/level-book.png',
      title: 'Обучение по карточкам',
      description:
          'Изучайте слова с помощью интерактивных карточек. Переворачивайте карточки, чтобы увидеть переводы, и практикуйте произношение со встроенным синтезом речи.',
    ),
    _SlideData(
      image: 'assets/images/progress-hero-bg.png',
      title: 'Квизы и отслеживание прогресса',
      description:
          'Проверяйте свои знания с помощью квизов с множественным выбором и вводом текста. Следите за статистикой, сериями и достижениями.',
    ),
  ];

  Future<void> _complete() async {
    await widget.appState.setWelcomeShown(true);
    widget.onFinished();
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
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _complete,
                child: const Text(
                  'Пропустить',
                  style: TextStyle(color: AppColors.textSecondary),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: AppColors.bgCard,
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: index == 2
                                ? EdgeInsets.zero
                                : const EdgeInsets.all(24),
                            child: index == 0
                                ? Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(34),
                                      child: Image.asset(
                                        slide.image,
                                        width: 156,
                                        height: 156,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    slide.image,
                                    fit: index == 2
                                        ? BoxFit.cover
                                        : BoxFit.contain,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15.5,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _complete();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Text(isLast ? 'Начать обучение' : 'Продолжить →'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String image;
  final String title;
  final String description;

  const _SlideData({
    required this.image,
    required this.title,
    required this.description,
  });
}
