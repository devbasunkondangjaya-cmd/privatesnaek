import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'audio_manager.dart';
import 'fx_kit.dart';
import 'image_store.dart';
import 'level_data.dart';
import 'save_data.dart';

const _expansionPuzzleData = <List<List<Object>>>[
  [
    [3720, 500, 'momentumSwitch'],
    [4580, 470, 'puzzleGate', 'a1VineGate'],
    [4980, 500, 'mushroom'],
    [5790, 430, 'wall'],
    [7160, 500, 'momentumSwitch'],
    [8080, 470, 'puzzleGate', 'a1BloomGate'],
    [8400, 520, 'wind'],
  ],
  [
    [3700, 500, 'venomSwitch'],
    [4550, 480, 'puzzleGate', 'a2WebBridge'],
    [5350, 230, 'venomSwitch'],
    [6120, 500, 'puzzleGate', 'a2Queen'],
    [7420, 500, 'venomSwitch'],
    [8350, 500, 'puzzleGate', 'a2Final'],
  ],
  [
    [3860, 500, 'switch'],
    [4300, 500, 'switch'],
    [4740, 500, 'switch'],
    [5480, 500, 'puzzleGate', 'a3ChordGate'],
    [7100, 480, 'block'],
    [8200, 500, 'puzzleGate', 'a3CartGate'],
  ],
  [
    [3700, 520, 'mushroom'],
    [4220, 500, 'switch'],
    [4820, 500, 'venomSwitch'],
    [5520, 500, 'switch'],
    [6200, 500, 'puzzleGate', 'a4ReedGate'],
    [7600, 520, 'wind'],
  ],
  [
    [3800, 470, 'switch'],
    [4520, 500, 'venomSwitch'],
    [5300, 470, 'switch'],
    [6100, 500, 'puzzleGate', 'a5GlassDoor'],
    [7580, 520, 'wind'],
  ],
  [
    [3700, 500, 'venomSwitch'],
    [4250, 500, 'switch'],
    [4860, 500, 'switch'],
    [5600, 500, 'puzzleGate', 'a6Hatch'],
    [7350, 520, 'wind'],
  ],
  [
    [3800, 510, 'mushroom'],
    [4380, 390, 'mushroom'],
    [4980, 280, 'mushroom'],
    [5700, 430, 'puzzleGate', 'a7SporeLock'],
    [7480, 500, 'mushroom'],
  ],
  [
    [3740, 480, 'switch'],
    [4400, 430, 'venomSwitch'],
    [5200, 480, 'puzzleGate', 'a8IceGate'],
    [7040, 430, 'block'],
    [8200, 500, 'puzzleGate', 'a8SocketGate'],
  ],
  [
    [3700, 500, 'switch'],
    [4380, 350, 'venomSwitch'],
    [5060, 470, 'switch'],
    [5780, 470, 'puzzleGate', 'a9Seal'],
    [7300, 520, 'wind'],
    [8200, 520, 'wind'],
  ],
  [
    [3800, 500, 'switch'],
    [4580, 330, 'venomSwitch'],
    [5360, 500, 'switch'],
    [6100, 500, 'puzzleGate', 'a10EliteGate'],
    [7420, 500, 'wall'],
    [9350, 470, 'puzzleGate', 'finalCoreSeal'],
  ],
];

class GameHudState {
  const GameHudState({
    this.hearts = 3,
    this.area = 1,
    this.areaName = 'Canopy Roots',
    this.lesson = '',
    this.elapsed = 0,
    this.progress = 0,
    this.overlay = 'menu',
    this.hint = '',
    this.skinIndex = 0,
    this.checkpoint = 0,
    this.completed = const {},
    this.bestTimes = const {},
    this.hasProgress = false,
    this.savedArea = 0,
    this.savedCheckpoint = 0,
    this.bossWipe = false,
    this.hurtCount = 0,
    this.loading = false,
    this.overMenu = false,
    this.intro = 0,
    this.bossHp = 0,
    this.bossMaxHp = 0,
    this.bossName = '',
  });

  /// Bumps on every hit so the HUD can shake the hearts.
  final int hurtCount;

  /// An area's art is being swapped; the loading veil covers the screen.
  final bool loading;

  /// The open popup was reached from the title screen, not from a run.
  final bool overMenu;

  /// Bumps when a run begins, so the area title card plays once.
  final int intro;

  /// Health of the boss in range; [bossMaxHp] is 0 when none is near.
  final int bossHp;
  final int bossMaxHp;
  final String bossName;

  final int hearts;
  final int area;
  final String areaName;
  final String lesson;
  final double elapsed;
  final double progress;
  final String? overlay;
  final String hint;
  final int skinIndex;
  final int checkpoint;
  final Set<int> completed;
  final Map<int, double> bestTimes;
  final bool hasProgress;
  final int savedArea;
  final int savedCheckpoint;

  /// The last death was to a big boss: retry starts at the theme's first flag.
  final bool bossWipe;

  /// Venom is unlocked from area 2 onward.
  bool get canVenom => area >= 2;

  // Value equality: publishing an unchanged state notifies no listener, so an
  // idle or paused game costs the widget tree nothing. Sets and maps compare
  // by identity because the game only replaces them when they really change.
  @override
  bool operator ==(Object other) =>
      other is GameHudState &&
      other.hearts == hearts &&
      other.elapsed == elapsed &&
      other.progress == progress &&
      other.overlay == overlay &&
      other.area == area &&
      other.areaName == areaName &&
      other.lesson == lesson &&
      other.hint == hint &&
      other.skinIndex == skinIndex &&
      other.checkpoint == checkpoint &&
      identical(other.completed, completed) &&
      identical(other.bestTimes, bestTimes) &&
      other.hasProgress == hasProgress &&
      other.savedArea == savedArea &&
      other.savedCheckpoint == savedCheckpoint &&
      other.bossWipe == bossWipe &&
      other.hurtCount == hurtCount &&
      other.loading == loading &&
      other.overMenu == overMenu &&
      other.intro == intro &&
      other.bossHp == bossHp &&
      other.bossMaxHp == bossMaxHp &&
      other.bossName == bossName;

  @override
  int get hashCode => Object.hash(overlay, area, hearts, elapsed, progress);
}

class _Platform {
  _Platform(
    this.x,
    this.y,
    this.width, {
    this.endY,
    this.tag,
    this.enabled = true,
  });

  final double x;
  final double y;
  final double width;
  final double? endY;
  final String? tag;
  bool enabled;

  double surfaceAt(double pointX) {
    if (endY == null) return y;
    final t = ((pointX - x) / width).clamp(0.0, 1.0);
    return y + (endY! - y) * t;
  }
}

class _Hazard {
  _Hazard(this.x, this.y, this.type, {this.activates, this.tag});

  final double x;
  final double y;
  final String type;
  final String? activates;
  final String? tag;
  bool active = true;
  bool enabled = true;

  /// Counts down after a mushroom bounce so its squash animation can play.
  double flash = 0;
}

/// A short sprite animation (hit sparks, gate opening, tail sweep...). Plays
/// the frames of one row of a sheet, or a single frame when [frame] is set.
class _VenomBurst {
  _VenomBurst(this.x, this.y);

  static const duration = 0.4;

  final double x;
  final double y;
  double age = 0;
}

class _Effect {
  _Effect(
    this.file,
    this.row,
    this.x,
    this.y,
    this.size, {
    this.cols = 5,
    this.rows = 4,
    this.frame,
    this.frames = 5,
    this.duration = 0.45,
    this.direction = 1,
    this.center = true,
    this.rise = 0,
    this.fade = false,
    this.firstFrame = 0,
  });

  final String file;
  final int row;
  final int cols;
  final int rows;
  final int? frame;
  final int frames;
  final int firstFrame;
  final double size;
  final double duration;
  final double direction;
  final bool center;
  final double rise;
  final bool fade;
  double x;
  double y;
  double age = 0;
}

/// Non-interactive background dressing taken from each area's prop sheets.
class _Scenery {
  _Scenery(this.file, this.cell, this.x, this.y, this.size, this.flip);

  final String file;
  final int cell;
  final double x;
  final double y;
  final double size;
  final bool flip;
}

class _Enemy {
  _Enemy(
    this.x,
    this.y,
    this.type, {
    this.boss = false,
    this.hp = 1,
    this.opens,
  }) : maxHp = hp;

  double x;
  double y;
  double direction = 1;
  final int maxHp;
  final String type;
  final bool boss;
  final String? opens;
  int hp;
  int parries = 0;
  double baseY = 0;
  double time = 0;
  double attackTimer = 1.6;

  /// Counts down after the boss is hit (hurt pose) or fires (attack pose).
  double hurtTime = 0;
  double fireTime = 0;
  bool active = true;
}

/// Projectile fired by a boss at the player.
class _BossShot {
  _BossShot(this.x, this.y, this.vx, this.vy);

  double x;
  double y;
  final double vx;
  final double vy;
  double age = 0;
}

class _VenomShot {
  _VenomShot(this.x, this.y, this.velocityX);

  double x;
  double y;
  final double velocityX;
  double age = 0;
}

class VenomcoilGame extends FlameGame with KeyboardEvents {
  VenomcoilGame(this.save);

  final SaveData save;

  static const skinNames = <String>[
    'Jade Warden',
    'Magma Coil',
    'Frostglass',
    'Moonspore',
    'Stormcoil',
    'Desert Prism',
    'Arachnid Silk',
    'Alchemist Brass',
    'Resonant Crystal',
    'Royal Ember',
  ];
  static const skinColors = <ui.Color>[
    ui.Color(0xff79ef6c),
    ui.Color(0xffff6a24),
    ui.Color(0xff78eaff),
    ui.Color(0xffe252ff),
    ui.Color(0xff70e8ff),
    ui.Color(0xffffcf64),
    ui.Color(0xffb9ff63),
    ui.Color(0xff55e1ad),
    ui.Color(0xff9b72ff),
    ui.Color(0xffffd65b),
  ];

  @override
  ui.Color backgroundColor() => const ui.Color(0xff082f2c);

  final ValueNotifier<GameHudState> hud = ValueNotifier(const GameHudState());

  // Per-frame readouts. Each drives one small painter directly, so moving
  // bars and cooldown sweeps never rebuild a widget.
  final ValueNotifier<double> momentumMeter = ValueNotifier(0);
  final ValueNotifier<double> coilMeter = ValueNotifier(0);
  final ValueNotifier<double> attackCooldownMeter = ValueNotifier(0);
  final ValueNotifier<double> venomCooldownMeter = ValueNotifier(0);
  final ImageStore _store = ImageStore.instance;
  final GameAudio _audio = GameAudio.instance;
  final Map<_Platform, ui.Picture> _platformPictures = {};
  final List<_Effect> _effects = [];
  final List<_VenomBurst> _venomBursts = [];
  final List<_Scenery> _scenery = [];
  final ParticlePool _particles = ParticlePool(220);
  late final GlowBatch _glows = GlowBatch(360);
  late final GlowBatch _shadows = GlowBatch(40);
  final ui.Paint _glowPaint = ui.Paint()
    ..blendMode = ui.BlendMode.plus
    ..filterQuality = ui.FilterQuality.low;
  final ui.Paint _shadowPaint = ui.Paint()
    ..filterQuality = ui.FilterQuality.low;
  double _shake = 0;
  ui.Color _groundColor = const ui.Color(0xff082f2c);
  ui.Color _primaryColor = const ui.Color(0xff2dd66f);
  ui.Color _accentColor = const ui.Color(0xffffd76a);
  ui.Size _shadedSize = ui.Size.zero;
  final ui.Paint _gradePaint = ui.Paint();
  final ui.Paint _vignettePaint = ui.Paint();
  final List<double> _checkpointYs = [];
  _Hazard? _exitGate;
  final List<_Enemy> _bosses = [];
  Set<String> _stageFiles = {};
  Set<String> _skinSheetFiles = {};

  /// True while a run's art is loaded; false on the title screen, which holds
  /// only its backdrop, the skin preview and the HUD icons.
  bool _inStage = false;
  bool _loading = false;
  bool _needsFrame = false;
  bool _introPending = false;
  int _intro = 0;
  String? _lastTrack;
  Set<int> _completedView = const {};
  Map<int, double> _bestView = const {};
  Future<void> _areaTransition = Future.value();
  Future<void> _skinTransition = Future.value();
  String? _tileFile;
  String? _enemyFile;
  String? _expFxFile;
  String? _propsFile;
  String _fxFile = 'fx_core-transparent.webp';
  double _clock = 0;
  bool _inUpdraft = false;
  String? _backTo;
  bool _resumedFromSave = false;
  bool _lessonPending = false;
  final List<_Platform> _platforms = [];
  final List<_Hazard> _hazards = [];
  final List<_Enemy> _enemies = [];
  final List<_VenomShot> _shots = [];
  final List<_BossShot> _bossShots = [];
  final List<double> _checkpointXs = [];
  List<dynamic> _levels = [];
  Map<String, dynamic> _level = {};
  int _area = 0;
  int _skinIndex = 0;
  double _length = 19200;
  double _playerX = 120;
  double _playerY = 325;
  double _velocityX = 0;
  double _velocityY = 0;
  double _jumpBuffer = 0;
  _Platform? _groundPlatform;
  double _cameraX = 0;
  double _cameraY = 300;
  double _coil = 0;
  double _elapsed = 0;
  double _lavaX = -180;
  double _lavaY = 780;
  double _invulnerable = 0;
  double _hurtFlash = 0;
  int _hurtCount = 0;
  double _hintTime = 0;
  double _lessonTime = 0;
  int _hearts = 3;
  int _checkpoint = 0;
  bool _left = false;
  bool _right = false;
  double _moveAxis = 0;
  double _playerDirection = 1;
  bool _coilHeld = false;
  bool _venomPressed = false;
  bool _tailPressed = false;
  bool _grounded = false;
  bool _airJumpUsed = false;
  bool _started = false;
  bool _dead = false;
  bool _completed = false;
  bool _paused = true;
  String? _overlay = 'menu';
  String _hint = '';
  String _lesson = '';
  String _playerAction = 'idle';
  double _actionTime = 0;
  double _coyoteTime = 0;
  double _sinkTime = 0;
  double _venomCooldown = 0;
  double _attackCooldown = 0;
  bool _onMushroom = false;
  double _hudTicker = 0;
  double _bumpCooldown = 0;
  bool _bossWipe = false;

  @visibleForTesting
  ({
    ui.Offset position,
    ui.Offset velocity,
    bool grounded,
    bool airJumpUsed,
    int projectiles,
  })
  get debugPlayerState => (
    position: ui.Offset(_playerX, _playerY),
    velocity: ui.Offset(_velocityX, _velocityY),
    grounded: _grounded,
    airJumpUsed: _airJumpUsed,
    projectiles: _shots.length,
  );

  @visibleForTesting
  void debugKillPlayer() {
    _invulnerable = 0;
    _hurt(fatal: true);
  }

  static const _lessonShown = 3.0;
  static const _titleCardTime = 2.4;

  static const _coreFxFiles = <String>[
    'fx_core-transparent.webp',
    'fx_impacts-transparent.webp',
  ];

  /// Which shared sheet each hazard type draws from (see [_hazardSpec]).
  static const _sharedSheetFor = <String, String>{
    'wall': _impactsFile,
    'venomWall': _worldCFile,
    'iceWall': _worldCFile,
    'block': _worldCFile,
    'gate': _finalFile,
    'puzzleGate': _finalFile,
    'pillar': _finalFile,
    'mushroom': _worldBFile,
    'venomSwitch': _worldBFile,
    'wind': _worldAFile,
    'updraft': _worldAFile,
    'ceiling': _worldAFile,
  };

