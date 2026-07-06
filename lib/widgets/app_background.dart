import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final Color? overlayColor;

  const AppBackground({
    super.key,
    required this.child,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color effectiveOverlayColor = overlayColor ??
        (theme.brightness == Brightness.dark
            ? theme.colorScheme.scrim.withOpacity(0.6)
            : theme.colorScheme.surface.withOpacity(0.85));

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              "assets/images/bg.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          // Adaptive overlay
          Container(
            color: effectiveOverlayColor,
          ),

          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}