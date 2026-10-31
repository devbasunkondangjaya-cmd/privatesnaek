import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'audio_manager.dart';
import 'fx_kit.dart';
import 'image_store.dart';
import 'level_data.dart';
import 'ui_kit.dart';
import 'venomcoil_game.dart';

/// Speaker button that cycles high -> low -> mute (shared by menu and HUD).
class VolumeButton extends StatelessWidget {
  const VolumeButton({super.key, required this.onTap, this.size = 40});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: GameAudio.instance.level,
    builder: (context, level, _) => RoundIconButton(
      size: size,
      label: 'Volume',
      onTap: onTap,
      child: Icon(
        const [
          Icons.volume_off_rounded,
          Icons.volume_down_rounded,
          Icons.volume_up_rounded,
        ][level],
        size: size * 0.52,
        color: level == 0 ? const Color(0xff9aa79a) : Palette.gold,
      ),
    ),
  );
}

/// The title screen: moving area backdrop, embers, the chosen skin as the hero
/// on a summoning circle, and the main actions.
class MainMenu extends StatelessWidget {
  const MainMenu({super.key, required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: const Color(0xaa020605),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (context, _, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OrnatePanel(
              accent: Palette.danger,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PanelHeader(
                      eyebrow: 'TINDAKAN PERMANEN',
                      title: 'RESET PROGRES?',
                      subtitle:
                          'Area yang sudah selesai, checkpoint, dan rekor waktu '
                          'akan dihapus dan kamu mulai lagi dari Area 1. '
                          'Pengaturan suara dan skin tetap.',
                      accent: Palette.danger,
                      titleSize: 22,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GameButton(
                            label: 'BATAL',
                            height: 44,
                            onTap: () => Navigator.pop(context, false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GameButton(
                            label: 'RESET',
                            style: GameButtonStyle.danger,
                            height: 44,
                            onTap: () => Navigator.pop(context, true),
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
      ),
    );
    if (ok != true || !context.mounted) return;
    await game.resetProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Center(
            child: Plaque(
              child: Text(
                'Progres direset. Selamat bertualang lagi!',
                style: Ts.body(14, color: Palette.cream, weight: FontWeight.w700),
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final safe = safeInsets(context);
    final actions = _Actions(
      state: state,
      game: game,
      onReset: () => _confirmReset(context),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        MenuBackdrop(
          background: 'area_${state.area.toString().padLeft(2, '0')}_bg.webp',
        ),
        Padding(
          padding: safe,
          child: LayoutBuilder(
            builder: (context, box) {
              final landscape = box.maxWidth > box.maxHeight * 1.15;
              if (!landscape) {
                return Column(
                  children: [
                    _TopBar(state: state, game: game),
                    const SizedBox(height: 6),
                    const _Title(size: 34),
                    Expanded(child: _Showcase(game: game, state: state)),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: actions,
                    ),
                  ],
                );
              }
              final titleSize = (box.maxHeight * 0.13).clamp(30.0, 56.0);
              return Column(
                children: [
                  _TopBar(state: state, game: game),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: math.min(320, box.maxWidth * 0.38),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _Title(size: titleSize),
                                  const SizedBox(height: 12),
                                  actions,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _Showcase(game: game, state: state)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.game});

  final GameHudState state;
  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Plaque(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtlasIcon(Hud.flag, size: 18),
            const SizedBox(width: 7),
            Text(
              '${state.completed.length} / 20',
              style: Ts.value(14.5, color: Palette.goldBright),
            ),
            const SizedBox(width: 6),
            Text('AREA', style: Ts.head(9.5, color: Palette.mist, spacing: 1.4)),
          ],
        ),
      ),
      const Spacer(),
      VolumeButton(onTap: game.cycleVolume),
    ],
  );
}

class _Title extends StatelessWidget {
  const _Title({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'LEGENDA 20 AREA',
        style: Ts.head(
          11,
          color: Palette.leafBright,
          spacing: 4,
          weight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 5),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: _Wordmark(text: 'VENOCIOL', size: size),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: _Wordmark(text: 'SNAKE', size: size * 0.86),
      ),
      const SizedBox(height: 6),
      const OrnateDivider(width: 230),
    ],
  );
}

/// The logotype: dark outline under a molten-gold fill.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Text(
        text,
        style: Ts.display(size).copyWith(
          color: null,
          letterSpacing: 2,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * 0.14
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xff0a0703),
          shadows: const [
            Shadow(color: Color(0xbb27e07a), blurRadius: 26),
            Shadow(color: Color(0xdd000000), blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
      ),
      GradientText(
        text,
        colors: const [
          Color(0xfffffbe6),
          Palette.goldBright,
          Color(0xffd9a94f),
          Color(0xff8a6426),
        ],
        style: Ts.display(size).copyWith(letterSpacing: 2),
      ),
    ],
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.game,
    required this.onReset,
  });

  final GameHudState state;
  final VenomcoilGame game;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final resume = state.hasProgress;
    final savedArea = (state.savedArea + 1).toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameButton(
          label: resume ? 'LANJUTKAN' : 'MAIN',
          subtitle: resume
              ? 'Area $savedArea${state.savedCheckpoint > 0 ? '  •  Checkpoint ${state.savedCheckpoint}/12' : ''}'
              : null,
          style: GameButtonStyle.primary,
          sheen: true,
          icon: const Icon(
            Icons.play_arrow_rounded,
            size: 32,
            color: Palette.goldBright,
          ),
          onTap: game.playFromMenu,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'AREA',
                height: 42,
                icon: const AtlasIcon(Hud.flag, size: 20),
                onTap: game.openAreaSelect,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GameButton(
                label: 'SKIN',
                height: 42,
                icon: const AtlasIcon(Hud.coil, size: 20),
                onTap: game.openSkinSelect,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'PANDUAN',
                style: GameButtonStyle.ghost,
                height: 36,
                onTap: game.showTutorial,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GameButton(
                label: 'RESET',
                style: GameButtonStyle.ghost,
                height: 36,
                onTap: onReset,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Character-select stage: the hero with arrows to change skin, and below it a
/// plate to browse the area to start in.
class _Showcase extends StatefulWidget {
  const _Showcase({required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  State<_Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<_Showcase> {
  late int _theme = widget.state.savedArea.clamp(0, 19);

  @override
  void didUpdateWidget(_Showcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A reset moves the saved spot; the browsed area follows it.
    if (widget.state.savedArea != oldWidget.state.savedArea) {
      _theme = widget.state.savedArea.clamp(0, 19);
    }
  }

  static String _skinFile(int skin) =>
      'skin_${(skin + 1).toString().padLeft(2, '0')}_motion_a-transparent.webp';

  void _skin(int delta) {
    final count = VenomcoilGame.skinNames.length;
    final next = (widget.state.skinIndex + delta + count) % count;
    ImageStore.instance.loadSheet(_skinFile(next), cols: 5, rows: 4);
    widget.game.selectSkin(next);
  }

  void _area(int delta) {
    setState(() => _theme = (_theme + delta + 20) % 20);
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.state.skinIndex;
    final glow = VenomcoilGame.skinColors[skin.clamp(0, 9)];
    final level = campaignLevels[_theme];
    final no = (_theme + 1).toString().padLeft(2, '0');
    final done = widget.state.completed.contains(_theme);
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _Arrow(cell: Hud.left, onTap: () => _skin(-1)),
              Expanded(child: RepaintBoundary(child: _Hero(skin: skin))),
              _Arrow(cell: Hud.right, onTap: () => _skin(1)),
            ],
          ),
        ),
        Plaque(
          accent: glow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            VenomcoilGame.skinNames[skin].toUpperCase(),
            maxLines: 1,
            style: Ts.head(12.5, color: Palette.goldBright, spacing: 1.6),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Arrow(cell: Hud.left, onTap: () => _area(-1), small: true),
            const SizedBox(width: 6),
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  UiKit.onTap?.call();
                  widget.game.pickArea(_theme);
                },
                child: Plaque(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (done) ...[
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Palette.gold,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          '$no  •  ${(level['shortName'] as String).toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Ts.head(11.5, spacing: 0.8),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'MULAI  ›',
                        style: Ts.head(11, color: Palette.leafBright),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _Arrow(cell: Hud.right, onTap: () => _area(1), small: true),
          ],
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.cell, required this.onTap, this.small = false});

  final int cell;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) => RoundIconButton(
    size: small ? 32 : 42,
    label: cell == Hud.left ? 'Sebelumnya' : 'Berikutnya',
    onTap: onTap,
    child: Icon(
      cell == Hud.left
          ? Icons.chevron_left_rounded
          : Icons.chevron_right_rounded,
      size: small ? 22 : 30,
      color: Palette.gold,
    ),
  );
}

/// The selected skin breathing above a slowly turning summoning circle. Runs
/// from one painter tied to a ticker: no widget rebuilds while it animates.
class _Hero extends StatefulWidget {
  const _Hero({required this.skin});

  final int skin;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file =
        'skin_${(widget.skin + 1).toString().padLeft(2, '0')}_motion_a-transparent.webp';
    return ValueListenableBuilder<int>(
      valueListenable: ImageStore.instance.revision,
      builder: (context, _, _) => CustomPaint(
        painter: _HeroPainter(
          sheet: ImageStore.instance.sheet(file),
          clock: _clock,
          glow: VenomcoilGame.skinColors[widget.skin.clamp(0, 9)],
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.sheet, required this.clock, required this.glow})
    : super(repaint: clock);

  final SheetInfo? sheet;
  final Animation<double> clock;
  final Color glow;
  final Paint _sprite = Paint()..filterQuality = FilterQuality.medium;
  final Paint _add = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.low;
  late final Paint _ring = Paint()
    ..filterQuality = FilterQuality.medium
    ..blendMode = BlendMode.plus
    ..colorFilter = ui.ColorFilter.mode(
      glow.withValues(alpha: 0.65),
      BlendMode.modulate,
    );
  late final Paint _aura = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.low
    ..colorFilter = ui.ColorFilter.mode(
      glow.withValues(alpha: 0.5),
      BlendMode.modulate,
    );

  static final GlowBatch _motes = GlowBatch(24);

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value * 90;
    final side = math.min(size.width * 0.85, size.height * 1.05);
    final foot = Offset(size.width / 2, size.height * 0.5 + side * 0.34);

    // Summoning circle lying flat on the ground.
    final rune = FxTextures.rune;
    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    canvas.scale(1, 0.3);
    canvas.rotate(t * 0.14);
    final ringSide = side * 1.05;
    canvas.drawImageRect(
      rune,
      Rect.fromLTWH(0, 0, rune.width.toDouble(), rune.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: ringSide, height: ringSide),
      _ring,
    );
    canvas.restore();

    final glowImage = FxTextures.glow;
    final pulse = 0.85 + 0.15 * math.sin(t * 1.6);
    final auraSide = side * 0.95 * pulse;
    canvas.drawImageRect(
      glowImage,
      FxTextures.glowSrc,
      Rect.fromCenter(
        center: foot.translate(0, -side * 0.34),
        width: auraSide,
        height: auraSide,
      ),
      _aura,
    );

    final current = sheet;
    if (current != null) {
      final col = (t * 7).floor() % 5;
      final row = const [0, 0, 1, 0][(t / 2.4).floor() % 4];
      final src = current.content(col, row);
      final scale = side / current.cellWidth;
      final w = src.width * scale, h = src.height * scale;
      final bob = math.sin(t * 2.1) * 4;
      canvas.drawImageRect(
        current.image,
        src,
        Rect.fromLTWH(foot.dx - w / 2, foot.dy - h + bob - side * 0.02, w, h),
        _sprite,
      );
    }

    queueAmbientMotes(
      _motes,
      count: 16,
      left: foot.dx - side * 0.5,
      top: foot.dy - side * 0.8,
      width: side,
      height: side * 0.8,
      time: t,
      rgb: glow.toARGB32(),
      rise: 22,
      radius: 7,
      alpha: 0.8,
    );
    _motes.flush(canvas, _add);
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.sheet != sheet || old.clock != clock || old.glow != glow;
}

/// Full-screen backdrop for the title screen and the popups opened from it:
/// the area art panning slowly, dark grading and drifting embers.
class MenuBackdrop extends StatefulWidget {
  const MenuBackdrop({
    super.key,
    required this.background,
    this.animate = true,
  });

  final String background;
  final bool animate;

  @override
  State<MenuBackdrop> createState() => _MenuBackdropState();
}

class _MenuBackdropState extends State<MenuBackdrop>
    with SingleTickerProviderStateMixin {
  // Motion is timed from app start, so returning from a popup does not jump.
  static final Stopwatch _epoch = Stopwatch()..start();

  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _ticker.repeat();
  }

  @override
  void didUpdateWidget(MenuBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    widget.animate ? _ticker.repeat() : _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ValueListenableBuilder<int>(
      valueListenable: ImageStore.instance.revision,
      builder: (context, _, _) => CustomPaint(
        painter: _BackdropPainter(
          ImageStore.instance[widget.background],
          _ticker,
          _epoch,
        ),
        size: Size.infinite,
        isComplex: true,
      ),
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.image, this.ticker, this.epoch) : super(repaint: ticker);

  final ui.Image? image;
  final Animation<double> ticker;
  final Stopwatch epoch;

  final Paint _imagePaint = Paint()..filterQuality = FilterQuality.low;
  final Paint _grade = Paint();
  final Paint _vignette = Paint();
  final Paint _add = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.low;
  Size _shaded = Size.zero;

  static final GlowBatch _embers = GlowBatch(40);

  @override
  void paint(Canvas canvas, Size size) {
    final t = epoch.elapsedMilliseconds / 1000;
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.ink);
    final img = image;
    if (img != null) {
      final scale =
          math.max(size.height / img.height, size.width / img.width) * 1.15;
      final w = img.width * scale, h = img.height * scale;
      final pan = (t * 10) % (w * 2);
      final source = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      // Mirror-tile so the slow pan never shows a seam.
      for (var i = 0; i < 3; i++) {
        final x = i * w - pan;
        if (x > size.width || x + w < 0) continue;
        canvas.save();
        canvas.translate(x + (i.isOdd ? w : 0), 0);
        if (i.isOdd) canvas.scale(-1, 1);
        canvas.drawImageRect(
          img,
          source,
          Rect.fromLTWH(0, (size.height - h) / 2, w, h),
          _imagePaint,
        );
        canvas.restore();
      }
    }
    if (_shaded != size) {
      _shaded = size;
      _grade.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        const [Color(0xf2030907), Color(0x99030907), Color(0x33030907)],
        const [0, 0.42, 1],
      );
      _vignette.shader = ui.Gradient.radial(
        size.center(Offset.zero),
        size.longestSide * 0.7,
        const [Color(0x00000000), Color(0xcc000000)],
        const [0.5, 1],
      );
    }
    final rect = Offset.zero & size;
    canvas.drawRect(rect, _grade);
    canvas.drawRect(rect, _vignette);
    queueAmbientMotes(
      _embers,
      count: 30,
      left: 0,
      top: 0,
      width: size.width,
      height: size.height,
      time: t,
      rgb: 0xffc25a,
      rise: 15,
      radius: 8,
      alpha: 0.7,
    );
    _embers.flush(canvas, _add);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.image != image || old.ticker != ticker;
}