  // Type groups looked up every frame; const sets avoid allocating a list for
  // each hazard on each check.
  static const _airCurrents = {'wind', 'updraft'};
  static const _solidTypes = {
    'wall',
    'venomWall',
    'gate',
    'puzzleGate',
    'iceWall',
    'pillar',
  };
  static const _venomTargets = {
    'venomWall',
    'iceWall',
    'switch',
    'venomSwitch',
    'momentumSwitch',
    'cocoon',
  };

  static const _bossNames = {
    'scorpion': 'Kalajengking Kaca',
    'sentinel': 'Sentinel Inti',
    'prism_leviathan': 'Leviathan Prisma',
    'world_serpent': 'Ular Dunia',
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _levels = campaignLevels;
    _skinIndex = save.skin.clamp(0, skinNames.length - 1);
    _refreshSaveViews();
    await _store.loadSheet('hud_atlas-transparent.webp', cols: 4, rows: 3);
    await _enterMenuStage(save.area);
    showMenu();
  }

  void _refreshSaveViews() {
    _completedView = Set.unmodifiable(save.completed);
    _bestView = Map.unmodifiable(save.bestTimes);
  }

  /// Unloads the run and keeps only what the title screen shows.
  Future<void> _enterMenuStage(int index) {
    final transition = _areaTransition.then((_) async {
      if (_overlay != 'menu' && _inStage) return;
      _inStage = false;
      _area = index.clamp(0, _levels.length - 1);
      _level = _levels[_area] as Map<String, dynamic>;
      _clearStageObjects();
      _hearts = 3;
      _checkpoint = 0;
      _elapsed = 0;
      _playerX = 120;
      final bg = _level['bg'] as String;
      _store.release(_stageFiles.difference({bg}));
      _stageFiles = {bg};
      await _store.loadSheet(bg);
      await _loadSkinSheets(_skinIndex);
      _setHud();
    });
    _areaTransition = transition.catchError((Object _) {});
    return transition;
  }

  void _clearStageObjects() {
    _clearPlatformPictures();
    _platforms.clear();
    _hazards.clear();
    _enemies.clear();
    _bosses.clear();
    _exitGate = null;
    _shots.clear();
    _bossShots.clear();
    _effects.clear();
    _venomBursts.clear();
    _scenery.clear();
    _particles.clear();
    _checkpointXs.clear();
    _checkpointYs.clear();
  }

  /// The "_b" boss sheets are shorter grids than the 5x4 "_a" sheets; slicing
  /// them as 5x4 cut every pose in half.
  static int _bossSheetRows(String file) {
    if (!file.contains('_b-')) return 4;
    return file.contains('sentinel') ? 3 : 2;
  }

  static String _skinFile(int skin, String kind) =>
      'skin_${(skin + 1).toString().padLeft(2, '0')}_$kind-transparent.webp';

  /// Loads the sheets one skin actually draws and frees the previous skin's:
  /// its movement poses always, its own fx only while a run needs them.
  Future<void> _loadSkinSheets(int skin) async {
    final next = <String>{};
    Future<void> add(String kind) async {
      final file = _skinFile(skin, kind);
      next.add(file);
      await _store.loadSheet(file, cols: 5, rows: 4);
    }

    await Future.wait([add('motion_a'), if (_inStage) add('fx')]);
    if (_store.sheet(_skinFile(skin, 'motion_a')) == null) {
      await _store.loadSheet(
        'vexa_motion_a-transparent.webp',
        cols: 5,
        rows: 4,
      );
    }
    _store.release(_skinSheetFiles.difference(next));
    _skinSheetFiles = next;
    _fxFile = _store.sheet(_skinFile(skin, 'fx')) != null
        ? _skinFile(skin, 'fx')
        : 'fx_core-transparent.webp';
  }

  /// Loads only the art the current area uses, and frees the previous area's
  /// first so the two never sit in memory together. Needs the geometry built:
  /// shared sheets are skipped when no object of the area draws from them.
  Future<void> _loadStageImages() async {
    final stage = _level;
    final id = (stage['id'] as num).toInt();
    final nn = id.toString().padLeft(2, '0');
    final bg = stage['bg'] as String;
    final tiles = stage['tiles'] as String?;
    final props = stage['props'] as String?;
    final enemy = stage['enemy'] as String;
    final expProps = 'area_${nn}_exp_props-transparent.webp';
    final expFx = id <= 10
        ? 'area_${nn}_exp_fx-transparent.webp'
        : 'area_${nn}_fx-transparent.webp';
    final bosses = id == 15 || id == 20
        ? ['boss_${nn}_a-transparent.webp', 'boss_${nn}_b-transparent.webp']
        : id == 5 || id == 10
        ? [enemy.replaceFirst('_a-', '_b-')]
        : const <String>[];
    final sharedFx = <String>{..._coreFxFiles};
    var usesValve = false;
    for (final hazard in _hazards) {
      final sheet = _sharedSheetFor[hazard.type];
      if (sheet != null) sharedFx.add(sheet);
      usesValve = usesValve || _isValve(hazard);
    }
    final next = <String>{
      bg,
      ?tiles,
      ?props,
      expProps,
      expFx,
      enemy,
      ...bosses,
      ...sharedFx,
      if (usesValve) _valveFile,
    };
    _store.release(_stageFiles.difference(next));
    _stageFiles = next;
    _inStage = true;
    await Future.wait([
      _store.loadSheet(bg),
      if (tiles != null) _store.loadSheet(tiles),
      if (props != null) _store.loadSheet(props, cols: 3, rows: 2),
      _store.loadSheet(expProps, cols: 3, rows: 2),
      _store.loadSheet(expFx, cols: 5, rows: 4),
      _store.loadSheet(enemy, cols: 5, rows: 4),
      for (final boss in bosses)
        _store.loadSheet(boss, cols: 5, rows: _bossSheetRows(boss)),
      for (final file in sharedFx) _store.loadSheet(file, cols: 5, rows: 4),
      if (usesValve) _store.loadSheet(_valveFile, cols: 3, rows: 2),
      _loadSkinSheets(_skinIndex),
    ]);
    _tileFile = tiles;
    _enemyFile = enemy;
    _expFxFile = expFx;
    _propsFile = props;
  }

  void _buildAreaGeometry() {
    final id = (_level['id'] as num).toInt();
    if (id <= 10) {
      final sectionWidth = id == 10 ? 3400.0 : 3200.0;
      final expandedLength = sectionWidth * 3;
      _length = expandedLength * 2;
      for (var section = 0; section < 6; section++) {
        final offset = sectionWidth * section;
        for (final raw in _level['platforms'] as List<dynamic>) {
          final values = raw as List<dynamic>;
          final x = (values[0] as num).toDouble();
          final baseBridgeTag = _bridgeTag(id, x);
          final bridgeTag = baseBridgeTag == null
              ? null
              : '$baseBridgeTag${section >= 3 ? '_b' : ''}';
          final initiallyClosed = bridgeTag != null && section == 0;
          _platforms.add(
            _Platform(
              x + offset,
              (values[1] as num).toDouble(),
              (values[2] as num).toDouble(),
              endY: values.length > 3 ? (values[3] as num).toDouble() : null,
              tag: bridgeTag,
              enabled: !initiallyClosed,
            ),
          );
        }

        final rawEnemies = _level['enemies'] as List<dynamic>;
        if (id != 5 && id != 10 && !(id == 1 && section == 0)) {
          for (final raw in rawEnemies) {
            final values = raw as List<dynamic>;
            final x = (values[0] as num).toDouble() + offset;
            final type = _enemyTypeForArea(id);
            // Walkers stand on the ledge under them; level data can place
            // them a few px into the platform body.
            final y = _groundsAt.contains(type)
                ? _standingY(x, (values[1] as num).toDouble())
                : (values[1] as num).toDouble();
            _enemies.add(_Enemy(x, y, type)..baseY = y);
          }
        }
      }

      for (final objectOffset in [0.0, expandedLength]) {
        final duplicateSuffix = objectOffset == 0 ? '' : '_b';
        for (final raw in _level['hazards'] as List<dynamic>) {
          final values = raw as List<dynamic>;
          final x = (values[0] as num).toDouble();
          final baseTag = _baseHazardActivation(id, x);
          final tag = baseTag == null ? null : '$baseTag$duplicateSuffix';
          final baseGateTag = _baseGateTag(id, x);
          _hazards.add(
            _Hazard(
              x + objectOffset,
              (values[1] as num).toDouble(),
              values[2] as String,
              activates: tag,
              tag: baseGateTag == null ? null : '$baseGateTag$duplicateSuffix',
            ),
          );
        }
      }
      _addExpansionPuzzles(id, expandedLength);
      if (id == 5 || id == 10) {
        final bossType = id == 5 ? 'scorpion' : 'sentinel';
        final bossY = id == 5 ? 500.0 : 500.0;
        _enemies.add(
          _Enemy(
            _length - 650,
            bossY,
            bossType,
            boss: true,
            hp: 6,
            opens: 'bossGate',
          )..baseY = bossY,
        );
        _hazards.add(
          _Hazard(_length - 320, bossY, 'puzzleGate', tag: 'bossGate'),
        );
      }
      if (id == 4) {
        for (final offset in [0.0, expandedLength]) {
          final duplicateSuffix = offset == 0 ? '' : '_b';
          _hazards.add(
            _Hazard(
              1190 + offset,
              520,
              'updraft',
              tag: 'gasLift$duplicateSuffix',
            )..enabled = false,
          );
        }
      }
      if (id == 3) {
        for (final offset in [0.0, expandedLength]) {
          final duplicateSuffix = offset == 0 ? '' : '_b';
          _hazards.add(
            _Hazard(
              1520 + offset,
              460,
              'block',
              activates: 'mineGate$duplicateSuffix',
            ),
          );
        }
      }
      return;
    }

    // The final ten JS levels use a 9,600-unit realm repeated once by
    // doubleLevel(), rather than the six 3,200-unit acts in the first worlds.
    const realmLength = 9600.0;
    _length = realmLength * 2;
    const heights = [500.0, 420.0, 520.0, 350.0];
    for (final offset in [0.0, realmLength]) {
      final duplicateSuffix = offset == 0 ? '' : '_b';
      for (var index = 0, x = 0.0; x < realmLength; index++, x += 800) {
        final y = heights[index % heights.length];
        _platforms.add(
          _Platform(x + offset, y, 690, endY: index % 3 == 0 ? y + 70 : null),
        );
      }
      for (final x in [1800.0, 2700, 3600, 5250, 6150, 7050]) {
        final activates = x == 3600 || x == 7050
            ? 'realm$id${x == 3600 ? 'A' : 'B'}Gate$duplicateSuffix'
            : null;
        _hazards.add(_Hazard(x + offset, 500, 'switch', activates: activates));
      }
      _hazards
        ..add(
          _Hazard(
            4300 + offset,
            500,
            'puzzleGate',
            tag: 'realm${id}AGate$duplicateSuffix',
          ),
        )
        ..add(
          _Hazard(
            7800 + offset,
            500,
            'puzzleGate',
            tag: 'realm${id}BGate$duplicateSuffix',
          ),
        );
      for (var i = 0; i < 5; i++) {
        final x = [900.0, 2300, 4700, 6500, 8350][i];
        final y = i.isEven ? 500.0 : 330.0;
        _enemies.add(_Enemy(x + offset, y, _enemyTypeForArea(id))..baseY = y);
      }
    }
    if (id == 12 || id == 17) {
      // Sticky water and ink bogs are duplicated with each realm half.
      for (final offset in [0.0, realmLength]) {
        _hazards.add(_Hazard(1000 + offset, 430, 'stickyZone'));
        _hazards.add(_Hazard(5800 + offset, 430, 'stickyZone'));
      }
    }
    if (id == 15 || id == 20) {
      final type = id == 15 ? 'prism_leviathan' : 'world_serpent';
      _enemies.add(
        _Enemy(_length - 650, 500, type, boss: true, hp: 12, opens: 'bossGate')
          ..baseY = 500,
      );
      _hazards.add(_Hazard(_length - 300, 500, 'puzzleGate', tag: 'bossGate'));
    }
    if (id == 20) {
      // The void forge inherits the lava pursuit from the source campaign.
      _level['chase'] = true;
    }
  }

  void _addExpansionPuzzles(int id, double expandedLength) {
    final puzzles = _expansionPuzzleData[id - 1];
    for (final offset in [0.0, expandedLength]) {
      final duplicateSuffix = offset == 0 ? '' : '_b';
      for (final puzzle in puzzles) {
        final sourceX = (puzzle[0] as num).toDouble();
        final x = sourceX + offset;
        final y = (puzzle[1] as num).toDouble();
        final type = puzzle[2] as String;
        final tag = type == 'puzzleGate' && puzzle.length > 3
            ? '${puzzle[3]}$duplicateSuffix'
            : null;
        final activates = type == 'puzzleGate'
            ? null
            : _puzzleActivation(id, sourceX, type) == null
            ? null
            : '${_puzzleActivation(id, sourceX, type)}$duplicateSuffix';
        _hazards.add(_Hazard(x, y, type, activates: activates, tag: tag));
      }
    }
  }

  String? _bridgeTag(int id, double x) {
    if (id == 3 && x == 900) return 'leverBridge';
    if (id == 5 && x == 930) return 'glassBridge';
    if (id == 6 && x == 1980) return 'frozenPool';
    if (id == 8 && x == 2070) return 'iceStep';
    if (id == 10 && x == 1880) return 'pillarBridge';
    return null;
  }

  String? _baseHazardActivation(int id, double x) {
    if (id == 3 && x == 760) return 'leverBridge';
    if (id == 4 && x == 1070) return 'gasLift';
    if (id == 5 && x == 880) return 'glassBridge';
    if (id == 6 && x == 1900) return 'frozenPool';
    if (id == 8 && x == 1840) return 'iceStep';
    if (id == 10 && x == 1770) return 'pillarBridge';
    return null;
  }

  String? _baseGateTag(int id, double x) {
    if (id == 3 && x == 2300) return 'mineGate';
    return null;
  }

  String? _puzzleActivation(int id, double x, String type) {
    if (id == 1 && x == 3720) return 'a1VineGate';
    if (id == 1 && x == 7160) return 'a1BloomGate';
    if (id == 2 && x == 3700) return 'a2WebBridge';
    if (id == 2 && x == 5350) return 'a2Queen';
    if (id == 2 && x == 7420) return 'a2Final';
    if (id == 3 && x == 4740) return 'a3ChordGate';
    if (id == 3 && x == 7100) return 'a3CartGate';
    if (id == 4 && x == 5520) return 'a4ReedGate';
    if (id == 5 && x == 5300) return 'a5GlassDoor';
    if (id == 6 && x == 4860) return 'a6Hatch';
    if (id == 7 && x == 4980) return 'a7SporeLock';
    if (id == 8 && x == 4400) return 'a8IceGate';
    if (id == 8 && x == 7040) return 'a8SocketGate';
    if (id == 9 && x == 5060) return 'a9Seal';
    if (id == 10 && x == 5360) return 'a10EliteGate';
    return null;
  }

  static const _groundsAt = {
    'frog',
    'spider',
    'scorpion',
    'spark_newt',
    'gear_mantis',
    'bone_scarab',
    'blot_toad',
    'rust_mite',
  };

