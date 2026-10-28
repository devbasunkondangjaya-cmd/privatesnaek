import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A decoded sprite sheet split into a grid of equally sized cells.
class SheetInfo {
  SheetInfo(this._image, this.cols, this.rows)
    : _gridWidth = _image.width.toDouble(),
      _gridHeight = _image.height.toDouble();

  ui.Image _image;
  ui.Image get image => _image;
  final int cols;
  final int rows;

  // The grid of the sheet as supplied. Character sheets are repacked into a
  // new atlas, but sizes are still scaled against the original cell.
  final double _gridWidth;
  final double _gridHeight;

  // Keep fractional boundaries: many supplied sheets are not evenly divisible
  // by their grid, and rounding shifts the final frames away from their cells.
  double get cellWidth => _gridWidth / cols;
  double get cellHeight => _gridHeight / rows;

  ui.Rect cell(int col, int row) => ui.Rect.fromLTWH(
    col * cellWidth + 1,
    row * cellHeight + 1,
    cellWidth - 2,
    cellHeight - 2,
  );

  /// Keep sampling inside the cell; adjacent frames contain visible artwork.
  ui.Rect content(int col, int row) =>
      _frames?[row * cols + col] ?? cell(col, row);

  List<ui.Rect>? _frames;

  /// Illustrations drift across the grid and fast poses (dashes, flight
  /// trails) spill into neighbouring cells, so no rectangle on the original
  /// sheet holds one whole pose alone. Each blob of artwork is assigned to the
  /// cell holding its centre, then every pose is copied into its own slot of a
  /// new atlas: complete, and free of its neighbours' pixels.
  Future<void> prepareCharacterFrames() async {
    final data = await _image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return;
    final packed = await compute(
      _separatePoses,
      _PoseJob(
        data.buffer.asUint8List(),
        _image.width,
        _image.height,
        cols,
        rows,
      ),
    );
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      packed.pixels,
      packed.width,
      packed.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final atlas = await completer.future;
    _image.dispose();
    _image = atlas;
    _frames = [
      for (var i = 0; i < cols * rows; i++)
        ui.Rect.fromLTWH(
          packed.frames[i * 4],
          packed.frames[i * 4 + 1],
          packed.frames[i * 4 + 2],
          packed.frames[i * 4 + 3],
        ),
    ];
    _rowMax.clear();
  }

  static const double overflowScale = 1;

  /// Largest content size across a row; used as a stable scale reference so
  /// animations don't pulse in size from frame to frame.
  ui.Size rowMax(int row) => _rowMax[row] ??= _computeRowMax(row);

  final Map<int, ui.Size> _rowMax = {};

  ui.Size _computeRowMax(int row) {
    var w = 1.0, h = 1.0;
    for (var c = 0; c < cols; c++) {
      final r = content(c, row);
      w = math.max(w, r.width);
      h = math.max(h, r.height);
    }
    return ui.Size(w, h);
  }
}

/// Shared image cache used by the game canvas and the Flutter widgets (HUD
/// icons, menu art). Sprite sheets are decoded near their rendered size to
/// keep memory use and frame upload costs reasonable on phones.
class ImageStore {
  ImageStore._();
  static final ImageStore instance = ImageStore._();

  final Map<String, SheetInfo> _sheets = {};
  final Map<String, Future<SheetInfo?>> _pending = {};

  /// Bumped whenever something finishes loading, so widgets can rebuild.
  final ValueNotifier<int> revision = ValueNotifier(0);

  ui.Image? operator [](String file) => _sheets[file]?.image;
  SheetInfo? sheet(String file) => _sheets[file];

  Future<SheetInfo?> loadSheet(String file, {int cols = 1, int rows = 1}) {
    final existing = _sheets[file];
    if (existing != null) {
      return Future.value(existing);
    }
    return _pending[file] ??= _load(file, cols, rows).whenComplete(() {
      _pending.remove(file);
    });
  }

  Future<SheetInfo?> _load(String file, int cols, int rows) async {
    try {
      var image = _sheets[file]?.image;
      if (image == null) {
        final data = await rootBundle.load('assets/images/$file');
        final maxCellWidth = file.startsWith('boss_') ? 384 : 320;
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: cols > 1 ? cols * maxCellWidth : null,
          allowUpscaling: false,
        );
        image = (await codec.getNextFrame()).image;
        codec.dispose();
      }
      final info = SheetInfo(image, cols, rows);
      if ((file.startsWith('skin_') && !file.contains('_fx-')) ||
          file.startsWith('vexa_') ||
          file.startsWith('boss_')) {
        await info.prepareCharacterFrames();
      }
      _sheets[file] = info;
      revision.value++;
      return info;
    } catch (e) {
      // Not every area ships every sheet (e.g. area 4 has no tile art); the
      // renderer falls back to procedural drawing when a sheet is missing.
      return null;
    }
  }

  void release(Iterable<String> files) {
    for (final file in files) {
      _sheets.remove(file)?.image.dispose();
    }
  }
}

class _PoseJob {
  const _PoseJob(this.pixels, this.width, this.height, this.cols, this.rows);

  final Uint8List pixels;
  final int width;
  final int height;
  final int cols;
  final int rows;
}

class _PackedPoses {
  const _PackedPoses(this.pixels, this.width, this.height, this.frames);

