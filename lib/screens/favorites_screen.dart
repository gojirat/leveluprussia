import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/word_detail_sheet.dart';
import 'select_mode_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final AppState appState;

  const FavoritesScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final favs = appState.favoriteWords;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'Избранное',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coralSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${favs.length}',
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (favs.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SelectModeScreen(
                                appState: appState,
                                levelCode: 'ALL',
                                initialFavoritesOnly: true,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Учить'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: favs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  'assets/images/favorite-star.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Нет избранных слов',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Добавьте слова в избранное, нажав на иконку сердца',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: favs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final word = favs[idx];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => showWordDetailSheet(
                              context: context,
                              word: word,
                              appState: appState,
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CefrBadge(level: word.level),
                                        const SizedBox(height: 6),
                                        Text(
                                          word.word,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (word.phonetic.isNotEmpty)
                                          Text(
                                            word.phonetic,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        const SizedBox(height: 3),
                                        Text(
                                          word.translation,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        TtsService().speak(word.word),
                                    icon: const Icon(
                                      Icons.volume_up_rounded,
                                      size: 21,
                                    ),
                                    color: AppColors.primaryLight,
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        appState.toggleFavorite(word.id),
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      size: 21,
                                    ),
                                    color: AppColors.coral,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
