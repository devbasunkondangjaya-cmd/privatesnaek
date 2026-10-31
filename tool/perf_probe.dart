// Plays the game by itself and reports real frame timings and decoded art size.
//
// Run it on a real phone, in profile mode (debug builds are always slow):
//   flutter run --profile -t tool/perf_probe.dart
// Results are printed to the console, then the app exits.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/audio_manager.dart';
import 'package:snake/image_store.dart';
import 'package:snake/main.dart';
import 'package:snake/save_data.dart';
import 'package:snake/venomcoil_game.dart';

final List<ui.FrameTiming> _frames = [];

Future<void> _measure(String name, Duration time) async {
  _frames.clear();
  await Future<void>.delayed(time);
  final totals = _frames.map((f) => f.totalSpan.inMicroseconds / 1000).toList()
    ..sort();
  final build = _frames.isEmpty
      ? 0.0
      : _frames.map((f) => f.buildDuration.inMicroseconds / 1000).reduce((a, b) => a + b) /
            _frames.length;
  final raster = _frames.isEmpty
      ? 0.0
      : _frames.map((f) => f.rasterDuration.inMicroseconds / 1000).reduce((a, b) => a + b) /
            _frames.length;
  String p(double q) => totals.isEmpty
      ? '-'
      : totals[math.min(totals.length - 1, (totals.length * q).floor())].toStringAsFixed(1);
  final slow = totals.where((t) => t > 1000 / 60).length;
  final mb = ImageStore.instance.loadedBytes / (1 << 20);
  debugPrint(
    'PERF $name: ${(_frames.length / time.inSeconds).toStringAsFixed(1)} frames/s, '
    'build ${build.toStringAsFixed(2)} ms, raster ${raster.toStringAsFixed(2)} ms, '
    'p50 ${p(.5)} ms, p99 ${p(.99)} ms, over 16.7 ms: $slow/${totals.length}, '
    'art ${mb.toStringAsFixed(0)} MB (${ImageStore.instance.loadedFiles.length} sheets)',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  PaintingBinding.instance.imageCache
    ..maximumSize = 40
    ..maximumSizeBytes = 16 << 20;
  final display = ui.PlatformDispatcher.instance.displays.first.size;
  ImageStore.instance.fitToScreen(display.shortestSide, display.longestSide);
  // A throwaway save: the probe must never touch the player's real progress.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final save = await SaveData.load();
  await GameAudio.instance.init(0);
  final game = VenomcoilGame(save);
  runApp(VenomcoilApp(save: save, game: game));
  await game.loaded;
  SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
  debugPrint('PERF display ${display.width.toInt()}x${display.height.toInt()} px');

  await _measure('menu', const Duration(seconds: 6));
  for (final area in const [0, 11, 19]) {
    await game.selectArea(area);
    game.startOrResume();
    game.setMoveAxis(1);
    var jumps = 0;
    final hops = Stream<void>.periodic(const Duration(milliseconds: 900)).listen((_) {
      game.setJumpHeld((jumps++).isEven);
      game.useAttack();
    });
    // Keep the world on screen: a dead snake would stop the game loop.
    var deaths = 0;
    final revive = Stream<void>.periodic(const Duration(milliseconds: 50)).listen((_) {
      if (game.hud.value.overlay != 'death') return;
      deaths++;
      game.retry();
      game.setMoveAxis(1);
    });
    await _measure('area ${area + 1} playing', const Duration(seconds: 15));
    debugPrint('PERF area ${area + 1} deaths during run: $deaths');
    await hops.cancel();
    await revive.cancel();
    game.setMoveAxis(0);
    game.setJumpHeld(false);
    if (game.hud.value.overlay == null) game.togglePause();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _measure('area ${area + 1} paused', const Duration(seconds: 4));
  }
  exit(0);
}
