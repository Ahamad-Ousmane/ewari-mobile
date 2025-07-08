import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/infrastructures');
        break;
      case 2:
        context.go('/ar');
        break;
      case 3:
        context.go('/map');
        break;
      case 4:
        final user = ref.read(authServiceProvider).value;
        if (user != null) {
          context.go('/profile');
        } else {
          context.go('/login');
        }
        break;
    }
  }

  void _updateSelectedIndex(String location) {
    int newIndex = 0;

    if (location == '/' || location.startsWith('/home')) {
      newIndex = 0;
    } else if (location.startsWith('/infrastructures') || location.startsWith('/infrastructure/')) {
      newIndex = 1;
    } else if (location.startsWith('/ar')) {
      newIndex = 2;
    } else if (location.startsWith('/map')) {
      newIndex = 3;
    } else if (location.startsWith('/profile') || location.startsWith('/login') || location.startsWith('/register')) {
      newIndex = 4;
    }

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authServiceProvider);
    final user = userAsync.value;

    // Mettre à jour l'index basé sur la route actuelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = GoRouterState.of(context).uri.toString();
      _updateSelectedIndex(location);
    });

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildModernBottomNav(user),
    );
  }

  Widget _buildModernBottomNav(user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.explore_outlined, Icons.explore, 1),
              label: 'Explorer',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.view_in_ar_outlined, Icons.view_in_ar, 2),
              label: 'RA',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.map_outlined, Icons.map, 3),
              label: 'Carte',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                user != null ? Icons.person_outline : Icons.login_outlined,
                user != null ? Icons.person : Icons.login,
                4,
              ),
              label: user != null ? 'Profil' : 'Connexion',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = _selectedIndex == index;

    // Couleur spéciale pour l'onglet RA
    Color selectedColor = const Color(0xFF6C63FF);
    if (index == 2) { // Onglet RA
      selectedColor = const Color(0xFF667eea);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? filledIcon : outlineIcon,
        size: 24,
        color: isSelected ? selectedColor : Colors.grey[400],
      ),
    );
  }
}