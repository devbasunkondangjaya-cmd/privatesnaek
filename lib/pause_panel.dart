import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'ui_kit.dart';
import 'venomcoil_game.dart';

/// Fades a popup in and springs it up from slightly smaller.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutBack,
    builder: (context, t, child) => Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
    ),
    child: child,
  );
}

/// Pause popup: frosted backdrop, a card glowing in the skin's colour with
/// the run's stats, a big resume button and shortcuts.
class PausePanel extends StatelessWidget {
  const PausePanel({super.key, required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  Widget build(BuildContext context) {
    final safe = safeInsets(context, extra: 8);
    final glow = VenomcoilGame.skinColors[state.skinIndex.clamp(0, 9)];
    final areaNo = state.area.toString().padLeft(2, '0');
    final wide = MediaQuery.sizeOf(context).height < 520;

    final stats = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'NYAWA',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      AtlasIcon(
                        i < state.hearts ? Hud.heart : Hud.brokenHeart,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: 'WAKTU',
                child: Text(formatTime(state.elapsed), style: _statText),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: 'BENDERA',
                child: Text('${state.checkpoint}/12', style: _statText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const AtlasIcon(Hud.flag, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 7,
                  color: Palette.gold,
                  backgroundColor: const Color(0xff20352b),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(state.progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Palette.gold,
              ),
            ),
          ],
        ),
      ],
    );

    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameButton(
          label: 'LANJUT MAIN',
          style: GameButtonStyle.primary,
          height: 54,
          icon: const Icon(
            Icons.play_arrow_rounded,
            size: 32,
            color: Color(0xff102114),
          ),
          onTap: game.startOrResume,
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'SKIN',
                icon: const AtlasIcon(Hud.coil, size: 20),
                onTap: game.openSkinSelect,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GameButton(
                label: 'AREA',
                icon: const AtlasIcon(Hud.flag, size: 20),
                onTap: game.openAreaSelect,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'ULANG',
                style: GameButtonStyle.ghost,
                height: 40,
                icon: const AtlasIcon(Hud.restart, size: 16),
                onTap: game.retry,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GameButton(
                label: 'MENU',
                style: GameButtonStyle.ghost,
                height: 40,
                onTap: game.quitToMenu,
              ),
            ),
          ],
        ),
      ],
    );

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: const Color(0xaa030d0a),
        padding: safe,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 640 : 440),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff1b3a2b), Color(0xff0c1b15)],
              ),
              border: Border.all(
                color: glow.withValues(alpha: 0.7),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(color: glow.withValues(alpha: 0.28), blurRadius: 40),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(glow: glow, areaNo: areaNo, name: state.areaName),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: stats),
                                const SizedBox(width: 16),
                                Expanded(child: buttons),
                              ],
                            )
                          : Column(
                              children: [
                                stats,
                                const SizedBox(height: 14),
                                buttons,
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.glow, required this.areaNo, required this.name});

  final Color glow;
  final String areaNo;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [glow.withValues(alpha: 0.35), glow.withValues(alpha: 0.04)],
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xff0c1b15),
            border: Border.all(color: glow, width: 2),
            boxShadow: [
              BoxShadow(color: glow.withValues(alpha: 0.5), blurRadius: 12),
            ],
          ),
          alignment: Alignment.center,
          child: const AtlasIcon(Hud.pause, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AREA $areaNo  •  ${name.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w900,
                  color: Palette.leafBright,
                ),
              ),
              const GradientText(
                'PERMAINAN DIJEDA',
                colors: [Color(0xfffff3a8), Color(0xff9bf07a)],
                style: TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

const _statText = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w900,
  color: Palette.cream,
  fontFeatures: [ui.FontFeature.tabularFigures()],
);

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(
      color: const Color(0x66000000),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x3375df69)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
            color: Palette.mist,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 22, child: Center(child: child)),
      ],
    ),
  );
}
