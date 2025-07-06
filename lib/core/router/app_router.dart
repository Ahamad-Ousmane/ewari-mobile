import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/infrastructure/presentation/screens/infrastructure_list_screen.dart';
import '../../features/infrastructure/presentation/screens/infrastructure_detail_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../navigation/main_shell.dart';
import '../services/auth_service.dart';

// Provider pour vérifier l'état de l'onboarding
final onboardingStateProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authServiceProvider);
  final onboardingState = ref.watch(onboardingStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isLoggedIn = authState.value != null;
      final isProfileRoute = state.matchedLocation == '/profile';

      // Vérifier si l'onboarding a été complété
      final hasCompletedOnboarding = await onboardingState.when(
        data: (completed) => completed,
        loading: () => false,
        error: (_, __) => false,
      );

      // Si onboarding pas complété et pas déjà sur l'onboarding
      if (!hasCompletedOnboarding && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      // Si onboarding complété mais on est encore sur la page onboarding
      if (hasCompletedOnboarding && state.matchedLocation == '/onboarding') {
        return '/';
      }

      // Redirection uniquement pour l'écran de profil si non connecté
      if (!isLoggedIn && isProfileRoute) {
        return '/login';
      }

      return null; // Pas de redirection pour les autres routes
    },
    routes: [
      // Onboarding Route (sans shell)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Shell principal avec bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Main Routes avec navigation
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
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
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
    ],
  );
});