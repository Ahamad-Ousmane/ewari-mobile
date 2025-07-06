// lib/shared/models/infrastructure_touristique_extension.dart
// VERSION SANS CACHE - POUR DEBUG COMPLET

import 'dart:math' as math;
import 'infrastructure_touristique.dart';

// Extension simplifiée SANS CACHE
extension InfrastructureTouristiqueExtension on InfrastructureTouristique {

  // Méthode principale SANS cache - calcul direct
  Future<MapCoordinates?> geocodeAndCache({bool forceRefresh = false}) async {
    print('🚀 === DEBUT GEOCODAGE SANS CACHE ===');
    print('📋 Infrastructure ID: $id');
    print('📋 Infrastructure nom: $nom');
    print('📋 Infrastructure localisation BRUTE: "$localisation"');
    print('📋 Infrastructure localisation type: ${localisation.runtimeType}');
    print('📋 Infrastructure localisation length: ${localisation?.length}');

    if (localisation == null || localisation!.isEmpty) {
      print('❌ PROBLÈME: Localisation vide ou null');
      return null;
    }

    // Calcul direct des coordonnées
    final coords = _getCoordinatesFromLocation();
    print('🎯 RÉSULTAT FINAL: $coords');
    print('🚀 === FIN GEOCODAGE SANS CACHE ===');

    return coords;
  }

  // Méthode pour calculer les coordonnées (AVEC LOGS DÉTAILLÉS)
  MapCoordinates? _getCoordinatesFromLocation() {
    if (localisation == null || localisation!.isEmpty) {
      print('❌ Localisation vide dans _getCoordinatesFromLocation');
      return null;
    }

    final location = localisation!.toLowerCase().trim();
    print('🔍 === ANALYSE LOCALISATION ===');
    print('🔍 Localisation originale: "$localisation"');
    print('🔍 Localisation normalisée: "$location"');
    print('🔍 Localisation length: ${location.length}');

    // Base de données des lieux du Bénin (SIMPLIFÉE POUR DEBUG)
    final Map<String, MapCoordinates> knownLocations = {
      'cotonou': MapCoordinates(latitude: 6.3654, longitude: 2.4183),
      'porto novo': MapCoordinates(latitude: 6.4969, longitude: 2.6281),
      'porto-novo': MapCoordinates(latitude: 6.4969, longitude: 2.6281),
      'ouidah': MapCoordinates(latitude: 6.3622, longitude: 2.0856),
      'abomey': MapCoordinates(latitude: 7.1833, longitude: 1.9833),
      'parakou': MapCoordinates(latitude: 9.3372, longitude: 2.6303),
      'natitingou': MapCoordinates(latitude: 10.3167, longitude: 1.3833),
      'kandi': MapCoordinates(latitude: 11.1167, longitude: 2.9333),
      'bohicon': MapCoordinates(latitude: 7.1667, longitude: 2.0667),
      'lokossa': MapCoordinates(latitude: 6.6333, longitude: 1.7167),
      'djougou': MapCoordinates(latitude: 9.7000, longitude: 1.6667),
      'ganvie': MapCoordinates(latitude: 6.4667, longitude: 2.4167),
      'place rouge cotonou': MapCoordinates(latitude: 6.3576, longitude: 2.4154),
      'marche dantokpa': MapCoordinates(latitude: 6.3698, longitude: 2.4289),
      'plage fidjrosse': MapCoordinates(latitude: 6.3123, longitude: 2.3987),
      'akpakpa': MapCoordinates(latitude: 6.3423, longitude: 2.4356),
      'godomey': MapCoordinates(latitude: 6.3789, longitude: 2.4012),
      'allada': MapCoordinates(latitude: 6.6667, longitude: 2.1500),
      'savalou': MapCoordinates(latitude: 7.9167, longitude: 1.9833),
      'pobe': MapCoordinates(latitude: 6.9833, longitude: 2.6667),
      'aplahoue': MapCoordinates(latitude: 6.9333, longitude: 1.6833),
      'dogbo': MapCoordinates(latitude: 6.8000, longitude: 1.7833),
      'come': MapCoordinates(latitude: 6.4000, longitude: 1.8833),
      'sakete': MapCoordinates(latitude: 6.7333, longitude: 2.6500),
    };

    print('🔍 Vérification correspondance exacte...');
    // Recherche exacte d'abord
    if (knownLocations.containsKey(location)) {
      final coords = knownLocations[location]!;
      print('✅ CORRESPONDANCE EXACTE trouvée pour "$location": $coords');
      return coords;
    } else {
      print('❌ Aucune correspondance exacte pour "$location"');
    }

    print('🔍 Vérification correspondances partielles...');
    // Recherche par correspondance partielle avec logs détaillés
    for (final entry in knownLocations.entries) {
      final key = entry.key;
      final value = entry.value;

      print('   🔍 Test: "$location" contient "$key" ? ${location.contains(key)}');
      print('   🔍 Test: "$key" contient "$location" ? ${key.contains(location)}');

      if (location.contains(key) || key.contains(location)) {
        print('✅ CORRESPONDANCE PARTIELLE trouvée: "$key" → $value');
        return value;
      }
    }
    print('❌ Aucune correspondance partielle trouvée');

    print('🔍 Vérification par régions...');
    // Recherche par région/département avec logs détaillés
    final List<Map<String, dynamic>> regions = [
      {
        'test': location.contains('littoral') || location.contains('cotonou'),
        'name': 'Littoral/Cotonou',
        'coords': MapCoordinates(latitude: 6.3654, longitude: 2.4183),
      },
      {
        'test': location.contains('oueme') || location.contains('porto'),
        'name': 'Ouémé/Porto-Novo',
        'coords': MapCoordinates(latitude: 6.4969, longitude: 2.6281),
      },
      {
        'test': location.contains('atlantique') || location.contains('ouidah'),
        'name': 'Atlantique/Ouidah',
        'coords': MapCoordinates(latitude: 6.3622, longitude: 2.0856),
      },
      {
        'test': location.contains('zou') || location.contains('abomey'),
        'name': 'Zou/Abomey',
        'coords': MapCoordinates(latitude: 7.1833, longitude: 1.9833),
      },
      {
        'test': location.contains('borgou') || location.contains('parakou'),
        'name': 'Borgou/Parakou',
        'coords': MapCoordinates(latitude: 9.3372, longitude: 2.6303),
      },
      {
        'test': location.contains('atacora') || location.contains('natitingou'),
        'name': 'Atacora/Natitingou',
        'coords': MapCoordinates(latitude: 10.3167, longitude: 1.3833),
      },
      {
        'test': location.contains('alibori') || location.contains('kandi'),
        'name': 'Alibori/Kandi',
        'coords': MapCoordinates(latitude: 11.1167, longitude: 2.9333),
      },
      {
        'test': location.contains('mono') || location.contains('lokossa'),
        'name': 'Mono/Lokossa',
        'coords': MapCoordinates(latitude: 6.6333, longitude: 1.7167),
      },
      {
        'test': location.contains('couffo') || location.contains('aplahoue'),
        'name': 'Couffo/Aplahoué',
        'coords': MapCoordinates(latitude: 6.9333, longitude: 1.6833),
      },
      {
        'test': location.contains('plateau') || location.contains('pobe'),
        'name': 'Plateau/Pobè',
        'coords': MapCoordinates(latitude: 6.9833, longitude: 2.6667),
      },
      {
        'test': location.contains('collines') || location.contains('savalou'),
        'name': 'Collines/Savalou',
        'coords': MapCoordinates(latitude: 7.9167, longitude: 1.9833),
      },
      {
        'test': location.contains('donga') || location.contains('djougou'),
        'name': 'Donga/Djougou',
        'coords': MapCoordinates(latitude: 9.7000, longitude: 1.6667),
      },
    ];

    for (final region in regions) {
      print('   🔍 Test région ${region['name']}: ${region['test']}');
      if (region['test'] == true) {
        final coords = region['coords'] as MapCoordinates;
        print('✅ RÉGION DÉTECTÉE: ${region['name']} → $coords');
        return coords;
      }
    }
    print('❌ Aucune région détectée');

    // Fallback au centre du Bénin
    final fallback = MapCoordinates(latitude: 9.30769, longitude: 2.31583);
    print('⚠️ UTILISATION DU FALLBACK: $fallback');
    return fallback;
  }

