import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'my_wishlist_screen.dart';
import 'profile_screen.dart';
import '../utils/colors.dart';
import 'trip_cart_screen.dart';
import 'search_screen.dart';
import 'hand_control_screen.dart';
import '../services/hand_action_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final HandActionService _handActionService = HandActionService.instance;

  @override
  void initState() {
    super.initState();
    _handActionService.currentAction.addListener(
      _handleHandAction,
    );
  }

  @override
  void dispose() {
    _handActionService.currentAction.removeListener(
      _handleHandAction,
    );
    super.dispose();
  }

  void _handleHandAction() {
    final action = _handActionService.currentAction.value;

    switch (action) {
      case HandAction.back:
        debugPrint('✊ Back action received by MainScreen');
        break;

      case HandAction.next:
        _goToNextPage();
        break;

      case HandAction.previous:
        _goToPreviousPage();
        break;

      case HandAction.select:
        debugPrint('👆 Select action detected');
        break;

      case HandAction.confirm:
        debugPrint('👍 Confirm action detected');
        break;

      case HandAction.pause:
        debugPrint('✋ Hand control paused');
        break;

      case HandAction.none:
        break;
    }

    _handActionService.reset();
  }

  void _goToNextPage() {
    if (_selectedIndex < _pages.length - 1) {
      setState(() {
        _selectedIndex++;
      });
    }
  }

  void _goToPreviousPage() {
    if (_selectedIndex > 0) {
      setState(() {
        _selectedIndex--;
      });
    }
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(), // ⭐ Badilisha Map → Search
    const MyWishlistScreen(), // ⭐ Wishlist
    const TripCartScreen(), // ⭐ Cart
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Transparent so the background image shows
      extendBody: true,
      body: Stack(
        children: [
          // 1. The page content
          _pages[_selectedIndex],

          // 2. The blur layer behind the nav bar (Positioned at the bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  height: 75, // Matches the new max height of nav bar
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
      // 🤚 TEMPORARY HAND CONTROL TEST BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentGold,
        foregroundColor: Colors.black,
        tooltip: 'Hand Control',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HandControlScreen(),
            ),
          );
        },
        child: const Icon(
          Icons.pan_tool_alt,
          size: 28,
        ),
      ),
      // 3. The actual nav bar
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 75.0, // Reduced to 75.0 to satisfy the package constraint (0 <= height <= 75.0)
        items: const <Widget>[
          HoverIcon(icon: Icons.home),
          HoverIcon(icon: Icons.search),
          HoverIcon(icon: Icons.favorite_border),
          HoverIcon(icon: Icons.shopping_cart_outlined),
          HoverIcon(icon: Icons.person),
        ],
        color: Colors.white.withOpacity(0.15), // GLASS effect
        buttonBackgroundColor: AppColors.accentGold, // Gold button (matches theme)
        backgroundColor: Colors.transparent, // Transparent so the background shows through
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
          size: 28, // Slightly smaller so it fits the glass pill nicely
          color: _isHovered ? AppColors.accentGold : Colors.white, // WHITE when idle, GOLD on hover
          shadows: _isHovered
              ? [
                  Shadow(
                    color: AppColors.accentGold.withOpacity(0.8),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}