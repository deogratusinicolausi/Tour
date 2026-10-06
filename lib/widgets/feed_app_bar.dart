import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class FeedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double scrollOffset;
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const FeedAppBar({
    super.key,
    required this.scrollOffset,
    required this.onBack,
    required this.onCreate,
    required this.onSearchChanged,
    required this.searchController,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(140);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final collapse = (scrollOffset / 150).clamp(0.0, 1.0);
    final searchHeight = 56 * (1 - collapse);
    final tabsOpacity = 1 - collapse;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20 + collapse * 10,
          sigmaY: 20 + collapse * 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a2e).withOpacity(0.75 + collapse * 0.2),
                const Color(0xFF16213e).withOpacity(0.7 + collapse * 0.25),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ═══ TOP ROW ═══
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: width * 0.03,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.025),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: width * 0.05,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.03),

                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  AppColors.accentGold,
                                  Colors.orange.shade300,
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'TURIVA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.055,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Text(
                              'Feed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: width * 0.028,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Create post
                      GestureDetector(
                        onTap: onCreate,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.03),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGold.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.black,
                            size: width * 0.06,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ═══ SEARCH BAR (animated height) ═══
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: searchHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                  ),
                  child: searchHeight > 10
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search posts, users, places...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.accentGold,
                              size: width * 0.05,
                            ),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: width * 0.04,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),

                // ═══ TABS (fade out on scroll) ═══
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: tabsOpacity,
                  child: Container(
                    height: 44 * (1 - collapse),
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                    ),
                    child: Row(
                      children: [
                        _tab('For You', 'for_you', width),
                        SizedBox(width: width * 0.02),
                        _tab('Following', 'following', width),
                        SizedBox(width: width * 0.02),
                        _tab('Trending', 'trending', width),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, String value, double width) {
    final active = activeTab == value;
    return GestureDetector(
      onTap: () => onTabChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.035,
          vertical: width * 0.02,
        ),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
            colors: [
              AppColors.accentGold,
              Colors.orange.shade400,
            ],
          )
              : null,
          color: active ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? Colors.transparent
                : Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: active
              ? [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontSize: width * 0.032,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}