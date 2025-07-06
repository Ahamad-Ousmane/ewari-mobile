class AppConfig {
  static const String supabaseUrl = 'https://gpogbnmvkvpzphtbosai.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdwb2dibm12a3ZwenBodGJvc2FpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxODAyNTMsImV4cCI6MjA2NTc1NjI1M30.I8rOoCMcEckFG85zo6vl9HZ34a69VqVByeim2sPCVBg';

  // Types d'infrastructures
  static const Map<String, String> infrastructureTypes = {
    'hotel': 'Hôtel',
    'restaurant': 'Restaurant',
    'plage': 'Espace Plage',
    'transport': 'Service de Transport',
  };

  // Types d'utilisateurs
  static const Map<String, String> userTypes = {
    'admin': 'Administrateur',
    'acteur_touristique': 'Acteur Touristique',
    'touriste': 'Touriste',
  };
}