  // Méthodes conservées pour compatibilité (mais SANS cache)
  Future<bool> get hasCoordinates async => false;

  Future<MapCoordinates?> get coordinates async => null;

  Future<void> clearCoordinatesCache() async {
    print('🗑️ clearCoordinatesCache appelé (mais pas de cache)');
  }

  // Petite variation aléatoire pour éviter les superpositions (DÉSACTIVÉE pour debug)
  double _getRandomOffset() {
    return 0.0; // Désactivé pour debug
  }

  // Méthode pour obtenir des coordonnées de fallback (conservée pour compatibilité)
  MapCoordinates? _getFallbackCoordinates() {
    return _getCoordinatesFromLocation();
  }
}

// Classe MapCoordinates simplifiée
class MapCoordinates {
  final double latitude;
  final double longitude;

  const MapCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'MapCoordinates($latitude, $longitude)';

  double distanceTo(MapCoordinates other) {
    const double earthRadius = 6371;
    double lat1Rad = latitude * (math.pi / 180);
    double lat2Rad = other.latitude * (math.pi / 180);
    double deltaLat = (other.latitude - latitude) * (math.pi / 180);
    double deltaLng = (other.longitude - longitude) * (math.pi / 180);

    double a = math.pow(math.sin(deltaLat / 2), 2) +
        math.pow(math.sin(deltaLng / 2), 2) *
            math.cos(lat1Rad) * math.cos(lat2Rad);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }
}

// Service pour gérer le géocodage en lot (VERSION SANS CACHE)
class GeocodeService {
  // Géocoder une liste d'infrastructures (version sans cache)
  static Future<Map<String, MapCoordinates>> geocodeInfrastructures(
      List<InfrastructureTouristique> infrastructures
      ) async {
    final Map<String, MapCoordinates> results = {};

    for (final infrastructure in infrastructures) {
      try {
        final coords = await infrastructure.geocodeAndCache();
        if (coords != null) {
          results[infrastructure.id] = coords;
        }
      } catch (e) {
        print('❌ Erreur géocodage ${infrastructure.nom}: $e');
      }
    }

    print('✅ Géocodage terminé: ${results.length}/${infrastructures.length} infrastructures localisées');
    return results;
  }

  // Version rapide pour le développement (sans cache)
  static Future<Map<String, MapCoordinates>> geocodeInfrastructuresFast(
      List<InfrastructureTouristique> infrastructures
      ) async {
    final Map<String, MapCoordinates> results = {};

    for (final infrastructure in infrastructures) {
      try {
        final coords = infrastructure._getCoordinatesFromLocation();
        if (coords != null) {
          results[infrastructure.id] = coords;
        }
      } catch (e) {
        print('❌ Erreur géocodage rapide ${infrastructure.nom}: $e');
      }
    }

    print('⚡ Géocodage rapide: ${results.length}/${infrastructures.length} infrastructures localisées');
    return results;
  }

  // Effacer tout le cache (pour debug - mais pas de cache dans cette version)
  static Future<void> clearAllCache() async {
    print('🗑️ clearAllCache appelé (mais pas de cache dans cette version)');
  }
}