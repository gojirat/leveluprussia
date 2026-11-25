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

class ListeningScreen extends StatefulWidget {
  final AppState appState;
  final String levelCode;
  final List<WordItem> initialWords;

  const ListeningScreen({
    super.key,
    required this.appState,
    required this.levelCode,
    required this.initialWords,
  });

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final Random _rng = Random();
  late List<WordItem> _words;
  int _index = 0;
  bool _completed = false;
  late DateTime _startedAt;

  List<WordItem> _options = [];
  String? _selectedId;
  bool _answered = false;
  bool _slowMode = false;

  int _streak = 0;
  int _maxStreak = 0;
  final List<SessionWordResult> _results = [];
  List<AchievementDef> _newlyUnlocked = [];

  @override
  void initState() {
    super.initState();
    _words = List.of(widget.initialWords);
    _startedAt = DateTime.now();
    _prepareQuestion(autoPlay: true);
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _prepareQuestion({bool autoPlay = false}) {
    final target = _words[_index];
    _selectedId = null;
    _answered = false;

    final pool = widget.appState.wordsForLevel(widget.levelCode);
    final source = pool.length >= 4 ? pool : widget.appState.words;
    final distractors = <WordItem>[];
    final used = <String>{target.translation.toLowerCase()};

    int attempts = 0;
    while (distractors.length < 3 && attempts < 100) {
      attempts++;
      final c = source[_rng.nextInt(source.length)];
      if (c.id != target.id && !used.contains(c.translation.toLowerCase())) {
        used.add(c.translation.toLowerCase());
        distractors.add(c);
      }
    }
    _options = [target, ...distractors]..shuffle(_rng);

    if (autoPlay) {
      unawaited(TtsService().speak(target.word, slow: _slowMode));
    }
  }

  Future<void> _select(WordItem opt) async {
    if (_answered) return;
    final target = _words[_index];
    final ok = opt.id == target.id;
    setState(() {
      _answered = true;
      _selectedId = opt.id;
    });

    _results.add(SessionWordResult(word: target, isCorrect: ok));
    await widget.appState.recordWordAnswer(target.id, ok);
    if (ok) {
      _streak++;
      if (_streak > _maxStreak) _maxStreak = _streak;
    } else {
      _streak = 0;
    }
  }

  Future<void> _next() async {
    if (_index + 1 >= _words.length) {
      final duration = DateTime.now().difference(_startedAt).inSeconds;
      final correctCount = _results.where((r) => r.isCorrect).length;
      final unlocked = await widget.appState.completeSession(
        mode: 'listening',
        level: widget.levelCode,
        totalWords: _words.length,
        correctCount: correctCount,
        durationSeconds: duration,
        maxCorrectStreak: _maxStreak,
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
      setState(() {
        _index++;
        _prepareQuestion(autoPlay: true);
      });
    }
  }

  void _restart() {
    final nextWords = widget.appState.pickSessionWords(
      level: widget.levelCode,
      count: _words.length,
      favoritesOnly: false,
    );
    setState(() {
      _words = nextWords.isNotEmpty ? nextWords : List.of(widget.initialWords);
      _index = 0;
      _completed = false;
      _results.clear();
      _newlyUnlocked = [];
      _streak = 0;
      _maxStreak = 0;
      _startedAt = DateTime.now();
      _prepareQuestion(autoPlay: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      final duration = DateTime.now().difference(_startedAt).inSeconds;
      return Scaffold(
        appBar: AppBar(title: const Text('Аудирование')),
        body: SessionSummaryView(
          title: 'Аудирование завершено!',
          results: _results,
          durationSeconds: duration,
          newlyUnlocked: _newlyUnlocked,
          onRestart: _restart,
          onHome: () => Navigator.of(context).pop(),
        ),
      );
    }

    final target = _words[_index];
    final progress = (_index + 1) / _words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Аудирование · ${_index + 1}/${_words.length}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

                  // Audio Player Hero Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CefrBadge(level: target.level),
                            const Spacer(),
                            ChoiceChip(
                              label: Text(_slowMode ? '0.7× Медленно' : '1.0× Обычно'),
                              selected: _slowMode,
                              onSelected: (v) {
                                setState(() => _slowMode = v);
                                TtsService().speak(target.word, slow: v);
                              },
                              showCheckmark: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          borderRadius: BorderRadius.circular(48),
                          onTap: () =>
                              TtsService().speak(target.word, slow: _slowMode),
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.purple],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _answered
                              ? target.word
                              : 'Нажмите, чтобы прослушать слово',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _answered ? 26 : 15,
                            fontWeight:
                                _answered ? FontWeight.w800 : FontWeight.w500,
                            color: _answered
                                ? AppColors.primaryText(context)
                                : AppColors.secondaryText(context),
                          ),
                        ),
                        if (_answered && target.phonetic.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            target.phonetic,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  ..._options.map((opt) {
                    final isTarget = opt.id == target.id;
                    final isSelected = _selectedId == opt.id;
                    Color bg = AppColors.cardBg(context);
                    Color border = AppColors.cardBorder(context);
                    IconData? icon;
                    Color? iconColor;

                    if (_answered) {
                      if (isTarget) {
                        bg = AppColors.emeraldSoft;
                        border = AppColors.emerald;
                        icon = Icons.check_circle_rounded;
                        iconColor = AppColors.emerald;
                      } else if (isSelected) {
                        bg = AppColors.coralSoft;
                        border = AppColors.coral;
                        icon = Icons.cancel_rounded;
                        iconColor = AppColors.coral;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _answered ? null : () => _select(opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border, width: 1.4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt.translation,
                                  style: TextStyle(
                                    color: AppColors.primaryText(context),
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (icon != null) Icon(icon, color: iconColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  if (_answered) ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        _index + 1 >= _words.length ? 'Завершить' : 'Далее →',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
