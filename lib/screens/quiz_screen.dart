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

class QuizScreen extends StatefulWidget {
  final AppState appState;
  final String levelCode;
  final List<WordItem> initialWords;
  final QuizMode quizMode;
  final bool favoritesOnly;
  final int requestedCount;

  const QuizScreen({
    super.key,
    required this.appState,
    required this.levelCode,
    required this.initialWords,
    required this.quizMode,
    required this.favoritesOnly,
    required this.requestedCount,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _rng = Random();
  late List<WordItem> _words;
  int _index = 0;
  bool _completed = false;
  late DateTime _startedAt;

  // Multiple choice state
  List<WordItem> _options = [];
  String? _selectedOptionId;
  bool _answered = false;
  bool _wasCorrect = false;

  // Typing state
  final TextEditingController _textController = TextEditingController();
  int _hintRevealedChars = 0;
  String? _hintBanner;

  int _currentCorrectStreak = 0;
  int _maxCorrectStreak = 0;
  final List<SessionWordResult> _results = [];
  List<AchievementDef> _newlyUnlocked = [];

  @override
  void initState() {
    super.initState();
    _words = List.of(widget.initialWords);
    _startedAt = DateTime.now();
    _prepareQuestion();
  }

  @override
  void dispose() {
    _textController.dispose();
    TtsService().stop();
    super.dispose();
  }

  void _prepareQuestion() {
    final target = _words[_index];
    _selectedOptionId = null;
    _answered = false;
    _wasCorrect = false;
    _textController.clear();
    _hintRevealedChars = 0;
    _hintBanner = null;

    if (widget.quizMode != QuizMode.typing) {
      final pool = widget.appState.wordsForLevel(widget.levelCode);
      final source = pool.length >= 4 ? pool : widget.appState.words;
      final distractors = <WordItem>[];
      final usedAnswers = <String>{
        target.word.toLowerCase(),
        target.translation.toLowerCase(),
      };

      int attempts = 0;
      while (distractors.length < 3 && attempts < 100) {
        attempts++;
        final candidate = source[_rng.nextInt(source.length)];
        if (candidate.id != target.id &&
            !usedAnswers.contains(candidate.word.toLowerCase()) &&
            !usedAnswers.contains(candidate.translation.toLowerCase())) {
          usedAnswers.add(candidate.word.toLowerCase());
          usedAnswers.add(candidate.translation.toLowerCase());
          distractors.add(candidate);
        }
      }

      _options = [target, ...distractors]..shuffle(_rng);
    }
  }

  Future<void> _selectOption(WordItem option) async {
    if (_answered) return;
    final target = _words[_index];
    final isCorrect = option.id == target.id;
    await _recordResult(isCorrect, selectedId: option.id);
  }

  Future<void> _submitTyping() async {
    if (_answered) return;
    final target = _words[_index];
    final input = _textController.text.trim().toLowerCase();
    if (input.isEmpty) return;
    final isCorrect = input == target.word.trim().toLowerCase();
    await _recordResult(isCorrect);
  }

  Future<void> _skipTyping() async {
    if (_answered) return;
    await _recordResult(false);
  }

  void _useTypingHint() {
    if (_answered) return;
    final targetWord = _words[_index].word;
    if (_hintRevealedChars < targetWord.length) {
      setState(() {
        _hintRevealedChars++;
        final prefix = targetWord.substring(0, _hintRevealedChars);
        _textController.text = prefix;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: prefix.length),
        );
        _hintBanner = 'Открыта следующая буква';
      });
    }
  }

