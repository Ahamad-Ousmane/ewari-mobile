// shared/widgets/safe_back_button.dart
import 'package:flutter/material.dart';
import '../../core/utils/navigation_helper.dart';

class SafeBackButton extends StatelessWidget {
  final String? fallbackRoute;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? iconSize;
  final EdgeInsets? margin;
  final VoidCallback? onPressed;
  final bool showTooltip;

  const SafeBackButton({
    super.key,
    this.fallbackRoute,
    this.iconColor,
    this.backgroundColor,
    this.iconSize,
    this.margin,
    this.onPressed,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed ?? () => NavigationHelper.safeGoBack(
          context,
          fallbackRoute: fallbackRoute,
        ),
        icon: Icon(
          Icons.arrow_back,
          color: iconColor ?? Colors.black87,
          size: iconSize ?? 24,
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: 'Retour',
        child: button,
      );
    }

    return button;
  }
}

// Variante pour les AppBars
class SafeBackButtonAppBar extends StatelessWidget {
  final String? fallbackRoute;
  final Color? color;

  const SafeBackButtonAppBar({
    super.key,
    this.fallbackRoute,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => NavigationHelper.safeGoBack(
        context,
        fallbackRoute: fallbackRoute,
      ),
      icon: Icon(
        Icons.arrow_back,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// Variante moderne avec style TourismoRA
class SafeBackButtonModern extends StatelessWidget {
  final String? fallbackRoute;
  final VoidCallback? onPressed;

  const SafeBackButtonModern({
    super.key,
    this.fallbackRoute,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed ?? () => NavigationHelper.safeGoBack(
          context,
          fallbackRoute: fallbackRoute,
        ),
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFF6C63FF),
          size: 24,
        ),
      ),
    );
  }
}