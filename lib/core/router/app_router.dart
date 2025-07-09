import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/infrastructure/presentation/screens/infrastructure_list_screen.dart';
import '../../features/infrastructure/presentation/screens/infrastructure_detail_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/ar/presentation/screens/ar_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/screens/loading_screen.dart';
import '../navigation/main_shell.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authServiceProvider);
  final onboardingState = ref.watch(onboardingServiceProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final currentLocation = state.matchedLocation;

      // Gérer les états de chargement
      final isOnboardingLoading = onboardingState.isLoading;
      final isAuthLoading = authState.isLoading;

      // Si on est en train de charger l'état d'onboarding, afficher le loading
      if (isOnboardingLoading) {
        print('⏳ Chargement état onboarding...');
        return '/loading';
      }

      // Récupérer les valeurs une fois le chargement terminé
      final isOnboardingCompleted = onboardingState.when(
        data: (completed) => completed,
        loading: () => false,
        error: (_, __) => false,
      );

      final isLoggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );

      print('🔄 Router redirect - Location: $currentLocation');
      print('📱 Onboarding completed: $isOnboardingCompleted');
      print('🔐 User logged in: $isLoggedIn');
      print('⏳ Auth loading: $isAuthLoading');

      // Éviter les redirections en boucle vers loading
      if (currentLocation == '/loading' && !isOnboardingLoading) {
        print('🔄 Sortie du loading...');
        return '/';
      }

      // 1. Si onboarding pas complété et pas déjà sur l'onboarding
      if (!isOnboardingCompleted && currentLocation != '/onboarding') {
        print('➡️ Redirection vers onboarding');
        return '/onboarding';
      }

      // 2. Si onboarding complété mais on est encore sur la page onboarding
      if (isOnboardingCompleted && currentLocation == '/onboarding') {
        print('➡️ Redirection vers login après onboarding');
        return '/login';
      }

      // 3. Si onboarding complété mais pas connecté et pas sur les pages auth
      if (isOnboardingCompleted && !isLoggedIn &&
          currentLocation != '/login' &&
          currentLocation != '/register' &&
          currentLocation != '/loading') {
        print('➡️ Redirection vers login (connexion requise)');
        return '/login';
      }

      // 4. Si connecté et sur les pages auth, rediriger vers l'accueil
      if (isLoggedIn && (currentLocation == '/login' || currentLocation == '/register')) {
        print('➡️ Redirection vers home (déjà connecté)');
        return '/';
      }

      print('✅ Pas de redirection nécessaire');
      return null; // Pas de redirection
    },
    routes: [
      // Loading screen
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),

      // Onboarding Route (sans shell - plein écran)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes (sans shell - plein écran)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Shell principal avec bottom navigation (NÉCESSITE CONNEXION)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Main Routes avec navigation (toutes protégées)
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/infrastructures',
            name: 'infrastructures',
            builder: (context, state) => const InfrastructureListScreen(),
          ),
          GoRoute(
            path: '/infrastructure/:id',
            name: 'infrastructure-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InfrastructureDetailScreen(infrastructureId: id);
            },
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/ar',
            name: 'ar',
            builder: (context, state) => const ARScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});