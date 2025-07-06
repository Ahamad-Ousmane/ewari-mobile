import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Tables
  static const String utilisateursTable = 'utilisateurs';
  static const String acteursTouristiquesTable = 'acteurs_touristiques';
  static const String infrastructuresTouristiquesTable = 'infrastructure_touristiques';
  static const String raContenusTable = 'ra_contenus';
}