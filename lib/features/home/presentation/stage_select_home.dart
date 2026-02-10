import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/utils/time_format.dart';
import '../../../game/base_defense_game.dart';

class StageSelectHome extends StatelessWidget {
  const StageSelectHome({
    required this.selectedStageIndex,
    required this.onStageSelected,
    required this.onStartPressed,
    required this.onBuyStarterCoinUpgrade,
    required this.onBuyWeaponStartUpgrade,
    required this.onBuyBaseHpUpgrade,
    required this.onBuyHeartRefill,
    required this.shopStarterCoinLevel,
    required this.shopStarterCoinMaxLevel,
    required this.shopStarterCoinUpgradeCost,
    required this.startingCoinsBonus,
    required this.shopWeaponLevel,
    required this.shopWeaponMaxLevel,
    required this.shopWeaponUpgradeCost,
    required this.startingWeaponLevel,
    required this.shopBaseHpLevel,
    required this.shopBaseHpMaxLevel,
    required this.shopBaseHpUpgradeCost,
    required this.shopBaseHpPercentBonus,
    required this.heartRefillStarCost,
    required this.debugUnlockAllStages,
    required this.onToggleDebugUnlock,
    required this.hearts,
    required this.maxHearts,
    required this.nextHeartIn,
    required this.stageCleared,
    required this.totalStars,
    required this.stageBestStars,
    this.notice,
    super.key,
  });

  final int selectedStageIndex;
  final ValueChanged<int> onStageSelected;
  final VoidCallback onStartPressed;
  final VoidCallback onBuyStarterCoinUpgrade;
  final VoidCallback onBuyWeaponStartUpgrade;
  final VoidCallback onBuyBaseHpUpgrade;
  final VoidCallback onBuyHeartRefill;
  final int shopStarterCoinLevel;
  final int shopStarterCoinMaxLevel;
  final int shopStarterCoinUpgradeCost;
  final int startingCoinsBonus;
  final int shopWeaponLevel;
  final int shopWeaponMaxLevel;
  final int shopWeaponUpgradeCost;
  final int startingWeaponLevel;
  final int shopBaseHpLevel;
  final int shopBaseHpMaxLevel;
  final int shopBaseHpUpgradeCost;
  final int shopBaseHpPercentBonus;
  final int heartRefillStarCost;
  final bool debugUnlockAllStages;
  final VoidCallback onToggleDebugUnlock;
  final int hearts;
  final int maxHearts;
  final Duration? nextHeartIn;
  final List<bool> stageCleared;
  final int totalStars;
  final List<int> stageBestStars;
  final String? notice;

  bool _isStageUnlocked(int index) =>
      debugUnlockAllStages || index == 0 || stageCleared[index - 1];

  String _difficultyLabel(int index) {
    final raw = BaseDefenseGame.stageNameAt(index);
    final parts = raw.split(' - ');
    return parts.length > 1 ? parts.last : 'Normal';
  }

  Color _difficultyColor(String difficulty) {
    final normalized = difficulty.toLowerCase();
    if (normalized.contains('hell')) {
      return const Color(0xFFD6424E);
    }
    if (normalized.contains('very hard')) {
      return const Color(0xFFC76329);
    }
    if (normalized.contains('hard')) {
      return const Color(0xFFDA8A2C);
    }
    return const Color(0xFF3E8CFF);
  }

  int _stageStarCount(int index) {
    if (index < 0 || index >= stageBestStars.length) {
      return 0;
    }
    return stageBestStars[index].clamp(0, 3);
  }

