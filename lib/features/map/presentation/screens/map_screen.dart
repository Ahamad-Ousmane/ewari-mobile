import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/models/infrastructure_touristique.dart';
import '../../../infrastructure/services/infrastructure_service.dart';
import '../../../../core/utils/navigation_helper.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _controller;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isLoadingInfrastructures = true;
  String? _error;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Données des infrastructures avec marqueurs et itinéraires
  List<InfrastructureTouristique> _infrastructures = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Filtres et recherche
  String? _selectedType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Clé API Google
  static const String _googleApiKey = 'ma clé';

  final List<Map<String, dynamic>> _availableTypes = [
    {'id': null, 'label': 'Tout', 'icon': Icons.explore, 'color': Color(0xFF6C63FF)},
    {'id': 'hotel', 'label': 'Hôtels', 'icon': Icons.hotel, 'color': Color(0xFF6C63FF)},
    {'id': 'restaurant', 'label': 'Restaurants', 'icon': Icons.restaurant, 'color': Color(0xFFFF6B6B)},
    {'id': 'attraction', 'label': 'Attractions', 'icon': Icons.beach_access, 'color': Color(0xFF4ECDC4)},
    {'id': 'transport', 'label': 'Transport', 'icon': Icons.directions_bus, 'color': Color(0xFF95E1D3)},
  ];

  // Coordonnées par défaut (Cotonou, Bénin)
  static const LatLng _defaultPosition = LatLng(6.3654, 2.4183);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    _loadInfrastructures();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Démarrer les animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      print('✅ Position actuelle: ${position.latitude}, ${position.longitude}');

      // Centrer la carte sur la position de l'utilisateur
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            12,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur géolocalisation: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadInfrastructures() async {
    try {
      setState(() {
        _isLoadingInfrastructures = true;
        _error = null;
      });

      print('🔄 Chargement des infrastructures - Type: $_selectedType, Recherche: "$_searchQuery"');

      final service = ref.read(infrastructureServiceProvider);
      final infrastructures = await service.getInfrastructures(
        type: _selectedType,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _infrastructures = infrastructures;
        _isLoadingInfrastructures = false;
      });

      print('✅ ${infrastructures.length} infrastructures chargées');

      // Charger automatiquement les marqueurs pour les premières infrastructures
      await _loadInitialMarkers();

    } catch (e) {
      print('❌ Erreur chargement infrastructures: $e');
      setState(() {
        _error = e.toString();
        _isLoadingInfrastructures = false;
      });
    }
  }

  // Charger automatiquement quelques marqueurs au démarrage
  Future<void> _loadInitialMarkers() async {
    final Set<Marker> markers = {};

    // Prendre les 5 premières infrastructures pour éviter trop d'appels API
    final initialInfrastructures = _infrastructures.take(5);

    for (final infrastructure in initialInfrastructures) {
      final coords = await _geocodeInfrastructure(infrastructure);
      if (coords != null) {
        markers.add(
          Marker(
            markerId: MarkerId(infrastructure.id),
            position: coords,
            icon: await _getMarkerIcon(infrastructure.type),
            infoWindow: InfoWindow(
              title: infrastructure.nom,
              snippet: infrastructure.localisation ?? 'Cliquez pour plus d\'infos',
              onTap: () => context.push('/infrastructure/${infrastructure.id}'),
            ),
            onTap: () => _onMarkerTap(infrastructure, coords),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });

    print('✅ ${markers.length} marqueurs initiaux chargés');
  }

  // Géocodage avec Google Geocoding API
  Future<LatLng?> _geocodeInfrastructure(InfrastructureTouristique infrastructure) async {
    try {
      String query = infrastructure.nom;
      if (infrastructure.localisation != null && infrastructure.localisation!.isNotEmpty) {
        query += ' ${infrastructure.localisation}';
      }
      query += ' Bénin';

      print('🔍 Géocodage Google: "$query"');

      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedQuery&key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final coords = LatLng(location['lat'], location['lng']);
          print('✅ Géocodage réussi: $query → ${coords.latitude}, ${coords.longitude}');
          return coords;
        } else {
          print('❌ Géocodage échoué pour "$query": ${data['status']}');
        }
      } else {
        print('❌ Erreur HTTP géocodage: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur géocodage ${infrastructure.nom}: $e');
    }

    return null;
  }

  // Localiser une infrastructure dans la carte
  Future<void> _locateInfrastructure(InfrastructureTouristique infrastructure) async {
    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Localisation en cours...'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      }

      // Vérifier si on a déjà le marqueur
      final existingMarker = _markers.where((m) => m.markerId.value == infrastructure.id).firstOrNull;

      LatLng? coords;
      if (existingMarker != null) {
        coords = existingMarker.position;
        print('✅ Marqueur existant trouvé pour ${infrastructure.nom}');
      } else {
        // Géocoder l'infrastructure
        coords = await _geocodeInfrastructure(infrastructure);
        if (coords != null) {
          // Ajouter le marqueur
          final marker = Marker(
            markerId: MarkerId(infrastructure.id),
            position: coords,
            icon: await _getMarkerIcon(infrastructure.type),
            infoWindow: InfoWindow(
              title: infrastructure.nom,
              snippet: infrastructure.localisation ?? 'Cliquez pour plus d\'infos',
              onTap: () => context.push('/infrastructure/${infrastructure.id}'),
            ),
            onTap: () => _onMarkerTap(infrastructure, coords!),
          );

          setState(() {
            _markers.add(marker);
          });
          print('✅ Nouveau marqueur ajouté pour ${infrastructure.nom}');
        }
      }

      if (coords != null && _controller != null) {
        // Centrer la carte sur l'infrastructure
        await _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(coords, 16),
        );

        // Message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.place, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('📍 ${infrastructure.nom} localisé sur la carte')),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Impossible de localiser cette infrastructure');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Afficher l'itinéraire vers une infrastructure avec Google Directions API
  Future<void> _showDirections(InfrastructureTouristique infrastructure) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position actuelle non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Calcul de l\'itinéraire...'),
              ],
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // D'abord localiser l'infrastructure
      await _locateInfrastructure(infrastructure);

      // Trouver le marqueur de l'infrastructure
      final marker = _markers.where((m) => m.markerId.value == infrastructure.id).firstOrNull;
      if (marker == null) {
        throw Exception('Marqueur de l\'infrastructure non trouvé');
      }

      final destination = marker.position;
      final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

      print('🚗 Calcul itinéraire: ${origin.latitude},${origin.longitude} → ${destination.latitude},${destination.longitude}');

      // Obtenir l'itinéraire avec Google Directions API
      final routeData = await _getDirections(origin, destination);

      if (routeData != null) {
        setState(() {
          _polylines.clear();
          _polylines.add(routeData['polyline']);
        });

        // Ajuster la vue pour montrer tout l'itinéraire
        if (_controller != null) {
          await _controller!.animateCamera(
            CameraUpdate.newLatLngBounds(
              routeData['bounds'],
              100, // padding
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.directions, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🚗 Itinéraire vers ${infrastructure.nom} (${routeData['distance']}, ${routeData['duration']})',
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.blue,
              action: SnackBarAction(
                label: 'Effacer',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _polylines.clear();
                  });
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Impossible de calculer l\'itinéraire');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur itinéraire: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Obtenir l'itinéraire avec Google Directions API
  Future<Map<String, dynamic>?> _getDirections(LatLng origin, LatLng destination) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&key=$_googleApiKey&language=fr';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Extraire les informations de l'itinéraire
          final points = route['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);

          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];

          // Créer la polyline
          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            points: decodedPoints,
            color: const Color(0xFF6C63FF),
            width: 5,
            patterns: [PatternItem.dot, PatternItem.gap(10)],
          );

          // Créer les bounds
          final bounds = _boundsFromLatLngList([origin, destination, ...decodedPoints]);

          print('✅ Itinéraire calculé: $distance, $duration');

          return {
            'polyline': polyline,
            'bounds': bounds,
            'distance': distance,
            'duration': duration,
          };
        } else {
          print('❌ Directions API erreur: ${data['status']}');
        }
      } else {
        print('❌ Erreur HTTP Directions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur directions: $e');
    }

    return null;
  }

  // Décoder les points de la polyline Google
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Créer les bounds pour ajuster la vue
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double minLat = list.first.latitude;
    double maxLat = list.first.latitude;
    double minLng = list.first.longitude;
    double maxLng = list.first.longitude;

    for (LatLng coord in list) {
      minLat = math.min(minLat, coord.latitude);
      maxLat = math.max(maxLat, coord.latitude);
      minLng = math.min(minLng, coord.longitude);
      maxLng = math.max(maxLng, coord.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // Obtenir l'icône du marqueur selon le type
  Future<BitmapDescriptor> _getMarkerIcon(String type) async {
    switch (type.toLowerCase()) {
      case 'hotel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'attraction':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'transport':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _onMarkerTap(InfrastructureTouristique infrastructure, LatLng position) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Text(
              infrastructure.nom,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Localisation
            if (infrastructure.localisation != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      infrastructure.localisation!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],

            // Description
            if (infrastructure.description != null) ...[
              const SizedBox(height: 12),
              Text(
                infrastructure.description!,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/infrastructure/${infrastructure.id}');
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDirections(infrastructure);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    if (_currentPosition != null && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    } else {
      await _getCurrentLocation();
    }
  }

  void _onTypeFilterChanged(String? type) {
    setState(() {
      _selectedType = type;
      _markers.clear(); // Effacer les marqueurs lors du changement de filtre
      _polylines.clear(); // Effacer les itinéraires
    });
    _loadInfrastructures();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        setState(() {
          _markers.clear(); // Effacer les marqueurs lors de la recherche
          _polylines.clear(); // Effacer les itinéraires
        });
        _loadInfrastructures();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header moderne avec titre
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6C63FF),
                  const Color(0xFF9C88FF),
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Bouton retour sécurisé
                  NavigationHelper.buildSafeBackButton(
                    context,
                    fallbackRoute: '/',
                    iconColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),

                  const SizedBox(width: 16),

                  // Titre et sous-titre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Carte Interactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_infrastructures.length} lieux • ${_markers.length} marqueurs',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isLoadingInfrastructures
                                ? Colors.orange
                                : Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoadingInfrastructures ? 'Sync...' : 'En ligne',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Carte Google Maps AVEC marqueurs et polylines
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : _defaultPosition,
                    zoom: 10,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    // Style moderne pour la carte
                    controller.setMapStyle('''
                    [
                      {
                        "featureType": "poi",
                        "elementType": "labels",
                        "stylers": [{"visibility": "off"}]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [{"color": "#4ECDC4"}]
                      },
                      {
                        "featureType": "landscape",
                        "elementType": "geometry",
                        "stylers": [{"color": "#f8f9fa"}]
                      }
                    ]
                    ''');
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  mapType: MapType.normal,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // Boutons flottants
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Bouton effacer itinéraires
                      if (_polylines.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _polylines.clear();
                              });
                            },
                            icon: const Icon(Icons.clear, color: Colors.white),
                            tooltip: 'Effacer itinéraires',
                          ),
                        ),

                      // Bouton de localisation
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _isLoadingLocation ? null : _centerOnUserLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6C63FF),
                            ),
                          )
                              : const Icon(
                            Icons.my_location,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section de recherche et liste (plus compacte)
          Expanded(
            flex: 2,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Barre de recherche et filtres
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Barre de recherche
                          TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Rechercher un lieu...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                icon: const Icon(Icons.clear),
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Filtres par type (plus compacts)
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availableTypes.length,
                              itemBuilder: (context, index) {
                                final type = _availableTypes[index];
                                final isSelected = _selectedType == type['id'];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          type['icon'],
                                          size: 16,
                                          color: isSelected ? Colors.white : type['color'],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          type['label'],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    onSelected: (selected) {
                                      _onTypeFilterChanged(selected ? type['id'] : null);
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: type['color'],
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    side: BorderSide(
                                      color: isSelected ? type['color'] : Colors.grey[300]!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Liste des infrastructures (compacte)
                    Expanded(
                      child: _isLoadingInfrastructures
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF6C63FF)),
                            const SizedBox(height: 16),
                            const Text('Chargement des lieux...'),
                          ],
                        ),
                      )
                          : _error != null
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                            const SizedBox(height: 16),
                            const Text('Erreur de chargement'),
                            const SizedBox(height: 8),
                            Text(_error!, style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadInfrastructures,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                          : _infrastructures.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.place_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Aucune infrastructure trouvée'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedType = null;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _loadInfrastructures();
                              },
                              child: const Text('Réinitialiser les filtres'),
                            ),
                          ],
                        ),
                      )
                          : RefreshIndicator(
                        onRefresh: _loadInfrastructures,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _infrastructures.length,
                          itemBuilder: (context, index) {
                            final infrastructure = _infrastructures[index];
                            final typeData = _availableTypes.firstWhere(
                                  (t) => t['id'] == infrastructure.type,
                              orElse: () => _availableTypes.first,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  typeData['icon'],
                                  color: typeData['color'],
                                ),
                                title: Text(
                                  infrastructure.nom,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  infrastructure.localisation ?? 'Localisation non renseignée',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _locateInfrastructure(infrastructure),
                                      icon: const Icon(Icons.place, color: Color(0xFF6C63FF), size: 20),
                                      tooltip: 'Localiser',
                                      visualDensity: VisualDensity.compact,
                                    ),

                                    IconButton(
                                      onPressed: () => context.push('/infrastructure/${infrastructure.id}'),
                                      icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                      tooltip: 'Détails',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}