import 'package:flutter/material.dart';

/// A widget that wraps its child with a scale-down effect on press.
///
/// Provides tactile visual feedback by scaling the child down when pressed
/// and springing back with a slight overshoot on release.
class PressScale extends StatefulWidget {
  /// The widget to display and apply the scale effect to.
  final Widget child;

  /// Callback invoked when the widget is tapped.
  final VoidCallback? onTap;

  /// The scale factor applied when pressed (0.0 to 1.0).
  /// Defaults to 0.96 for a subtle but noticeable effect.
  final double scaleFactor;

  /// The duration of the scale animation.
  /// Defaults to 120ms for quick, responsive feedback.
  final Duration duration;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(PressScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.scaleFactor != widget.scaleFactor) {
      _animation = Tween<double>(
        begin: 1.0,
        end: widget.scaleFactor,
      ).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.animateTo(
      1.0,
      duration: widget.duration,
      curve: Curves.easeInOut,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _controller.animateBack(
      0.0,
      duration: widget.duration,
      curve: Curves.easeOutBack,
    );
  }

  void _onTapCancel() {
    _controller.animateBack(
      0.0,
      duration: widget.duration,
      curve: Curves.easeOutBack,
    );
  }

  void _onTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_animation.value * (1.0 - widget.scaleFactor)),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
