import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService extends StateNotifier<AsyncValue<bool>> {
  OnboardingService() : super(const AsyncValue.loading()) {
    _loadOnboardingState();
  }

  static const String _onboardingKey = 'onboarding_completed';

  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_onboardingKey) ?? false;
      state = AsyncValue.data(completed);
      print('📱 Onboarding state loaded: $completed');
    } catch (e, stackTrace) {
      print('❌ Erreur chargement onboarding: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      state = const AsyncValue.data(true);
      print('✅ Onboarding marqué comme terminé');
    } catch (e, stackTrace) {
      print('❌ Erreur sauvegarde onboarding: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, false);
      state = const AsyncValue.data(false);
      print('🔄 Onboarding reset');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  bool get isCompleted => state.when(
    data: (completed) => completed,
    loading: () => false,
    error: (_, __) => false,
  );
}

// Provider pour le service d'onboarding
final onboardingServiceProvider = StateNotifierProvider<OnboardingService, AsyncValue<bool>>((ref) {
  return OnboardingService();
});

// Provider simple pour l'état booléen
final isOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingServiceProvider).when(
    data: (completed) => completed,
    loading: () => false,
    error: (_, __) => false,
  );
});