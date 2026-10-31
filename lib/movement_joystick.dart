import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ui_kit.dart';

/// A single-pointer stick; other fingers remain free for jump and attack.
/// The thumb moves through a notifier, so dragging repaints only the thumb
/// layer and never rebuilds a widget.
class MovementJoystick extends StatefulWidget {
  const MovementJoystick({
    super.key,
    required this.onChanged,
    this.size = 116,
    this.enabled = true,
  });

  final ValueChanged<double> onChanged;
  final double size;
  final bool enabled;

  @override
  State<MovementJoystick> createState() => _MovementJoystickState();
}

class _MovementJoystickState extends State<MovementJoystick>
    with WidgetsBindingObserver {
  int? _pointer;
  final ValueNotifier<double> _offset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _reset() {
    _pointer = null;
    _offset.value = 0;
    widget.onChanged(0);
  }

  @override
  void didUpdateWidget(MovementJoystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) _reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offset.dispose();
    widget.onChanged(0);
    super.dispose();
  }

  void _move(Offset position) {
    final radius = widget.size * .29;
    final dx = (position.dx - widget.size / 2).clamp(-radius, radius);
    _offset.value = dx;
    final horizontal = dx / radius;
    widget.onChanged(
      horizontal.abs() <= .12
          ? 0
          : horizontal.sign * (horizontal.abs() - .12) / .88,
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Joystick gerak kiri dan kanan',
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!widget.enabled || _pointer != null) return;
        _pointer = event.pointer;
        _move(event.localPosition);
      },
      onPointerMove: (event) {
        if (event.pointer == _pointer) _move(event.localPosition);
      },
      onPointerUp: (event) {
        if (event.pointer == _pointer) _reset();
      },
      onPointerCancel: (event) {
        if (event.pointer == _pointer) _reset();
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: const JoystickBasePainter(),
            foregroundPainter: JoystickThumbPainter(_offset),
          ),
        ),
      ),
    ),
  );
}

/// The carved socket of the stick, with its left and right guide arrows.
class JoystickBasePainter extends CustomPainter {
  const JoystickBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..shader = ui.Gradient.radial(c, r, const [
          Color(0xcc050a08),
          Color(0xb00d1713),
          Color(0xd01c2a23),
        ], const [0, 0.72, 1]),
    );
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = goldTrim(rect),
    );
    canvas.drawCircle(
      c,
      r - 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Palette.gold.withValues(alpha: 0.32),
    );
    final arrow = Paint()..color = Palette.gold.withValues(alpha: 0.75);
    for (final side in const [-1.0, 1.0]) {
      final x = c.dx + side * (r - 14);
      canvas.drawPath(
        Path()
          ..moveTo(x + side * 6, c.dy)
          ..lineTo(x - side * 3, c.dy - 8)
          ..lineTo(x - side * 3, c.dy + 8)
          ..close(),
        arrow,
      );
    }
  }

  @override
  bool shouldRepaint(JoystickBasePainter old) => false;
}

/// The emerald thumb. Also used by the tutorial's animated illustration.
class JoystickThumbPainter extends CustomPainter {
  JoystickThumbPainter(this.offset) : super(repaint: offset);

  final ValueListenable<double> offset;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * .21;
    final c = size.center(Offset.zero).translate(offset.value, 0);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r * 1.5,
      Paint()
        ..shader = ui.Gradient.radial(c, r * 1.5, const [
          Color(0x6627e07a),
          Color(0x0027e07a),
        ]),
    );
    canvas.drawCircle(c, r, Paint()..shader = goldTrim(rect));
    canvas.drawCircle(c, r - 2, Paint()..color = const Color(0xff120c04));
    canvas.drawCircle(
      c,
      r - 3,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-r * 0.25, -r * 0.4),
          r * 1.4,
          const [Color(0xff8dffb0), Color(0xff169a56), Color(0xff06381f)],
          const [0, 0.5, 1],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, -r * 0.48),
        width: r * 1.05,
        height: r * 0.42,
      ),
      Paint()..color = const Color(0x55ffffff),
    );
  }

  @override
  bool shouldRepaint(JoystickThumbPainter old) => old.offset != offset;
}
