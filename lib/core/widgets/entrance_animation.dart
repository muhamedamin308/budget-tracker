import 'package:flutter/material.dart';

class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.06),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _isVisible = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _isVisible ? 1 : 0,
    duration: widget.duration,
    curve: Curves.easeOutCubic,
    child: AnimatedSlide(
      offset: _isVisible ? Offset.zero : widget.offset,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}
