class Utilisateur {
  final String id;
  final String nom;
  final String email;
  final String? telephone;
  final String type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    required this.type,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing utilisateur JSON: $json');

      return Utilisateur(
        id: json['id']?.toString() ?? '', // Force conversion en string
        nom: json['nom']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        telephone: json['telephone']?.toString(),
        type: json['type']?.toString() ?? 'touriste',
        isActive: _parseBool(json['is_active']),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      print('❌ Erreur parsing Utilisateur: $e');
      print('❌ JSON reçu: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'type': type,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return true;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Erreur parsing date: $value');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  bool get isAdmin => type == 'admin';
  bool get isActeurTouristique => type == 'acteur_touristique';
  bool get isTouriste => type == 'touriste';

  @override
  String toString() {
    return 'Utilisateur(id: $id, nom: $nom, email: $email, type: $type)';
  }
}