  final Uint8List pixels;
  final int width;
  final int height;

  /// left, top, width, height of every frame in the atlas, row by row.
  final Float64List frames;
}

/// Runs off the UI thread: labels the artwork, then repacks it pose by pose.
_PackedPoses _separatePoses(_PoseJob job) {
  final w = job.width, h = job.height, src = job.pixels;
  final cols = job.cols, rows = job.rows;
  final cellW = w / cols, cellH = h / rows;

  // Label on a half-resolution mask: four times less work, and it bridges
  // hairline gaps inside one pose. 0 = empty, -1 = ink not yet labelled.
  final gw = (w + 1) >> 1, gh = (h + 1) >> 1;
  final labels = Int32List(gw * gh);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (src[(y * w + x) * 4 + 3] >= 96) labels[(y >> 1) * gw + (x >> 1)] = -1;
    }
  }
  // Which frame each blob belongs to: the cell holding its centre. Some
  // sheets draw a dash pose as one long snake across two cells; it stays
  // whole instead of being cut in half.
  final owner = <int>[0];
  final stack = Int32List(gw * gh);
  var next = 0;
  for (var start = 0; start < labels.length; start++) {
    if (labels[start] != -1) continue;
    next++;
    var top = 0;
    stack[top++] = start;
    labels[start] = next;
    var sumX = 0.0, sumY = 0.0, count = 0;
    while (top > 0) {
      final p = stack[--top];
      final px = p % gw, py = p ~/ gw;
      sumX += px;
      sumY += py;
      count++;
      for (var ny = math.max(0, py - 1); ny <= math.min(gh - 1, py + 1); ny++) {
        for (
          var nx = math.max(0, px - 1);
          nx <= math.min(gw - 1, px + 1);
          nx++
        ) {
          final q = ny * gw + nx;
          if (labels[q] == -1) {
            labels[q] = next;
            stack[top++] = q;
          }
        }
      }
    }
    final col = ((sumX / count) * 2 + 1) ~/ cellW;
    final row = ((sumY / count) * 2 + 1) ~/ cellH;
    owner.add(row.clamp(0, rows - 1) * cols + col.clamp(0, cols - 1));
  }

  // Soft pixels (trails, glow) do not join blobs, so they cannot fuse two
  // poses together; they stay with the grid cell they sit in.
  int frameOf(int x, int y) {
    final label = labels[(y >> 1) * gw + (x >> 1)];
    if (label > 0) return owner[label];
    return math.min(rows - 1, y ~/ cellH) * cols +
        math.min(cols - 1, x ~/ cellW);
  }

  final count = cols * rows;
  final left = List.filled(count, w), top = List.filled(count, h);
  final right = List.filled(count, 0), bottom = List.filled(count, 0);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (src[(y * w + x) * 4 + 3] == 0) continue;
      final f = frameOf(x, y);
      if (f < 0) continue;
      left[f] = math.min(left[f], x);
      top[f] = math.min(top[f], y);
      right[f] = math.max(right[f], x + 1);
      bottom[f] = math.max(bottom[f], y + 1);
    }
  }

  var slotW = 3, slotH = 3;
  for (var f = 0; f < count; f++) {
    slotW = math.max(slotW, right[f] - left[f] + 2);
    slotH = math.max(slotH, bottom[f] - top[f] + 2);
  }
  final outW = cols * slotW, outH = rows * slotH;
  final out = Uint8List(outW * outH * 4);
  final frames = Float64List(count * 4);
  for (var f = 0; f < count; f++) {
    final slotX = (f % cols) * slotW + 1, slotY = (f ~/ cols) * slotH + 1;
    final empty = right[f] <= left[f];
    // Include the slot's 1px transparent border so edges never sample ink.
    frames[f * 4] = slotX - 1.0;
    frames[f * 4 + 1] = slotY - 1.0;
    frames[f * 4 + 2] = empty ? 1 : (right[f] - left[f] + 2).toDouble();
    frames[f * 4 + 3] = empty ? 1 : (bottom[f] - top[f] + 2).toDouble();
  }
  // A cell left empty by a two-cell pose shows the nearest pose in its row
  // (the one before it first), so animations never blink out.
  bool filled(int f) => right[f] > left[f];
  for (var f = 0; f < count; f++) {
    if (filled(f)) continue;
    final rowStart = f - f % cols;
    for (var d = 1; d < cols; d++) {
      final before = f - d, after = f + d;
      final source = before >= rowStart && filled(before)
          ? before
          : after < rowStart + cols && filled(after)
          ? after
          : -1;
      if (source < 0) continue;
      for (var k = 0; k < 4; k++) {
        frames[f * 4 + k] = frames[source * 4 + k];
      }
      break;
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      if (src[i + 3] == 0) continue;
      final f = frameOf(x, y);
      if (f < 0) continue;
      final ox = (f % cols) * slotW + 1 + x - left[f];
      final oy = (f ~/ cols) * slotH + 1 + y - top[f];
      final o = (oy * outW + ox) * 4;
      out[o] = src[i];
      out[o + 1] = src[i + 1];
      out[o + 2] = src[i + 2];
      out[o + 3] = src[i + 3];
    }
  }
  return _PackedPoses(out, outW, outH, frames);
}
