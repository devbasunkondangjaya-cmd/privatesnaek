import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_manager.dart';
import 'image_store.dart';
import 'menu_screen.dart';
import 'movement_joystick.dart';
import 'overlay_cards.dart';
import 'save_data.dart';
import 'tutorial_overlay.dart';
import 'ui_kit.dart';
import 'venomcoil_game.dart';

import 'package:flame/game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Previews in the pickers go through Flutter's image cache, 100 MB by
  // default. Everything else is owned by ImageStore, so keep this one small.
  PaintingBinding.instance.imageCache
    ..maximumSize = 40
    ..maximumSizeBytes = 16 << 20;
  final display = ui.PlatformDispatcher.instance.displays.first.size;
  ImageStore.instance.fitToScreen(display.shortestSide, display.longestSide);
  final save = await SaveData.load();
  await GameAudio.instance.init(save.volumeLevel);
  runApp(VenomcoilApp(save: save));
}

class VenomcoilApp extends StatelessWidget {
  const VenomcoilApp({super.key, required this.save, this.game});

  final SaveData save;
  final VenomcoilGame? game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venociol Snake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.leaf,
          brightness: Brightness.dark,
        ),
        fontFamily: 'AlegreyaSans',
      ),
      home: GameScreen(save: save, game: game),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.save, this.game});

  final SaveData save;

  /// Lets a tool drive the game; normally the screen creates its own.
  final VenomcoilGame? game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final VenomcoilGame _game;

  @override
  void initState() {
    super.initState();
    _game = widget.game ?? VenomcoilGame(widget.save);
    UiKit.onTap = _game.uiTap;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UiKit.onTap = null;
    super.dispose();
  }

  /// Leaving the app saves immediately and pauses a running game.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _game.saveNow();
    if (_game.hud.value.overlay == null) _game.togglePause();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<VenomcoilGame>(
        game: _game,
        loadingBuilder: (_) => const _BootScreen(),
        errorBuilder: (_, error) => Center(
          child: Text(
            'Permainan gagal dimuat. Tutup lalu buka kembali aplikasi.',
            style: Ts.body(14, color: Palette.cream),
          ),
        ),
        initialActiveOverlays: const ['interface'],
        overlayBuilderMap: {
          // Own layer: the game canvas repaints every frame, and without this
          // boundary it would drag the whole interface along with it.
          'interface': (context, game) => Positioned.fill(
            child: RepaintBoundary(child: _Interface(game: _game)),
          ),
        },
      ),
    );
  }
}

/// Rebuilds [builder] only when the value picked out of the HUD state changes.
/// Gameplay publishes that state several times a second; this keeps each
/// widget's rebuilds down to the moments its own content is different.
class HudSelect<T> extends StatefulWidget {
  const HudSelect({
    super.key,
    required this.game,
    required this.select,
    required this.builder,
  });

  final VenomcoilGame game;
  final T Function(GameHudState state) select;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<HudSelect<T>> createState() => _HudSelectState<T>();
}

class _HudSelectState<T> extends State<HudSelect<T>> {
  late T _value = widget.select(widget.game.hud.value);

  @override
  void initState() {
    super.initState();
    widget.game.hud.addListener(_changed);
  }

  @override
  void dispose() {
    widget.game.hud.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final next = widget.select(widget.game.hud.value);
    if (next != _value) setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

class _Interface extends StatelessWidget {
  const _Interface({required this.game});

  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) =>
      HudSelect<({String? overlay, bool overMenu, bool loading, int area})>(
        game: game,
        select: (s) => (
          overlay: s.overlay,
          overMenu: s.overMenu,
          loading: s.loading,
          area: s.area,
        ),
        builder: (context, shell) {
          final overlay = shell.overlay;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (overlay == 'menu')
                ValueListenableBuilder<GameHudState>(
                  valueListenable: game.hud,
                  builder: (context, state, _) =>
                      MainMenu(game: game, state: state),
                )
              else if (overlay == null)
                _PlayHud(game: game)
              else ...[
                if (shell.overMenu)
                  MenuBackdrop(
                    background:
                        'area_${shell.area.toString().padLeft(2, '0')}_bg.webp',
                    animate: false,
                  ),
                if (overlay == 'tutorial')
                  TutorialOverlay(game: game)
                else
                  ValueListenableBuilder<GameHudState>(
                    valueListenable: game.hud,
                    builder: (context, state, _) => OverlayCard(
                      key: ValueKey(overlay),
                      game: game,
                      state: state,
                      overlay: overlay,
                    ),
                  ),
              ],
              if (shell.loading) _LoadingVeil(game: game),
            ],
          );
        },
      );
}

