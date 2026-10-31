import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Soft textures baked once, so glows never need a per-frame blur or shader.
class FxTextures {
  FxTextures._();

  static const _glowSize = 128;
  static const _runeSize = 512;
  static const glowSrc = ui.Rect.fromLTWH(0, 0, 128, 128);

  static ui.Image? _glow;
  static ui.Image? _rune;

  static ui.Image get glow => _glow ??= _bakeGlow();
  static ui.Image get rune => _rune ??= _bakeRune();

  static ui.Image _bakeGlow() {
    final recorder = ui.PictureRecorder();
    const center = ui.Offset(_glowSize / 2, _glowSize / 2);
    ui.Canvas(recorder).drawCircle(
      center,
      _glowSize / 2,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          center,
          _glowSize / 2,
          const [
            ui.Color(0xffffffff),
            ui.Color(0x88ffffff),
            ui.Color(0x22ffffff),
            ui.Color(0x00ffffff),
          ],
          const [0, 0.25, 0.6, 1],
        ),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_glowSize, _glowSize);
    picture.dispose();
    return image;
  }

  /// Engraved summoning circle under the hero on the title screen.
  static ui.Image _bakeRune() {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const c = _runeSize / 2.0;
    final line = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = const ui.Color(0xffffffff);
    canvas.translate(c, c);
    for (final (radius, width) in const [
      (248.0, 3.0),
      (236.0, 1.0),
      (196.0, 2.0),
      (150.0, 1.0),
    ]) {
      line.strokeWidth = width;
      canvas.drawCircle(ui.Offset.zero, radius, line);
    }
    line.strokeWidth = 2;
    for (var i = 0; i < 72; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 36);
      canvas.drawLine(
        ui.Offset(0, i.isEven ? -236 : -228),
        const ui.Offset(0, -212),
        line,
      );
      canvas.restore();
    }
    final fill = ui.Paint()..color = const ui.Color(0xffffffff);
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 4);
      canvas.drawPath(
        ui.Path()
          ..moveTo(0, -206)
          ..lineTo(9, -188)
          ..lineTo(0, -170)
          ..lineTo(-9, -188)
          ..close(),
        fill,
      );
      canvas.drawLine(const ui.Offset(0, -170), const ui.Offset(58, -60), line);
      canvas.drawLine(
        const ui.Offset(0, -170),
        const ui.Offset(-58, -60),
        line,
      );
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_runeSize, _runeSize);
    picture.dispose();
    return image;
  }
}

/// Queues glows and flushes them as one atlas draw call. Storage is fixed, so
/// a frame full of glows allocates nothing beyond the typed-list views.
class GlowBatch {
  GlowBatch(this.capacity)
    : _rst = Float32List(capacity * 4),
      _rects = Float32List(capacity * 4),
      _colors = Int32List(capacity) {
    for (var i = 0; i < capacity; i++) {
      _rects[i * 4 + 2] = FxTextures.glowSrc.width;
      _rects[i * 4 + 3] = FxTextures.glowSrc.height;
    }
  }

  final int capacity;
  final Float32List _rst;
  final Float32List _rects;
  final Int32List _colors;
  int _count = 0;

  /// [color] is packed ARGB; [radius] is in the canvas' current units.
  void add(double x, double y, double radius, int color) {
    if (_count >= capacity) return;
    final scale = radius / 64;
    final i = _count * 4;
    _rst[i] = scale;
    _rst[i + 1] = 0;
    _rst[i + 2] = x - radius;
    _rst[i + 3] = y - radius;
    _colors[_count++] = color;
  }

  void flush(ui.Canvas canvas, ui.Paint paint) {
    if (_count == 0) return;
    canvas.drawRawAtlas(
      FxTextures.glow,
      Float32List.sublistView(_rst, 0, _count * 4),
      Float32List.sublistView(_rects, 0, _count * 4),
      Int32List.sublistView(_colors, 0, _count),
      ui.BlendMode.modulate,
      null,
      paint,
    );
    _count = 0;
  }
}

