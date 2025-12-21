import 'package:flutter/material.dart';

/// Common border gradient widget
/// Creates a linear gradient border effect with white color transitioning from 60% to 10% opacity
class BorderGradient extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius? borderRadius;

  const BorderGradient({
    super.key,
    required this.child,
    this.borderWidth = 1.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.zero,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.75],
          colors: [
            Color.fromRGBO(255, 255, 255, 0.6), // White at 60% opacity (0%)
            Color.fromRGBO(255, 255, 255, 0.1), // White at 10% opacity (75%)
          ],
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
        child: child,
      ),
    );
  }
}

/// Border gradient decoration for use with Container decoration
class BorderGradientDecoration {
  static BoxDecoration decoration({
    double borderWidth = 1.0,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.zero,
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        stops: [0.0, 0.75],
        colors: [
          Color.fromRGBO(255, 255, 255, 0.6), // White at 60% opacity (0%)
          Color.fromRGBO(255, 255, 255, 0.1), // White at 10% opacity (75%)
        ],
      ),
    );
  }

  /// Returns the gradient itself for use in other contexts
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 0.75],
    colors: [
      Color.fromRGBO(255, 255, 255, 0.6), // White at 60% opacity (0%)
      Color.fromRGBO(255, 255, 255, 0.1), // White at 10% opacity (75%)
    ],
  );
}