  void _openShopSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF13223A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4E7897), width: 1.6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA0C1422),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _OutlinedLabel(
                      'Shop',
                      fillColor: Color(0xFFEFF8FF),
                      strokeColor: Color(0xFF101827),
                      fontSize: 22,
                      strokeWidth: 4,
                    ),
                    const Spacer(),
                    _ResourceCapsule(
                      icon: Icons.star_rounded,
                      text: '$totalStars',
                      color: const Color(0xFFFFD55A),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 136,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _ShopItemCard(
                        title: 'Starter Coins',
                        detail: '+$startingCoinsBonus at start',
                        levelText:
                            'Lv.$shopStarterCoinLevel/$shopStarterCoinMaxLevel',
                        cost: shopStarterCoinUpgradeCost,
                        isMaxed:
                            shopStarterCoinLevel >= shopStarterCoinMaxLevel,
                        onBuy: () {
                          Navigator.of(context).pop();
                          onBuyStarterCoinUpgrade();
                        },
                      ),
                      _ShopItemCard(
                        title: 'Starter Weapon',
                        detail: 'Start Lv.$startingWeaponLevel',
                        levelText: 'Lv.$shopWeaponLevel/$shopWeaponMaxLevel',
                        cost: shopWeaponUpgradeCost,
                        isMaxed: shopWeaponLevel >= shopWeaponMaxLevel,
                        onBuy: () {
                          Navigator.of(context).pop();
                          onBuyWeaponStartUpgrade();
                        },
                      ),
                      _ShopItemCard(
                        title: 'Base Armor',
                        detail: 'Base HP +$shopBaseHpPercentBonus%',
                        levelText: 'Lv.$shopBaseHpLevel/$shopBaseHpMaxLevel',
                        cost: shopBaseHpUpgradeCost,
                        isMaxed: shopBaseHpLevel >= shopBaseHpMaxLevel,
                        onBuy: () {
                          Navigator.of(context).pop();
                          onBuyBaseHpUpgrade();
                        },
                      ),
                      _ShopItemCard(
                        title: 'Heart Refill',
                        detail: 'Instant +1 Heart',
                        levelText: 'Consumable',
                        cost: heartRefillStarCost,
                        isMaxed: hearts >= maxHearts,
                        onBuy: () {
                          Navigator.of(context).pop();
                          onBuyHeartRefill();
                        },
                        maxLabel: 'FULL',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final selectedUnlocked = _isStageUnlocked(selectedStageIndex);
    final selectedDifficulty = _difficultyLabel(selectedStageIndex);
    final selectedColor = _difficultyColor(selectedDifficulty);
    final selectedStars = _stageStarCount(selectedStageIndex);
    final nextIndex = selectedStageIndex + 1;
    final hasNext = nextIndex < BaseDefenseGame.stageCount;

    final screenWidth = media.size.width;

    return MediaQuery(
      data: media.copyWith(textScaler: const TextScaler.linear(1)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D3FBF), Color(0xFF2577E8), Color(0xFF4DA6FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(painter: _HomePatternPainter()),
              ),
              // Radial glow
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.14),
                        radius: 0.92,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Column(
                  children: [
                    // ─── Top Bar ───
                    _buildTopBar(context),
                    // Heart timer
                    if (nextHeartIn != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xD10F1A36),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xAA799BDA),
                            width: 1.2,
                          ),
                        ),
                        child: _OutlinedLabel(
                          'Next heart in ${formatMmSs(nextHeartIn!)}',
                          fillColor: const Color(0xFFFFDDE3),
                          strokeColor: const Color(0xFF43222A),
                          fontSize: 13,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                    // Notice
                    if (notice != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1B3A5F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF8BC2FF),
                            width: 1.8,
                          ),
                        ),
                        child: _OutlinedLabel(
                          notice!,
                          fillColor: const Color(0xFFF0FAFF),
                          strokeColor: const Color(0xFF1A2A44),
                          fontSize: 14,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // ─── Stage Map Area ───
                    Expanded(
                      child: Stack(
                        children: [
                          // Golden vertical road
                          Align(
                            child: Container(
                              width: 26,
                              margin: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFEAA5),
                                    Color(0xFFF6D774),
                                    Color(0xFFE6B953),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xAA644719),
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xAA7D581C),
                                    blurRadius: 13,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ─── Left side items ───
                          Positioned(
                            left: 0,
                            top: 12,
                            child: _KeyProgressCard(
                              current: shopStarterCoinLevel,
                              max: shopStarterCoinMaxLevel,
                              badgeCount: totalStars,
                              onTap: () => _openShopSheet(context),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 136,
                            child: _EventGiftCard(onTap: onBuyHeartRefill),
                          ),
                          // ─── Right side: ADS button ───
                          Positioned(
                            right: 0,
                            top: 12,
                            child: _AdsButton(
                              debugUnlockAllStages: debugUnlockAllStages,
                              onTap: onToggleDebugUnlock,
                            ),
                          ),
                          // ─── Stage hex nodes ───
                          // Show next+2 at top (e.g. stage 9)
                          if (nextIndex + 1 < BaseDefenseGame.stageCount)
                            Align(
                              alignment: const Alignment(0, -0.78),
                              child: _StageHexNode(
                                stageNumber: nextIndex + 2,
                                accentColor: _difficultyColor(
                                  _difficultyLabel(nextIndex + 1),
                                ),
                                isSelected: false,
                                isUnlocked: _isStageUnlocked(nextIndex + 1),
                                onTap: () => onStageSelected(nextIndex + 1),
                              ),
                            ),
                          // Show next at middle (e.g. stage 8)
                          if (hasNext)
                            Align(
                              alignment: const Alignment(0, -0.08),
                              child: _StageHexNode(
                                stageNumber: nextIndex + 1,
                                accentColor: _difficultyColor(
                                  _difficultyLabel(nextIndex),
                                ),
                                isSelected: false,
                                isUnlocked: _isStageUnlocked(nextIndex),
                                onTap: () => onStageSelected(nextIndex),
                              ),
                            ),
                          // Selected stage at bottom (e.g. stage 7, nearest to Play button)
                          Align(
                            alignment: const Alignment(0, 0.68),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StageHexNode(
                                  stageNumber: selectedStageIndex + 1,
                                  accentColor: selectedColor,
                                  isSelected: true,
                                  isUnlocked: selectedUnlocked,
                                  onTap: () {},
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        selectedColor.withValues(alpha: 0.95),
                                        selectedColor.withValues(alpha: 0.78),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF2D1010),
                                      width: 2.2,
                                    ),
                                  ),
                                  child: _OutlinedLabel(
                                    selectedDifficulty,
                                    fillColor: Colors.white,
                                    strokeColor: const Color(0xFF2C0E0E),
                                    fontSize: 16,
                                    strokeWidth: 4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(3, (index) {
                                    final filled = index < selectedStars;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 20,
                                        color: filled
                                            ? const Color(0xFFFFDE5D)
                                            : const Color(0xFF8CA1C9),
                                        shadows: const [
                                          Shadow(
                                            color: Color(0x99220F13),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ─── Play Button ───
                    SizedBox(
                      width: screenWidth * 0.72,
                      child: _PlayButton(
                        enabled: selectedUnlocked,
                        onTap: selectedUnlocked ? onStartPressed : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ─── Bottom Nav ───
                    _BottomNavBar(
                      onShopTap: () => _openShopSheet(context),
                      onStartTap: selectedUnlocked ? onStartPressed : null,
                      isUnlocked: selectedUnlocked,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF96D2FF), Color(0xFF2E73E2)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7F6FF), width: 2.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99304E9E),
                  blurRadius: 11,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Color(0xFFFFE48B),
              size: 26,
            ),
          ),
          const SizedBox(width: 8),
          // Heart capsule
          _TopBarCapsule(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFFF4466),
            text: '$hearts',
            suffix: hearts >= maxHearts ? 'MAX' : null,
            suffixColor: const Color(0xFFFFD44F),
          ),
          const SizedBox(width: 6),
          // Coin capsule
          Expanded(
            child: _TopBarCoinCapsule(
              text: '$totalStars',
              onAddTap: () => _openShopSheet(context),
            ),
          ),
          const SizedBox(width: 6),
          // Settings gear
          GestureDetector(
            onTap: () {},
            onLongPress: onToggleDebugUnlock,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3C4A71), Color(0xFF242F4E)],
                ),
                border: Border.all(color: const Color(0xFFC5D8FF), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5510192C),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                debugUnlockAllStages
                    ? Icons.bug_report_rounded
                    : Icons.settings_rounded,
                color: const Color(0xFFEFF4FF),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Top Bar Widgets
// ═══════════════════════════════════════════════════════════════

class _TopBarCapsule extends StatelessWidget {
  const _TopBarCapsule({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.suffix,
    this.suffixColor,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final String? suffix;
  final Color? suffixColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xE5131B35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xAA718CC6), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 4),
          _OutlinedLabel(
            text,
            fillColor: Colors.white,
            strokeColor: const Color(0xFF101724),
            fontSize: 16,
            strokeWidth: 3,
          ),
          if (suffix != null) ...[
            const SizedBox(width: 3),
            _OutlinedLabel(
              suffix!,
              fillColor: suffixColor ?? Colors.white,
              strokeColor: const Color(0xFF101724),
              fontSize: 11,
              strokeWidth: 2.5,
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBarCoinCapsule extends StatelessWidget {
  const _TopBarCoinCapsule({required this.text, required this.onAddTap});

  final String text;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: const Color(0xE5131B35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xAA718CC6), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD44F).withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFD44F),
              size: 14,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _OutlinedLabel(
                text,
                fillColor: Colors.white,
                strokeColor: const Color(0xFF101724),
                fontSize: 15,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF56D456), Color(0xFF3BAF3B)],
                ),
                border: Border.all(color: const Color(0xFF1A4A1A), width: 1.4),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Left Side Widgets
// ═══════════════════════════════════════════════════════════════

class _KeyProgressCard extends StatelessWidget {
  const _KeyProgressCard({
    required this.current,
    required this.max,
    required this.badgeCount,
    required this.onTap,
  });

  final int current;
  final int max;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 94,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF1FAFF), Color(0xFFBCD7FF)],
                    ),
                    border: Border.all(
                      color: const Color(0xFF1E2F4E),
                      width: 2.4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55253857),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.vpn_key_rounded,
                      color: Color(0xFFE8A42D),
                      size: 30,
                    ),
                  ),
                ),
                // Badge count
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64CE64),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF143415),
                        width: 1.6,
                      ),
                    ),
                    child: _OutlinedLabel(
                      '$badgeCount',
                      fillColor: Colors.white,
                      strokeColor: const Color(0xFF132611),
                      fontSize: 12,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Progress text (e.g., "17/30")
            Container(
              width: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A3C64), Color(0xFF1B284A)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5A78B2), width: 1.4),
              ),
              child: Center(
                child: _OutlinedLabel(
                  '$current/$max',
                  fillColor: Colors.white,
                  strokeColor: const Color(0xFF101828),
                  fontSize: 13,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventGiftCard extends StatelessWidget {
  const _EventGiftCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 94,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF1FAFF), Color(0xFFBCD7FF)],
                    ),
                    border: Border.all(
                      color: const Color(0xFF1E2F4E),
                      width: 2.4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55253857),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFFE84040),
                      size: 28,
                    ),
                  ),
                ),
                // Red exclamation badge
                Positioned(
                  right: -4,
                  top: -3,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF4444),
                      border: Border.all(
                        color: const Color(0xFF5C1111),
                        width: 1.6,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFEFA2), Color(0xFFF0C650)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3F2A0F), width: 1.9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55332310),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const _OutlinedLabel(
                'START',
                fillColor: Colors.white,
                strokeColor: Color(0xFF22160A),
                fontSize: 14,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Right Side: ADS Button
// ═══════════════════════════════════════════════════════════════

class _AdsButton extends StatelessWidget {
  const _AdsButton({required this.debugUnlockAllStages, required this.onTap});

  final bool debugUnlockAllStages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: debugUnlockAllStages
                ? const [Color(0xFF72D862), Color(0xFF43A73B)]
                : const [Color(0xFFF06A79), Color(0xFFD53C4C)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF39161D), width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66350F16),
              blurRadius: 9,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block_rounded, color: Colors.white, size: 28),
            const SizedBox(height: 2),
            _OutlinedLabel(
              debugUnlockAllStages ? 'DEBUG' : 'ADS',
              fillColor: Colors.white,
              strokeColor: const Color(0xFF231014),
              fontSize: 18,
              strokeWidth: 4,
            ),
            _OutlinedLabel(
              debugUnlockAllStages ? 'ON' : 'NO ADS',
              fillColor: const Color(0xFFFFEE88),
              strokeColor: const Color(0xFF231014),
              fontSize: 12,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Stage Hex Node
// ═══════════════════════════════════════════════════════════════

class _StageHexNode extends StatelessWidget {
  const _StageHexNode({
    required this.stageNumber,
    required this.accentColor,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
  });

  final int stageNumber;
  final Color accentColor;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 130.0 : 96.0;
    final shellTop = isSelected
        ? const Color(0xFFF3FAFF)
        : const Color(0xFFD8EBFF);
    final shellBottom = isSelected
        ? const Color(0xFFC6DEFB)
        : const Color(0xFFBFD9F8);
    final coreColor = isUnlocked ? accentColor : const Color(0xFF6A7283);
    final cornerRadius = isSelected ? 14.0 : 10.0;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Opacity(
        opacity: isUnlocked ? 1 : 0.62,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer shell
              ClipPath(
                clipper: _RoundedHexagonClipper(cornerRadius: cornerRadius),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [shellTop, shellBottom],
                    ),
                  ),
                ),
              ),
              // Dark border (slightly smaller)
              ClipPath(
                clipper: _RoundedHexagonClipper(
                  cornerRadius: cornerRadius,
                  inset: 0,
                ),
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _HexBorderPainter(
                    cornerRadius: cornerRadius,
                    borderColor: const Color(0xFF111C2C),
                    borderWidth: 3,
                  ),
                ),
              ),
              // Inner core
              Padding(
                padding: const EdgeInsets.all(8),
                child: ClipPath(
                  clipper: _RoundedHexagonClipper(
                    cornerRadius: cornerRadius - 2,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          coreColor.withValues(alpha: 0.95),
                          coreColor,
                          coreColor.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Shine highlight
              Positioned(
                top: size * 0.14,
                child: Container(
                  width: size * 0.22,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              // Stage number
              _OutlinedLabel(
                '$stageNumber',
                fillColor: Colors.white,
                strokeColor: const Color(0xFF151C2A),
                fontSize: isSelected ? 50 : 36,
                strokeWidth: 6,
              ),
              // Lock icon
              if (!isUnlocked)
                Positioned(
                  top: 12,
                  right: 14,
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 17,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips to a regular hexagon (pointy-top) with rounded corners.
class _RoundedHexagonClipper extends CustomClipper<Path> {
  _RoundedHexagonClipper({this.cornerRadius = 12, this.inset = 0});

  final double cornerRadius;
  final double inset;

  @override
  Path getClip(Size size) {
    return _buildRoundedHexPath(size, cornerRadius, inset);
  }

  @override
  bool shouldReclip(covariant _RoundedHexagonClipper oldClipper) =>
      cornerRadius != oldClipper.cornerRadius || inset != oldClipper.inset;
}

/// Paints just the hex border stroke.
class _HexBorderPainter extends CustomPainter {
  _HexBorderPainter({
    required this.cornerRadius,
    required this.borderColor,
    required this.borderWidth,
  });

  final double cornerRadius;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildRoundedHexPath(size, cornerRadius, 0);
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexBorderPainter oldDelegate) =>
      cornerRadius != oldDelegate.cornerRadius ||
      borderColor != oldDelegate.borderColor ||
      borderWidth != oldDelegate.borderWidth;
}

/// Builds a rounded regular hexagon path (pointy-top orientation).
Path _buildRoundedHexPath(Size size, double radius, double inset) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = (size.width / 2) - inset; // circumradius

  // 6 vertices of a pointy-top regular hexagon
  final vertices = <Offset>[];
  for (int i = 0; i < 6; i++) {
    final angle = (math.pi / 180) * (60 * i - 90);
    vertices.add(Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)));
  }

  final path = Path();
  for (int i = 0; i < 6; i++) {
    final prev = vertices[(i + 5) % 6];
    final curr = vertices[i];
    final next = vertices[(i + 1) % 6];

    // Shorten edges by cornerRadius
    final toPrev = (prev - curr);
    final toNext = (next - curr);
    final lenPrev = toPrev.distance;
    final lenNext = toNext.distance;
    final clampedR = radius.clamp(0, math.min(lenPrev, lenNext) / 2).toDouble();

    final startPt = curr + toPrev * (clampedR / lenPrev);
    final endPt = curr + toNext * (clampedR / lenNext);

    if (i == 0) {
      path.moveTo(startPt.dx, startPt.dy);
    } else {
      path.lineTo(startPt.dx, startPt.dy);
    }
    path.quadraticBezierTo(curr.dx, curr.dy, endPt.dx, endPt.dy);
  }
  path.close();
  return path;
}

// ═══════════════════════════════════════════════════════════════
// Play Button
// ═══════════════════════════════════════════════════════════════

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.65,
          child: Container(
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFED9B),
                  Color(0xFFF4CB5F),
                  Color(0xFFE6B548),
                ],
              ),
              border: Border.all(color: const Color(0xFF2F2111), width: 3.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA624311),
                  blurRadius: 11,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 14,
                  right: 14,
                  top: 7,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const _OutlinedLabel(
                  'Play',
                  fillColor: Colors.white,
                  strokeColor: Color(0xFF121111),
                  fontSize: 46,
                  strokeWidth: 7,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Bottom Navigation Bar
// ═══════════════════════════════════════════════════════════════

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.onShopTap,
    required this.onStartTap,
    required this.isUnlocked,
  });

  final VoidCallback onShopTap;
  final VoidCallback? onStartTap;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEE1C2147), Color(0xEE141A3A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xAA687CB5), width: 1.4),
      ),
      child: Row(
        children: [
          // Shop
          _BottomNavItem(
            icon: Icons.storefront_rounded,
            label: 'Shop',
            onTap: onShopTap,
          ),
          // Start (center, elevated)
          _BottomNavItem(
            icon: Icons.pets_rounded,
            label: 'Start',
            selected: true,
            prominent: true,
            onTap: onStartTap,
          ),
          // Lock / Ready
          _BottomNavItem(
            icon: Icons.lock_rounded,
            label: isUnlocked ? 'Ready' : 'Locked',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final margin = const EdgeInsets.symmetric(horizontal: 4, vertical: 5);
    final backgroundColor = selected
        ? (prominent ? const Color(0xFF4A57D8) : const Color(0xFF4959D2))
        : Colors.transparent;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(prominent ? 16 : 14),
            border: selected
                ? Border.all(
                    color: prominent
                        ? const Color(0xFFC3D0FF)
                        : const Color(0xFFA7B9FF),
                    width: prominent ? 1.8 : 1.4,
                  )
                : null,
            boxShadow: prominent
                ? const [
                    BoxShadow(
                      color: Color(0x5531337B),
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFFEFF4FF)
                    : const Color(0xFFB6C8E8),
                size: selected ? (prominent ? 31 : 30) : 27,
              ),
              const SizedBox(height: 3),
              _OutlinedLabel(
                label,
                fillColor: selected
                    ? const Color(0xFFF7FBFF)
                    : const Color(0xFFD6E3F8),
                strokeColor: const Color(0xFF1A2141),
                fontSize: 14,
                strokeWidth: 3,
                fontWeight: FontWeight.w800,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════════

class _OutlinedLabel extends StatelessWidget {
  const _OutlinedLabel(
    this.text, {
    required this.fillColor,
    required this.strokeColor,
    required this.fontSize,
    required this.strokeWidth,
    this.fontWeight = FontWeight.w900,
  });

  final String text;
  final Color fillColor;
  final Color strokeColor;
  final double fontSize;
  final double strokeWidth;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

class _ResourceCapsule extends StatelessWidget {
  const _ResourceCapsule({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE6111930),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xAA90A9D8), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 4),
          _OutlinedLabel(
            text,
            fillColor: Colors.white,
            strokeColor: const Color(0xFF101724),
            fontSize: 16,
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Background Pattern Painter
// ═══════════════════════════════════════════════════════════════

class _HomePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0x22FFFFFF);

    for (var i = 0; i < 18; i += 1) {
      final x = ((i * 127) % size.width);
      final y = ((i * 197) % size.height);
      final radius = 15.0 + (i % 5) * 3;
      canvas.drawCircle(Offset(x, y), radius, linePaint);
      canvas.drawCircle(
        Offset(x + 5, y),
        1.8,
        Paint()..color = const Color(0x22FFFFFF),
      );
      canvas.drawCircle(
        Offset(x - 5, y),
        1.8,
        Paint()..color = const Color(0x22FFFFFF),
      );
    }

    final glowPaint = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x66B9ECFF), Color(0x00000000)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.45),
              radius: size.shortestSide * 0.56,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.shortestSide * 0.56,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Shop Item Card (for bottom sheet)
// ═══════════════════════════════════════════════════════════════

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.title,
    required this.detail,
    required this.levelText,
    required this.cost,
    required this.isMaxed,
    required this.onBuy,
    this.maxLabel = 'MAX',
  });

  final String title;
  final String detail;
  final String levelText;
  final int cost;
  final bool isMaxed;
  final VoidCallback onBuy;
  final String maxLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3554), Color(0xFF162A42)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B6E8B), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OutlinedLabel(
            title,
            fillColor: const Color(0xFFF3F9FF),
            strokeColor: const Color(0xFF0F1724),
            fontSize: 14,
            strokeWidth: 3,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC4D8EE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            levelText,
            style: const TextStyle(
              color: Color(0xFF9FC2E0),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isMaxed ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2C756),
                disabledBackgroundColor: const Color(0xFF546271),
                minimumSize: const Size.fromHeight(34),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF483213), width: 1.6),
                ),
              ),
              child: _OutlinedLabel(
                isMaxed ? maxLabel : 'Buy $cost★',
                fillColor: Colors.white,
                strokeColor: const Color(0xFF22170A),
                fontSize: 15,
                strokeWidth: 3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