class _PlayHud extends StatelessWidget {
  const _PlayHud({required this.game});

  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      _TopHud(game: game),
      _ControlDock(game: game),
      HudSelect<String>(
        game: game,
        select: (s) => s.lesson,
        builder: (context, text) =>
            text.isEmpty ? const SizedBox.shrink() : _LessonBanner(text: text),
      ),
      HudSelect<int>(
        game: game,
        select: (s) => s.intro,
        builder: (context, intro) =>
            intro == 0 ? const SizedBox.shrink() : _AreaTitleCard(key: ValueKey(intro), game: game),
      ),
    ],
  );
}

/// First thing on screen while the game's core art decodes.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Palette.ink,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientText(
            'VENOCIOL SNAKE',
            colors: const [Palette.goldBright, Palette.gold, Color(0xffa97f3a)],
            style: Ts.display(30),
          ),
          const SizedBox(height: 12),
          const OrnateDivider(),
          const SizedBox(height: 14),
          const _Pulsing(child: _LoadingText('Memuat permainan…')),
        ],
      ),
    ),
  );
}

class _LoadingText extends StatelessWidget {
  const _LoadingText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Ts.body(14, color: Palette.gold, weight: FontWeight.w700));
}

class _Pulsing extends StatefulWidget {
  const _Pulsing({required this.child});

  final Widget child;

  @override
  State<_Pulsing> createState() => _PulsingState();
}

class _PulsingState extends State<_Pulsing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _c, child: widget.child);
}

/// Covers the swap between areas, while the old art unloads and the new decodes.
class _LoadingVeil extends StatelessWidget {
  const _LoadingVeil({required this.game});

  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) {
    final state = game.hud.value;
    return ColoredBox(
      color: Palette.ink,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AREA ${state.area.toString().padLeft(2, '0')}',
              style: Ts.head(12, color: Palette.leafBright, spacing: 4),
            ),
            const SizedBox(height: 6),
            GradientText(
              state.areaName.toUpperCase(),
              colors: const [Palette.goldBright, Palette.gold],
              style: Ts.head(26, spacing: 2),
            ),
            const SizedBox(height: 10),
            const OrnateDivider(),
            const SizedBox(height: 10),
            const _Pulsing(child: _LoadingText('Menyiapkan area…')),
          ],
        ),
      ),
    );
  }
}

