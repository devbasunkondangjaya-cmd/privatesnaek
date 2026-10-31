import 'package:flutter/material.dart';

import 'ui_kit.dart';
import 'venomcoil_game.dart';

export 'ui_kit.dart' show PopIn;

/// Pause popup: a card glowing in the skin's colour with the run's stats, a
/// big resume button and shortcuts. The game loop is off while it is open, so
/// the screen is completely still and costs no frames.
class PausePanel extends StatelessWidget {
  const PausePanel({super.key, required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  Widget build(BuildContext context) {
    final glow = VenomcoilGame.skinColors[state.skinIndex.clamp(0, 9)];
    final areaNo = state.area.toString().padLeft(2, '0');
    final wide = MediaQuery.sizeOf(context).height < 520;
    final playIcon = const Icon(
      Icons.play_arrow_rounded,
      size: 30,
      color: Palette.goldBright,
    );

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
            const SizedBox(width: 7),
            Expanded(
              child: _Stat(
                label: 'WAKTU',
                child: Text(formatTime(state.elapsed), style: Ts.value(16)),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _Stat(
                label: 'BENDERA',
                child: Text('${state.checkpoint}/12', style: Ts.value(16)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            const AtlasIcon(Hud.flag, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: RuneBar(
                fill: state.progress,
                color: Palette.gold,
                height: 9,
                notches: 13,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(state.progress * 100).round()}%',
              style: Ts.value(13.5, color: Palette.gold),
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
          height: 52,
          icon: playIcon,
          onTap: game.startOrResume,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'SKIN',
                height: 42,
                icon: const AtlasIcon(Hud.coil, size: 20),
                onTap: game.openSkinSelect,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GameButton(
                label: 'AREA',
                height: 42,
                icon: const AtlasIcon(Hud.flag, size: 20),
                onTap: game.openAreaSelect,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'ULANG',
                style: GameButtonStyle.ghost,
                height: 36,
                icon: const AtlasIcon(Hud.restart, size: 16),
                onTap: game.retry,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GameButton(
                label: 'MENU',
                style: GameButtonStyle.ghost,
                height: 36,
                onTap: game.quitToMenu,
              ),
            ),
          ],
        ),
      ],
    );

    return ModalVeil(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 660 : 440),
        child: OrnatePanel(
          accent: glow,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PanelHeader(
                  eyebrow: 'AREA $areaNo  •  ${state.areaName.toUpperCase()}',
                  title: 'PERMAINAN DIJEDA',
                  accent: glow,
                  titleSize: wide ? 22 : 25,
                ),
                const SizedBox(height: 11),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: stats),
                      const SizedBox(width: 16),
                      Expanded(child: buttons),
                    ],
                  )
                else ...[
                  stats,
                  const SizedBox(height: 13),
                  buttons,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Plaque(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
    child: Column(
      children: [
        Text(
          label,
          style: Ts.head(8.5, color: Palette.mist, spacing: 1.2),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 22, child: Center(child: child)),
      ],
    ),
  );
}
