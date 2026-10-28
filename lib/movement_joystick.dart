import 'package:flutter/material.dart';

/// A single-pointer stick; other fingers remain free for jump and attack.
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
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _reset() {
    _pointer = null;
    if (mounted) setState(() => _offset = Offset.zero);
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
    widget.onChanged(0);
    super.dispose();
  }

  void _move(Offset position) {
    final radius = widget.size * .29;
    final dx = (position.dx - widget.size / 2).clamp(-radius, radius);
    final offset = Offset(dx, 0);
    setState(() => _offset = offset);
    final horizontal = offset.dx / radius;
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
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xbb101d19),
          border: Border.all(color: const Color(0x995e7755), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              left: 7,
              child: Icon(Icons.chevron_left, color: Color(0x8872f070)),
            ),
            const Positioned(
              right: 7,
              child: Icon(Icons.chevron_right, color: Color(0x8872f070)),
            ),
            Transform.translate(
              offset: _offset,
              child: Container(
                width: widget.size * .42,
                height: widget.size * .42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xff73bf59), Color(0xff294f33)],
                  ),
                  border: Border.all(color: const Color(0xffa9dc81), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  color: Color(0xfffff3d3),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
