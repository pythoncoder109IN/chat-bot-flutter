import 'package:flutter/material.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // Slide Transitions
  static Widget slideFromRight(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: elasticOut)),
      ),
      child: child,
    );
  }

  static Widget slideFromLeft(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: elasticOut)),
      ),
      child: child,
    );
  }

  static Widget slideFromBottom(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .chain(CurveTween(curve: elasticOut)),
      ),
      child: child,
    );
  }

  // Scale Transitions
  static Widget scaleIn(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: animation.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: elasticOut)),
      ),
      child: child,
    );
  }

  // Fade Transitions
  static Widget fadeIn(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: easeInOut)),
      ),
      child: child,
    );
  }

  // Staggered Animation Helper
  static Animation<double> createStaggeredAnimation({
    required AnimationController controller,
    required double delay,
    required double duration,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(delay, delay + duration, curve: curve),
    ));
  }
}