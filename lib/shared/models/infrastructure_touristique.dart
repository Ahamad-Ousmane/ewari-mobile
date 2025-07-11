import 'acteur_touristique.dart';
class InfrastructureTouristique {
  final String id;
  final String acteurTouristiqueId;
  final String nom;
  final String? description;
  final String? localisation;
  final List<String> images;
  final String type;
  final Map<String, dynamic> caracteristiques;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final ActeurTouristique? acteurTouristique;

  const InfrastructureTouristique({
    required this.id,
    required this.acteurTouristiqueId,
    required this.nom,
    this.description,
    this.localisation,
    required this.images,
    required this.type,
    required this.caracteristiques,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.acteurTouristique,
  });

  factory InfrastructureTouristique.fromJson(Map<String, dynamic> json) {
    return InfrastructureTouristique(
      id: json['id'].toString(),
      acteurTouristiqueId: json['acteur_touristique_id'].toString(),
      nom: json['nom'] ?? '',
      description: json['description'],
      localisation: json['localisation'],
      images: List<String>.from(json['images'] ?? []),
      type: json['type'] ?? '',
      caracteristiques: Map<String, dynamic>.from(json['caracteristiques'] ?? {}),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      acteurTouristique: json['acteur_touristique'] != null
          ? ActeurTouristique.fromJson(json['acteur_touristique'])
          : null,
    );
  }

  String? get mainImage => images.isNotEmpty ? images.first : null;

  double? get prix {
    final prixValue = caracteristiques['prix'];
    if (prixValue is num) return prixValue.toDouble();
    if (prixValue is String) return double.tryParse(prixValue);
    return null;
  }

  int? get capacite {
    final capaciteValue = caracteristiques['capacite'];
    if (capaciteValue is num) return capaciteValue.toInt();
    if (capaciteValue is String) return int.tryParse(capaciteValue);
    return null;
  }

  List<String> get amenities {
    final amenitiesValue = caracteristiques['amenities'];
    if (amenitiesValue is List) {
      return List<String>.from(amenitiesValue);
    }
    return [];
  }

  String get typeLibelle {
    const types = {
      'hotel': 'Hôtel',
      'restaurant': 'Restaurant',
      'attraction': 'Attraction',
      'transport': 'Service de Transport',
    };
    return types[type] ?? type;
  }
}