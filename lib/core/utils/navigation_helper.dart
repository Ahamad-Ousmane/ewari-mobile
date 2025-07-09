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

  // === NOUVELLES MÉTHODES AJOUTÉES ===

  /// Navigation vers une route avec vérification (alias pour compatibilité)
  static void safeNavigate(BuildContext context, String route) {
    safeNavigateTo(context, route);
  }

  /// Navigation push avec vérification
  static void safePush(BuildContext context, String route) {
    try {
      context.push(route);
    } catch (e) {
      print('❌ Erreur push vers $route: $e');
      // Fallback vers navigation normale
      context.go(route);
    }
  }

  /// Vérifier si une route est valide
  static bool isValidRoute(String route) {
    final validRoutes = [
      '/',
      '/login',
      '/register',
      '/onboarding',
      '/infrastructures',
      '/map',
      '/ar',
      '/profile',
      '/loading',
    ];

    return validRoutes.contains(route) ||
        route.startsWith('/infrastructure/') ||
        route.startsWith('/infrastructures?');
  }

  /// Obtenir la route actuelle
  static String getCurrentRoute(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.toString();
    } catch (e) {
      print('❌ Erreur récupération route actuelle: $e');
      return '/';
    }
  }

  /// Vérifier si on est sur une route spécifique
  static bool isCurrentRoute(BuildContext context, String route) {
    return getCurrentRoute(context) == route;
  }

  /// Navigation avec feedback visuel
  static void navigateWithFeedback(BuildContext context, String route, {String? successMessage}) {
    try {
      context.go(route);
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation avec feedback vers $route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de navigation'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/');
    }
  }
}