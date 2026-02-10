import 'dart:async';
import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/game/presentation/game_over_overlay.dart';
import '../features/game/presentation/hud_overlay.dart';
import '../features/home/presentation/stage_select_home.dart';
import '../game/base_defense_game.dart';

class DefenseShooterApp extends StatefulWidget {
  const DefenseShooterApp({super.key});

  @override
  State<DefenseShooterApp> createState() => _DefenseShooterAppState();
}

class _DefenseShooterAppState extends State<DefenseShooterApp> {
  static const int _initialHearts = 3;
  static const int _maxHearts = 5;
  static const Duration _heartRegenInterval = Duration(minutes: 15);
  static const String _saveKey = 'progress_v1';
  static const int _shopStarterCoinMaxLevel = 5;
  static const int _shopWeaponMaxLevel = 3;
  static const int _shopBaseHpMaxLevel = 4;
  static const int _heartRefillStarCost = 5;

  BaseDefenseGame? _game;
  int _selectedStageIndex = 0;
  String? _homeNotice;
  int _hearts = _initialHearts;
  int _totalStars = 0;
  late final List<bool> _stageCleared = List<bool>.filled(
    BaseDefenseGame.stageCount,
    false,
  );
  late final List<int> _stageBestStars = List<int>.filled(
    BaseDefenseGame.stageCount,
    0,
  );
  Timer? _heartTicker;
  DateTime? _nextHeartAt;
  bool _isLoadingSave = true;
  bool _debugUnlockAllStages = false;
  int _shopStarterCoinLevel = 0;
  int _shopWeaponLevel = 0;
  int _shopBaseHpLevel = 0;

