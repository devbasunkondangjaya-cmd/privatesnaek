import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around flame_audio: three volume steps (mute / low / high)
/// shared by music and effects. All calls swallow errors so a device without
/// audio output (or a browser that blocks autoplay) never breaks the game.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  // Music is left out on purpose: each track is cached only while it plays.
  static const _effectFiles = [
    'sfx_ui_click.mp3',
    'sfx_jump.mp3',
    'sfx_land.mp3',
    'sfx_coil.mp3',
    'sfx_bounce.mp3',
    'sfx_attack.mp3',
    'sfx_venom.mp3',
    'sfx_hit.mp3',
    'sfx_defeat.mp3',
    'sfx_hurt.mp3',
    'sfx_death.mp3',
    'sfx_switch.mp3',
    'sfx_break.mp3',
    'sfx_gate.mp3',
    'sfx_bump.mp3',
    'sfx_wind.mp3',
    'sfx_checkpoint.mp3',
    'sfx_complete.mp3',
  ];

  /// Never take audio focus: a focus-grabbing effect pauses the music on
  /// Android, so both effects and music mix with each other.
  static final AudioContext _mixContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  /// 0 = mute, 1 = low, 2 = high. Listen to rebuild volume buttons.
  final ValueNotifier<int> level = ValueNotifier(2);
  String? _music;
  String? _pendingMusic;
  Future<void> _musicTransition = Future.value();
  bool _ready = false;
  final Map<String, Future<AudioPool>> _effectPools = {};
  static const double _musicGain = 0.55;

  double get volume => const [0.0, 0.35, 1.0][level.value];

  Future<void> init(int savedLevel) async {
    level.value = savedLevel.clamp(0, 2);
    try {
      await FlameAudio.audioCache.loadAll(_effectFiles);
      for (final name in ['ui_click', 'jump', 'attack', 'venom', 'hit']) {
        try {
          await _pool(name);
        } catch (_) {
          // Other effects can still play when one pool is unavailable.
        }
      }
      await FlameAudio.bgm.initialize(audioContext: _mixContext);
      _ready = true;
    } catch (_) {}
  }

  /// Cycles high -> low -> mute -> high and returns the new level.
  int cycle() {
    level.value = (level.value + 2) % 3;
    _syncMusicVolume();
    return level.value;
  }

  void sfx(String name) {
    if (!_ready || volume == 0) return;
    unawaited(_playEffect(name, volume));
  }

  /// Every effect plays through a small reusable pool, built on first use;
  /// creating a fresh native player per sound caused hitches mid-game.
  Future<AudioPool> _pool(String name) => _effectPools[name] ??=
      FlameAudio.createPool(
        'sfx_$name.mp3',
        minPlayers: name == 'venom' ? 2 : 1,
        maxPlayers: 3,
        audioContext: _mixContext,
      );

  Future<void> _playEffect(String name, double effectVolume) async {
    try {
      await (await _pool(name)).start(volume: effectVolume);
    } catch (_) {
      _effectPools.remove(name);
    }
  }

  /// A tap may retry a track blocked by browser autoplay, but never restarts
  /// music that is already playing. Transitions run in order.
  Future<void> music(String name) {
    if (!_ready) return Future.value();
    if (_music == name && _appliedVolume >= 0) {
      _syncMusicVolume();
      return Future.value();
    }
    if (_pendingMusic == name) return _musicTransition;
    _music = name;
    _pendingMusic = name;
    final transition = _musicTransition.then((_) async {
      if (_music != name) return;
      try {
        await FlameAudio.bgm.stop();
        // Free the previous track: only the one playing stays cached.
        final previous = _cachedTrack;
        if (previous != null && previous != 'bgm_$name.mp3') {
          await FlameAudio.audioCache.clear(previous);
          _cachedTrack = null;
        }
        if (_music != name) return;
        _appliedVolume = -1;
        if (volume > 0) {
          _cachedTrack = 'bgm_$name.mp3';
          await FlameAudio.bgm.play(
            'bgm_$name.mp3',
            volume: volume * _musicGain,
          );
          _appliedVolume = volume;
        } else {
          _appliedVolume = 0;
        }
      } catch (_) {
        // A later user gesture can retry when autoplay was blocked.
      } finally {
        if (_pendingMusic == name) _pendingMusic = null;
      }
    });
    _musicTransition = transition;
    return transition;
  }

  double _appliedVolume = -1;
  String? _cachedTrack;

  /// Pushes the current volume to the player, only when it actually changed.
  void _syncMusicVolume() {
    if (_music == null || _appliedVolume == volume) return;
    try {
      if (volume == 0) {
        FlameAudio.bgm.pause();
      } else if (_appliedVolume == 0 || _appliedVolume < 0) {
        final name = _music!;
        _music = null;
        unawaited(music(name));
        return;
      } else {
        FlameAudio.bgm.audioPlayer.setVolume(volume * _musicGain);
      }
      _appliedVolume = volume;
    } catch (_) {}
  }

  void pause() {
    try {
      FlameAudio.bgm.pause();
    } catch (_) {}
  }

  void resume() {
    if (volume == 0 || !_ready) return;
    try {
      FlameAudio.bgm.resume();
    } catch (_) {}
  }
}