  Future<void> _useRewardedHint() async {
    if (_answered) return;
    final earned = await AdService().showRewardedAd();
    if (!mounted) return;
    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Реклама сейчас недоступна. Попробуйте позже.'),
        ),
      );
      return;
    }
    final targetWord = _words[_index].word;
    final nextChars = (_hintRevealedChars + 3).clamp(0, targetWord.length);
    setState(() {
      _hintRevealedChars = nextChars;
      final prefix = targetWord.substring(0, _hintRevealedChars);
      _textController.text = prefix;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: prefix.length),
      );
      _hintBanner = 'Открыто 3 буквы за просмотр рекламы!';
    });
  }

  Future<void> _recordResult(bool isCorrect, {String? selectedId}) async {
    final target = _words[_index];
    setState(() {
      _answered = true;
      _wasCorrect = isCorrect;
      _selectedOptionId = selectedId;
    });

    _results.add(SessionWordResult(word: target, isCorrect: isCorrect));
    await widget.appState.recordWordAnswer(target.id, isCorrect);

    if (isCorrect) {
      _currentCorrectStreak++;
      if (_currentCorrectStreak > _maxCorrectStreak) {
        _maxCorrectStreak = _currentCorrectStreak;
      }
    } else {
      _currentCorrectStreak = 0;
    }
  }

  Future<void> _nextQuestion() async {
    if (_index + 1 >= _words.length) {
      final duration = DateTime.now().difference(_startedAt).inSeconds;
      final correctCount = _results.where((r) => r.isCorrect).length;
      final modeName = switch (widget.quizMode) {
        QuizMode.multipleChoice => 'quiz_choice',
        QuizMode.reverseChoice => 'quiz_reverse',
        QuizMode.typing => 'quiz_typing',
      };
      final unlocked = await widget.appState.completeSession(
        mode: modeName,
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
      setState(() {
        _index++;
        _prepareQuestion();
      });
    }
  }

  void _restart() {
    final nextWords = widget.appState.pickSessionWords(
      level: widget.levelCode,
      count: widget.requestedCount,
      favoritesOnly: widget.favoritesOnly,
    );
    setState(() {
      _words = nextWords.isNotEmpty ? nextWords : List.of(widget.initialWords);
      _index = 0;
      _completed = false;
      _results.clear();
      _newlyUnlocked = [];
      _currentCorrectStreak = 0;
      _maxCorrectStreak = 0;
      _startedAt = DateTime.now();
      _prepareQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      final duration = DateTime.now().difference(_startedAt).inSeconds;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Квиз'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: SessionSummaryView(
          title: 'Квиз завершен!',
          results: _results,
          durationSeconds: duration,
          newlyUnlocked: _newlyUnlocked,
          onRestart: _restart,
          onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      );
    }

    final target = _words[_index];
    final progress = (_index + 1) / _words.length;
    final isEnPrompt = widget.quizMode == QuizMode.multipleChoice;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${_words.length}'),
        centerTitle: true,
        actions: [
          if (_currentCorrectStreak >= 3)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🔥 $_currentCorrectStreak',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppColors.bgCard,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 22),

              // Prompt Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CefrBadge(level: target.level),
                        const Spacer(),
                        if (isEnPrompt || _answered)
                          IconButton(
                            onPressed: () => TtsService().speak(target.word),
                            icon: const Icon(Icons.volume_up_rounded),
                            color: AppColors.primaryLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEnPrompt
                          ? 'Какой перевод слова?'
                          : 'Какое английское слово означает:',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEnPrompt ? target.word : target.translation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isEnPrompt && target.phonetic.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        target.phonetic,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (widget.quizMode != QuizMode.typing)
                ..._options.map((opt) {
                  final isTarget = opt.id == target.id;
                  final isSelected = _selectedOptionId == opt.id;

                  Color bg = AppColors.bgCard;
                  Color border = AppColors.border;
                  IconData? trailingIcon;
                  Color? iconColor;

                  if (_answered) {
                    if (isTarget) {
                      bg = AppColors.emeraldSoft;
                      border = AppColors.emerald;
                      trailingIcon = Icons.check_circle_rounded;
                      iconColor = AppColors.emerald;
                    } else if (isSelected) {
                      bg = AppColors.coralSoft;
                      border = AppColors.coral;
                      trailingIcon = Icons.cancel_rounded;
                      iconColor = AppColors.coral;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _answered ? null : () => _selectOption(opt),
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
                                isEnPrompt ? opt.translation : opt.word,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (trailingIcon != null)
                              Icon(trailingIcon, color: iconColor),
                          ],
                        ),
                      ),
                    ),
                  );
                })
              else ...[
                TextField(
                  controller: _textController,
                  enabled: !_answered,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitTyping(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Введите ответ...',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                ),
                if (_hintBanner != null && !_answered) ...[
                  const SizedBox(height: 8),
                  Text(
                    _hintBanner!,
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (!_answered)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _useTypingHint,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('Подсказка'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.amber,
                          side: BorderSide(
                            color: AppColors.amber.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitTyping,
                          child: const Text('Проверить'),
                        ),
                      ),
                    ],
                  ),
                if (!_answered) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _useRewardedHint,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Открыть 3 буквы (реклама)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      side: BorderSide(
                        color: AppColors.emerald.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _skipTyping,
                    child: const Text(
                      'Пропустить',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],

              if (_answered) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        _wasCorrect ? AppColors.emeraldSoft : AppColors.coralSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _wasCorrect ? AppColors.emerald : AppColors.coral,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _wasCorrect
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color:
                            _wasCorrect ? AppColors.emerald : AppColors.coral,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _wasCorrect
                              ? 'Правильно!'
                              : 'Правильный ответ: ${isEnPrompt ? target.translation : target.word}',
                          style: TextStyle(
                            color: _wasCorrect
                                ? AppColors.emerald
                                : AppColors.coral,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text(
                    _index + 1 >= _words.length ? 'Завершить' : 'Далее →',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