  /// Surface of the nearest platform under [x] within reach of [y]; keeps [y]
  /// when no ledge is close enough (flyers and swimmers keep their data).
  double _standingY(double x, double y) {
    double? best;
    for (final platform in _platforms) {
      if (x < platform.x + 16 || x > platform.x + platform.width - 16) continue;
      final surface = platform.surfaceAt(x);
      if ((surface - y).abs() > 90) continue;
      if (best == null || (surface - y).abs() < (best - y).abs()) {
        best = surface;
      }
    }
    return best ?? y;
  }

  String _enemyTypeForArea(int id) => switch (id) {
    1 => 'frog',
    2 => 'spider',
    3 => 'bat',
    4 => 'frog',
    5 => 'scorpion',
    6 => 'spider',
    7 => 'spore',
    8 => 'bat',
    9 => 'drone',
    10 => 'sentinel',
    11 => 'spark_newt',
    12 => 'ink_eel',
    13 => 'gear_mantis',
    14 => 'bone_scarab',
    15 => 'aurora_fish',
    16 => 'storm_hatchling',
    17 => 'blot_toad',
    18 => 'rust_mite',
    19 => 'comet_wisp',
    _ => 'void_drone',
  };

  Future<void> selectArea(int index, {int checkpoint = 0, bool run = true}) {
    final transition = _areaTransition.then(
      (_) => _selectArea(index, checkpoint: checkpoint, run: run),
    );
    _areaTransition = transition.catchError((Object _) {});
    return transition;
  }

  Future<void> _selectArea(
    int index, {
    required int checkpoint,
    required bool run,
  }) async {
    if (_levels.isEmpty) return;
    _paused = true;
    _loading = true;
    _area = index.clamp(0, _levels.length - 1);
    _level = _levels[_area] as Map<String, dynamic>;
    _clearStageObjects();
    _setHud();
    _bossWipe = false;
    _dead = false;
    _completed = false;
    _buildAreaGeometry();
    _buildCheckpoints();
    final palette = (_level['palette'] as List<dynamic>).cast<String>();
    _groundColor = _parseColor(palette[0]);
    _primaryColor = _parseColor(palette[1]);
    _accentColor = _parseColor(palette[2]);
    _shadedSize = ui.Size.zero;
    _bosses.addAll(_enemies.where((enemy) => enemy.boss));
    for (final hazard in _hazards) {
      if (hazard.type == 'puzzleGate' && hazard.x >= _length - 400) {
        _exitGate = hazard;
        break;
      }
    }
    await _loadStageImages();
    _buildScenery();
    final spawn = _level['spawn'] as List<dynamic>;
    final restore = checkpoint > 0 && checkpoint <= _checkpointXs.length;
    final startX = restore
        ? _checkpointXs[checkpoint - 1]
        : (spawn[0] as num).toDouble();
    _playerX = startX;
    _groundPlatform = _platformAt(startX);
    _playerY =
        _groundPlatform?.surfaceAt(startX) ??
        (restore ? _platformYBelow(startX) : (spawn[1] as num).toDouble());
    _velocityX = 0;
    _velocityY = 0;
    _grounded = _groundPlatform != null;
    _coyoteTime = _grounded ? 0.16 : 0;
    _left = false;
    _right = false;
    _moveAxis = 0;
    _coilHeld = false;
    _airJumpUsed = false;
    _venomPressed = false;
    _tailPressed = false;
    _playerDirection = 1;
    _cameraX = startX;
    _cameraY = _playerY - 40;
    _coil = 0;
    _jumpBuffer = 0;
    _sinkTime = 0;
    _onMushroom = false;
    _venomCooldown = 0;
    _attackCooldown = 0;
    _elapsed = 0;
    _lavaX = startX > 0 ? math.max(-180, startX - 700) : -180;
    _lavaY = 780;
    _hearts = 3;
    _checkpoint = restore ? checkpoint : 0;
    _resumedFromSave = restore;
    if (restore) _restorePuzzlesBefore(startX);
    _invulnerable = 0;
    _shake = 0;
    _started = false;
    _paused = !run;
    _introPending = true;
    _needsFrame = true;
    _loading = false;
    if (run) _overlay = null;
    _lesson = _level['lesson'] as String;
    _lessonPending = !run;
    _lessonTime = run ? _lessonShown + _titleCardTime : 0;
    _hint = '';
    _persist();
    _setHud();
  }

  /// When continuing from a saved checkpoint the puzzle objects behind the
  /// player are already solved, so the gates they opened stay open.
  void _restorePuzzlesBefore(double x) {
    const switches = {
      'switch',
      'venomSwitch',
      'momentumSwitch',
      'cocoon',
      'block',
      'valve',
      'ceiling',
    };
    for (final hazard in _hazards) {
      if (hazard.x >= x - 120) continue;
      if (switches.contains(hazard.type)) {
        _activateHazard(hazard, silent: true);
      } else if (hazard.type != 'spikes') {
        hazard.active = false;
      }
    }
    for (final enemy in _enemies) {
      if (!enemy.boss && enemy.x < x - 120) enemy.active = false;
    }
    _hint = '';
    _hintTime = 0;
  }

  // ---- menu / overlay flow -------------------------------------------------

  void showMenu() {
    _backTo = null;
    _paused = true;
    _overlay = 'menu';
    _setHud();
  }

  void _clearInput() {
    _left = false;
    _right = false;
    _moveAxis = 0;
    _coilHeld = false;
    _coil = 0;
    _jumpBuffer = 0;
  }

  /// Start at the saved spot; the skippable how-to-play cards come first.
  Future<void> playFromMenu() async {
    await selectArea(save.area, checkpoint: save.checkpoint);
    showTutorial(beforeRun: true);
  }

  /// Where closing the tutorial goes: back to the main menu when it was
  /// opened from there just to read, otherwise into the run.
  bool _tutorialToMenu = false;

  void showTutorial({bool beforeRun = false}) {
    _tutorialToMenu = !beforeRun && _overlay == 'menu';
    _clearInput();
    _paused = true;
    _overlay = 'tutorial';
    _setHud();
  }

  void closeTutorial() {
    if (_tutorialToMenu) {
      _tutorialToMenu = false;
      showMenu();
    } else {
      startOrResume();
    }
  }

  void _openSub(String name) {
    if (_overlay != 'areas' && _overlay != 'skins') _backTo = _overlay;
    _clearInput();
    _paused = true;
    _overlay = name;
    _setHud();
  }

  void openAreaSelect() => _openSub('areas');

  void openSkinSelect() => _openSub('skins');

  /// Back button of the areas / skins pages: returns to wherever they were
  /// opened from (main menu, pause, game over) or resumes play.
  void backFromSubmenu() {
    final back = _backTo;
    _backTo = null;
    if (back == null) {
      startOrResume();
      return;
    }
    _paused = true;
    _overlay = back;
    _setHud();
  }

  /// Picking an area starts a fresh run immediately.
  Future<void> pickArea(int index) async {
    _backTo = null;
    await selectArea(index);
    showTutorial(beforeRun: true);
  }

  Future<void> selectSkin(int index) {
    if (index < 0 || index >= skinNames.length) return Future.value();
    final transition = _skinTransition.then((_) => _selectSkin(index));
    _skinTransition = transition.catchError((Object _) {});
    return transition;
  }

  Future<void> _selectSkin(int index) async {
    await _loadSkinSheets(index);
    _skinIndex = index;
    _persist();
    _setHud();
  }

  void startOrResume() {
    _paused = false;
    _started = true;
    _overlay = null;
    _backTo = null;
    if (_lessonPending) {
      _lessonPending = false;
      _lessonTime = _lessonShown + _titleCardTime;
    }
    _setHud();
  }

  void togglePause() {
    if (_dead || _completed || (_overlay != null && _overlay != 'pause')) {
      return;
    }
    _paused = !_paused;
    if (_paused) _clearInput();
    _overlay = _paused ? 'pause' : null;
    _setHud();
  }

  void quitToMenu() {
    _persist();
    _dead = false;
    _completed = false;
    showMenu();
    unawaited(_enterMenuStage(save.area));
  }

  Future<void> resetProgress() async {
    await save.resetProgress();
    _refreshSaveViews();
    showMenu();
    await _enterMenuStage(0);
  }

  void cycleVolume() {
    _audio.cycle();
    _persist();
    _audio.sfx('ui_click');
    _setHud();
  }

  /// Called for every menu tap: click sound, and (re)starts the music, which
  /// browsers only allow after a user gesture.
  void uiTap() {
    _audio.sfx('ui_click');
    unawaited(_audio.music(_musicTrack));
  }

  /// Menu theme, then one track per world of five areas.
  String get _musicTrack =>
      _overlay == 'menu' ? 'menu' : 'world${_area ~/ 5 + 1}';

  void saveNow() => _persist();

  void _persist({int? area, int? checkpoint}) {
    // Outside a live run (title screen, cleared area, boss wipe) the spot to
    // come back to is already saved; only an explicit value may replace it.
    final liveRun = _inStage && !_completed && !_bossWipe;
    if (area != null || liveRun) save.area = area ?? _area;
    if (checkpoint != null || liveRun) {
      save.checkpoint = checkpoint ?? _checkpoint;
    }
    save.skin = _skinIndex;
    save.volumeLevel = _audio.level.value;
    unawaited(save.save());
  }

  void retry() {
    if (_bossWipe) {
      unawaited(selectArea((_area ~/ 5) * 5, checkpoint: 1));
      return;
    }
    final stageStart = _checkpoint == 0
        ? 120.0
        : (_checkpointXs.isEmpty ? 120.0 : _checkpointXs[_checkpoint - 1]);
    _playerX = stageStart;
    _groundPlatform = _platformAt(stageStart);
    _playerY =
        _groundPlatform?.surfaceAt(stageStart) ?? _platformYBelow(stageStart);
    _velocityX = 0;
    _velocityY = 0;
    _grounded = _groundPlatform != null;
    _coyoteTime = _grounded ? 0.16 : 0;
    _cameraX = stageStart;
    _cameraY = _playerY - 40;
    // Pull the chasing lava back too, or it swallows the respawn point forever.
    _lavaX = math.max(-180, stageStart - 700);
    _lavaY = 780;
    _coil = 0;
    _jumpBuffer = 0;
    _coilHeld = false;
    _airJumpUsed = false;
    _left = false;
    _right = false;
    _moveAxis = 0;
    _hearts = 3;
    _invulnerable = 0;
    _shake = 0;
    _bossShots.clear();
    _particles.clear();
    _dead = false;
    _completed = false;
    _started = false;
    _paused = false;
    _overlay = null;
    _setHud();
  }

  void nextArea() {
    if (_area + 1 < _levels.length) {
      unawaited(selectArea(_area + 1));
    } else {
      openAreaSelect();
    }
  }

  /// Keep the stick's magnitude so a small gesture permits precise movement.
  void setMoveAxis(double value) {
    _moveAxis = value.clamp(-1.0, 1.0);
    if (_moveAxis != 0) _beginRun();
  }

  void setMove({bool? left, bool? right}) {
    if (left != null) _left = left;
    if (right != null) _right = right;
    if (_right && !_left) _playerDirection = 1;
    if (_left && !_right) _playerDirection = -1;
    if (_left || _right) _beginRun();
  }

  void setJumpHeld(bool value) {
    if (_paused || _dead || _completed) {
      _coilHeld = false;
      return;
    }
    if (value && !_coilHeld) _beginRun();
    // Second jump in mid-air: only once per landing, and only after coyote
    // time has run out (otherwise the normal coil jump handles it).
    final airJump =
        value &&
        !_coilHeld &&
        !_grounded &&
        !_airJumpUsed &&
        _coyoteTime <= 0 &&
        _started &&
        !_paused &&
        !_dead &&
        !_completed;
    if (airJump) {
      _airJumpUsed = true;
      _velocityY = -(430 + 0.18 * 260) * 1.14;
      _playerAction = 'coil';
      _actionTime = 0.22;
      _audio.sfx('jump');
      _jumpBuffer = 0;
      return;
    }
    if (!value && _coilHeld) {
      _jumpBuffer = 0.2;
    }
    if (value && !_coilHeld && _grounded) _audio.sfx('coil');
    _coilHeld = value;
  }

  void setCoilHeld(bool value) => setJumpHeld(value);

  void useVenom() {
    _beginRun();
    _venomPressed = true;
  }

  void useTail() {
    useAttack();
  }

  void useAttack() {
    _beginRun();
    _tailPressed = true;
  }

