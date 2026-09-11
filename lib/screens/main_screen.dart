import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../utils/colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const HomeScreen(),
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // ⭐ Must be TRUE
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 65.0,
        items: const <Widget>[
          HoverIcon(icon: Icons.home),
          HoverIcon(icon: Icons.search),
          HoverIcon(icon: Icons.favorite),
          HoverIcon(icon: Icons.person),
        ],
        color: Colors.black,
        buttonBackgroundColor: const Color(0xFFF5A623),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubic,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// ⭐ HOVER ANIMATION WIDGET
class HoverIcon extends StatefulWidget {
  final IconData icon;

  const HoverIcon({super.key, required this.icon});

  @override
  State<HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends State<HoverIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()..scale(_isHovered ? 1.3 : 1.0),
        transformAlignment: Alignment.center,
        child: Icon(
          widget.icon,
          size: 30,
          color: _isHovered ? AppColors.accentGold : Colors.grey.shade700,
        ),
      ),
    );
  }
}