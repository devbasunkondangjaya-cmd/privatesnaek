import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'audio_manager.dart';
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
        size: size * 0.57,
        color: level == 0 ? const Color(0xff9aa79a) : Palette.cream,
      ),
    ),
  );
}

/// The title screen: moving area backdrop, fireflies, the chosen skin as the
/// hero and the main actions (play / continue, areas, skins, reset).
class MainMenu extends StatefulWidget {
  const MainMenu({super.key, required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x99ff5b55), width: 1.4),
        ),
        title: const Text(
          'Reset progres?',
          style: TextStyle(fontWeight: FontWeight.w900, color: Palette.cream),
        ),
        content: const Text(
          'Area yang sudah selesai, checkpoint, dan rekor waktu akan dihapus '
          'dan kamu mulai lagi dari Area 1. Pengaturan suara dan skin tetap.',
          style: TextStyle(color: Palette.mist, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Palette.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.game.resetProgress();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Palette.panel,
          content: const Text('Progres direset. Selamat bertualang lagi!'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final game = widget.game;
    final safe = safeInsets(context);
    final stage = _stageBackground(state.area);
    return Stack(
      fit: StackFit.expand,
      children: [
        _MenuBackdrop(clock: _clock, background: stage),
        Padding(
          padding: safe,
          child: LayoutBuilder(
            builder: (context, box) {
              final landscape = box.maxWidth > box.maxHeight * 1.15;
              final hero = _Showcase(clock: _clock, game: game, state: state);
              final title = const _Title();
              final actions = _Actions(
                state: state,
                game: game,
                onReset: _confirmReset,
              );
              final topBar = Row(
                children: [
                  _ProgressBadge(done: state.completed.length),
                  const Spacer(),
                  VolumeButton(onTap: game.cycleVolume),
                ],
              );
              if (landscape) {
                return Column(
                  children: [
                    topBar,
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                title,
                                Expanded(child: hero),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 360,
                                  ),
                                  child: actions,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  topBar,
                  const SizedBox(height: 4),
                  title,
                  Expanded(child: hero),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: actions,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _stageBackground(int area) =>
      'area_${area.toString().padLeft(2, '0')}_bg.webp';
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          AtlasIcon(Hud.coil, size: 34),
          SizedBox(width: 8),
          Text(
            'LEGENDA 20 AREA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Palette.leafBright,
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'VENOCIOL SNAKE',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              height: 1,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 7
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xff0b2a14),
            ),
          ),
          const GradientText(
            'VENOCIOL SNAKE',
            colors: [Color(0xfffff3a8), Color(0xff9bf07a), Color(0xff2fa04a)],
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              height: 1,
              shadows: [Shadow(color: Color(0xff3bd65a), blurRadius: 24)],
            ),
          ),
        ],
      ),
    ],
  );
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xcc10201d),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0x8858e86c)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AtlasIcon(Hud.flag, size: 18),
        const SizedBox(width: 6),
        Text(
          '$done / 20',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Palette.cream,
          ),
        ),
      ],
    ),
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
        _PulseGlow(
          child: GameButton(
            label: resume ? 'LANJUTKAN' : 'MAIN',
            subtitle: resume
                ? 'Area $savedArea${state.savedCheckpoint > 0 ? '  •  Checkpoint ${state.savedCheckpoint}/12' : ''}'
                : null,
            style: GameButtonStyle.primary,
            icon: const Icon(
              Icons.play_arrow_rounded,
              size: 34,
              color: Color(0xff102114),
            ),
            onTap: game.playFromMenu,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 46,
              child: GameButton(label: '?', onTap: game.showTutorial),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GameButton(
          label: 'RESET PROGRES',
          style: GameButtonStyle.danger,
          height: 40,
          icon: const AtlasIcon(Hud.restart, size: 18),
          onTap: onReset,
        ),
      ],
    );
  }
}

class _PulseGlow extends StatefulWidget {
  const _PulseGlow({required this.child});