  void _beginRun() {
    if (!_paused && !_dead && !_completed) _started = true;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final down = event is KeyDownEvent || event is KeyRepeatEvent;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      setMove(left: down);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      setMove(right: down);
    } else if (key == LogicalKeyboardKey.space) {
      setJumpHeld(down);
    } else if (down && key == LogicalKeyboardKey.keyJ) {
      useVenom();
    } else if (down && key == LogicalKeyboardKey.keyK) {
      useAttack();
    } else if (down && key == LogicalKeyboardKey.escape) {
      togglePause();
    }
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_levels.isEmpty || _loading) return;
    dt = dt.clamp(0, 1 / 30);
    _clock += dt;
    _particles.update(dt);
    _shake = math.max(0, _shake - dt * 2.6);
    for (final effect in _effects) {
      effect.age += dt;
    }
    _effects.removeWhere((effect) => effect.age >= effect.duration);
    for (final burst in _venomBursts) {
      burst.age += dt;
    }
    _venomBursts.removeWhere((burst) => burst.age >= _VenomBurst.duration);
    for (final hazard in _hazards) {
      if (hazard.flash > 0) hazard.flash = math.max(0, hazard.flash - dt);
    }
    _hudTicker += dt;
    _lessonTime = math.max(0, _lessonTime - dt);
    _hintTime = math.max(0, _hintTime - dt);
    _actionTime = math.max(0, _actionTime - dt);
    if (_actionTime == 0 &&
        (_playerAction == 'venom' || _playerAction == 'tail')) {
      _playerAction = 'idle';
    }
    _jumpBuffer = math.max(0, _jumpBuffer - dt);
    _venomCooldown = math.max(0, _venomCooldown - dt);
    _attackCooldown = math.max(0, _attackCooldown - dt);
    if (_paused || _dead || _completed) {
      if (_hudTicker >= 0.1) {
        _hudTicker = 0;
        _setHud();
      }
      return;
    }
    // Enemies far outside the view are switched off until the player nears.
    for (final enemy in _enemies) {
      if (!enemy.active || (enemy.x - _playerX).abs() > 1500) continue;
      enemy.time += dt;
      enemy.hurtTime = math.max(0, enemy.hurtTime - dt);
      enemy.fireTime = math.max(0, enemy.fireTime - dt);
      switch (enemy.type) {
        case 'frog':
          final cycle = enemy.time % 2.1;
          enemy.y =
              enemy.baseY -
              (cycle >= 0.45 && cycle < 1.25
                  ? math.sin((cycle - 0.45) / 0.8 * math.pi) * 120
                  : 0);
          break;
        case 'spider':
          enemy.x += math.sin(enemy.time * 1.7) * 22 * dt;
          break;
        case 'bat':
          final near = (_playerX - enemy.x).abs() < 330;
          enemy.y =
              enemy.baseY +
              math.sin(enemy.time * 2.7) * 28 +
              (near ? math.min(150, (enemy.time % 2.2) * 65) : 0);
          break;
        case 'spore':
          enemy.y = enemy.baseY + math.sin(enemy.time * 2.1) * 34;
          break;
        case 'drone':
          enemy.y = enemy.baseY + math.sin(enemy.time * 2.4) * 20;
          break;
        case 'ink_eel':
        case 'aurora_fish':
        case 'comet_wisp':
        case 'void_drone':
          enemy.y = enemy.baseY + math.sin(enemy.time * 2.2) * 25;
          break;
        default:
          break;
      }
    }
    _invulnerable = math.max(0, _invulnerable - dt);
    _hurtFlash = math.max(0, _hurtFlash - dt);
    _bumpCooldown = math.max(0, _bumpCooldown - dt);
    if (!_started) {
      if (_hudTicker >= 0.1) {
        _hudTicker = 0;
        _setHud();
      }
      return;
    }

    _elapsed += dt;
    final move = _left || _right
        ? ((_right ? 1 : 0) - (_left ? 1 : 0)).toDouble()
        : _moveAxis;
    if (move != 0) _playerDirection = move.sign;
    final targetSpeed = move * 520;
    final reversing = move != 0 && _velocityX * move < 0;
    final acceleration = reversing ? 3600.0 : (move == 0 ? 3000.0 : 2400.0);
    if (_grounded) {
      // Walking on the ground is direct: speed follows the stick, no build-up.
      _velocityX = targetSpeed;
    } else {
      final step = acceleration * 0.7 * dt;
      _velocityX += (targetSpeed - _velocityX).clamp(-step, step);
    }

    if (_coilHeld && _grounded) {
      _coil = (_coil + dt / 1.15).clamp(0.0, 1.0);
      _velocityX *= math.pow(0.8, dt * 10).toDouble();
    }
    _coyoteTime = _grounded ? 0.16 : math.max(0, _coyoteTime - dt);
    if (_jumpBuffer > 0 && (_grounded || _coyoteTime > 0 || _onMushroom)) {
      final firstArea = (_level['id'] as num).toInt() == 1;
      final charge = math.max(firstArea ? 0.45 : 0.18, _coil);
      final bounceBoost = _onMushroom ? 1.32 : 1.0;
      final tutorialBoost = firstArea ? 1.12 : 1.0;
      // 1.14 = sqrt(1.3): gravity makes peak height scale with speed squared,
      // so this lifts the apex by 30%.
      _velocityY = -(430 + charge * 260) * 1.14 * bounceBoost * tutorialBoost;
      // A stationary jump must not launch sideways merely because of facing.
      _velocityX += move * (65 + charge * 120) * (firstArea ? 1.25 : 1.0);
      _grounded = false;
      _groundPlatform = null;
      _onMushroom = false;
      _coil = 0;
      _jumpBuffer = 0;
      _playerAction = 'coil';
      _actionTime = 0.22;
      _audio.sfx('jump');
      _dust(_playerX, _playerY, 8);
    } else if (!_coilHeld && !_grounded) {
      _coil = 0;
    }

    if (_venomPressed) _spitVenom();
    if (_tailPressed) _tailWhip();
    _venomPressed = false;
    _tailPressed = false;

    final wasGrounded = _grounded;
    final supportingPlatform = _groundPlatform;
    final oldX = _playerX;
    final oldY = _playerY;
    _applyTerrainForces(dt);
    _velocityY += 1280 * dt;
    _playerX = math.max(24, _playerX + _velocityX * dt);
    _resolveWalls(oldX);
    _playerY += _velocityY * dt;
    _grounded = false;
    _groundPlatform = null;
    var mushroomBounce = false;
    if (_velocityY >= 0) {
      for (final hazard in _hazards) {
        if (!hazard.active || hazard.type != 'mushroom') continue;
        if ((hazard.x - _playerX).abs() > 70 ||
            oldY > hazard.y + 10 ||
            _playerY < hazard.y - 18) {
          continue;
        }
        _playerY = hazard.y;
        _velocityY = _coilHeld ? -760 : -510;
        _grounded = false;
        _groundPlatform = null;
        _onMushroom = _coilHeld;
        _playerAction = 'bounce';
        _actionTime = 0.25;
        mushroomBounce = true;
        hazard.flash = 0.5;
        _audio.sfx('bounce');
        if (_coilHeld) _showHint('PERFECT BOUNCE');
        break;
      }
    }
    var keptGroundSupport = false;
    if (!mushroomBounce &&
        wasGrounded &&
        _velocityY >= 0 &&
        supportingPlatform != null &&
        supportingPlatform.enabled &&
        _playerX >= supportingPlatform.x + 16 &&
        _playerX <= supportingPlatform.x + supportingPlatform.width - 16) {
      _playerY = supportingPlatform.surfaceAt(_playerX);
      _velocityY = 0;
      _grounded = true;
      _airJumpUsed = false;
      _groundPlatform = supportingPlatform;
      _coyoteTime = 0.09;
      keptGroundSupport = true;
    }
    if (!mushroomBounce && !keptGroundSupport && _velocityY >= 0) {
      _Platform? landing;
      var landingY = double.infinity;
      for (final platform in _platforms) {
        if (!platform.enabled) continue;
        if (_playerX < platform.x + 16 ||
            _playerX > platform.x + platform.width - 16) {
          continue;
        }
        final surface = platform.surfaceAt(_playerX);
        if (oldY <= surface + 24 && _playerY >= surface && surface < landingY) {
          landing = platform;
          landingY = surface;
        }
      }
      if (landing != null) {
        if (!wasGrounded && _velocityY > 320) {
          _audio.sfx('land');
          _dust(_playerX, landingY, 10);
        }
        _playerY = landingY;
        _velocityY = 0;
        _grounded = true;
        _airJumpUsed = false;
        _groundPlatform = landing;
        _coyoteTime = 0.09;
        _onMushroom = false;
      }
    }

    _updateShots(dt);
    _updateBossAttacks(dt);
    _checkHazards();
    _checkEnemyContact();
    // Past the last flag there is nothing left to pass (a restored save can
    // sit at 12/12); indexing it here threw every frame and froze the game.
    final nextCheckpoint = _checkpoint >= _checkpointXs.length
        ? double.infinity
        : _checkpointXs[_checkpoint];
    if (_checkpoint < 12 && _playerX >= nextCheckpoint) {
      _checkpoint++;
      // Checkpoints only save the spot; hearts refill to full only after
      // dying and respawning here (see retry).
      _showHint('CHECKPOINT $_checkpoint/12');
      _audio.sfx('checkpoint');
      _particles.burst(
        nextCheckpoint,
        _platformYBelow(nextCheckpoint) - 60,
        _goldRgb,
        count: 26,
        speed: 300,
        life: 0.9,
        size: 16,
      );
      _fx(
        'fx_core-transparent.webp',
        2,
        nextCheckpoint,
        _platformYBelow(nextCheckpoint),
        170,
        center: false,
        duration: 0.7,
      );
      _persist();
    }
    if (_level['chase'] == true) {
      _lavaX += (112 + _elapsed / 20) * dt;
      _lavaY = math.max(650, 780 - _elapsed / 0.5);
      if (_playerX < _lavaX + 80 || _playerY > _lavaY) _hurt(fatal: true);
    }
    if (_playerY > 860) _hurt(fatal: true);
    final exitGate = _exitGate;
    if (_playerX >= _length - 70 &&
        !_dead &&
        (exitGate == null || !exitGate.active) &&
        !_bosses.any((enemy) => enemy.active)) {
      _completed = true;
      _paused = true;
      _overlay = 'complete';
      _playerAction = 'victory';
      _audio.sfx('complete');
      _particles.burst(
        _playerX,
        _playerY - 70,
        _goldRgb,
        count: 46,
        speed: 420,
        life: 1.1,
        size: 18,
      );
      _fx(
        'fx_core-transparent.webp',
        2,
        _playerX,
        _playerY,
        260,
        center: false,
        duration: 0.9,
      );
      save.completed.add(_area);
      if (!_resumedFromSave) {
        final best = save.bestTimes[_area];
        if (best == null || _elapsed < best) save.bestTimes[_area] = _elapsed;
      }
      _refreshSaveViews();
      _persist(area: math.min(_area + 1, _levels.length - 1), checkpoint: 0);
    }
    _cameraX +=
        (_playerX + _velocityX * 0.35 - _cameraX) * math.min(1, dt * 4.5);
    _cameraY += (_playerY - 40 - _cameraY) * math.min(1, dt * 3.5);
    momentumMeter.value = (_velocityX.abs() / 560 * 40).round().clamp(0, 40) / 40;
    coilMeter.value = (_coil * 40).round() / 40;
    attackCooldownMeter.value = (_attackCooldown / 0.42 * 30).ceil() / 30;
    venomCooldownMeter.value = (_venomCooldown / 0.36 * 30).ceil() / 30;
    // The HUD only displays coarse time and meter values. Rebuilding its
    // entire Flutter widget tree every few frames competes with game frames.
    if (_hudTicker >= 0.16) {
      _hudTicker = 0;
      _setHud();
    }
  }

  void _applyTerrainForces(double dt) {
    final id = (_level['id'] as num).toInt();
    final wasInUpdraft = _inUpdraft;
    _inUpdraft = false;
    var inSink = false;
    if (id == 2 || id == 12) {
      final cycle = id == 2 ? 3200.0 : 9600.0;
      final localX = _playerX % cycle;
      final sticky = id == 2
          ? localX >= 300 && localX <= 810 && _playerY >= 470 && _playerY <= 560
          : ((localX >= 1000 && localX <= 1500) ||
                (localX >= 5800 && localX <= 6350));
      if (sticky) _velocityX *= math.pow(0.12, dt * 7).toDouble();
    }
    if (id == 4) {
      for (var section = 0; section < 6; section++) {
        final offset = section * 3200.0;
        if ((_playerX >= offset + 260 &&
                _playerX <= offset + 1240 &&
                _playerY >= 330 &&
                _playerY <= 590) ||
            (_playerX >= offset + 2120 &&
                _playerX <= offset + 2540 &&
                _playerY >= 380 &&
                _playerY <= 570)) {
          inSink = _grounded;
          break;
        }
      }
    } else if (id == 17 &&
        ((_playerX % 9600) >= 1000 && (_playerX % 9600) <= 1500 ||
            (_playerX % 9600) >= 5800 && (_playerX % 9600) <= 6350)) {
      inSink = _grounded;
    }
    if (inSink && _velocityX.abs() < 42) {
      _sinkTime += dt;
      if (_sinkTime > 2) _hurt(fatal: true);
    } else {
      _sinkTime = math.max(0, _sinkTime - dt * 2);
    }
    for (final hazard in _hazards) {
      if (!hazard.enabled || !_airCurrents.contains(hazard.type)) continue;
      final width = hazard.type == 'wind' ? 250.0 : 190.0;
      final height = hazard.type == 'wind' ? 520.0 : 440.0;
      if (_playerX > hazard.x &&
          _playerX < hazard.x + width &&
          _playerY > hazard.y - height &&
          _playerY < hazard.y + 30) {
        _velocityY = math.max(-390, _velocityY - 930 * dt);
        _inUpdraft = true;
      }
    }
    if (_inUpdraft && !wasInUpdraft) _audio.sfx('wind');
  }

  void _resolveWalls(double oldX) {
    for (final hazard in _hazards) {
      if (!hazard.active) continue;
      if (hazard.type == 'momentumSwitch' &&
          (hazard.x - _playerX).abs() < 72 &&
          (_playerY - hazard.y).abs() < 150 &&
          _velocityX.abs() >= 250) {
        _activateHazard(hazard);
        continue;
      }
      if (!_solidTypes.contains(hazard.type)) continue;
      // Locked gates / portals are full-height force fields: no jumping over.
      final fullHeight = hazard.type == 'gate' || hazard.type == 'puzzleGate';
      if ((hazard.x - _playerX).abs() > 74 ||
          (!fullHeight && (hazard.y - _playerY).abs() > 170)) {
        continue;
      }
      if (hazard.type == 'wall' && _velocityX.abs() >= 330) {
        _activateHazard(hazard);
        _showHint('BARRIER BROKEN');
      } else {
        _playerX = oldX;
        _velocityX *= -0.16;
        if (_bumpCooldown <= 0) {
          _bumpCooldown = 0.35;
          _audio.sfx('bump');
        }
        _showHint(
          hazard.type == 'venomWall' || hazard.type == 'iceWall'
              ? 'VENOM'
              : hazard.type == 'puzzleGate' || hazard.type == 'gate'
              ? 'CARI SAKLAR · TEKAN SERANG'
              : 'BUILD SPEED',
        );
      }
    }
  }

  /// Fires a little below the jaw, nearer the height of ground enemies.
  static const _venomDrop = 60.0;

  void _spitVenom() {
    if ((_level['id'] as int) < 2) {
      _showHint('VENOM UNLOCKS IN AREA 2');
      return;
    }
    if (_venomCooldown > 0) return;
    _audio.sfx('venom');
    _venomCooldown = 0.36;
    _playerAction = 'venom';
    _actionTime = 0.34;
    final direction = _playerDirection;
    // Start the glob at the jaw, the same point the spit animation opens from
    // (see _drawPlayer), using the same sprite scale.
    final sheet =
        _store.sheet(_skinFile(_skinIndex, 'motion_a')) ??
        _store.sheet('vexa_motion_a-transparent.webp');
    var mouthX = 34.0, mouthY = -38.0 + _venomDrop;
    if (sheet != null) {
      final scale = 192 / sheet.cellWidth;
      final ref = sheet.rowMax(0);
      mouthX = ref.width * scale * 0.4 + 14;
      mouthY = -ref.height * scale * 0.76 + 3 + _venomDrop;
    }
    _shots.add(
      _VenomShot(
        _playerX + direction * mouthX,
        _playerY + mouthY,
        direction * 560,
      ),
    );
  }

  void _tailWhip() {
    if (_attackCooldown > 0) return;
    _attackCooldown = 0.42;
    _playerAction = 'tail';
    _actionTime = 0.3;
    final direction = _playerDirection;
    _audio.sfx('attack');
    _particles.burst(
      _playerX + direction * 70,
      _playerY - 70,
      _skinRgb,
      count: 10,
      speed: 320,
      life: 0.32,
      size: 13,
      gravity: 0,
      angle: direction > 0 ? 0 : math.pi,
      spread: 0.9,
    );
    _fx(
      _fxFile,
      2,
      _playerX + direction * 70,
      _playerY - 70,
      210,
      direction: direction,
      duration: 0.3,
    );
    for (final hazard in _hazards) {
      if (!hazard.active ||
          (hazard.x - _playerX).abs() > 125 ||
          (hazard.y - _playerY).abs() > 175) {
        continue;
      }
      if (hazard.type == 'switch' ||
          hazard.type == 'venomSwitch' ||
          hazard.type == 'momentumSwitch' ||
          hazard.type == 'pillar' ||
          hazard.type == 'block' ||
          hazard.type == 'valve' ||
          hazard.type == 'puzzleGate') {
        _activateHazard(hazard);
      }
    }
    for (final enemy in _enemies) {
      if (enemy.active &&
          (enemy.x - _playerX).abs() < 125 &&
          (enemy.y - _playerY).abs() < 140) {
        if (enemy.type == 'sentinel') {
          enemy.parries++;
          _showHint(
            enemy.parries >= 3
                ? 'TAIL FINISHER!'
                : '${3 - enemy.parries} PARRIES LEFT',
          );
          if (enemy.parries >= 3) {
            _defeatEnemy(enemy);
          } else {
            _audio.sfx('hit');
          }
        } else if (enemy.boss) {
          enemy.hp--;
          enemy.hurtTime = 0.3;
          _showHint(enemy.hp <= 0 ? 'BOSS BROKEN' : 'BOSS ${enemy.hp}');
          if (enemy.hp <= 0) {
            _defeatEnemy(enemy);
          } else {
            _audio.sfx('hit');
          }
        } else if (enemy.type == 'spider' || enemy.type == 'scorpion') {
          _showHint('ARMORED');
          _audio.sfx('hit');
        } else {
          _defeatEnemy(enemy);
        }
      }
    }
    _shots.removeWhere((shot) => (shot.x - _playerX).abs() < 130);
    // The tail can swat incoming boss projectiles out of the air.
    final before = _bossShots.length;
    _bossShots.removeWhere(
      (shot) =>
          (shot.x - _playerX).abs() < 130 && (shot.y - _playerY).abs() < 150,
    );
    if (_bossShots.length != before) _audio.sfx('hit');
    _velocityX += direction * 18;
  }

  void _activateHazard(_Hazard hazard, {bool silent = false}) {
    _deactivate(hazard, fx: !silent);
    _openActivatedTag(hazard.activates, fx: !silent);
    if (!silent) {
      _audio.sfx('switch');
      _particles.burst(hazard.x, hazard.y - 50, _goldRgb, count: 14, speed: 260);
      _fx(
        'fx_core-transparent.webp',
        2,
        hazard.x,
        hazard.y,
        150,
        center: false,
        duration: 0.6,
      );
    }
    if (hazard.type == 'valve') {
      for (final item in _hazards) {
        if (item.type == 'updraft') item.enabled = true;
      }
      if (!silent) _showHint('GAS LIFT ACTIVE');
    } else if (!silent) {
      _showHint('MACHINERY ACTIVATED');
    }
    if (hazard.type == 'switch' && hazard.activates == null) {
      final nextGate = _hazards
          .where(
            (item) =>
                item.active &&
                (item.type == 'gate' || item.type == 'puzzleGate') &&
                item.x > hazard.x &&
                item.x - hazard.x < 1800,
          )
          .toList();
      if (nextGate.isNotEmpty) _deactivate(nextGate.first, fx: !silent);
    }
  }

  void _openActivatedTag(String? tag, {bool fx = true}) {
    if (tag == null) return;
    for (final platform in _platforms) {
      if (platform.tag == tag) platform.enabled = true;
    }
    _cacheCheckpointHeights();
    for (final hazard in _hazards) {
      if (hazard.tag != tag) continue;
      if (hazard.type == 'updraft') {
        hazard.enabled = true;
      } else {
        _deactivate(hazard, fx: fx);
      }
    }
  }

  void _defeatEnemy(_Enemy enemy) {
    enemy.active = false;
    _audio.sfx('defeat');
    _particles.burst(
      enemy.x,
      enemy.y - 40,
      enemy.boss ? _goldRgb : _skinRgb,
      count: enemy.boss ? 60 : 18,
      speed: enemy.boss ? 520 : 300,
      life: enemy.boss ? 1.2 : 0.6,
      size: enemy.boss ? 24 : 16,
    );
    _shake = math.max(_shake, enemy.boss ? 1 : 0.25);
    _fx(
      'fx_impacts-transparent.webp',
      0,
      enemy.x,
      enemy.y - 30,
      enemy.boss ? 260 : 130,
      duration: 0.4,
    );
    final file = _enemyFile;
    if (!enemy.boss && file != null) {
      _fx(
        file,
        3,
        enemy.x,
        enemy.y - 30,
        105,
        frame: 2,
        duration: 0.5,
        rise: 70,
        fade: true,
      );
    }
    if (enemy.opens != null) _openActivatedTag(enemy.opens);
    if (enemy.boss) {
      for (final hazard in _hazards) {
        if (hazard.tag == 'bossGate') _deactivate(hazard);
        if (enemy.type == 'sentinel' && hazard.tag == 'finalCoreSeal') {
          _deactivate(hazard);
        }
      }
    }
  }

  void _updateShots(double dt) {
    for (final shot in _shots) {
      shot.age += dt;
      shot.x += shot.velocityX * dt;
      for (final hazard in _hazards) {
        if (!hazard.active || !_venomTargets.contains(hazard.type)) continue;
        if ((hazard.x - shot.x).abs() < 68 && (hazard.y - shot.y).abs() < 150) {
          _activateHazard(hazard);
          _shotHit(shot);
          _showHint('VENOM TARGET MELTED');
          break;
        }
      }
      for (final enemy in _enemies) {
        if (enemy.active &&
            (enemy.x - shot.x).abs() < 60 &&
            (enemy.y - shot.y).abs() < 100) {
          if (enemy.type == 'spider' || enemy.type == 'scorpion') {
            enemy.hp--;
            _showHint(enemy.hp <= 0 ? 'ENEMY DEFEATED' : 'ARMORED');
            if (enemy.hp <= 0) {
              _defeatEnemy(enemy);
            } else {
              _audio.sfx('hit');
            }
          } else if (enemy.boss) {
            enemy.hp--;
            enemy.hurtTime = 0.3;
            _showHint(enemy.hp <= 0 ? 'BOSS BROKEN' : 'BOSS ${enemy.hp}');
            if (enemy.hp <= 0) {
              _defeatEnemy(enemy);
            } else {
              _audio.sfx('hit');
            }
          } else {
            _defeatEnemy(enemy);
          }
          _shotHit(shot);
          break;
        }
      }
    }
    _shots.removeWhere(
      (shot) =>
          shot.age > 2.2 || shot.x < _cameraX - 900 || shot.x > _length + 100,
    );
  }

  /// Bosses in range aim projectiles at the player; they fire faster and in
  /// spreads as they get hurt.
  void _updateBossAttacks(double dt) {
    for (final enemy in _enemies) {
      if (!enemy.active || !enemy.boss) continue;
      if ((enemy.x - _playerX).abs() > 820) {
        enemy.attackTimer = math.max(enemy.attackTimer, 0.8);
        continue;
      }
      final bigBoss =
          enemy.type == 'prism_leviathan' || enemy.type == 'world_serpent';
      if (bigBoss) {
        // Big bosses weave back and forth (and faster when enraged) so they
        // can't be pinned in one spot and whittled down.
        final pace = enemy.hp <= 5 ? 1.5 : 0.9;
        enemy.x +=
            math.sin(enemy.time * pace) * (enemy.hp <= 5 ? 170 : 110) * dt;
        enemy.y = enemy.baseY + math.sin(enemy.time * pace * 1.7) * 40;
      }
      enemy.attackTimer -= dt;
      if (enemy.attackTimer > 0) continue;
      final enraged = enemy.hp <= (bigBoss ? 5 : 4);
      final desperate = bigBoss && enemy.hp <= 3;
      enemy.attackTimer = bigBoss
          ? (desperate ? 1.2 : (enraged ? 1.6 : 2.2))
          : (enraged ? 1.5 : 2.3) + enemy.hp * 0.08;
      final fromX = enemy.x;
      enemy.fireTime = 0.45;
      final fromY = enemy.y - 95;
      final aim = math.atan2(_playerY - 45 - fromY, _playerX - fromX);
      final speed = bigBoss ? (enraged ? 460.0 : 400.0) : 340.0;
      final spreads = desperate
          ? const [-0.5, -0.25, 0.0, 0.25, 0.5]
          : enraged
          ? const [-0.28, 0.0, 0.28]
          : bigBoss
          ? const [-0.14, 0.14]
          : const [0.0];
      for (final spread in spreads) {
        _bossShots.add(
          _BossShot(
            fromX,
            fromY,
            math.cos(aim + spread) * speed,
            math.sin(aim + spread) * speed,
          ),
        );
      }
      if (bigBoss && enraged) {
        // Enraged: a ground-hugging shot too, so standing still isn't safe.
        final dir = (_playerX - fromX).sign;
        _bossShots.add(_BossShot(fromX, enemy.baseY - 40, dir * 300, 0));
      }
      _audio.sfx('venom');
    }
    for (final shot in _bossShots) {
      shot.age += dt;
      shot.x += shot.vx * dt;
      shot.y += shot.vy * dt;
      if ((shot.x - _playerX).abs() < 34 &&
          (shot.y - (_playerY - 45)).abs() < 58) {
        shot.age = 99;
        _hurt();
      }
    }
    _bossShots.removeWhere((shot) => shot.age > 4.5);
  }

  void _shotHit(_VenomShot shot) {
    shot.age = 3;
    _particles.burst(shot.x, shot.y, _skinRgb, count: 10, speed: 240, life: 0.4);
    _venomBursts.add(_VenomBurst(shot.x, shot.y + 36));
  }

  void _checkHazards() {
    for (final hazard in _hazards) {
      if (!hazard.active) continue;
      if (hazard.type == 'spikes' &&
          (hazard.x - _playerX).abs() < 52 &&
          (hazard.y - _playerY).abs() < 62) {
        _hurt();
      }
    }
  }

  void _checkEnemyContact() {
    for (final enemy in _enemies) {
      if (!enemy.active ||
          (enemy.x - _playerX).abs() > 52 ||
          (enemy.y - _playerY).abs() > 72) {
        continue;
      }
      const armored = {'spider', 'scorpion', 'sentinel'};
      final swinging = _actionTime > 0 && _playerAction == 'tail';
      // Landing on top of a small foe squashes it; any other touch costs a
      // heart, so small enemies and poison spores are a real threat.
      final stomp = !_grounded && _velocityY > 120 && _playerY < enemy.y - 18;
      if (enemy.boss || armored.contains(enemy.type)) {
        _hurt();
      } else if (swinging || stomp) {
        _defeatEnemy(enemy);
        if (stomp) _velocityY = -380;
      } else {
        _hurt();
      }
    }
  }

  void _hurt({bool fatal = false}) {
    if (_invulnerable > 0 || _dead) return;
    _hearts = fatal ? 0 : _hearts - 1;
    // Losing to a big boss returns to the first checkpoint of its theme. Only
    // a death inside the boss fight counts; dying earlier in the level keeps
    // the normal checkpoint respawn.
    final id = (_level['id'] as num).toInt();
    final inBossFight = _enemies.any(
      (enemy) => enemy.boss && enemy.active && (enemy.x - _playerX).abs() < 820,
    );
    if (_hearts <= 0 && (id == 15 || id == 20) && inBossFight) {
      _bossWipe = true;
      _persist(area: (_area ~/ 5) * 5, checkpoint: 1);
    }
    _invulnerable = 1.2;
    _hurtFlash = 0.45;
    _hurtCount++;
    _shake = math.max(_shake, fatal ? 1 : 0.7);
    _particles.burst(
      _playerX,
      _playerY - 60,
      0xff3b30,
      count: 16,
      speed: 300,
      life: 0.5,
    );
    if (_hearts > 0) _showHint('-1 NYAWA');
    _audio.sfx(_hearts <= 0 ? 'death' : 'hurt');
    _fx(
      'fx_impacts-transparent.webp',
      0,
      _playerX,
      _playerY - 60,
      120,
      duration: 0.35,
    );
    _velocityX = -(_velocityX.sign == 0 ? 1 : _velocityX.sign) * 220;
    _velocityY = -260;
    if (_hearts <= 0) {
      _dead = true;
      _paused = true;
      _overlay = 'death';
      _setHud();
    }
  }

  _Platform? _platformAt(double x) {
    _Platform? best;
    var bestY = double.infinity;
    for (final platform in _platforms) {
      if (platform.enabled &&
          x >= platform.x &&
          x <= platform.x + platform.width) {
        final y = platform.surfaceAt(x);
        if (y < bestY) {
          best = platform;
          bestY = y;
        }
      }
    }
    return best;
  }

  double _platformYBelow(double x) => _platformAt(x)?.surfaceAt(x) ?? 520;

  void _buildCheckpoints() {
    _checkpointXs.clear();
    for (var i = 1; i <= 12; i++) {
      _checkpointXs.add(_platformCenterX(_length * i / 13));
    }
    _cacheCheckpointHeights();
  }

  /// Flag heights, refreshed only when a bridge opens; finding them meant
  /// scanning every platform for every visible flag on every frame.
  void _cacheCheckpointHeights() {
    _checkpointYs
      ..clear()
      ..addAll(_checkpointXs.map(_platformYBelow));
  }

  int get _skinRgb =>
      skinColors[_skinIndex.clamp(0, 9)].toARGB32() & 0xffffff;

  static const _goldRgb = 0xffd66a;

  void _dust(double x, double y, int count) {
    _particles.burst(
      x,
      y - 4,
      // Particles add light: a dim tone stays dust instead of a white flare.
      0x4a3f2e,
      count: count,
      speed: 170,
      life: 0.4,
      size: 13,
      gravity: -30,
      spread: 1.35,
    );
  }

  // Snap a target x to the centre of the platform it sits on so the
  // checkpoint flag (and the respawn point) lands safely in the middle of a
  // ledge rather than on a platform edge or a gap between platforms.
  double _platformCenterX(double x) {
    final platform = _platformAt(x);
    if (platform != null) return platform.x + platform.width / 2;
    var best = x;
    var bestDistance = double.infinity;
    for (final candidate in _platforms) {
      if (!candidate.enabled) continue;
      final center = candidate.x + candidate.width / 2;
      final distance = (center - x).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = center;
      }
    }
    return best;
  }

  void _showHint(String text) {
    _hint = text;
    _hintTime = 1.2;
  }

  void _setHud() {
    final name = _level['shortName'] as String? ?? 'Canopy Roots';
    // The lesson waits for the area title card to finish.
    final label = _hintTime > 0
        ? _hint
        : (_lessonTime > 0 && _lessonTime <= _lessonShown ? _lesson : '');
    if (_overlay == null && _introPending && !_loading) {
      _introPending = false;
      _intro++;
    }
    _Enemy? boss;
    for (final enemy in _bosses) {
      if (enemy.active && (enemy.x - _playerX).abs() <= 820) {
        boss = enemy;
        break;
      }
    }
    final sentinel = boss?.type == 'sentinel';
    hud.value = GameHudState(
      hearts: _hearts,
      area: _area + 1,
      areaName: name,
      lesson: label,
      elapsed: _elapsed,
      progress: (_playerX / _length).clamp(0.0, 1.0),
      overlay: _overlay,
      hint: label,
      skinIndex: _skinIndex,
      checkpoint: _checkpoint,
      completed: _completedView,
      bestTimes: _bestView,
      hasProgress: save.hasProgress,
      savedArea: save.area,
      savedCheckpoint: save.checkpoint,
      bossWipe: _bossWipe,
      hurtCount: _hurtCount,
      loading: _loading,
      overMenu: _backTo == 'menu' || _tutorialToMenu,
      intro: _intro,
      bossHp: boss == null ? 0 : (sentinel ? 3 - boss.parries : boss.hp),
      bossMaxHp: boss == null ? 0 : (sentinel ? 3 : boss.maxHp),
      bossName: boss == null ? '' : _bossNames[boss.type] ?? '',
    );
    final track = _musicTrack;
    if (track != _lastTrack) {
      _lastTrack = track;
      unawaited(_audio.music(track));
    }
    _syncEngine();
  }

  /// Runs the game loop only while the world is on screen and moving. Behind
  /// the title screen and popups the loop is off: no update, no render, and
  /// with nothing animating the app schedules no frames at all.
  void _syncEngine() {
    final settling =
        (_dead || _completed) &&
        (_effects.isNotEmpty || !_particles.isEmpty || _venomBursts.isNotEmpty);
    final live = !_loading && (_overlay == null || settling);
    if (live) {
      if (paused) resumeEngine();
      return;
    }
    if (!paused) pauseEngine();
    if (_needsFrame && _inStage && !_loading) {
      // A new area was set up behind a popup: draw it once.
      _needsFrame = false;
      stepEngine(stepTime: 0);
    }
  }

  /// Screen-sized shaders only change with the window, never per frame.
  void _updateScreenShaders(double width, double height) {
    final screen = ui.Size(width, height);
    if (screen == _shadedSize) return;
    _shadedSize = screen;
    _gradePaint.shader = ui.Gradient.linear(
      ui.Offset.zero,
      ui.Offset(0, height),
      [
        _groundColor.withValues(alpha: 0.2),
        const ui.Color(0x00000000),
        const ui.Color(0x55020407),
      ],
      const [0, 0.5, 1],
    );
    final center = ui.Offset(width / 2, height * 0.46);
    _vignettePaint.shader = ui.Gradient.radial(
      center,
      screen.longestSide * 0.68,
      const [ui.Color(0x00000000), ui.Color(0x12000000), ui.Color(0x99000000)],
      const [0.45, 0.72, 1],
    );
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final screenWidth = size.x;
    final screenHeight = size.y;
    if (screenWidth <= 0 || screenHeight <= 0) return;
    // The title screen fully covers the world, so nothing is drawn behind it.
    if (!_inStage) {
      canvas.drawColor(const ui.Color(0xff050b0a), ui.BlendMode.src);
      return;
    }
    final screen = ui.Rect.fromLTWH(0, 0, screenWidth, screenHeight);
    _updateScreenShaders(screenWidth, screenHeight);
    final bg = _store[_level['bg'] as String];
    canvas.drawRect(screen, ui.Paint()..color = _groundColor);
    if (bg != null) {
      final scale = math.max(screenHeight / bg.height, screenWidth / bg.width);
      final drawW = bg.width * scale;
      final drawH = bg.height * scale;
      final parallax = (_cameraX * 0.08 * (screenWidth / 720)) % drawW;
      final source = ui.Rect.fromLTWH(
        0,
        0,
        bg.width.toDouble(),
        bg.height.toDouble(),
      );
      for (var x = -parallax; x < screenWidth; x += drawW) {
        canvas.drawImageRect(
          bg,
          source,
          ui.Rect.fromLTWH(x, 0, drawW, drawH),
          _backdropPaint,
        );
      }
      canvas.drawRect(screen, _gradePaint);
    }

    // 720 world units span the short side, so portrait and landscape both work.
    final worldScale = math.min(screenWidth, screenHeight) / 720;
    final visibleWidth = screenWidth / worldScale;
    final visibleHeight = screenHeight / worldScale;
    final cameraLeft = (_cameraX - visibleWidth * 0.42)
        .clamp(0.0, math.max(0.0, _length - visibleWidth))
        .toDouble();
    final cameraTop = (_cameraY - math.min(visibleHeight * 0.5, 500.0))
        .toDouble();
    final shakeAmount = _shake * _shake * 11;
    canvas.save();
    if (shakeAmount > 0.05) {
      canvas.translate(
        math.sin(_clock * 67) * shakeAmount,
        math.cos(_clock * 53) * shakeAmount,
      );
    }
    canvas.scale(worldScale);
    canvas.translate(-cameraLeft, -cameraTop);
    _queueLightShafts(cameraLeft, cameraTop, visibleWidth, visibleHeight);
    _glows.flush(canvas, _glowPaint);
    _drawScenery(canvas);
    _drawPlatforms(canvas);
    _drawCheckpoints(canvas);
    _drawHazards(canvas);
    _queueGroundShadows();
    _shadows.flush(canvas, _shadowPaint);
    _drawEnemies(canvas);
    _drawShots(canvas);
    _queueVenomBursts();
    _queueBossShots();
    if (_level['chase'] == true) {
      _drawLava(canvas, cameraTop, visibleHeight);
    }
    _drawPlayer(canvas);
    _drawEffects(canvas);
    queueAmbientMotes(
      _glows,
      count: 22,
      left: cameraLeft,
      top: cameraTop,
      width: visibleWidth,
      height: visibleHeight,
      time: _clock,
      rgb: _accentColor.toARGB32(),
      rise: _area == 9 ? 46 : 14,
      radius: 9,
      alpha: 0.5,
      seed: _area,
    );
    _particles.queue(_glows);
    _glows.flush(canvas, _glowPaint);
    canvas.restore();
    canvas.drawRect(screen, _vignettePaint);
    if (_hurtFlash > 0) {
      canvas.drawRect(
        screen,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            screen.center,
            screen.longestSide * 0.6,
            [
              const ui.Color(0x00ff1e1e),
              const ui.Color(0xffd01818).withValues(alpha: _hurtFlash),
            ],
            const [0.55, 1],
          ),
      );
    }
  }

  final ui.Paint _backdropPaint = ui.Paint()
    ..filterQuality = ui.FilterQuality.low;

  /// Soft pools of light in the area's colour, drifting slower than the world.
  void _queueLightShafts(double left, double top, double width, double height) {
    final rgb = _primaryColor.toARGB32();
    for (var i = 0; i < 3; i++) {
      final x = left + width * (0.2 + i * 0.3) - (left * 0.04) % 240;
      final pulse = 0.5 + 0.5 * math.sin(_clock * 0.5 + i * 2.1);
      _glows.add(
        x,
        top + height * 0.14,
        height * (0.42 + i * 0.05),
        glowColor(rgb, 0.05 + pulse * 0.05),
      );
    }
  }

  /// Contact shadows ground the hero and walkers on the ledges.
  void _queueGroundShadows() {
    final footY = _grounded ? _playerY : _platformYBelow(_playerX);
    final height = (footY - _playerY).abs();
    if (height < 420) {
      _shadows.add(
        _playerX,
        footY + 4,
        62 * (1 - height / 700),
        glowColor(0, 0.5 * (1 - height / 420)),
      );
    }
    for (final enemy in _enemies) {
      if (!enemy.active || !_groundsAt.contains(enemy.type)) continue;
      if ((enemy.x - _cameraX).abs() > 750) continue;
      _shadows.add(enemy.x, enemy.baseY + 4, 58, glowColor(0, 0.42));
    }
  }

  ui.Picture _recordPlatform(_Platform platform) {
    final endY = platform.endY ?? platform.y;
    final top = math.min(platform.y, endY) - 4;
    final bottom = math.max(platform.y, endY) + 120;
    final recorder = ui.PictureRecorder();
    _drawPlatform(
      ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(
          platform.x - 90,
          top - 60,
          platform.width + 180,
          bottom - top + 140,
        ),
      ),
      platform,
    );
    return recorder.endRecording();
  }

  void _clearPlatformPictures() {
    for (final picture in _platformPictures.values) {
      picture.dispose();
    }
    _platformPictures.clear();
  }

  /// Tiled ledges are one image draw. Hand-drawn ones (the area without tile
  /// art) are recorded when they come into view and dropped once far behind.
  void _drawPlatforms(ui.Canvas canvas) {
    final tile = _tileFile == null ? null : _store.sheet(_tileFile!);
    for (final platform in _platforms) {
      final visible =
          platform.enabled &&
          platform.x + platform.width >= _cameraX - 800 &&
          platform.x <= _cameraX + 1400;
      if (!visible) {
        if (tile == null) _platformPictures.remove(platform)?.dispose();
        continue;
      }
      if (tile != null) {
        _drawTiledPlatform(canvas, platform, tile);
      } else {
        canvas.drawPicture(
          _platformPictures[platform] ??= _recordPlatform(platform),
        );
      }
    }
  }

  void _drawPlatform(ui.Canvas canvas, _Platform platform) {
    final groundColor = _groundColor;
    final glow = _primaryColor;
    final accent = _accentColor;
    final soil = ui.Color.lerp(const ui.Color(0xffa77b49), accent, 0.12)!;
    final deepSoil = ui.Color.lerp(
      const ui.Color(0xff30251c),
      groundColor,
      0.22,
    )!;
    final endY = platform.endY ?? platform.y;
    final shadow = ui.Path()
      ..moveTo(platform.x + 4, platform.y + 16)
      ..lineTo(platform.x + platform.width, endY + 16)
      ..lineTo(platform.x + platform.width, endY + 112)
      ..lineTo(platform.x + 4, platform.y + 112)
      ..close();
    canvas.drawPath(shadow, ui.Paint()..color = const ui.Color(0x99060c09));
    final path = ui.Path()
      ..moveTo(platform.x, platform.y)
      ..lineTo(platform.x + platform.width, endY)
      ..lineTo(platform.x + platform.width, endY + 104)
      ..lineTo(platform.x, platform.y + 104)
      ..close();
    canvas.drawPath(
      path,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(platform.x, platform.y),
          ui.Offset(platform.x, platform.y + 104),
          [ui.Color.lerp(glow, groundColor, 0.18)!, soil, deepSoil],
          const [0, 0.32, 1],
        ),
    );
    canvas.drawLine(
      ui.Offset(platform.x, platform.y + 13),
      ui.Offset(platform.x + platform.width, endY + 13),
      ui.Paint()
        ..color = const ui.Color(0xff402c1e)
        ..strokeWidth = 24
        ..strokeCap = ui.StrokeCap.round,
    );
    canvas.drawLine(
      ui.Offset(platform.x, platform.y + 9),
      ui.Offset(platform.x + platform.width, endY + 9),
      ui.Paint()
        ..color = ui.Color.lerp(
          glow,
          const ui.Color(0xff89bd4c),
          0.4,
        )!.withValues(alpha: 0.98)
        ..strokeWidth = 12
        ..strokeCap = ui.StrokeCap.round,
    );
    canvas.drawLine(
      ui.Offset(platform.x, platform.y + 22),
      ui.Offset(platform.x + platform.width, endY + 22),
      ui.Paint()
        ..color = const ui.Color(0x66f2cf8b)
        ..strokeWidth = 2,
    );

    // Fine dirt strata, exposed roots and stones make each ledge read as a
    // continuous traversable ground lane rather than a flat colored block.
    for (var layer = 0; layer < 2; layer++) {
      final yOffset = 36.0 + layer * 23;
      final strata = ui.Path()
        ..moveTo(platform.x + 18, platform.surfaceAt(platform.x + 18) + yOffset)
        ..quadraticBezierTo(
          platform.x + platform.width * 0.48,
          platform.y + yOffset + (layer == 0 ? 9 : -7),
          platform.x + platform.width - 18,
          platform.surfaceAt(platform.x + platform.width - 18) + yOffset,
        );
      canvas.drawPath(
        strata,
        ui.Paint()
          ..color = (layer == 0 ? accent : const ui.Color(0xffd0a26c))
              .withValues(alpha: 0.42)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = layer == 0 ? 2 : 3,
      );
    }
    for (
      var offset = 34.0, detail = 0;
      offset < platform.width - 24;
      offset += 112, detail++
    ) {
      final x = platform.x + offset;
      final surfaceY = platform.surfaceAt(x);
      final grass = ui.Path()
        ..moveTo(x - 8, surfaceY + 3)
        ..lineTo(x - 4, surfaceY - (8 + detail % 3 * 3))
        ..lineTo(x, surfaceY + 3)
        ..lineTo(x + 5, surfaceY - (7 + detail % 2 * 4))
        ..lineTo(x + 10, surfaceY + 4)
        ..close();
      canvas.drawPath(grass, ui.Paint()..color = glow.withValues(alpha: 0.8));
      final stoneY = surfaceY + 38 + detail % 3 * 8;
      canvas.drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(x + 36, stoneY),
          width: 13 + detail % 3 * 4,
          height: 7,
        ),
        ui.Paint()..color = const ui.Color(0xffd2b487).withValues(alpha: 0.7),
      );
    }
  }

  /// Draws a platform with the area's own tile art: end caps once, and the
  /// middle slice repeated so long ledges don't stretch the artwork.
  void _drawTiledPlatform(
    ui.Canvas canvas,
    _Platform platform,
    SheetInfo tile,
  ) {
    final endY = platform.endY ?? platform.y;
    final dx = platform.width;
    final dy = endY - platform.y;
    final length = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);

    // The source is one complete ledge illustration. Its top and bottom
    // include matte/background pixels, so crop to the painted ledge itself.
    final cell = tile.cell(0, 0);
    final src = ui.Rect.fromLTRB(
      cell.left,
      cell.top + cell.height * 0.17,
      cell.right,
      cell.top + cell.height * 0.72,
    );
    const drawHeight = 150.0;
    final top = -drawHeight * 0.22;
    final paint = _spritePaint..color = const ui.Color(0xffffffff);
    canvas.save();
    canvas.translate(platform.x, platform.y);
    canvas.rotate(angle);
    canvas.drawImageRect(
      tile.image,
      src,
      ui.Rect.fromLTWH(0, top, length, drawHeight),
      paint,
    );
    canvas.restore();
  }

  void _buildScenery() {
    _scenery.clear();
    final id = (_level['id'] as num).toInt();
    final props = _level['props'] as String?;
    final expProps =
        'area_${id.toString().padLeft(2, '0')}_exp_props-transparent.webp';
    final files = [
      if (props != null && _store.sheet(props) != null) props,
      if (_store.sheet(expProps) != null) expProps,
    ];
    if (files.isEmpty) return;
    var seed = _area * 7919 + 13;
    int next(int n) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return (seed >> 8) % n;
    }

    for (final platform in _platforms) {
      if (platform.width < 380) continue;
      final count = (platform.width / 650).floor().clamp(1, 6);
      for (var i = 0; i < count; i++) {
        final x =
            platform.x + platform.width * (i + 0.5) / count + next(90) - 45;
        if (x < platform.x + 90 || x > platform.x + platform.width - 90) {
          continue;
        }
        final blocked =
            _hazards.any((h) => h.type != 'spikes' && (h.x - x).abs() < 150) ||
            _checkpointXs.any((c) => (c - x).abs() < 130);
        if (blocked) continue;
        _scenery.add(
          _Scenery(
            files[next(files.length)],
            next(6),
            x,
            platform.surfaceAt(x) + 34,
            110.0 + next(60),
            next(2) == 0,
          ),
        );
      }
    }
  }

  void _drawScenery(ui.Canvas canvas) {
    for (final item in _scenery) {
      if ((item.x - _cameraX).abs() > 1100) continue;
      final sheet = _store.sheet(item.file);
      if (sheet == null) continue;
      final col = item.cell % sheet.cols;
      final row = item.cell ~/ sheet.cols;
      _drawCell(
        canvas,
        sheet,
        col,
        row,
        item.x,
        item.y,
        item.size,
        flip: item.flip,
        alpha: 0.92,
        ref: sheet.content(col, row).size,
      );
    }
  }

  final ui.Paint _spritePaint = ui.Paint()
    ..filterQuality = ui.FilterQuality.medium;

  /// Draws one trimmed sheet cell, scaled so the row's largest frame is
  /// [size] world units, anchored bottom-centre (or centred).
  void _drawCell(
    ui.Canvas canvas,
    SheetInfo sheet,
    int col,
    int row,
    double x,
    double y,
    double size, {
    bool center = false,
    bool flip = false,
    double alpha = 1,
    ui.Size? ref,
  }) {
    final src = sheet.content(col, row);
    final reference = ref ?? sheet.rowMax(row);
    final scale = size / math.max(reference.width, reference.height);
    final w = src.width * scale;
    final h = src.height * scale;
    _spritePaint.color = ui.Color.fromRGBO(
      255,
      255,
      255,
      alpha.clamp(0.0, 1.0),
    );
    canvas.save();
    canvas.translate(x, y);
    if (flip) canvas.scale(-1, 1);
    canvas.drawImageRect(
      sheet.image,
      src,
      center
          ? ui.Rect.fromCenter(center: ui.Offset.zero, width: w, height: h)
          : ui.Rect.fromLTWH(-w / 2, -h, w, h),
      _spritePaint,
    );
    canvas.restore();
  }

  void _fx(
    String file,
    int row,
    double x,
    double y,
    double size, {
    int cols = 5,
    int rows = 4,
    int? frame,
    int frames = 5,
    int firstFrame = 0,
    double duration = 0.45,
    double direction = 1,
    bool center = true,
    double rise = 0,
    bool fade = false,
  }) {
    if (_store.sheet(file) == null) return;
    if (_effects.length > 48) _effects.removeAt(0);
    _effects.add(
      _Effect(
        file,
        row,
        x,
        y,
        size,
        cols: cols,
        rows: rows,
        frame: frame,
        frames: frames,
        firstFrame: firstFrame,
        duration: duration,
        direction: direction,
        center: center,
        rise: rise,
        fade: fade,
      ),
    );
  }

  void _drawEffects(ui.Canvas canvas) {
    for (final effect in _effects) {
      final sheet = _store.sheet(effect.file);
      if (sheet == null) continue;
      final t = (effect.age / effect.duration).clamp(0.0, 0.999);
      final col =
          effect.frame ??
          (effect.firstFrame + (t * effect.frames).floor()).clamp(
            0,
            sheet.cols - 1,
          );
      _drawCell(
        canvas,
        sheet,
        col,
        effect.row,
        effect.x,
        effect.y - effect.rise * t,
        effect.size,
        center: effect.center,
        flip: effect.direction < 0,
        alpha: effect.fade ? 1 - t : 1,
      );
    }
  }

  static const _impactsFile = 'fx_impacts-transparent.webp';
  static const _finalFile = 'fx_final-transparent.webp';
  static const _worldAFile = 'fx_world_a-transparent.webp';
  static const _worldBFile = 'fx_world_b-transparent.webp';
  static const _worldCFile = 'fx_world_c-transparent.webp';
  static const _valveFile = 'prop_valve_anim-transparent.webp';

  /// Which sheet row draws a given hazard type (same in every area, so a
  /// gate always looks like a gate); [halo] colours interactive hints.
  ({String file, int col, int row, double size, ui.Color? halo})? _hazardSpec(
    _Hazard hazard,
  ) {
    switch (hazard.type) {
      case 'spikes':
        final file = _propsFile;
        return file == null
            ? null
            : (file: file, col: 2, row: 0, size: 120, halo: null);
      case 'wall':
        return (file: _impactsFile, col: 0, row: 2, size: 150, halo: null);
      case 'venomWall':
      case 'iceWall':
        return (file: _worldCFile, col: 0, row: 0, size: 150, halo: null);
      case 'gate':
      case 'puzzleGate':
        return (file: _finalFile, col: 0, row: 3, size: 210, halo: null);
      case 'pillar':
        return (file: _finalFile, col: 0, row: 1, size: 210, halo: null);
      case 'mushroom':
        return (file: _worldBFile, col: 0, row: 2, size: 105, halo: null);
      case 'venomSwitch':
        return (
          file: _worldBFile,
          col: 0,
          row: 1,
          size: 105,
          halo: const ui.Color(0xff83ff4f),
        );
      case 'cocoon':
        final file = _expFxFile;
        return file == null
            ? null
            : (
                file: file,
                col: 0,
                row: 1,
                size: 110,
                halo: const ui.Color(0xff83ff4f),
              );
      case 'switch':
        final file = _expFxFile;
        return file == null
            ? null
            : (
                file: file,
                col: 0,
                row: 3,
                size: 115,
                halo: const ui.Color(0xffffd260),
              );
      case 'momentumSwitch':
        final file = _expFxFile;
        return file == null
            ? null
            : (
                file: file,
                col: 0,
                row: 0,
                size: 125,
                halo: const ui.Color(0xffff884f),
              );
      case 'block':
        return (
          file: _worldCFile,
          col: 0,
          row: 3,
          size: 115,
          halo: const ui.Color(0xffff884f),
        );
      case 'ceiling':
        return (file: _worldAFile, col: 0, row: 0, size: 150, halo: null);
    }
    return null;
  }

  bool _isValve(_Hazard hazard) =>
      hazard.type == 'switch' &&
      (hazard.activates?.startsWith('gasLift') ?? false);

  void _deactivate(_Hazard hazard, {bool fx = true}) {
    final wasActive = hazard.active;
    hazard.active = false;
    if (!fx || !wasActive || hazard.type == 'mushroom' || _isValve(hazard)) {
      return;
    }
    const breakable = {
      'wall',
      'venomWall',
      'iceWall',
      'cocoon',
      'pillar',
      'block',
      'ceiling',
    };
    if (breakable.contains(hazard.type)) {
      _audio.sfx('break');
    } else if (hazard.type == 'gate' || hazard.type == 'puzzleGate') {
      _audio.sfx('gate');
    }
    final spec = _hazardSpec(hazard);
    if (spec == null) return;
    _fx(
      spec.file,
      spec.row,
      hazard.x,
      hazard.y + 4,
      spec.size,
      firstFrame: 1,
      frames: 4,
      duration: 0.5,
      center: false,
    );
  }

  bool _drawHazardSprite(ui.Canvas canvas, _Hazard hazard) {
    if (hazard.type == 'wind' || hazard.type == 'updraft') {
      final sheet = _store.sheet(_worldAFile);
      if (sheet == null) return false;
      if (!hazard.enabled) return true;
      for (var i = 0; i < 3; i++) {
        final phase = (_clock * 0.7 + i / 3) % 1;
        _drawCell(
          canvas,
          sheet,
          (_clock * 6 + i).floor() % 5,
          2,
          hazard.x + 95 + (i - 1) * 46,
          hazard.y - 20 - phase * 240,
          120,
          alpha: math.sin(math.pi * phase) * 0.7,
        );
      }
      return true;
    }
    if (_isValve(hazard)) {
      final sheet = _store.sheet(_valveFile);
      if (sheet == null) return false;
      _drawCell(
        canvas,
        sheet,
        0,
        0,
        hazard.x,
        hazard.y + 4,
        120,
        ref: sheet.content(0, 0).size,
      );
      _drawHalo(canvas, hazard.x, hazard.y - 60, const ui.Color(0xffffd260));
      return true;
    }
    final spec = _hazardSpec(hazard);
    if (spec == null) return false;
    final sheet = _store.sheet(spec.file);
    if (sheet == null) return false;
    var col = 0;
    if (hazard.type == 'mushroom' && hazard.flash > 0) {
      col = 1 + ((0.5 - hazard.flash) / 0.5 * 3).floor().clamp(0, 2);
    }
    _drawCell(
      canvas,
      sheet,
      hazard.type == 'mushroom' ? col : spec.col,
      spec.row,
      hazard.x,
      hazard.y + 4,
      spec.size,
    );
    final halo = spec.halo;
    if (halo != null) {
      _drawHalo(canvas, hazard.x, hazard.y - spec.size * 0.5, halo);
    }
    return true;
  }

  void _drawHalo(ui.Canvas canvas, double x, double y, ui.Color color) {
    final pulse = 0.5 + 0.5 * math.sin(_clock * 4);
    _glows.add(x, y, 58 + 12 * pulse, glowColor(color.toARGB32(), 0.5 + 0.2 * pulse));
  }

  void _drawCheckpoints(ui.Canvas canvas) {
    final accent = _accentColor;
    for (var i = 1; i <= _checkpointXs.length; i++) {
      final x = _checkpointXs[i - 1];
      if ((x - _cameraX).abs() > 1000) continue;
      final y = _checkpointYs[i - 1];
      final active = i <= _checkpoint;
      final hudSheet = _store.sheet('hud_atlas-transparent.webp');
      if (hudSheet != null) {
        if (active) {
          _glows.add(x + 16, y - 62, 86, glowColor(accent.toARGB32(), 0.5));
        }
        _drawCell(
          canvas,
          hudSheet,
          2,
          1,
          x,
          y + 6,
          118,
          alpha: active ? 1 : 0.5,
          ref: hudSheet.content(2, 1).size,
        );
        continue;
      }
      canvas.drawLine(
        ui.Offset(x, y),
        ui.Offset(x, y - 82),
        ui.Paint()
          ..color = const ui.Color(0xff242d28)
          ..strokeWidth = 7,
      );
      final flag = ui.Path()
        ..moveTo(x, y - 80)
        ..lineTo(x + 52, y - 67)
        ..lineTo(x, y - 52)
        ..close();
      canvas.drawPath(
        flag,
        ui.Paint()..color = active ? accent : accent.withValues(alpha: 0.42),
      );
      if (active) {
        canvas.drawCircle(
          ui.Offset(x, y - 66),
          38,
          ui.Paint()..color = accent.withValues(alpha: 0.15),
        );
      }
    }
  }

  /// Translucent force field rising from a locked gate / portal to the sky,
  /// so it reads as "can't jump over this until the puzzle is solved".
  void _drawBarrier(ui.Canvas canvas, _Hazard hazard, ui.Color color) {
    const top = -1400.0;
    final bottom = hazard.y + 10;
    // Stacked bands fake the beam's soft edge without a gradient per frame.
    final band = _barrierPaint;
    for (final (half, alpha) in const [(30.0, 0.05), (18.0, 0.07), (7.0, 0.12)]) {
      band.color = color.withValues(alpha: alpha);
      canvas.drawRect(
        ui.Rect.fromLTRB(hazard.x - half, top, hazard.x + half, bottom),
        band,
      );
    }
    band.color = color.withValues(alpha: 0.55);
    canvas.drawRect(
      ui.Rect.fromLTRB(hazard.x - 1, top, hazard.x + 1, bottom),
      band,
    );
    // Rising sparks so the field shimmers.
    final rgb = color.toARGB32();
    for (var i = 0; i < 10; i++) {
      final y = bottom - ((_clock * 90 + i * 137) % (bottom - top));
      final x = hazard.x + math.sin(_clock * 3 + i) * 18;
      _glows.add(x, y, 9, glowColor(rgb, 0.8));
    }
  }

  final ui.Paint _barrierPaint = ui.Paint();

  void _drawHazards(ui.Canvas canvas) {
    final accent = _accentColor;
    final primary = _primaryColor;
    for (final hazard in _hazards) {
      if (!hazard.active || (hazard.x - _cameraX).abs() > 1100) continue;
      if (hazard.type == 'gate' || hazard.type == 'puzzleGate') {
        _drawBarrier(canvas, hazard, accent);
      }
      if (_drawHazardSprite(canvas, hazard)) continue;
      switch (hazard.type) {
        case 'spikes':
          final spikes = ui.Path()..moveTo(hazard.x - 60, hazard.y + 5);
          for (var i = 0; i < 5; i++) {
            spikes
              ..lineTo(hazard.x - 55 + i * 26, hazard.y - (i.isEven ? 42 : 30))
              ..lineTo(hazard.x - 34 + i * 26, hazard.y + 5);
          }
          spikes.close();
          canvas.drawPath(spikes, ui.Paint()..color = accent);
          break;
        case 'wall':
        case 'venomWall':
        case 'iceWall':
        case 'gate':
        case 'puzzleGate':
        case 'pillar':
          final wallColor = hazard.type == 'venomWall' ? primary : accent;
          final rect = ui.Rect.fromCenter(
            center: ui.Offset(hazard.x, hazard.y - 72),
            width: 72,
            height: 180,
          );
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(16)),
            ui.Paint()..color = wallColor.withValues(alpha: 0.55),
          );
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              rect.deflate(8),
              const ui.Radius.circular(12),
            ),
            ui.Paint()
              ..color = wallColor
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 4,
          );
          break;
        case 'mushroom':
          canvas.drawOval(
            ui.Rect.fromCenter(
              center: ui.Offset(hazard.x, hazard.y - 17),
              width: 76,
              height: 34,
            ),
            ui.Paint()..color = primary,
          );
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromCenter(
                center: ui.Offset(hazard.x, hazard.y + 3),
                width: 28,
                height: 34,
              ),
              const ui.Radius.circular(9),
            ),
            ui.Paint()..color = const ui.Color(0xffffe0a5),
          );
          break;
        case 'wind':
        case 'updraft':
          final paint = ui.Paint()
            ..color = primary.withValues(alpha: 0.27)
            ..strokeWidth = 15;
          for (var i = 0; i < 4; i++) {
            canvas.drawLine(
              ui.Offset(hazard.x + i * 18, hazard.y - 240),
              ui.Offset(hazard.x + i * 18, hazard.y - 15),
              paint,
            );
          }
          break;
        case 'switch':
        case 'venomSwitch':
        case 'momentumSwitch':
        case 'cocoon':
        case 'block':
        case 'ceiling':
        case 'valve':
          canvas.drawCircle(
            ui.Offset(hazard.x, hazard.y - 24),
            24,
            ui.Paint()..color = accent.withValues(alpha: 0.82),
          );
          canvas.drawCircle(
            ui.Offset(hazard.x, hazard.y - 24),
            35,
            ui.Paint()
              ..color = accent.withValues(alpha: 0.25)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 5,
          );
          break;
      }
    }
  }

  void _drawEnemies(ui.Canvas canvas) {
    const sizes = <String, double>{
      'frog': 105,
      'spider': 120,
      'bat': 110,
      'scorpion': 145,
      'spore': 88,
      'drone': 115,
      'sentinel': 190,
      'prism_leviathan': 290,
      'world_serpent': 310,
    };
    for (final enemy in _enemies) {
      if (!enemy.active || (enemy.x - _cameraX).abs() > 1100) continue;
      if (enemy.type == 'prism_leviathan' || enemy.type == 'world_serpent') {
        _drawBigBoss(canvas, enemy, sizes[enemy.type]!);
        continue;
      }
      var file = _enemyFile;
      // Enraged mini-bosses switch to their battle-worn "_b" look.
      if (enemy.boss &&
          file != null &&
          (enemy.type == 'scorpion' || enemy.type == 'sentinel') &&
          enemy.hp <= 2) {
        final alt = file.replaceFirst('_a-', '_b-');
        if (_store.sheet(alt) != null) file = alt;
      }
      final sheet = file == null ? null : _store.sheet(file);
      if (sheet != null) {
        var size = sizes[enemy.type] ?? 110.0;
        if (enemy.boss && size < 200) size *= 1.25;
        var col = (_clock * 7).floor() % 5;
        var row = 0;
        final lift = enemy.baseY - enemy.y;
        if (enemy.type == 'frog' && lift > 18) {
          row = 2;
          col = lift > 70 ? 2 : 1;
        }
        final flip = enemy.x < _playerX;
        canvas.save();
        canvas.translate(enemy.x, enemy.y);
        if (flip) canvas.scale(-1, 1);
        final drawn = size * SheetInfo.overflowScale;
        canvas.drawImageRect(
          sheet.image,
          sheet.content(col, row),
          ui.Rect.fromCenter(
            center: ui.Offset(0, -size * 0.34),
            width: drawn,
            height: drawn,
          ),
          _spritePaint..color = const ui.Color(0xffffffff),
        );
        canvas.restore();
      } else {
        canvas.drawCircle(
          ui.Offset(enemy.x, enemy.y - 28),
          30,
          ui.Paint()..color = const ui.Color(0xffed684d),
        );
        canvas.drawCircle(
          ui.Offset(enemy.x + 9, enemy.y - 37),
          5,
          ui.Paint()..color = const ui.Color(0xffffffff),
        );
      }
    }
  }

  /// Big bosses pick a pose row from what they're doing instead of looping
  /// one row: idle, hurt flinch, charge-up and firing. Frames are trimmed at
  /// load, scaled against the idle row and anchored at the back of the body
  /// so wide beam frames don't shove the creature sideways.
  void _drawBigBoss(ui.Canvas canvas, _Enemy enemy, double size) {
    final number = enemy.type == 'prism_leviathan' ? '15' : '20';
    final a = _store.sheet('boss_${number}_a-transparent.webp');
    if (a == null) return;
    final enraged = enemy.hp <= 5;
    final b = _store.sheet('boss_${number}_b-transparent.webp');
    final idle = (enemy.time * 6).floor() % 5;
    final charging =
        enemy.attackTimer < 0.55 && (enemy.x - _playerX).abs() <= 820;
    var sheet = a;
    int row, col;
    if (enemy.hurtTime > 0) {
      row = 1;
      col = 2;
    } else if (enemy.fireTime > 0) {
      final t = 1 - enemy.fireTime / 0.45;
      if (number == '15') {
        row = 2;
        col = (1 + t * 3).floor().clamp(1, 3);
      } else {
        row = 3;
        col = (2 + t * 2).floor().clamp(2, 3);
      }
    } else if (charging) {
      row = number == '15' ? 2 : 3;
      col = number == '15' ? 0 : 1;
    } else if (enraged && b != null) {
      sheet = b;
      row = 0;
      col = idle;
    } else {
      row = 0;
      col = idle;
    }
    final ref = a.rowMax(0);
    final scale = size * 1.25 / math.max(ref.width, ref.height);
    final src = sheet.content(col, row);
    final w = src.width * scale;
    final h = src.height * scale;
    // Sheets face left; flip so the head points at the player.
    final flip = enemy.x < _playerX;
    final bob = math.sin(enemy.time * 2) * 6;
    final shake = enemy.hurtTime > 0 ? math.sin(enemy.time * 90) * 5 : 0.0;
    canvas.save();
    canvas.translate(enemy.x + shake, enemy.y + bob);
    if (flip) canvas.scale(-1, 1);
    final back = ref.width * scale / 2;
    _spritePaint.color =
        enemy.hurtTime > 0 && (enemy.hurtTime * 20).floor().isEven
        ? const ui.Color(0xccffffff)
        : const ui.Color(0xffffffff);
    canvas.drawImageRect(
      sheet.image,
      src,
      ui.Rect.fromLTWH(back - w, -h, w, h),
      _spritePaint,
    );
    canvas.restore();
    _spritePaint.color = const ui.Color(0xffffffff);
  }

  void _drawShots(ui.Canvas canvas) {
    final sheet = _store.sheet(_fxFile);
    for (final shot in _shots) {
      if (sheet != null) {
        _drawCell(
          canvas,
          sheet,
          (shot.age * 14).floor() % 5,
          0,
          shot.x,
          shot.y,
          84,
          center: true,
          flip: shot.velocityX < 0,
        );
        continue;
      }
      canvas.drawCircle(
        ui.Offset(shot.x, shot.y),
        17,
        ui.Paint()..color = const ui.Color(0xff9fff52).withValues(alpha: 0.32),
      );
      canvas.drawCircle(
        ui.Offset(shot.x, shot.y),
        9,
        ui.Paint()..color = const ui.Color(0xffbaff55),
      );
    }
  }

  /// Venom splash where a glob lands: skin-coloured bloom and droplets.
  void _queueVenomBursts() {
    final rgb = _skinRgb;
    for (final burst in _venomBursts) {
      final t = (burst.age / _VenomBurst.duration).clamp(0.0, 1.0);
      final fade = 1 - t;
      _glows.add(burst.x, burst.y, 34 + t * 70, glowColor(rgb, 0.8 * fade));
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3 + 0.3;
        final d = 14 + t * 46;
        _glows.add(
          burst.x + math.cos(a) * d,
          burst.y + math.sin(a) * d,
          7 * fade + 3,
          glowColor(rgb, fade),
        );
      }
    }
  }

  void _queueBossShots() {
    // Wind-up glow so the player can read the next shot coming.
    for (final enemy in _bosses) {
      if (!enemy.active || enemy.attackTimer > 0.55) continue;
      if ((enemy.x - _playerX).abs() > 820) continue;
      final charge = 1 - enemy.attackTimer / 0.55;
      _glows.add(
        enemy.x,
        enemy.y - 95,
        30 + charge * 44,
        glowColor(0xff5b2e, 0.4 + charge * 0.6),
      );
    }
    for (final shot in _bossShots) {
      if ((shot.x - _cameraX).abs() > 1100) continue;
      final angle = math.atan2(shot.vy, shot.vx);
      final tailX = math.cos(angle) * 14;
      final tailY = math.sin(angle) * 14;
      for (var i = 4; i >= 1; i--) {
        _glows.add(
          shot.x - tailX * i,
          shot.y - tailY * i,
          26 - i * 4.0,
          glowColor(0xff7a2e, 0.14 * (5 - i)),
        );
      }
      _glows.add(shot.x, shot.y, 40, glowColor(0xff4a1c, 0.8));
      _glows.add(shot.x, shot.y, 18, glowColor(0xfff2b0, 1));
    }
  }

  void _drawLava(
    ui.Canvas canvas,
    double top,
    double height,
  ) {
    final t = _clock;
    final wallTop = top - 250;
    final wallBottom = top + height + 250;
    final edge = _lavaX + 60;

    // Advancing wall: molten gradient with a rippling, glowing front edge.
    final wall = ui.Path()..moveTo(_lavaX - 220, wallTop);
    wall.lineTo(edge, wallTop);
    for (var y = wallTop; y <= wallBottom; y += 18) {
      wall.lineTo(
        edge +
            math.sin(y * 0.045 + t * 3.2) * 14 +
            math.sin(y * 0.11 - t * 5) * 6,
        y,
      );
    }
    wall.lineTo(_lavaX - 220, wallBottom);
    wall.close();
    canvas.drawPath(
      wall,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(_lavaX - 220, 0),
          ui.Offset(edge, 0),
          const [
            ui.Color(0xff3a0a05),
            ui.Color(0xffc2300c),
            ui.Color(0xffff7a1c),
            ui.Color(0xffffd36a),
          ],
          const [0, 0.45, 0.85, 1],
        ),
    );

    // Floor lava: layered waves, bright crest line, glow above the surface.
    final floorWidth = _length + 300;
    final floorLeft = _lavaX - 80;
    final waveStart = (_cameraX - 900).clamp(floorLeft, floorLeft + floorWidth);
    final waveEnd = (_cameraX + 1500).clamp(floorLeft, floorLeft + floorWidth);
    canvas.drawRect(
      ui.Rect.fromLTWH(floorLeft, _lavaY - 120, floorWidth, 120),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, _lavaY - 120),
          ui.Offset(0, _lavaY),
          const [ui.Color(0x00ff5a14), ui.Color(0x66ff6a1a)],
        ),
    );
    const topColors = [
      ui.Color(0xffffd36a),
      ui.Color(0xffff9a2a),
      ui.Color(0xffd23a0a),
    ];
    const bottomColors = [
      ui.Color(0xffff7a1c),
      ui.Color(0xffc2300c),
      ui.Color(0xff6a1305),
    ];
    for (var layer = 0; layer < 3; layer++) {
      final base = _lavaY + layer * 14;
      final path = ui.Path()..moveTo(waveStart, base + 440);
      for (var x = waveStart; x <= waveEnd; x += 16) {
        path.lineTo(
          x,
          base +
              math.sin(x * 0.02 + t * (2.2 + layer * 0.7) + layer * 2) *
                  (9 - layer * 2) +
              math.sin(x * 0.05 - t * 3.1) * 3,
        );
      }
      path.lineTo(waveEnd, base + 440);
      path.close();
      canvas.drawPath(
        path,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            ui.Offset(0, base - 12),
            ui.Offset(0, base + 120),
            [topColors[layer], bottomColors[layer]],
          ),
      );
    }
    final crest = ui.Path();
    for (var x = waveStart; x <= waveEnd; x += 16) {
      final y =
          _lavaY +
          math.sin(x * 0.02 + t * 2.2) * 9 +
          math.sin(x * 0.05 - t * 3.1) * 3;
      x == waveStart ? crest.moveTo(x, y) : crest.lineTo(x, y);
    }
    canvas.drawPath(
      crest,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const ui.Color(0x55fff0a8),
    );
    canvas.drawPath(
      crest,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const ui.Color(0xfffff0a8),
    );

    // Bubbles popping on the surface and embers drifting upward.
    for (var i = 0; i < 18; i++) {
      final seed = i * 91.7;
      final x = _cameraX - 700 + ((seed * 13.1 + t * (18 + i % 4 * 7)) % 1900);
      final pop = (t * 0.6 + i * 0.37) % 1;
      _glows.add(
        x,
        _lavaY + 4 - math.sin(pop * math.pi) * 10,
        7 + (i % 3) * 3 * math.sin(pop * math.pi),
        glowColor(0xffe08a, 0.85 * (1 - pop)),
      );
    }
    for (var i = 0; i < 34; i++) {
      final seed = i * 57.3;
      final life = (t * (0.18 + i % 5 * 0.04) + seed) % 1;
      final x =
          _cameraX - 700 + ((seed * 31.7) % 1900) + math.sin(t * 2 + seed) * 22;
      _glows.add(
        x,
        _lavaY - life * (260 + i % 4 * 70),
        4.5 + (i % 3) * 1.8,
        glowColor(i.isEven ? 0xffb347 : 0xff5a1f, (1 - life) * 0.9),
      );
    }
    // Embers flying off the advancing wall.
    for (var i = 0; i < 20; i++) {
      final seed = i * 43.9;
      final life = (t * (0.3 + i % 4 * 0.06) + seed) % 1;
      final y = wallTop + ((seed * 17.3) % (wallBottom - wallTop));
      _glows.add(
        edge + life * 150,
        y - life * 40,
        5.0 + (i % 2) * 2,
        glowColor(0xffc15b, (1 - life) * 0.85),
      );
    }
  }

  void _drawPlayer(ui.Canvas canvas) {
    final motionA =
        _store.sheet(_skinFile(_skinIndex, 'motion_a')) ??
        _store.sheet('vexa_motion_a-transparent.webp');
    if (motionA == null) return;
    // Keep the same snake design across actions. Some auxiliary sheets depict
    // a different creature; attacks already have their own separate effects.
    final sheet = motionA;
    var row = 0;
    var col = (_clock * 8).floor() % 5;
    var tilt = 0.0;
    var squash = 1.0;
    if (_dead) {
      row = 2;
      col = 2;
      squash = 0.65;
    } else if (_completed) {
      row = 0;
      tilt = math.sin(_clock * 5) * 0.06;
    } else if (_coil > 0) {
      row = 3;
      col = 2;
      squash = 1 - _coil * 0.2;
    } else if (!_grounded) {
      // The flat dash row reads as a much smaller snake in the air.
      row = 1;
      tilt = _inUpdraft ? -0.22 : (_velocityY / 1600).clamp(-0.22, 0.22);
    } else if (_velocityX.abs() > 330) {
      row = 2;
    } else if (_velocityX.abs() > 26) {
      row = 1;
    }
    if (_actionTime > 0 && _playerAction == 'tail') {
      row = 3;
      col = (2 + (1 - _actionTime / 0.3) * 2).round().clamp(2, 4);
      tilt = math.sin((1 - _actionTime / 0.3) * math.pi) * 0.12;
    }
    // Venom spit: rear back, then lunge the head forward as the glob leaves.
    var spit = -1.0;
    var stretch = 1.0;
    if (_actionTime > 0 && _playerAction == 'venom') {
      spit = 1 - _actionTime / 0.34;
      if (spit < 0.35) {
        row = 3;
        col = 3;
        tilt = -0.14 * (spit / 0.35);
        squash = 1.05;
      } else {
        final lunge = math.sin((spit - 0.35) / 0.65 * math.pi);
        row = 0;
        col = 0;
        tilt = 0.16 * lunge;
        stretch = 1 + 0.1 * lunge;
        squash = 1 - 0.05 * lunge;
      }
    }
    final skinRgb = _skinRgb;
    _glows.add(
      _playerX,
      _playerY - 52,
      92 + _coil * 70,
      glowColor(skinRgb, 0.1 + _coil * 0.45),
    );
    if (_grounded && _velocityX.abs() > 330 && (_clock * 30).floor().isEven) {
      _particles.burst(
        _playerX - _playerDirection * 60,
        _playerY - 8,
        skinRgb,
        count: 1,
        speed: 40,
        life: 0.36,
        size: 12,
        gravity: -60,
      );
    }
    final blink = _invulnerable > 0 && (_invulnerable * 14).floor().isEven;
    _spritePaint.color = ui.Color.fromRGBO(255, 255, 255, blink ? 0.38 : 1);
    canvas.save();
    canvas.translate(_playerX, _playerY);
    if (_playerDirection < 0) canvas.scale(-1, 1);
    canvas.rotate(tilt);
    canvas.scale(stretch, squash);
    final src = sheet.content(col, row);
    final scale = 192 / sheet.cellWidth * sheet.poseScale(row);
    final width = src.width * scale;
    final height = src.height * scale;
    canvas.drawImageRect(
      sheet.image,
      src,
      ui.Rect.fromLTWH(
        -width / 2,
        -height + sheet.footGap(row) * scale,
        width,
        height,
      ),
      _spritePaint,
    );
    if (spit >= 0) {
      // Open the jaw on the same snake sprite while the venom leaves it.
      final mouth = ui.Offset(width * 0.4, -height * 0.76);
      final opening = math.sin((0.15 + spit * 0.85) * math.pi);
      final jaw = ui.Path()
        ..moveTo(mouth.dx - 11, mouth.dy)
        ..quadraticBezierTo(mouth.dx + 2, mouth.dy - 3, mouth.dx + 13, mouth.dy)
        ..quadraticBezierTo(
          mouth.dx + 8,
          mouth.dy + 5 + opening * 13,
          mouth.dx - 8,
          mouth.dy + 3 + opening * 7,
        )
        ..close();
      canvas.drawPath(jaw, ui.Paint()..color = const ui.Color(0xff17231b));
      canvas.drawLine(
        ui.Offset(mouth.dx - 8, mouth.dy + 3 + opening * 7),
        ui.Offset(mouth.dx + 8, mouth.dy + 5 + opening * 13),
        ui.Paint()
          ..color = const ui.Color(0xffb8df80)
          ..strokeWidth = 2.5
          ..strokeCap = ui.StrokeCap.round,
      );
      final burst = math.sin(spit * math.pi);
      final glow = skinColors[_skinIndex.clamp(0, 9)];
      canvas.drawCircle(
        mouth + const ui.Offset(14, 3),
        5 + burst * 18,
        ui.Paint()..color = glow.withValues(alpha: 0.3 * burst),
      );
      canvas.drawCircle(
        mouth + const ui.Offset(14, 3),
        4 + burst * 7,
        ui.Paint()..color = const ui.Color(0xffeaffb0).withValues(alpha: burst),
      );
      for (var i = 0; i < 4; i++) {
        final a = -0.5 + i * 0.33;
        final d = 12 + burst * 26;
        canvas.drawCircle(
          mouth +
              const ui.Offset(14, 3) +
              ui.Offset(math.cos(a) * d, math.sin(a) * d),
          2.5,
          ui.Paint()..color = glow.withValues(alpha: burst * 0.9),
        );
      }
    }
    canvas.restore();
  }

  static ui.Color _parseColor(String value) =>
      ui.Color(int.parse(value.substring(1), radix: 16) | 0xff000000);

  @override
  void onRemove() {
    _clearPlatformPictures();
    _store.release(_stageFiles);
    _store.release(_skinSheetFiles);
    _stageFiles = {};
    _skinSheetFiles = {};
    hud.dispose();
    momentumMeter.dispose();
    coilMeter.dispose();
    attackCooldownMeter.dispose();
    venomCooldownMeter.dispose();
    super.onRemove();
  }
}
