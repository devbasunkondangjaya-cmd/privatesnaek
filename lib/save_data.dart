import 'package:shared_preferences/shared_preferences.dart';

/// Everything that survives an app restart. Written automatically by the game
/// on checkpoints, area clears, skin/volume changes and when the app is paused.
class SaveData {
  SaveData._(this._prefs);

  static const _kArea = 'area';
  static const _kCheckpoint = 'checkpoint';
  static const _kSkin = 'skin';
  static const _kVolume = 'volumeLevel';
  static const _kCompleted = 'completedAreas';
  static const _kBest = 'bestTimes';

  final SharedPreferences? _prefs;

  int area = 0;
  int checkpoint = 0;
  int skin = 0;

  /// 0 = mute, 1 = low, 2 = high.
  int volumeLevel = 2;
  final Set<int> completed = {};
  final Map<int, double> bestTimes = {};

  static Future<SaveData> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Storage unavailable: play without persistence.
    }
    final data = SaveData._(prefs);
    if (prefs == null) return data;
    data.area = (prefs.getInt(_kArea) ?? 0).clamp(0, 19);
    data.checkpoint = (prefs.getInt(_kCheckpoint) ?? 0).clamp(0, 12);
    data.skin = (prefs.getInt(_kSkin) ?? 0).clamp(0, 9);
    data.volumeLevel = (prefs.getInt(_kVolume) ?? 2).clamp(0, 2);
    data.completed.addAll(
      (prefs.getStringList(_kCompleted) ?? const []).map(int.parse),
    );
    for (final entry in prefs.getStringList(_kBest) ?? const <String>[]) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        data.bestTimes[int.parse(parts[0])] = double.parse(parts[1]);
      }
    }
    return data;
  }

  bool get hasProgress => area > 0 || checkpoint > 0 || completed.isNotEmpty;

  Future<void> save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setInt(_kArea, area);
      await prefs.setInt(_kCheckpoint, checkpoint);
      await prefs.setInt(_kSkin, skin);
      await prefs.setInt(_kVolume, volumeLevel);
      await prefs.setStringList(
        _kCompleted,
        completed.map((e) => e.toString()).toList(),
      );
      await prefs.setStringList(
        _kBest,
        bestTimes.entries.map((e) => '${e.key}:${e.value}').toList(),
      );
    } catch (_) {
      // Storage can be unavailable (private browsing); the game still runs.
    }
  }

  /// Wipes story progress but keeps preferences (volume, chosen skin).
  Future<void> resetProgress() async {
    area = 0;
    checkpoint = 0;
    completed.clear();
    bestTimes.clear();
    await save();
  }
}
