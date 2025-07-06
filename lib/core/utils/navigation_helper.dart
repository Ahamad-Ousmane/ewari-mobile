// core/utils/navigation_helper.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationHelper {
  /// Fonction de retour sécurisée qui gère le cas où il n'y a rien à pop
  static void safeGoBack(BuildContext context, {String? fallbackRoute}) {
    // Vérifier si on peut faire un pop
    if (context.canPop()) {
      context.pop();
    } else {
      // Si on ne peut pas pop, aller vers la route de fallback (par défaut: accueil)
      context.go(fallbackRoute ?? '/');
    }
  }

  /// Widget bouton de retour sécurisé
  static Widget buildSafeBackButton(
      BuildContext context, {
        String? fallbackRoute,
        Color? iconColor,
        Color? backgroundColor,
        VoidCallback? onPressed,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: onPressed ?? () => safeGoBack(context, fallbackRoute: fallbackRoute),
        icon: Icon(
          Icons.arrow_back,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }

  /// Vérifier si on peut naviguer en arrière
  static bool canGoBack(BuildContext context) {
    return context.canPop();
  }

  /// Navigation vers l'accueil avec feedback
  static void goToHome(BuildContext context) {
    context.go('/');
  }

  /// Navigation vers une route avec gestion d'erreur
  static void safeNavigateTo(BuildContext context, String route) {
    try {
      context.go(route);
    } catch (e) {
      // En cas d'erreur, retourner à l'accueil
      context.go('/');
    }
  }
}