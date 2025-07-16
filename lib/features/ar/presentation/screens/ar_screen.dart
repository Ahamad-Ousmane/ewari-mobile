import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter/services.dart';

class ARScreen extends ConsumerStatefulWidget {
  const ARScreen({super.key});

  @override
  ConsumerState<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends ConsumerState<ARScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const platform = MethodChannel('unity_channel');

  bool _isARSupported = true; // Pour simuler la détection AR
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkARSupport();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  void _checkARSupport() {
    // Ici vous pourrez intégrer la vérification réelle AR
    // Par exemple avec ARCore/ARKit
    setState(() {
      _isARSupported = true; // Simule que l'AR est supportée
    });
  }

  Future<void> _startARExperience() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await platform.invokeMethod('launchUnity');
    } on PlatformException catch (e) {
      print("Erreur lors du lancement d'Unity : ${e.message}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authServiceProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Header avec design cohérent
          _buildARHeader(user),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),

                if (!_isARSupported)
                  _buildARNotSupportedCard()
                else ...[
                  // Section principale AR
                  _buildMainARSection(),

                  const SizedBox(height: 24),

                  // Expériences AR disponibles
                  _buildARExperiences(),

                  const SizedBox(height: 24),

                  // Comment utiliser l'AR
                  _buildHowToUseSection(),

                  const SizedBox(height: 100), // Espace pour la bottom nav
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARHeader(user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 24,
          right: 24,
          bottom: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea), // Bleu AR
              Color(0xFF764ba2), // Violet AR
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              // Icon AR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Titre et sous-titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Réalité Augmentée',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Découverte Interactive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton info
              _buildHeaderAction(Icons.info_outline, () {
                _showARInfoDialog();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMainARSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF8B5CF6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge beta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🚀 EXPÉRIENCE IMMERSIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Titre principal
              const Text(
                'Explorez le Bénin en Réalité Augmentée',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Découvrez l\'histoire cachée des monuments, visualisez les sites touristiques en 3D et vivez une expérience interactive unique.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // Bouton principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startARExperience,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                    ),
                  )
                      : const Icon(Icons.camera_alt, color: Color(0xFF667eea)),
                  label: Text(
                    _isLoading ? 'Initialisation...' : 'Lancer l\'AR',
                    style: const TextStyle(
                      color: Color(0xFF667eea),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildARExperiences() {
    final experiences = [
      {
        'title': 'Monuments Historiques',
        'description': 'Découvrez l\'histoire cachée des monuments avec des infographies 3D',
        'icon': Icons.account_balance,
        'color': const Color(0xFF6C63FF),
        'available': true,
      },
      {
        'title': 'Sites Touristiques',
        'description': 'Visualisez les sites en 3D avant votre visite',
        'icon': Icons.landscape,
        'color': const Color(0xFF4ECDC4),
        'available': true,
      },
      {
        'title': 'Culture & Traditions',
        'description': 'Immersion dans les traditions béninoises',
        'icon': Icons.theater_comedy,
        'color': const Color(0xFFFF6B6B),
        'available': false,
      },
      {
        'title': 'Navigation AR',
        'description': 'Guidage visuel pour vos déplacements',
        'icon': Icons.navigation,
        'color': const Color(0xFFFFE66D),
        'available': false,
      },
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expériences AR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.view_in_ar,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid des expériences
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: experiences.length,
              itemBuilder: (context, index) {
                final experience = experiences[index];
                return _buildExperienceCard(experience, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> experience, int index) {
    final isAvailable = experience['available'] as bool;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: isAvailable ? () => _startSpecificARExperience(experience['title'] as String) : null,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon avec background coloré
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (experience['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            experience['icon'] as IconData,
                            color: experience['color'] as Color,
                            size: 24,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Titre
                        Text(
                          experience['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isAvailable ? Colors.black87 : Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Description
                        Expanded(
                          child: Text(
                            experience['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isAvailable ? Colors.grey[600] : Colors.grey[400],
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge "Bientôt disponible" pour les expériences non disponibles
                  if (!isAvailable)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bientôt',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHowToUseSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Color(0xFF667eea),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Comment utiliser l\'AR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...List.generate(3, (index) {
              final steps = [
                'Pointez votre caméra vers un monument ou site touristique',
                'L\'application détectera automatiquement le lieu',
                'Découvrez les informations 3D et interactives',
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildARNotSupportedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 48,
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'AR non supportée',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre appareil ne supporte pas la réalité augmentée ou les permissions nécessaires ne sont pas accordées.',
            style: TextStyle(
              color: Colors.orange.shade600,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _startSpecificARExperience(String experienceTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎯 Lancement de "$experienceTitle" (Mode démo)'),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showARInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF667eea)),
            SizedBox(width: 8),
            Text('À propos de l\'AR'),
          ],
        ),
        content: const Text(
          'La réalité augmentée vous permet de découvrir le patrimoine béninois de manière interactive. Pointez simplement votre caméra vers les monuments pour révéler leur histoire cachée.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris', style: TextStyle(color: Color(0xFF667eea))),
          ),
        ],
      ),
    );
  }
}