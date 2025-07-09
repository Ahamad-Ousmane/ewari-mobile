import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class LogoutHelper {
  /// Afficher un dialog de confirmation de déconnexion
  static Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (result == true) {
      await performLogout(context, ref);
    }
  }

  /// Effectuer la déconnexion
  static Future<void> performLogout(BuildContext context, WidgetRef ref) async {
    try {
      // Afficher un loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Déconnecter l'utilisateur
      await ref.read(authServiceProvider.notifier).signOut();

      // Fermer le dialog de loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message de succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déconnexion réussie'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Redirection automatique vers login (grâce au router)
        // Le router détectera que l'utilisateur n'est plus connecté
        context.go('/login');
      }
    } catch (e) {
      // Fermer le dialog de loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher l'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Bouton de déconnexion rapide
  static Widget buildLogoutButton(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Déconnexion',
        style: TextStyle(color: Colors.red),
      ),
      onTap: () => showLogoutDialog(context, ref),
    );
  }

  /// Bouton de déconnexion avec icône
  static Widget buildLogoutIconButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => showLogoutDialog(context, ref),
      icon: const Icon(Icons.logout, color: Colors.red),
      tooltip: 'Déconnexion',
    );
  }
}