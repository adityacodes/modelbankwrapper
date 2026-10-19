import 'package:flutter/material.dart';

/// Smooth, elegant page transition builder with subtle slide and fade.
/// Provides a fluid, premium feel across all platform routes.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.04, 0.0);
    const end = Offset.zero;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slideIn = Tween<Offset>(begin: begin, end: end).animate(curvedAnimation);
    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    final slideOut =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.02, 0.0))
            .animate(secondaryCurved);
    final fadeOut =
        Tween<double>(begin: 1.0, end: 0.88).animate(secondaryCurved);

    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: fadeOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Drop-in replacement for MaterialPageRoute with smooth slide and fade animations.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({
    required this.page,
    super.settings,
    Duration duration = const Duration(milliseconds: 320),
    Duration reverseDuration = const Duration(milliseconds: 260),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideIn = Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation);
            final fadeIn =
                Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.02, 0.0),
            ).animate(secondaryCurved);
            final fadeOut =
                Tween<double>(begin: 1.0, end: 0.88).animate(secondaryCurved);

            return SlideTransition(
              position: slideOut,
              child: FadeTransition(
                opacity: fadeOut,
                child: SlideTransition(
                  position: slideIn,
                  child: FadeTransition(
                    opacity: fadeIn,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
