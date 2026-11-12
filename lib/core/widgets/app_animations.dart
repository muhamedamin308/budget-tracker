import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/money_format.dart';

/// Tactile spring-scale effect on touch down, making cards and tiles feel native and alive.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.enableHaptic = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool enableHaptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _onTap() {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Smoothly animates numeric money values from previous amount to new amount.
class CountUpMoneyText extends StatelessWidget {
  const CountUpMoneyText({
    required this.amountMinor,
    this.style,
    this.prefix = '',
    this.duration = const Duration(milliseconds: 700),
    super.key,
  });

  final int amountMinor;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amountMinor.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final formatted = formatMinor(value.round());
        return Text(
          '$prefix$formatted',
          style: style,
        );
      },
    );
  }
}

/// Animated progress indicator with custom gradient, height and smooth transitions.
class AnimatedGradientProgressBar extends StatelessWidget {
  const AnimatedGradientProgressBar({
    required this.progress,
    this.gradient,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.borderRadius = 10.0,
    this.duration = const Duration(milliseconds: 650),
    super.key,
  });

  final double progress;
  final Gradient? gradient;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0));
    final clamped = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Container(
          width: totalWidth,
          height: height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: clamped),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  return Container(
                    width: totalWidth * animatedValue,
                    height: height,
                    decoration: BoxDecoration(
                      color: gradient == null ? (color ?? theme.colorScheme.primary) : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: color != null
                          ? [
                              BoxShadow(
                                color: color!.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Badge wrapper that applies smooth entrance scale without infinite ticker loop
class PulsingBadge extends StatelessWidget {
  const PulsingBadge({
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.minScale = 0.94,
    this.maxScale = 1.04,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  @override
  Widget build(BuildContext context) => child;
}