  final Widget child;

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.scale(
      scale: 1 + 0.025 * Curves.easeInOut.transform(_c.value),
      child: child,
    ),
    child: widget.child,
  );
}

/// Two preview cards side by side: the skin in use (browse with the arrows,
/// applied immediately) and the area theme to play (tap MAIN to start there).
class _Showcase extends StatefulWidget {
  const _Showcase({
    required this.clock,
    required this.game,
    required this.state,
  });

  final AnimationController clock;
  final VenomcoilGame game;
  final GameHudState state;

  @override
  State<_Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<_Showcase> {
  late int _theme = widget.state.savedArea.clamp(0, 19);

  static String _skinFile(int skin) =>
      'skin_${(skin + 1).toString().padLeft(2, '0')}_motion_a-transparent.webp';

  void _skin(int delta) {
    UiKit.onTap?.call();
    final count = VenomcoilGame.skinNames.length;
    final next = (widget.state.skinIndex + delta + count) % count;
    ImageStore.instance.loadSheet(_skinFile(next), cols: 5, rows: 4);
    widget.game.selectSkin(next);
  }

  void _area(int delta) {
    UiKit.onTap?.call();
    setState(() => _theme = (_theme + delta + 20) % 20);
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.state.skinIndex;
    final glow = VenomcoilGame.skinColors[skin.clamp(0, 9)];
    final level = campaignLevels[_theme];
    final no = (_theme + 1).toString().padLeft(2, '0');
    final bg = (level['bg'] as String?) ?? 'area_${no}_bg.webp';
    final palette = (level['palette'] as List<dynamic>)
        .cast<String>()
        .map((v) => Color(int.parse('ff${v.substring(1)}', radix: 16)))
        .toList();
    final done = widget.state.completed.contains(_theme);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _PreviewCard(
              tag: 'SKIN',
              title: VenomcoilGame.skinNames[skin],
              accent: glow,
              onPrev: () => _skin(-1),
              onNext: () => _skin(1),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.2),
                    colors: [
                      glow.withValues(alpha: 0.45),
                      const Color(0xff0a1712),
                    ],
                  ),
                ),
              ),
              child: _Hero(clock: widget.clock, skin: skin),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PreviewCard(
              tag: 'TEMA $no',
              title: level['shortName'] as String,
              accent: palette.length > 1 ? palette[1] : Palette.leafBright,
              onPrev: () => _area(-1),
              onNext: () => _area(1),
              onTap: () => widget.game.pickArea(_theme),
              action: 'MULAI',
              badge: done ? Icons.check_circle : null,
              background: AnimatedBuilder(
                animation: widget.clock,
                builder: (context, child) {
                  // Slow Ken Burns pan so the theme feels alive.
                  final t = widget.clock.value * 90;
                  return Transform.scale(
                    scale: 1.18,
                    child: Transform.translate(
                      offset: Offset(math.sin(t * 0.25) * 14, 0),
                      child: child,
                    ),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Image.asset(
                    'assets/images/$bg',
                    key: ValueKey(bg),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    cacheWidth: 520,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => ColoredBox(color: palette.first),
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final c in palette)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Framed preview tile with a tag, arrows to browse, a name plate and an
/// optional action chip. Tapping the tile opens the full picker / starts.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.tag,
    required this.title,
    required this.accent,
    required this.onPrev,
    required this.onNext,
    this.onTap,
    required this.background,
    required this.child,
    this.action = 'LIHAT',
    this.badge,
  });

  final String tag;
  final String title;
  final Color accent;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onTap;
  final Widget background;
  final Widget child;
  final String action;
  final IconData? badge;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      UiKit.onTap?.call();
      onTap?.call();
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.6),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 22),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            background,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xdd04110d)],
                  stops: [0.5, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 40),
              child: child,
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xcc0a1712),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: accent.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 4),
                      Icon(badge, size: 11, color: Palette.gold),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 2,
              top: 0,
              bottom: 30,
              child: _Arrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
            ),
            Positioned(
              right: 2,
              top: 0,
              bottom: 30,
              child: _Arrow(icon: Icons.chevron_right_rounded, onTap: onNext),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Palette.cream,
                        shadows: [Shadow(blurRadius: 6)],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Color(0xff102114),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    // Generous touch target for thumbs.
    child: SizedBox(
      width: 34,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xaa0a1712),
          ),
          child: Icon(icon, size: 22, color: Palette.cream),
        ),
      ),
    ),
  );
}

