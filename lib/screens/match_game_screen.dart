import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../services/ad_service.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class MatchGameScreen extends StatefulWidget {
  final AppState appState;
  final String levelCode;

  const MatchGameScreen({
    super.key,
    required this.appState,
    required this.levelCode,
  });

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  final Random _rng = Random();
  List<WordItem> _roundWords = [];
  List<WordItem> _leftColumn = [];
  List<WordItem> _rightColumn = [];

  String? _selectedLeftId;
  String? _selectedRightId;
  final Set<String> _matchedIds = {};
  String? _wrongLeftId;
  String? _wrongRightId;

  int _mistakes = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    final picked = widget.appState.pickSessionWords(
      level: widget.levelCode,
      count: 6,
      favoritesOnly: false,
    );
    _roundWords = picked;
    _leftColumn = List.of(picked)..shuffle(_rng);
    _rightColumn = List.of(picked)..shuffle(_rng);
    _selectedLeftId = null;
    _selectedRightId = null;
    _matchedIds.clear();
    _wrongLeftId = null;
    _wrongRightId = null;
    _mistakes = 0;
    _elapsedSeconds = 0;
    _completed = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completed) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _tapLeft(WordItem w) {
    if (_matchedIds.contains(w.id)) return;
    TtsService().speak(w.word);
    setState(() {
      _wrongLeftId = null;
      _wrongRightId = null;
      _selectedLeftId = w.id;
    });
    _checkMatch();
  }

  void _tapRight(WordItem w) {
    if (_matchedIds.contains(w.id)) return;
    setState(() {
      _wrongLeftId = null;
      _wrongRightId = null;
      _selectedRightId = w.id;
    });
    _checkMatch();
  }

  Future<void> _checkMatch() async {
    final leftId = _selectedLeftId;
    final rightId = _selectedRightId;
    if (leftId == null || rightId == null) return;

    if (leftId == rightId) {
      setState(() {
        _matchedIds.add(leftId);
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      await widget.appState.recordWordAnswer(leftId, true);

      if (_matchedIds.length == _roundWords.length) {
        _timer?.cancel();
        await widget.appState.recordMatchGameTime(_elapsedSeconds);
        await widget.appState.completeSession(
          mode: 'match_game',
          level: widget.levelCode,
          totalWords: _roundWords.length,
          correctCount: max(0, _roundWords.length - _mistakes),
          durationSeconds: max(1, _elapsedSeconds),
          maxCorrectStreak: _mistakes == 0 ? _roundWords.length : 0,
        );
        if (!mounted) return;
        setState(() => _completed = true);
        unawaited(AdService().onSessionCompleted());
      }
    } else {
      setState(() {
        _mistakes++;
        _wrongLeftId = leftId;
        _wrongRightId = rightId;
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _wrongLeftId = null;
        _wrongRightId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final best = widget.appState.bestMatchSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Найди пары'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⏱ $_elapsedSeconds с',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _completed
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emeraldSoft,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            size: 46,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Раунд пройден за $_elapsedSeconds с!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ошибок: $_mistakes${best != null ? ' · Лучшее время: $best с' : ''}',
                          style: TextStyle(
                            color: AppColors.secondaryText(context),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(_startRound),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Сыграть ещё раз'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Назад'),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      children: [
                        Text(
                          'Соедините английское слово с переводом (${_matchedIds.length}/${_roundWords.length})',
                          style: TextStyle(
                            color: AppColors.secondaryText(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _leftColumn.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, idx) {
                                    final w = _leftColumn[idx];
                                    return _MatchTile(
                                      text: w.word,
                                      matched: _matchedIds.contains(w.id),
                                      selected: _selectedLeftId == w.id,
                                      wrong: _wrongLeftId == w.id,
                                      onTap: () => _tapLeft(w),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _rightColumn.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, idx) {
                                    final w = _rightColumn[idx];
                                    return _MatchTile(
                                      text: w.translation,
                                      matched: _matchedIds.contains(w.id),
                                      selected: _selectedRightId == w.id,
                                      wrong: _wrongRightId == w.id,
                                      onTap: () => _tapRight(w),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String text;
  final bool matched;
  final bool selected;
  final bool wrong;
  final VoidCallback onTap;

  const _MatchTile({
    required this.text,
    required this.matched,
    required this.selected,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.cardBg(context);
    Color border = AppColors.cardBorder(context);
    if (matched) {
      bg = AppColors.emeraldSoft;
      border = AppColors.emerald;
    } else if (wrong) {
      bg = AppColors.coralSoft;
      border = AppColors.coral;
    } else if (selected) {
      bg = AppColors.primary.withValues(alpha: 0.16);
      border = AppColors.primary;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: matched ? 0.45 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: matched ? null : onTap,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: selected || wrong ? 2 : 1),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