/// Cinematic area name that eases in as a run begins, then gets out of the way.
class _AreaTitleCard extends StatelessWidget {
  const _AreaTitleCard({super.key, required this.game});

  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) {
    final state = game.hud.value;
    final child = IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AREA ${state.area.toString().padLeft(2, '0')}',
            style: Ts.head(
              13,
              color: Palette.leafBright,
              spacing: 5,
              shadows: const [Shadow(blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 4),
          GradientText(
            state.areaName.toUpperCase(),
            colors: const [Palette.goldBright, Palette.gold, Color(0xffa97f3a)],
            style: Ts.head(
              34,
              spacing: 2.4,
              shadows: const [
                Shadow(color: Color(0xdd000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const OrnateDivider(width: 300),
        ],
      ),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2600),
      builder: (context, t, child) {
        if (t >= 1) return const SizedBox.shrink();
        final fade = t < 0.18 ? t / 0.18 : (t > 0.72 ? (1 - t) / 0.28 : 1.0);
        return Align(
          alignment: const Alignment(0, -0.32),
          child: FadeTransition(
            opacity: AlwaysStoppedAnimation(fade),
            child: Transform.scale(scale: 0.96 + 0.06 * t, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _LessonBanner extends StatelessWidget {
  const _LessonBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Positioned(
    top: math.max(MediaQuery.sizeOf(context).height * 0.24, 100),
    left: 20,
    right: 20,
    child: IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(text),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (context, t, child) => FadeTransition(
            opacity: AlwaysStoppedAnimation(t),
            child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
          ),
          child: Plaque(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Ts.head(12, color: Palette.goldBright, spacing: 1.2),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TopHud extends StatelessWidget {
  const _TopHud({required this.game});

  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) {
    final safe = safeInsets(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    final button = compact ? 34.0 : 38.0;
    final gap = compact ? 5.0 : 7.0;
    return Positioned(
      top: safe.top,
      left: safe.left,
      right: safe.right,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(child: _UnitFrame(game: game, compact: compact)),
              const Spacer(),
              RepaintBoundary(
                child: HudSelect<int>(
                  game: game,
                  select: (s) => (s.elapsed * 10).floor(),
                  builder: (context, tenths) => Plaque(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      formatTime(tenths / 10),
                      style: Ts.value(compact ? 13 : 14.5),
                    ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              RoundIconButton(
                size: button,
                label: 'Cara main',
                onTap: game.showTutorial,
                child: Text(
                  '?',
                  style: Ts.head(button * 0.48, color: Palette.gold, spacing: 0),
                ),
              ),
              SizedBox(width: gap),
              VolumeButton(size: button, onTap: game.cycleVolume),
              SizedBox(width: gap),
              RoundIconButton(
                size: button,
                label: 'Jeda',
                onTap: game.togglePause,
                child: AtlasIcon(Hud.pause, size: button * 0.56),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(child: _AreaPlate(game: game)),
              RepaintBoundary(
                child: HudSelect<({int hp, int max, String name})>(
                  game: game,
                  select: (s) => (
                    hp: s.bossHp,
                    max: s.bossMaxHp,
                    name: s.bossName,
                  ),
                  builder: (context, boss) => boss.max == 0
                      ? const SizedBox.shrink()
                      : _BossBar(hp: boss.hp, max: boss.max, name: boss.name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Portrait medallion, hearts and the momentum bar, MMORPG unit-frame style.
class _UnitFrame extends StatelessWidget {
  const _UnitFrame({required this.game, required this.compact});

  final VenomcoilGame game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final portrait = compact ? 46.0 : 54.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HudSelect<int>(
          game: game,
          select: (s) => s.skinIndex,
          builder: (context, skin) {
            final glow = VenomcoilGame.skinColors[skin.clamp(0, 9)];
            return SizedBox(
              width: portrait,
              height: portrait,
              child: CustomPaint(
                painter: MedallionPainter(accent: glow.withValues(alpha: 0.55)),
                foregroundPainter: _PortraitPainter(skin),
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            HudSelect<({int hearts, int hits})>(
              game: game,
              select: (s) => (hearts: s.hearts, hits: s.hurtCount),
              builder: (context, v) => _HeartShake(
                hits: v.hits,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: AtlasIcon(
                        index < v.hearts ? Hud.heart : Hud.brokenHeart,
                        size: compact ? 22 : 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: compact ? 82 : 100,
              height: 8,
              child: CustomPaint(
                painter: RuneBarPainter(
                  fill: game.momentumMeter,
                  color: Palette.leaf,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.skin);

  final int skin;

  @override
  void paint(Canvas canvas, Size size) {
    final file =
        'skin_${(skin + 1).toString().padLeft(2, '0')}_motion_a-transparent.webp';
    final sheet = ImageStore.instance.sheet(file);
    if (sheet == null) return;
    final src = sheet.content(0, 0);
    final inner = size.width * 0.84;
    final scale = inner / math.max(src.width, src.height);
    final w = src.width * scale, h = src.height * scale;
    canvas.drawImageRect(
      sheet.image,
      src,
      Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PortraitPainter old) => old.skin != skin;
}

/// Current area's name and how far along it the player is; tap to change area.
class _AreaPlate extends StatelessWidget {
  const _AreaPlate({required this.game});

  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      UiKit.onTap?.call();
      game.openAreaSelect();
    },
    child: Plaque(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudSelect<(int, String)>(
            game: game,
            select: (s) => (s.area, s.areaName),
            builder: (context, v) => Text(
              '${v.$1.toString().padLeft(2, '0')}  •  ${v.$2.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Ts.head(10.5, color: Palette.goldBright, spacing: 1.1),
            ),
          ),
          const SizedBox(height: 5),
          HudSelect<int>(
            game: game,
            select: (s) => (s.progress * 150).round(),
            builder: (context, v) => RuneBar(
              width: 150,
              height: 6,
              fill: v / 150,
              color: Palette.gold,
              notches: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BossBar extends StatelessWidget {
  const _BossBar({required this.hp, required this.max, required this.name});

  final int hp;
  final int max;
  final String name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Plaque(
      accent: Palette.danger,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.toUpperCase(),
            style: Ts.head(10, color: const Color(0xffffb8ae), spacing: 1.6),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(end: hp / max),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            builder: (context, fill, _) => RuneBar(
              width: 210,
              height: 9,
              fill: fill,
              color: Palette.danger,
              notches: max,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shakes and flashes red its child each time [hits] goes up.
class _HeartShake extends StatelessWidget {
  const _HeartShake({required this.hits, required this.child});

  final int hits;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(hits),
    tween: Tween(begin: hits == 0 ? 1 : 0, end: 1),
    duration: const Duration(milliseconds: 520),
    builder: (context, t, child) {
      final strength = 1 - t;
      return Transform.translate(
        offset: Offset(math.sin(t * math.pi * 8) * 7 * strength, 0),
        child: Transform.scale(
          scale: 1 + 0.25 * strength,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      );
    },
    child: child,
  );
}

/// Joystick on the left, skill orbs (jump / attack / venom) on the right.
class _ControlDock extends StatelessWidget {
  const _ControlDock({required this.game});

  final VenomcoilGame game;

  @override
  Widget build(BuildContext context) {
    final safe = safeInsets(context, extra: 4);
    final scale = (MediaQuery.sizeOf(context).shortestSide / 400).clamp(
      0.82,
      1.2,
    );
    final stick = 124.0 * scale;
    final big = 80.0 * scale;
    final mid = 66.0 * scale;
    final small = 60.0 * scale;
    return Positioned(
      left: safe.left,
      right: safe.right,
      bottom: safe.bottom,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MovementJoystick(
            size: stick,
            onChanged: game.setMoveAxis,
          ),
          const Spacer(),
          SizedBox(
            width: big + mid + 16 * scale,
            height: big + small + 14 * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: SkillOrb(
                    cell: Hud.coil,
                    label: 'LOMPAT',
                    size: big,
                    color: Palette.leafBright,
                    charge: game.coilMeter,
                    hold: true,
                    onDown: () => game.setJumpHeld(true),
                    onUp: () => game.setJumpHeld(false),
                  ),
                ),
                Positioned(
                  right: big + 10 * scale,
                  bottom: 4 * scale,
                  child: SkillOrb(
                    cell: Hud.tail,
                    label: 'SERANG',
                    size: mid,
                    color: Palette.gold,
                    cooldown: game.attackCooldownMeter,
                    onDown: game.useAttack,
                  ),
                ),
                Positioned(
                  right: big * 0.5 - small * 0.15,
                  bottom: big + 6 * scale,
                  child: HudSelect<bool>(
                    game: game,
                    select: (s) => s.canVenom,
                    builder: (context, canVenom) => SkillOrb(
                      cell: canVenom ? Hud.venom : Hud.lock,
                      label: 'RACUN',
                      size: small,
                      color: const Color(0xff83ff4f),
                      enabled: canVenom,
                      cooldown: game.venomCooldownMeter,
                      onDown: game.useVenom,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A round skill button: a static gold bezel, plus one small painter for the
/// charge ring or cooldown sweep. Only that painter runs while a value changes.
class SkillOrb extends StatefulWidget {
  const SkillOrb({
    super.key,
    required this.cell,
    required this.label,
    required this.size,
    required this.color,
    required this.onDown,
    this.onUp,
    this.hold = false,
    this.charge,
    this.cooldown,
    this.enabled = true,
  });

  final int cell;
  final String label;
  final double size;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final bool hold;
  final ValueListenable<double>? charge;
  final ValueListenable<double>? cooldown;
  final bool enabled;

  @override
  State<SkillOrb> createState() => _SkillOrbState();
}

class _SkillOrbState extends State<SkillOrb> {
  bool _down = false;

  void _release() {
    if (_down) setState(() => _down = false);
    if (widget.hold) widget.onUp?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          if (!widget.enabled) return;
          setState(() => _down = true);
          widget.onDown();
        },
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedScale(
          scale: _down ? 0.91 : 1,
          duration: const Duration(milliseconds: 70),
          child: RepaintBoundary(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _OrbPainter(
                        color: widget.color,
                        enabled: widget.enabled,
                        lit: _down,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: size * 0.1),
                    child: AtlasIcon(
                      widget.cell,
                      size: size * 0.54,
                      opacity: widget.enabled ? 1 : 0.55,
                    ),
                  ),
                  if (widget.cooldown != null || widget.charge != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OrbMeterPainter(
                          color: widget.color,
                          cooldown: widget.cooldown,
                          charge: widget.charge,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: -3,
                    child: Plaque(
                      accent: widget.color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        widget.label,
                        style: Ts.head(
                          math.max(8, size * 0.115),
                          color: widget.enabled
                              ? Palette.goldBright
                              : Palette.mist,
                          spacing: 0.6,
                        ),
                      ),
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

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.color,
    required this.enabled,
    required this.lit,
  });

  final Color color;
  final bool enabled;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r * 1.22,
      Paint()
        ..shader = ui.Gradient.radial(c, r * 1.22, [
          color.withValues(alpha: lit ? 0.55 : 0.2),
          color.withValues(alpha: lit ? 0.3 : 0.1),
          color.withValues(alpha: 0),
        ], const [0, 0.75, 1]),
    );
    canvas.drawCircle(c, r, Paint()..shader = goldTrim(rect));
    canvas.drawCircle(c, r - 2.2, Paint()..color = const Color(0xff120c04));
    canvas.drawCircle(
      c,
      r - 3.4,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(0, -r * 0.5),
          r * 1.45,
          [
            Color.lerp(const Color(0xff24382e), color, lit ? 0.5 : 0.22)!,
            const Color(0xcc0a1210),
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.color != color || old.enabled != enabled || old.lit != lit;
}

class _OrbMeterPainter extends CustomPainter {
  _OrbMeterPainter({required this.color, this.cooldown, this.charge})
    : super(repaint: Listenable.merge([?cooldown, ?charge]));

  final Color color;
  final ValueListenable<double>? cooldown;
  final ValueListenable<double>? charge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3.4);
    final wait = cooldown?.value ?? 0;
    if (wait > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * wait,
        true,
        Paint()..color = const Color(0xaa020605),
      );
    }
    final power = charge?.value ?? 0;
    if (power > 0) {
      canvas.drawArc(
        rect.deflate(1),
        -math.pi / 2,
        math.pi * 2 * power,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbMeterPainter old) =>
      old.cooldown != cooldown || old.charge != charge || old.color != color;
}