  int get _shopStarterCoinUpgradeCost => 6 + (_shopStarterCoinLevel * 4);
  int get _shopWeaponUpgradeCost => 12 + (_shopWeaponLevel * 8);
  int get _shopBaseHpUpgradeCost => 10 + (_shopBaseHpLevel * 7);
  int get _startingCoinsBonus => _shopStarterCoinLevel * 5;
  int get _startingWeaponLevel => 1 + _shopWeaponLevel;
  int get _shopBaseHpPercentBonus => _shopBaseHpLevel * 10;
  double get _shopBaseHpMultiplier => 1 + (_shopBaseHpLevel * 0.10);

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _heartTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickHeartRegeneration(),
    );
  }

  @override
  void dispose() {
    _heartTicker?.cancel();
    super.dispose();
  }

  bool _isStageUnlocked(int index) =>
      _debugUnlockAllStages || index == 0 || _stageCleared[index - 1];

  int get _highestUnlockedStageIndex {
    var highest = 0;
    for (var i = 1; i < BaseDefenseGame.stageCount; i += 1) {
      if (_stageCleared[i - 1]) {
        highest = i;
      } else {
        break;
      }
    }
    return highest;
  }

  int _clampToSelectableStage(int index) {
    final bounded = index.clamp(0, BaseDefenseGame.stageCount - 1).toInt();
    if (_debugUnlockAllStages) {
      return bounded;
    }
    return bounded.clamp(0, _highestUnlockedStageIndex).toInt();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (!mounted) {
      return;
    }

    if (raw == null) {
      setState(() {
        _ensureHeartRegenScheduled();
        _isLoadingSave = false;
      });
      return;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final clearedRaw = (map['stageCleared'] as List<dynamic>? ?? const [])
          .cast<bool>();
      final starsRaw = (map['stageBestStars'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList();

      setState(() {
        _selectedStageIndex = (map['selectedStageIndex'] as num? ?? 0)
            .toInt()
            .clamp(0, BaseDefenseGame.stageCount - 1);
        _hearts = (map['hearts'] as num? ?? _initialHearts).toInt().clamp(
          0,
          _maxHearts,
        );
        _totalStars = (map['totalStars'] as num? ?? 0).toInt().clamp(0, 999999);
        _shopStarterCoinLevel = (map['shopStarterCoinLevel'] as num? ?? 0)
            .toInt()
            .clamp(0, _shopStarterCoinMaxLevel);
        _shopWeaponLevel = (map['shopWeaponLevel'] as num? ?? 0).toInt().clamp(
          0,
          _shopWeaponMaxLevel,
        );
        _shopBaseHpLevel = (map['shopBaseHpLevel'] as num? ?? 0).toInt().clamp(
          0,
          _shopBaseHpMaxLevel,
        );

        for (var i = 0; i < _stageCleared.length; i += 1) {
          _stageCleared[i] = i < clearedRaw.length ? clearedRaw[i] : false;
        }
        for (var i = 0; i < _stageBestStars.length; i += 1) {
          _stageBestStars[i] = i < starsRaw.length
              ? starsRaw[i].clamp(0, 3)
              : 0;
        }

        final nextHeartEpoch = (map['nextHeartAt'] as num?)?.toInt();
        _nextHeartAt = nextHeartEpoch == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(nextHeartEpoch);
        _selectedStageIndex = _clampToSelectableStage(_selectedStageIndex);
        _ensureHeartRegenScheduled();
        _isLoadingSave = false;
      });
      _tickHeartRegeneration();
    } catch (_) {
      setState(() {
        _ensureHeartRegenScheduled();
        _isLoadingSave = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'selectedStageIndex': _selectedStageIndex,
      'hearts': _hearts,
      'totalStars': _totalStars,
      'shopStarterCoinLevel': _shopStarterCoinLevel,
      'shopWeaponLevel': _shopWeaponLevel,
      'shopBaseHpLevel': _shopBaseHpLevel,
      'stageCleared': _stageCleared,
      'stageBestStars': _stageBestStars,
      'nextHeartAt': _nextHeartAt?.millisecondsSinceEpoch,
    };
    await prefs.setString(_saveKey, jsonEncode(payload));
  }

  Duration? get _nextHeartIn {
    final nextAt = _nextHeartAt;
    if (nextAt == null) {
      return null;
    }
    final remain = nextAt.difference(DateTime.now());
    if (remain.isNegative) {
      return Duration.zero;
    }
    return remain;
  }

  void _ensureHeartRegenScheduled() {
    if (_hearts < _maxHearts && _nextHeartAt == null) {
      _nextHeartAt = DateTime.now().add(_heartRegenInterval);
    }
    if (_hearts >= _maxHearts) {
      _nextHeartAt = null;
    }
  }

  void _tickHeartRegeneration() {
    if (!mounted) {
      return;
    }

    if (_hearts >= _maxHearts) {
      if (_nextHeartAt != null) {
        setState(() {
          _nextHeartAt = null;
        });
        unawaited(_saveProgress());
      }
      return;
    }

    final now = DateTime.now();
    final scheduledAt = _nextHeartAt ?? now.add(_heartRegenInterval);
    if (_nextHeartAt == null) {
      setState(() {
        _nextHeartAt = scheduledAt;
      });
      unawaited(_saveProgress());
      return;
    }

    if (now.isBefore(scheduledAt)) {
      setState(() {});
      return;
    }

    final intervalSeconds = _heartRegenInterval.inSeconds;
    final gained =
        1 + (now.difference(scheduledAt).inSeconds ~/ intervalSeconds);
    final newHearts = (_hearts + gained).clamp(0, _maxHearts).toInt();
    final actualGained = newHearts - _hearts;

    setState(() {
      _hearts = newHearts;
      if (_hearts >= _maxHearts) {
        _nextHeartAt = null;
      } else {
        _nextHeartAt = scheduledAt.add(
          Duration(seconds: intervalSeconds * actualGained),
        );
      }
    });
    unawaited(_saveProgress());
  }

  bool _trySpendStars(int amount) {
    if (_totalStars < amount || amount <= 0) {
      return false;
    }
    _totalStars -= amount;
    return true;
  }

  void _buyStarterCoinUpgrade() {
    if (_shopStarterCoinLevel >= _shopStarterCoinMaxLevel) {
      setState(() {
        _homeNotice = 'Starter Coin upgrade is already maxed';
      });
      return;
    }
    final cost = _shopStarterCoinUpgradeCost;
    setState(() {
      if (!_trySpendStars(cost)) {
        _homeNotice = 'Not enough stars';
        return;
      }
      _shopStarterCoinLevel += 1;
      _homeNotice =
          'Starter Coins upgraded: +$_startingCoinsBonus at stage start';
    });
    unawaited(_saveProgress());
  }

  void _buyWeaponStartUpgrade() {
    if (_shopWeaponLevel >= _shopWeaponMaxLevel) {
      setState(() {
        _homeNotice = 'Starter Weapon upgrade is already maxed';
      });
      return;
    }
    final cost = _shopWeaponUpgradeCost;
    setState(() {
      if (!_trySpendStars(cost)) {
        _homeNotice = 'Not enough stars';
        return;
      }
      _shopWeaponLevel += 1;
      _homeNotice =
          'Starter Weapon upgraded: starts at Lv.$_startingWeaponLevel';
    });
    unawaited(_saveProgress());
  }

  void _buyBaseHpUpgrade() {
    if (_shopBaseHpLevel >= _shopBaseHpMaxLevel) {
      setState(() {
        _homeNotice = 'Base Armor upgrade is already maxed';
      });
      return;
    }
    final cost = _shopBaseHpUpgradeCost;
    setState(() {
      if (!_trySpendStars(cost)) {
        _homeNotice = 'Not enough stars';
        return;
      }
      _shopBaseHpLevel += 1;
      _homeNotice = 'Base HP upgraded: +$_shopBaseHpPercentBonus%';
    });
    unawaited(_saveProgress());
  }

  void _buyHeartRefill() {
    if (_hearts >= _maxHearts) {
      setState(() {
        _homeNotice = 'Hearts are already full';
      });
      return;
    }
    setState(() {
      if (!_trySpendStars(_heartRefillStarCost)) {
        _homeNotice = 'Not enough stars';
        return;
      }
      _hearts = (_hearts + 1).clamp(0, _maxHearts).toInt();
      _ensureHeartRegenScheduled();
      _homeNotice = 'Heart +1';
    });
    unawaited(_saveProgress());
  }

  void _startSelectedStage() {
    if (!_isStageUnlocked(_selectedStageIndex)) {
      setState(() {
        _selectedStageIndex = _clampToSelectableStage(_selectedStageIndex);
        _homeNotice =
            'Selected stage was locked. Moved to Stage ${_selectedStageIndex + 1}.';
      });
      unawaited(_saveProgress());
      return;
    }

    final selectedStage = _selectedStageIndex;
    late final BaseDefenseGame newGame;
    newGame = BaseDefenseGame(
      startStageIndex: selectedStage,
      startingCoins: _startingCoinsBonus,
      startingWeaponLevel: _startingWeaponLevel,
      baseHpMultiplier: _shopBaseHpMultiplier,
      onStageCleared: (stars) {
        if (!mounted || _game != newGame) {
          return;
        }
        setState(() {
          _totalStars += stars;
          _stageCleared[selectedStage] = true;
          _stageBestStars[selectedStage] =
              stars > _stageBestStars[selectedStage]
              ? stars
              : _stageBestStars[selectedStage];
          if (selectedStage + 1 < BaseDefenseGame.stageCount) {
            _selectedStageIndex = selectedStage + 1;
          }
        });
        unawaited(_saveProgress());
        _returnToHome(notice: 'STAGE CLEAR  +$stars STAR');
      },
    );
    setState(() {
      _game = newGame;
      _homeNotice = null;
    });
  }

  void _returnToHome({String? notice}) {
    _game?.pauseEngine();
    setState(() {
      _game = null;
      _homeNotice = notice;
    });
  }

  void _retryCurrentStage() {
    final game = _game;
    if (game == null || _hearts <= 0) {
      return;
    }
    setState(() {
      _hearts -= 1;
      _ensureHeartRegenScheduled();
    });
    unawaited(_saveProgress());
    game.resetGame();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quarterview Base Defense',
      home: Scaffold(body: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoadingSave) {
      return const ColoredBox(
        color: Color(0xFF121B25),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF8EB5D8)),
        ),
      );
    }

    final game = _game;
    if (game == null) {
      return StageSelectHome(
        selectedStageIndex: _selectedStageIndex,
        onStageSelected: (index) {
          if (!_isStageUnlocked(index)) {
            return;
          }
          setState(() {
            _selectedStageIndex = index;
          });
          unawaited(_saveProgress());
        },
        onStartPressed: _startSelectedStage,
        onBuyStarterCoinUpgrade: _buyStarterCoinUpgrade,
        onBuyWeaponStartUpgrade: _buyWeaponStartUpgrade,
        onBuyBaseHpUpgrade: _buyBaseHpUpgrade,
        onBuyHeartRefill: _buyHeartRefill,
        shopStarterCoinLevel: _shopStarterCoinLevel,
        shopStarterCoinMaxLevel: _shopStarterCoinMaxLevel,
        shopStarterCoinUpgradeCost: _shopStarterCoinUpgradeCost,
        startingCoinsBonus: _startingCoinsBonus,
        shopWeaponLevel: _shopWeaponLevel,
        shopWeaponMaxLevel: _shopWeaponMaxLevel,
        shopWeaponUpgradeCost: _shopWeaponUpgradeCost,
        startingWeaponLevel: _startingWeaponLevel,
        shopBaseHpLevel: _shopBaseHpLevel,
        shopBaseHpMaxLevel: _shopBaseHpMaxLevel,
        shopBaseHpUpgradeCost: _shopBaseHpUpgradeCost,
        shopBaseHpPercentBonus: _shopBaseHpPercentBonus,
        heartRefillStarCost: _heartRefillStarCost,
        debugUnlockAllStages: _debugUnlockAllStages,
        onToggleDebugUnlock: () {
          setState(() {
            _debugUnlockAllStages = !_debugUnlockAllStages;
            if (!_debugUnlockAllStages) {
              final before = _selectedStageIndex;
              _selectedStageIndex = _clampToSelectableStage(
                _selectedStageIndex,
              );
              if (_selectedStageIndex != before) {
                _homeNotice =
                    'Locked stage deselected. Current Stage ${_selectedStageIndex + 1}.';
              }
            }
          });
        },
        notice: _homeNotice,
        hearts: _hearts,
        maxHearts: _maxHearts,
        nextHeartIn: _nextHeartIn,
        stageCleared: _stageCleared,
        totalStars: _totalStars,
        stageBestStars: _stageBestStars,
      );
    }

    return Stack(
      children: [
        GameWidget<BaseDefenseGame>(
          game: game,
          overlayBuilderMap: {
            BaseDefenseGame.hudOverlayId: (context, game) =>
                HudOverlay(game: game),
            BaseDefenseGame.gameOverOverlayId: (context, game) =>
                GameOverOverlay(
                  game: game,
                  hearts: _hearts,
                  maxHearts: _maxHearts,
                  nextHeartIn: _nextHeartIn,
                  onRetry: _retryCurrentStage,
                  onBackHome: _returnToHome,
                ),
          },
          initialActiveOverlays: const [BaseDefenseGame.hudOverlayId],
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xAA0E1A24),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x996C89A4)),
                ),
                child: IconButton(
                  onPressed: _returnToHome,
                  icon: const Icon(Icons.home_rounded, color: Colors.white),
                  tooltip: 'Stage Select',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
