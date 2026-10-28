import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_manager.dart';
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
  final save = await SaveData.load();
  await GameAudio.instance.init(save.volumeLevel);
  runApp(VenomcoilApp(save: save));
}

class VenomcoilApp extends StatelessWidget {
  const VenomcoilApp({super.key, required this.save});

  final SaveData save;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venomcoil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff59d45c),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: GameScreen(save: save),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.save});

  final SaveData save;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final VenomcoilGame _game;

  @override
  void initState() {
    super.initState();
    _game = VenomcoilGame(widget.save);
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
        loadingBuilder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat permainan…'),
            ],
          ),
        ),
        errorBuilder: (_, error) => const Center(
          child: Text(
            'Permainan gagal dimuat. Tutup lalu buka kembali aplikasi.',
          ),
        ),
        initialActiveOverlays: const ['interface'],
        overlayBuilderMap: {
          'interface': (context, game) => Positioned.fill(
            child: ValueListenableBuilder<GameHudState>(
              valueListenable: _game.hud,
              builder: (context, state, _) {
                final overlay = state.overlay;
                if (overlay == 'menu') {
                  return MainMenu(game: _game, state: state);
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _TopHud(game: _game, state: state),
                    _ControlDock(game: _game, state: state),
                    if (overlay == null && state.lesson.isNotEmpty)
                      _LessonBanner(text: state.lesson),
                    if (overlay == 'tutorial')
                      TutorialOverlay(game: _game)
                    else if (overlay != null)
                      OverlayCard(game: _game, state: state, overlay: overlay),
                  ],
                );
              },
            ),
          ),
        },
      ),
    );
  }
}

class _LessonBanner extends StatelessWidget {
  const _LessonBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Positioned(
    top: MediaQuery.sizeOf(context).height * 0.22,
    left: 20,
    right: 20,
    child: IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xdd101e19),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x8859de62)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: Color(0xffffedc1),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TopHud extends StatelessWidget {
  const _TopHud({required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  Widget build(BuildContext context) {
    final safe = safeInsets(context);
    return Positioned(
      top: safe.top,
      left: safe.left,
      right: safe.right,
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 340;
          final button = compact ? 34.0 : 38.0;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeartShake(
                        hits: state.hurtCount,
                        child: Row(
                          children: List.generate(
                            3,
                            (index) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: AtlasIcon(
                                index < state.hearts
                                    ? Hud.heart
                                    : Hud.brokenHeart,
                                size: compact ? 24 : 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      _Meter(
                        fill: state.momentum,
                        color: const Color(0xff69e46d),
                        width: compact ? 86 : 104,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: button,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xdd10201d),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      formatTime(state.elapsed),
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 5 : 7),
                  RoundIconButton(
                    size: button,
                    label: 'Cara main',
                    onTap: game.showTutorial,
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: button * 0.55,
                        fontWeight: FontWeight.w900,
                        color: Palette.gold,
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 5 : 7),
                  VolumeButton(size: button, onTap: game.cycleVolume),
                  SizedBox(width: compact ? 5 : 7),
                  RoundIconButton(
                    size: button,
                    label: 'Jeda',
                    onTap: game.togglePause,
                    child: AtlasIcon(Hud.pause, size: button * 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  UiKit.onTap?.call();
                  game.openAreaSelect();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xdd10201d),
                    border: Border.all(color: const Color(0x9958e86c)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.area.toString().padLeft(2, '0')}  ${state.areaName.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                          color: Color(0xfffff3d0),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 135,
                        child: _Meter(
                          fill: state.progress,
                          color: const Color(0xffffd76a),
                          height: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: Palette.danger.withValues(alpha: 0.7 * strength),
                  blurRadius: 16,
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.fill,
    required this.color,
    this.width = double.infinity,
    this.height = 8,
  });

  final double fill;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xcc12241e),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0x9953634a), width: 1),
    ),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: fill.clamp(0, 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
          ],
        ),
      ),
    ),
  );
}

/// Joystick on the left, action cluster (jump / attack / venom) on the right.
class _ControlDock extends StatelessWidget {
  const _ControlDock({required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  Widget build(BuildContext context) {
    final safe = safeInsets(context, extra: 4);
    final shortSide = math.min(
      MediaQuery.sizeOf(context).width,
      MediaQuery.sizeOf(context).height,
    );
    final scale = (shortSide / 400).clamp(0.82, 1.2);
    final stick = 124.0 * scale;
    final big = 78.0 * scale;
    final mid = 64.0 * scale;
    final small = 58.0 * scale;
    return Positioned(
      left: safe.left,
      right: safe.right,
      bottom: safe.bottom,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MovementJoystick(
            size: stick,
            enabled: state.overlay == null,
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
                  child: _ActionButton(
                    cell: Hud.coil,
                    label: 'LOMPAT',
                    size: big,
                    color: Palette.leafBright,
                    charge: state.coilCharge,
                    hold: true,
                    onDown: () => game.setJumpHeld(true),
                    onUp: () => game.setJumpHeld(false),
                  ),
                ),
                Positioned(
                  right: big + 10 * scale,
                  bottom: 4 * scale,
                  child: _ActionButton(
                    cell: Hud.tail,
                    label: 'SERANG',
                    size: mid,
                    color: Palette.gold,
                    onDown: game.useAttack,
                  ),
                ),
                Positioned(
                  right: big * 0.5 - small * 0.15,
                  bottom: big + 6 * scale,
                  child: _ActionButton(
                    cell: state.canVenom ? Hud.venom : Hud.lock,
                    label: 'RACUN',
                    size: small,
                    color: const Color(0xff83ff4f),
                    enabled: state.canVenom,
                    onDown: game.useVenom,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.cell,
    required this.label,
    required this.size,
    required this.color,
    required this.onDown,
    this.onUp,
    this.hold = false,
    this.charge = 0,
    this.enabled = true,
  });

  final int cell;
  final String label;
  final double size;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final bool hold;
  final double charge;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (enabled) onDown();
      },
      onPointerUp: (_) {
        if (hold) onUp?.call();
      },
      onPointerCancel: (_) {
        if (hold) onUp?.call();
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xdd101d19),
            border: Border.all(
              color: charge > 0
                  ? Palette.leafBright
                  : color.withValues(alpha: 0.7),
              width: charge > 0 ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: charge > 0 ? 0.45 : 0.14),
                blurRadius: charge > 0 ? 20 : 10,
              ),
              const BoxShadow(
                color: Colors.black38,
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (charge > 0)
                SizedBox(
                  width: size - 8,
                  height: size - 8,
                  child: CircularProgressIndicator(
                    value: charge,
                    strokeWidth: 4,
                    color: Palette.leafBright,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AtlasIcon(cell, size: size * 0.5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: math.max(8, size * 0.135),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
