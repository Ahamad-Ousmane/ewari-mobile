import 'utilisateur.dart';

class ActeurTouristique {
  final String id;
  final String utilisateurId;
  final String nomEntreprise;
  final String? description;
  final String? adresse;
  final String? siteWeb;
  final Map<String, dynamic> reseauxSociaux;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final Utilisateur? utilisateur;

  const ActeurTouristique({
    required this.id,
    required this.utilisateurId,
    required this.nomEntreprise,
    this.description,
    this.adresse,
    this.siteWeb,
    required this.reseauxSociaux,
    required this.createdAt,
    required this.updatedAt,
    this.utilisateur,
  });

  factory ActeurTouristique.fromJson(Map<String, dynamic> json) {
    return ActeurTouristique(
      id: json['id'].toString(),
      utilisateurId: json['utilisateur_id'].toString(),
      nomEntreprise: json['nom_entreprise'] ?? '',
      description: json['description'],
      adresse: json['adresse'],
      siteWeb: json['site_web'],
      reseauxSociaux: Map<String, dynamic>.from(json['reseaux_sociaux'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      utilisateur: json['utilisateur'] != null
          ? Utilisateur.fromJson(json['utilisateur'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'nom_entreprise': nomEntreprise,
      'description': description,
      'adresse': adresse,
      'site_web': siteWeb,
      'reseaux_sociaux': reseauxSociaux,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (utilisateur != null) 'utilisateur': utilisateur!.toJson(),
    };
  }
}