import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../models/learning_models.dart';
import '../services/ad_service.dart';
import '../services/review_service.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/session_summary_view.dart';
import '../widgets/word_detail_sheet.dart';

class LearnScreen extends StatefulWidget {
  final AppState appState;
  final String levelCode;
  final List<WordItem> initialWords;
  final bool reverseMode;
  final bool favoritesOnly;
  final int requestedCount;

  const LearnScreen({
    super.key,
    required this.appState,
    required this.levelCode,
    required this.initialWords,
    required this.reverseMode,
    required this.favoritesOnly,
    required this.requestedCount,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with SingleTickerProviderStateMixin {
  late List<WordItem> _words;
  int _index = 0;
  bool _isFlipped = false;
  bool _completed = false;
  late DateTime _startedAt;
  int _currentCorrectStreak = 0;
  int _maxCorrectStreak = 0;
  final List<SessionWordResult> _results = [];
  List<AchievementDef> _newlyUnlocked = [];

  late final AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _words = List.of(widget.initialWords);
    _startedAt = DateTime.now();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    TtsService().stop();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  Future<void> _rateSrs(SrsRating rating) async {
    final word = _words[_index];
    final known = rating != SrsRating.again;
    _results.add(SessionWordResult(word: word, isCorrect: known));
    await widget.appState.recordSrsRating(word.id, rating);

    if (known) {
      _currentCorrectStreak++;
      if (_currentCorrectStreak > _maxCorrectStreak) {
        _maxCorrectStreak = _currentCorrectStreak;
      }
    } else {
      _currentCorrectStreak = 0;
    }

    if (_index + 1 >= _words.length) {
      final duration = DateTime.now().difference(_startedAt).inSeconds;
      final correctCount = _results.where((r) => r.isCorrect).length;
      final unlocked = await widget.appState.completeSession(
        mode: 'flashcard',
        level: widget.levelCode,
        totalWords: _words.length,
        correctCount: correctCount,
        durationSeconds: duration,
        maxCorrectStreak: _maxCorrectStreak,
      );
      if (!mounted) return;
      setState(() {
        _newlyUnlocked = unlocked;
        _completed = true;
      });
      unawaited(AdService().onSessionCompleted());
      unawaited(
        ReviewService().maybeRequestReview(
          totalCompletedSessions: widget.appState.sessions.length,
        ),
      );
    } else {
      _flipController.value = 0;
      setState(() {
        _index++;
        _isFlipped = false;
      });
    }
  }

  void _restart() {
    final nextWords = widget.appState.pickSessionWords(
      level: widget.levelCode,
      count: widget.requestedCount,
      favoritesOnly: widget.favoritesOnly,
    );
    _flipController.value = 0;
    setState(() {
      _words = nextWords.isNotEmpty ? nextWords : List.of(widget.initialWords);
      _index = 0;
      _isFlipped = false;
      _completed = false;
      _results.clear();
      _newlyUnlocked = [];
      _currentCorrectStreak = 0;
      _maxCorrectStreak = 0;
      _startedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      final duration = DateTime.now().difference(_startedAt).inSeconds;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Интервальные карточки'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: SessionSummaryView(
          title: 'Тренировка завершена!',
          results: _results,
          durationSeconds: duration,
          newlyUnlocked: _newlyUnlocked,
          onRestart: _restart,
          onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      );
    }

    final word = _words[_index];
    final progress = (_index + 1) / _words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${_words.length}'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Примеры',
            onPressed: () => showWordDetailSheet(
              context: context,
              word: word,
              appState: widget.appState,
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: AppColors.cardBorder(context),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3D Flippable Card
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleFlip,
                      child: AnimatedBuilder(
                        animation: _flipController,
                        builder: (context, _) {
                          final angle = _flipController.value * pi;
                          final showBack = angle > pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY(angle),
                            child: showBack
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(pi),
                                    child: _buildCardFace(
                                      word: word,
                                      isBack: true,
                                    ),
                                  )
                                : _buildCardFace(
                                    word: word,
                                    isBack: false,
                                  ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SM-2 Spaced Repetition 4-level rating buttons
                  Row(
                    children: [
                      Expanded(
                        child: _SrsButton(
                          label: 'Снова',
                          interval: '10м',
                          color: AppColors.coral,
                          onTap: () => _rateSrs(SrsRating.again),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SrsButton(
                          label: 'Трудно',
                          interval: '1д',
                          color: AppColors.amber,
                          onTap: () => _rateSrs(SrsRating.hard),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SrsButton(
                          label: 'Хорошо',
                          interval: '3д',
                          color: AppColors.primary,
                          onTap: () => _rateSrs(SrsRating.good),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SrsButton(
                          label: 'Легко',
                          interval: '4д+',
                          color: AppColors.emerald,
                          onTap: () => _rateSrs(SrsRating.easy),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace({required WordItem word, required bool isBack}) {
    final showEnglish = widget.reverseMode ? isBack : !isBack;

    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final isFav = widget.appState.isFavorite(word.id);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isBack
                  ? AppColors.emerald.withValues(alpha: 0.6)
                  : AppColors.primary.withValues(alpha: 0.4),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CefrBadge(level: word.level),
                  const Spacer(),
                  if (showEnglish)
                    IconButton(
                      onPressed: () => TtsService().speak(word.word),
                      icon: const Icon(Icons.volume_up_rounded),
                      color: AppColors.primary,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => widget.appState.toggleFavorite(word.id),
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    color: isFav
                        ? AppColors.coral
                        : AppColors.secondaryText(context),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                showEnglish ? word.word : word.translation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: showEnglish ? 36 : 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText(context),
                  letterSpacing: -0.5,
                ),
              ),
              if (showEnglish && word.phonetic.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  word.phonetic,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (isBack) ...[
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    showEnglish ? word.translation : word.word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: AppColors.mutedText(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isBack
                        ? 'Оцените, насколько легко вспомнили слово'
                        : 'Нажмите на карточку, чтобы перевернуть',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SrsButton extends StatelessWidget {
  final String label;
  final String interval;
  final Color color;
  final VoidCallback onTap;

  const _SrsButton({
    required this.label,
    required this.interval,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              interval,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