/// Packs a colour with a new 0..1 alpha into the ARGB int [GlowBatch] takes.
int glowColor(int rgb, double alpha) =>
    ((alpha.clamp(0.0, 1.0) * 255).round() << 24) | (rgb & 0xffffff);

/// Fixed-size particle pool: spawning past capacity simply drops the particle,
/// so a chaotic moment can never grow memory or the frame's draw cost.
class ParticlePool {
  ParticlePool(this.capacity)
    : _x = Float32List(capacity),
      _y = Float32List(capacity),
      _vx = Float32List(capacity),
      _vy = Float32List(capacity),
      _age = Float32List(capacity),
      _life = Float32List(capacity),
      _size = Float32List(capacity),
      _gravity = Float32List(capacity),
      _rgb = Int32List(capacity);

  final int capacity;
  final Float32List _x, _y, _vx, _vy, _age, _life, _size, _gravity;
  final Int32List _rgb;
  final math.Random _random = math.Random(11);
  int _count = 0;

  bool get isEmpty => _count == 0;

  void clear() => _count = 0;

  void burst(
    double x,
    double y,
    int rgb, {
    int count = 12,
    double speed = 220,
    double life = 0.55,
    double size = 16,
    double gravity = 260,
    double angle = -math.pi / 2,
    double spread = math.pi,
  }) {
    for (var n = 0; n < count && _count < capacity; n++) {
      final i = _count++;
      final a = angle + (_random.nextDouble() * 2 - 1) * spread;
      final v = speed * (0.35 + _random.nextDouble() * 0.65);
      _x[i] = x;
      _y[i] = y;
      _vx[i] = math.cos(a) * v;
      _vy[i] = math.sin(a) * v;
      _age[i] = 0;
      _life[i] = life * (0.6 + _random.nextDouble() * 0.4);
      _size[i] = size * (0.6 + _random.nextDouble() * 0.6);
      _gravity[i] = gravity;
      _rgb[i] = rgb;
    }
  }

  void update(double dt) {
    var i = 0;
    while (i < _count) {
      _age[i] += dt;
      if (_age[i] >= _life[i]) {
        final last = --_count;
        _x[i] = _x[last];
        _y[i] = _y[last];
        _vx[i] = _vx[last];
        _vy[i] = _vy[last];
        _age[i] = _age[last];
        _life[i] = _life[last];
        _size[i] = _size[last];
        _gravity[i] = _gravity[last];
        _rgb[i] = _rgb[last];
        continue;
      }
      _vy[i] += _gravity[i] * dt;
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
      i++;
    }
  }

  void queue(GlowBatch batch) {
    for (var i = 0; i < _count; i++) {
      final fade = 1 - _age[i] / _life[i];
      batch.add(_x[i], _y[i], _size[i] * (0.4 + fade * 0.6), glowColor(_rgb[i], fade));
    }
  }
}

/// Drifting motes wrapped around a window; positions come purely from time and
/// index, so the field holds no per-mote state at all.
void queueAmbientMotes(
  GlowBatch batch, {
  required int count,
  required double left,
  required double top,
  required double width,
  required double height,
  required double time,
  required int rgb,
  double rise = 16,
  double radius = 7,
  double alpha = 0.55,
  int seed = 0,
}) {
  for (var i = 0; i < count; i++) {
    final s = (i + seed * 7) * 97.31;
    final sway = math.sin(time * 0.6 + s) * 18;
    final x = (math.sin(s) * 0.5 + 0.5) * width + sway;
    final y = height - ((time * (rise + i % 5 * 5) + s * 23) % (height + 40));
    final pulse = 0.5 + 0.5 * math.sin(time * 2 + s);
    batch.add(
      left + x,
      top + y,
      radius * (0.7 + (i % 3) * 0.45),
      glowColor(rgb, alpha * (0.3 + 0.7 * pulse)),
    );
  }
}
