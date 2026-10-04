import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../utils/colors.dart';
import '../widgets/coupon_card_user.dart';
import 'dart:ui';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _service = CouponService();
  final _user = FirebaseAuth.instance.currentUser;
  String _filter = 'available';

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== BACKGROUND IMAGE =====
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ===== DARK OVERLAY =====
          Container(color: Colors.black.withOpacity(0.7)),

          // ===== CONTENT =====
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(context, width),

                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.accentGold,
                    backgroundColor: Colors.black,
                    onRefresh: () async {
                      await Future.delayed(
                          const Duration(milliseconds: 700));
                    },
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.zero,
                      children: [
                        // ===== GLASS HEADER =====
                        _buildGlassHeader(width, height),

                        // ===== FILTER CHIPS =====
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04,
                            vertical: height * 0.015,
                          ),
                          child: Row(
                            children: [
                              _filterChip('available', '🎁 Available',
                                  width, height),
                              _filterChip(
                                  'used', '✅ Used', width, height),
                            ],
                          ),
                        ),

                        // ===== CONTENT =====
                        _filter == 'available'
                            ? _buildAvailableCoupons(width, height)
                            : _buildUsedCoupons(width, height),

                        SizedBox(height: height * 0.05),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GLASS APP BAR (Parallax aware)
  // ============================================================
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, _) {
        final opacity = (offset / 200).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.03,
            vertical: width * 0.02,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 12 + opacity * 8, sigmaY: 12 + opacity * 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.02,
                  vertical: width * 0.02,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15 + opacity * 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                    Colors.white.withOpacity(0.3 + opacity * 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                    const Expanded(
                      child: Text(
                        '🎁 Coupons & Offers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // GLASS HEADER CARD
  // ============================================================
  Widget _buildGlassHeader(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.005,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(width * 0.04),
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
                  child: Icon(Icons.local_offer,
                      color: Colors.black, size: width * 0.09),
                ),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save Big with Coupons!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.048,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        'Apply at checkout and save instantly',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.032,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS FILTER CHIP
  // ============================================================
  Widget _filterChip(
      String value, String label, double width, double height) {
    final isSelected = _filter == value;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: EdgeInsets.only(right: width * 0.02),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.05, vertical: height * 0.012),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentGold
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentGold
                      : Colors.white.withOpacity(0.3),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color:
                    AppColors.accentGold.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.032,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AVAILABLE COUPONS
  // ============================================================
  Widget _buildAvailableCoupons(double width, double height) {
    return StreamBuilder<List<CouponModel>>(
      stream: _service.getActiveCoupons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.accentGold)),
          );
        }

        var coupons = snapshot.data ?? [];
        if (_user != null) {
          coupons =
              coupons.where((c) => !c.userUsed(_user!.uid)).toList();
        }

        if (coupons.isEmpty) {
          return _buildEmptyState(
            width,
            height,
            'No coupons available',
            'Check back later for new offers!',
          );
        }

        return Column(
          children: coupons
              .map((c) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.008,
            ),
            child: CouponCardUser(
              coupon: c,
              showApplyButton: false,
              onApply: () {},
            ),
          ))
              .toList(),
        );
      },
    );
  }

  // ============================================================
  // USED COUPONS
  // ============================================================
  Widget _buildUsedCoupons(double width, double height) {
    if (_user == null) {
      return _buildEmptyState(width, height, 'Please login',
          'Login to see your used coupons');
    }

    return StreamBuilder<List<CouponModel>>(
      stream: _service.getUserUsedCoupons(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.accentGold)),
          );
        }

        final coupons = snapshot.data ?? [];
        if (coupons.isEmpty) {
          return _buildEmptyState(
            width,
            height,
            'No used coupons',
            'Coupons you use will appear here',
          );
        }

        return Column(
          children: coupons
              .map((c) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.008,
            ),
            child: CouponCardUser(
              coupon: c,
              showApplyButton: false,
              isUsed: true,
            ),
          ))
              .toList(),
        );
      },
    );
  }

  // ============================================================
  // GLASS EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(double width, double height, String title,
      String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.08),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.1),
          padding: EdgeInsets.all(width * 0.08),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.06),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.local_offer,
                    size: width * 0.12, color: Colors.black),
              ),
              SizedBox(height: height * 0.025),
              Text(
                title,
                style: TextStyle(
                  fontSize: width * 0.048,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: height * 0.01),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.032,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}