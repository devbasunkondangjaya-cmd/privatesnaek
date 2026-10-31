import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'pause_panel.dart';
import 'pickers.dart';
import 'ui_kit.dart';
import 'venomcoil_game.dart';

/// Dimmed full-screen layer with a centred card for pause, game over, area
/// clear and the area / skin pickers.
class OverlayCard extends StatelessWidget {
  const OverlayCard({
    super.key,
    required this.game,
    required this.state,
    required this.overlay,
  });

  final VenomcoilGame game;
  final GameHudState state;
  final String overlay;

  @override
  Widget build(BuildContext context) => PopIn(
    child: switch (overlay) {
      'pause' => PausePanel(game: game, state: state),
      'areas' || 'skins' => _PickerCard(
        game: game,
        state: state,
        areas: overlay == 'areas',
      ),
      'death' => _DeathCard(game: game, state: state),
      _ => _CompleteCard(game: game, state: state),
    },
  );
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.game,
    required this.state,
    required this.areas,
  });

  final VenomcoilGame game;
  final GameHudState state;
  final bool areas;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return ModalVeil(
      extra: 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: OrnatePanel(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PanelHeader(
                eyebrow: areas
                    ? 'SELESAI ${state.completed.length} DARI 20'
                    : 'SEMUA BENTUK TERBUKA',
                title: areas ? 'JEJAK 20 AREA' : 'PILIH SKIN',
                titleSize: 21,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SizedBox(
                  height: (screen.height - 150).clamp(150.0, 320.0),
                  child: areas
                      ? AreaPicker(game: game, state: state)
                      : SkinPicker(game: game, state: state),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      label: 'KEMBALI',
                      height: 40,
                      onTap: game.backFromSubmenu,
                    ),
                  ),
                  if (!areas) ...[
                    const SizedBox(width: 9),
                    Expanded(
                      child: GameButton(
                        label: 'PILIH AREA',
                        height: 40,
                        onTap: game.openAreaSelect,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared shape of the end-of-run cards: a medallion, the title and actions.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.accent,
    required this.veil,
    required this.medal,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final Color accent;
  final Color veil;
  final Widget medal;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).height < 520;
    final heading = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 66,
          height: 66,
          child: CustomPaint(
            painter: const MedallionPainter(),
            child: Center(child: medal),
          ),
        ),
        const SizedBox(height: 7),
        PanelHeader(
          eyebrow: eyebrow,
          title: title,
          subtitle: subtitle,
          accent: accent,
          titleSize: 24,
        ),
      ],
    );
    final buttons = Column(mainAxisSize: MainAxisSize.min, children: actions);
    return ModalVeil(
      color: veil,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 660 : 440),
        child: OrnatePanel(
          accent: accent,
          child: SingleChildScrollView(
            child: wide
                ? Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 18),
                      Expanded(child: buttons),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      heading,
                      const SizedBox(height: 14),
                      buttons,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DeathCard extends StatelessWidget {
  const _DeathCard({required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  Widget build(BuildContext context) => _ResultCard(
    accent: Palette.danger,
    veil: const Color(0xc0170305),
    medal: const AtlasIcon(Hud.brokenHeart, size: 40),
    eyebrow: 'JEJAK TERPUTUS',
    title: 'COBA LAGI',
    subtitle: state.bossWipe
        ? 'Dikalahkan bos besar. Ulang dari checkpoint pertama tema ini.'
        : 'Ulang dari checkpoint terakhir. Rutemu masih segar.',
    actions: [
      GameButton(
        label: 'ULANGI',
        style: GameButtonStyle.primary,
        height: 52,
        icon: const AtlasIcon(Hud.restart, size: 26),
        onTap: game.retry,
      ),
      const SizedBox(height: 8),
      GameButton(label: 'PILIH AREA', height: 42, onTap: game.openAreaSelect),
      const SizedBox(height: 8),
      GameButton(
        label: 'MENU UTAMA',
        style: GameButtonStyle.ghost,
        height: 36,
        onTap: game.quitToMenu,
      ),
    ],
  );
}

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  Widget build(BuildContext context) {
    final best = state.bestTimes[state.area - 1];
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: RepaintBoundary(child: _VictoryRays())),
        _ResultCard(
          accent: Palette.gold,
          veil: const Color(0x99060a05),
          medal: const AtlasIcon(Hud.flag, size: 40),
          eyebrow: 'AREA SELESAI',
          title: state.areaName.toUpperCase(),
          subtitle: best == null
              ? 'Jejak berlanjut. Lanjut ke area berikutnya.'
              : 'Waktu terbaik ${formatTime(best)}',
          actions: [
            GameButton(
              label: state.area < 20 ? 'AREA BERIKUTNYA' : 'PILIH AREA',
              style: GameButtonStyle.primary,
              height: 52,
              sheen: true,
              onTap: game.nextArea,
            ),
            const SizedBox(height: 8),
            GameButton(
              label: 'ULANGI AREA',
              height: 42,
              onTap: () => game.selectArea(state.area - 1),
            ),
            const SizedBox(height: 8),
            GameButton(
              label: 'MENU UTAMA',
              style: GameButtonStyle.ghost,
              height: 36,
              onTap: game.quitToMenu,
            ),
          ],
        ),
      ],
    );
  }
}

/// Slowly turning golden rays behind the victory card.
class _VictoryRays extends StatefulWidget {
  const _VictoryRays();

  @override
  State<_VictoryRays> createState() => _VictoryRaysState();
}

class _VictoryRaysState extends State<_VictoryRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _RaysPainter(_c), size: Size.infinite);
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t) : super(repaint: t);

  final Animation<double> t;
  final Paint _paint = Paint();
  Size _shaped = Size.zero;
  final Path _rays = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.longestSide * 0.75;
    if (_shaped != size) {
      _shaped = size;
      _paint.shader = ui.Gradient.radial(Offset.zero, radius, const [
        Color(0x55ffd98a),
        Color(0x00ffd98a),
      ]);
      _rays.reset();
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        _rays
          ..moveTo(0, 0)
          ..lineTo(math.cos(a - 0.1) * radius, math.sin(a - 0.1) * radius)
          ..lineTo(math.cos(a + 0.1) * radius, math.sin(a + 0.1) * radius)
          ..close();
      }
    }
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(t.value * math.pi * 2);
    canvas.drawPath(_rays, _paint);
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}
