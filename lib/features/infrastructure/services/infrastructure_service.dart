// lib/features/infrastructure/services/infrastructure_service.dart (Version finale)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/infrastructure_touristique.dart';

class InfrastructureService {

  Future<List<InfrastructureTouristique>> getInfrastructures({
    String? type,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      print('🔍 Récupération infrastructures - Type: $type, Search: $searchQuery, Limit: $limit');

      // Construire la requête
      dynamic query = SupabaseService.client
          .from('infrastructure_touristiques')
          .select('*');

      // Filtres
      if (type != null && type.isNotEmpty) {
        query = query.eq('type', type);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('nom.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // Ordre et limite
      query = query.order('created_at', ascending: false);

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      final response = await query;
      print('✅ ${response.length} infrastructures récupérées');

      return _convertToInfrastructures(response);

    } catch (e, stackTrace) {
      print('❌ Erreur getInfrastructures: $e');
      print('📚 Stack: $stackTrace');
      rethrow; // Important: relancer l'erreur pour Riverpod
    }
  }

  List<InfrastructureTouristique> _convertToInfrastructures(List<dynamic> response) {
    return response.map<InfrastructureTouristique>((json) {
      return InfrastructureTouristique(
        id: json['id'].toString(),
        acteurTouristiqueId: json['acteur_touristique_id']?.toString() ?? '0',
        nom: json['nom'] ?? 'Infrastructure sans nom',
        description: json['description'],
        localisation: json['localisation'],
        images: _parseImages(json['images']),
        type: json['type'] ?? 'autre',
        caracteristiques: json['caracteristiques'] is Map
            ? Map<String, dynamic>.from(json['caracteristiques'])
            : {},
        isActive: json['is_active'] == true || json['is_active'] == 1,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
      );
    }).toList();
  }

  List<String> _parseImages(dynamic images) {
    if (images == null) return [];

    try {
      if (images is List) {
        return images.map((e) => e.toString()).toList();
      } else if (images is String) {
        // Si c'est une chaîne JSON
        if (images.startsWith('[') && images.endsWith(']')) {
          // Parsing simple pour éviter les erreurs
          return images
              .substring(1, images.length - 1)
              .split(',')
              .map((e) => e.trim().replaceAll('"', ''))
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          return [images];
        }
      }
    } catch (e) {
      print('⚠️ Erreur parsing images: $e pour $images');
    }

    return [];
  }

  Future<InfrastructureTouristique> getInfrastructureById(String id) async {
    try {
      final response = await SupabaseService.client
          .from('infrastructure_touristiques')
          .select('*')
          .eq('id', id)
          .single();

      return _convertToInfrastructures([response]).first;
    } catch (e) {
      print('❌ Erreur getInfrastructureById: $e');
      rethrow;
    }
  }

  Future<List<InfrastructureTouristique>> getInfrastructuresNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    // Pour l'instant, retourner les infrastructures limitées
    return getInfrastructures(limit: 10);
  }
}

// Providers simplifiés
final infrastructureServiceProvider = Provider<InfrastructureService>((ref) {
  return InfrastructureService();
});

// Provider principal - SIMPLIFIÉ pour éviter les boucles
final infrastructuresProvider = FutureProvider.autoDispose
    .family<List<InfrastructureTouristique>, Map<String, String?>>((ref, filters) async {
  print('🔄 Provider appelé avec filtres: $filters');

  final service = ref.read(infrastructureServiceProvider);

  try {
    final result = await service.getInfrastructures(
      type: filters['type'],
      searchQuery: filters['search'],
    );
    print('🎯 Provider terminé: ${result.length} éléments');
    return result;
  } catch (e) {
    print('❌ Provider erreur: $e');
    rethrow;
  }
});

final infrastructureDetailProvider = FutureProvider.autoDispose
    .family<InfrastructureTouristique, String>((ref, id) async {
  final service = ref.read(infrastructureServiceProvider);
  return service.getInfrastructureById(id);
});