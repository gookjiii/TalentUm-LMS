import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../main.dart';

// ─────────────────────────────────────────────────────────────────
// FADE IN (Smooth entry)
// ─────────────────────────────────────────────────────────────────
class FadeIn extends HookWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);

    useEffect(() {
      Future.delayed(delay, () {
        if (context.mounted) controller.forward();
      });
      return null;
    }, [delay]);

    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FADE IN UP (Elite revelation)
// ─────────────────────────────────────────────────────────────────
class FadeInUp extends HookWidget {
  const FadeInUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.offset = 30.0,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);

    useEffect(() {
      Future.delayed(delay, () {
        if (context.mounted) controller.forward();
      });
      return null;
    }, [delay]);

    final opacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
        );

    final translation =
        Tween<double>(begin: offset, end: 0.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value,
          child: Transform.translate(
            offset: Offset(0, translation.value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FADE INDEXED STACK
// ─────────────────────────────────────────────────────────────────
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STAGGERED LIST
// ─────────────────────────────────────────────────────────────────
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 350),
    this.delayStep = const Duration(milliseconds: 40),
    this.slideOffset = const Offset(0, 8),
    this.physics,
    this.shrinkWrap = true,
  });

  final List<Widget> children;
  final Duration duration;
  final Duration delayStep;
  final Offset slideOffset;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: duration,
          delay: Duration(milliseconds: delayStep.inMilliseconds * index),
          offset: slideOffset.dy,
          child: children[index],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ANIMATED COUNTER
// ─────────────────────────────────────────────────────────────────
class AnimatedCounter extends HookWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
  });

  final num value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final isPerformance = AppScope.of(context).appState.performanceMode;
    if (isPerformance) {
      return Text('$prefix$value$suffix', style: style);
    }

    final controller = useAnimationController(duration: duration);
    final animation =
        Tween<double>(begin: 0, end: value.toDouble()).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutExpo),
        );

    useEffect(() {
      controller.forward(from: 0);
      return null;
    }, [value]);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final val = animation.value;
        String text;
        if (value is int) {
          text = val.round().toString();
        } else {
          text = val.toStringAsFixed(1);
        }
        return Text('$prefix$text$suffix', style: style);
      },
    );
  }
}