/// The selected skin, idle-breathing with a soft glow in its own colour.
class _Hero extends StatelessWidget {
  const _Hero({required this.clock, required this.skin});

  final AnimationController clock;
  final int skin;

  @override
  Widget build(BuildContext context) {
    final file =
        'skin_${(skin + 1).toString().padLeft(2, '0')}_motion_a-transparent.webp';
    final glow = VenomcoilGame.skinColors[skin.clamp(0, 9)];
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.maxWidth * 0.9, box.maxHeight * 0.95);
        return Center(
          child: AnimatedBuilder(
            animation: clock,
            builder: (context, _) {
              final t = clock.value * 90;
              final bob = math.sin(t * 2.1) * 6;
              return Transform.translate(
                offset: Offset(0, bob),
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: side * 0.8,
                        height: side * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              glow.withValues(alpha: 0.38),
                              glow.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: ImageStore.instance.revision,
                        builder: (context, _, _) {
                          final sheet = ImageStore.instance.sheet(file);
                          if (sheet == null) return const SizedBox.shrink();
                          return CustomPaint(
                            size: Size(side, side),
                            // Show off a few moves: idle, slither, coil.
                            painter: SpriteFrame(
                              sheet,
                              (t * 7).floor() % 5,
                              const [0, 1, 0, 3][(t / 2.4).floor() % 4],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MenuBackdrop extends StatelessWidget {
  const _MenuBackdrop({required this.clock, required this.background});

  final AnimationController clock;
  final String background;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: clock,
    builder: (context, _) => ValueListenableBuilder<int>(
      valueListenable: ImageStore.instance.revision,
      builder: (context, _, _) => CustomPaint(
        painter: _BackdropPainter(
          ImageStore.instance[background],
          clock.value * 90,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.image, this.t);

  final dynamic image;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.ink);
    final img = image;
    if (img != null) {
      final scale =
          math.max(size.height / img.height, size.width / img.width) * 1.15;
      final w = img.width * scale, h = img.height * scale;
      final pan = (t * 14) % (w * 2);
      // Mirror-tile so the slow pan never shows a seam.
      for (var i = -1; i < 3; i++) {
        final x = i * w - pan;
        if (x > size.width || x + w < 0) continue;
        canvas.save();
        canvas.translate(x + (i.isOdd ? w : 0), 0);
        if (i.isOdd) canvas.scale(-1, 1);
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width * 1.0, img.height * 1.0),
          Rect.fromLTWH(0, (size.height - h) / 2, w, h),
          Paint()..filterQuality = FilterQuality.low,
        );
        canvas.restore();
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xaa04110d),
            Color(0x2204110d),
            Color(0x66051410),
            Color(0xee04110d),
          ],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(Offset.zero & size),
    );
    // Fireflies drifting upward.
    for (var i = 0; i < 26; i++) {
      final seed = i * 97.31;
      final x =
          (math.sin(seed) * 0.5 + 0.5) * size.width +
          math.sin(t * 0.6 + seed) * 18;
      final y =
          size.height -
          ((t * (14 + i % 5 * 6) + seed * 23) % (size.height + 40));
      final pulse = 0.5 + 0.5 * math.sin(t * 2 + seed);
      canvas.drawCircle(
        Offset(x, y),
        1.6 + (i % 3),
        Paint()
          ..color = const Color(
            0xffcaff8a,
          ).withValues(alpha: 0.25 + 0.5 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => true;
}
