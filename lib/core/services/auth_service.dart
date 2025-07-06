import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/utilisateur.dart';
import 'supabase_service.dart';

class AuthService extends StateNotifier<AsyncValue<Utilisateur?>> {
  // Table séparée pour l'app mobile
  static const String mobileUsersTable = 'utilisateurs_mobile';

  AuthService() : super(const AsyncValue.data(null)) {
    // Écouter les changements d'authentification
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      print('🔄 Auth state change: ${data.event}');

      if (session != null) {
        print('✅ Session active: ${session.user.id}');
        _loadUserProfile(session.user.id);
      } else {
        print('❌ Aucune session active');
        state = const AsyncValue.data(null);
      }
    });

    // Charger l'utilisateur actuel s'il existe
    final currentSession = SupabaseService.client.auth.currentSession;
    if (currentSession != null) {
      print('🔄 Session existante trouvée: ${currentSession.user.id}');
      _loadUserProfile(currentSession.user.id);
    } else {
      print('ℹ️ Aucune session existante au démarrage');
      // S'assurer qu'on a un état initial propre
      state = const AsyncValue.data(null);
    }
  }

  Utilisateur? get currentUser => state.value;
  bool get isAuthenticated => currentUser != null;

  Future<void> _loadUserProfile(String userId) async {
    try {
      print('🔍 Chargement profil mobile utilisateur: $userId');

      // Utiliser select() sans .single() pour éviter l'erreur "0 rows"
      final response = await SupabaseService.client
          .from(mobileUsersTable)
          .select()
          .eq('id', userId);

      if (response.isEmpty) {
        print('⚠️ Aucun profil mobile trouvé pour: $userId');
        // Déconnecter silencieusement sans créer de boucle
        await SupabaseService.client.auth.signOut();
        state = const AsyncValue.data(null);
        return;
      }

      final user = Utilisateur.fromJson(response.first);
      state = AsyncValue.data(user);
      print('✅ Profil mobile chargé: ${user.nom} (${user.email})');
    } catch (e) {
      print('❌ Erreur chargement profil mobile: $e');
      // En cas d'erreur, déconnecter sans état d'erreur
      try {
        await SupabaseService.client.auth.signOut();
      } catch (signOutError) {
        print('❌ Erreur déconnexion: $signOutError');
      }
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      print('🔐 Tentative de connexion mobile: $email');
      state = const AsyncValue.loading();

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Connexion Auth réussie: ${response.user!.id}');

        // Vérifier que l'utilisateur existe dans la table mobile
        final mobileCheck = await SupabaseService.client
            .from(mobileUsersTable)
            .select()
            .eq('id', response.user!.id);

        if (mobileCheck.isEmpty) {
          // Utilisateur n'existe pas dans table mobile
          await SupabaseService.client.auth.signOut();
          throw Exception('Ce compte n\'est pas autorisé sur l\'application mobile');
        }

        // Charger le profil
        await _loadUserProfile(response.user!.id);
      }
    } catch (e) {
      print('❌ Erreur connexion mobile: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signUp({
    required String nom,
    required String email,
    required String password,
    String? telephone,
  }) async {
    try {
      print('📝 Tentative d\'inscription mobile: $email');
      state = const AsyncValue.loading();

      // 1. Créer l'utilisateur dans Supabase Auth
      final authResponse = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        print('✅ Utilisateur Auth créé: ${authResponse.user!.id}');
        print('🔐 Auth UID: ${SupabaseService.client.auth.currentUser?.id}');

        // 2. Préparer les données utilisateur
        final userData = {
          'id': authResponse.user!.id, // UUID de Supabase Auth
          'nom': nom.trim(),
          'email': email.trim().toLowerCase(),
          'telephone': telephone?.trim(),
          'type': 'touriste', // Toujours touriste pour l'app mobile
          'is_active': true,
        };

        print('📊 Données à insérer dans table mobile: $userData');
        print('🔐 Current auth user: ${SupabaseService.client.auth.currentUser?.id}');

        // 3. Insérer dans la table mobile avec gestion d'erreur détaillée
        try {
          final insertResponse = await SupabaseService.client
              .from(mobileUsersTable)
              .insert(userData)
              .select()
              .single();

          print('✅ Profil mobile créé: $insertResponse');

          // 4. Charger le profil
          await _loadUserProfile(authResponse.user!.id);

        } catch (insertError) {
          print('❌ Erreur détaillée insertion: $insertError');
          print('❌ Type erreur: ${insertError.runtimeType}');

          // Si c'est une erreur RLS, essayer sans RLS
          if (insertError.toString().contains('row-level security')) {
            print('🚨 Erreur RLS détectée. Vérifiez les politiques Supabase.');
            print('💡 Suggestion: Désactivez temporairement RLS pour debug');
          }

          rethrow;
        }
      } else {
        throw Exception('Échec de création du compte utilisateur');
      }
    } catch (e) {
      print('❌ Erreur inscription mobile complète: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Mettre à jour un utilisateur existant avec le nouvel ID Auth
  Future<void> _updateExistingUserWithNewId(User authUser, Map<String, dynamic> existingUser) async {
    try {
      print('🔄 Mise à jour ID utilisateur: ${existingUser['id']} → ${authUser.id}');

      // Supprimer l'ancien enregistrement
      await SupabaseService.client
          .from(mobileUsersTable)
          .delete()
          .eq('id', existingUser['id']);

      // Créer avec le nouvel ID
      final userData = {
        'id': authUser.id, // Nouvel ID Auth
        'nom': existingUser['nom'] ?? authUser.email?.split('@')[0] ?? 'Utilisateur',
        'email': authUser.email ?? '',
        'telephone': existingUser['telephone'] ?? authUser.phone,
        'type': 'touriste',
        'is_active': true,
      };

      await SupabaseService.client
          .from(mobileUsersTable)
          .insert(userData);

      // Charger le profil
      await _loadUserProfile(authUser.id);
      print('✅ Utilisateur mobile mis à jour avec nouvel ID');
    } catch (e) {
      print('❌ Erreur mise à jour ID utilisateur: $e');
      rethrow;
    }
  }

  // Créer un utilisateur mobile à partir d'un utilisateur Auth existant
  Future<void> _createMobileUserFromAuth(User authUser) async {
    try {
      print('🔄 Création utilisateur mobile à partir de Auth: ${authUser.id}');

      final userData = {
        'id': authUser.id,
        'nom': authUser.userMetadata?['full_name'] ??
            authUser.userMetadata?['nom'] ??
            authUser.email?.split('@')[0] ??
            'Utilisateur',
        'email': authUser.email ?? '',
        'telephone': authUser.userMetadata?['telephone'] ?? authUser.phone,
        'type': 'touriste',
        'is_active': true,
      };

      print('📊 Données utilisateur mobile à créer: $userData');

      await SupabaseService.client
          .from(mobileUsersTable)
          .insert(userData);

      // Charger le profil après création
      await _loadUserProfile(authUser.id);
      print('✅ Utilisateur mobile créé et profil chargé');
    } catch (e) {
      print('❌ Erreur création utilisateur mobile: $e');

      // Si duplicate email, ne pas faire de boucle
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        print('⚠️ Email déjà utilisé - arrêt pour éviter boucle');
        state = AsyncValue.error(
            Exception('Conflit de données utilisateur. Veuillez vous déconnecter et réessayer.'),
            StackTrace.current
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    try {
      print('🚪 Déconnexion mobile en cours...');
      await SupabaseService.client.auth.signOut();
      state = const AsyncValue.data(null);
      print('✅ Déconnexion mobile réussie');
    } catch (e) {
      print('❌ Erreur déconnexion mobile: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? nom,
    String? telephone,
  }) async {
    if (currentUser == null) return;

    try {
      print('🔄 Mise à jour profil mobile: ${currentUser!.id}');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nom != null && nom.trim().isNotEmpty) {
        updateData['nom'] = nom.trim();
      }

      if (telephone != null) {
        updateData['telephone'] = telephone.trim().isEmpty ? null : telephone.trim();
      }

      await SupabaseService.client
          .from(mobileUsersTable)
          .update(updateData)
          .eq('id', currentUser!.id);

      // Recharger le profil
      await _loadUserProfile(currentUser!.id);
      print('✅ Profil mobile mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour profil mobile: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Méthode pour vérifier si l'email existe déjà dans la table mobile
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await SupabaseService.client
          .from(mobileUsersTable)
          .select('email')
          .eq('email', email.trim().toLowerCase())
          .limit(1);

      return response.isEmpty; // true si email disponible
    } catch (e) {
      print('❌ Erreur vérification email mobile: $e');
      return false;
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      print('🔄 Réinitialisation mot de passe pour: $email');
      await SupabaseService.client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: 'https://yourapp.com/reset-password', // À personnaliser
      );
      print('✅ Email de réinitialisation envoyé à: $email');
    } catch (e) {
      print('❌ Erreur réinitialisation: $e');
      rethrow;
    }
  }

  // Méthode pour supprimer le compte (optionnel)
  Future<void> deleteAccount() async {
    if (currentUser == null) return;

    try {
      print('🗑️ Suppression compte mobile: ${currentUser!.id}');

      // Supprimer d'abord de la table mobile
      await SupabaseService.client
          .from(mobileUsersTable)
          .delete()
          .eq('id', currentUser!.id);

      // Puis supprimer de Auth (nécessite des privilèges admin)
      // Note: En général, on désactive plutôt que supprimer
      await SupabaseService.client
          .from(mobileUsersTable)
          .update({'is_active': false})
          .eq('id', currentUser!.id);

      await signOut();
      print('✅ Compte mobile supprimé/désactivé');
    } catch (e) {
      print('❌ Erreur suppression compte mobile: $e');
      rethrow;
    }
  }

  // Méthode pour obtenir les statistiques utilisateur (optionnel)
  Future<Map<String, dynamic>> getUserStats() async {
    if (currentUser == null) return {};

    try {
      // Ici vous pouvez ajouter des requêtes pour obtenir des stats
      // comme le nombre de favoris, d'avis laissés, etc.
      return {
        'user_id': currentUser!.id,
        'nom': currentUser!.nom,
        'email': currentUser!.email,
        'type': currentUser!.type,
        'member_since': currentUser!.createdAt.toIso8601String(),
        'is_active': currentUser!.isActive,
      };
    } catch (e) {
      print('❌ Erreur stats utilisateur: $e');
      return {};
    }
  }

  // Méthode pour debug - lister tous les utilisateurs mobiles
  Future<List<Map<String, dynamic>>> debugListMobileUsers() async {
    try {
      final response = await SupabaseService.client
          .from(mobileUsersTable)
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      print('📊 Utilisateurs mobiles: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur debug utilisateurs: $e');
      return [];
    }
  }
}

final authServiceProvider = StateNotifierProvider<AuthService, AsyncValue<Utilisateur?>>((ref) {
  return AuthService();
});