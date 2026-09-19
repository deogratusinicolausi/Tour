import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../utils/colors.dart';
import '../widgets/coupon_card_user.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _service = CouponService();
  final _user = FirebaseAuth.instance.currentUser;
  String _filter = 'available';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🎁 Coupons & Offers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_offer,
                      color: Colors.white, size: width * 0.1),
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
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        'Apply at checkout and save instantly',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: width * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: Colors.white,
            child: Row(
              children: [
                _filterChip('available', '🎁 Available', width, height),
                _filterChip('used', '✅ Used', width, height),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _filter == 'available'
                ? _buildAvailableCoupons(width, height)
                : _buildUsedCoupons(width, height),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      String value, String label, double width, double height) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: height * 0.01),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.03,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCoupons(double width, double height) {
    return StreamBuilder<List<CouponModel>>(
      stream: _service.getActiveCoupons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var coupons = snapshot.data ?? [];
        // Filter out used
        if (_user != null) {
          coupons = coupons
              .where((c) => !c.userUsed(_user!.uid))
              .toList();
        }

        if (coupons.isEmpty) {
          return _buildEmptyState(
            width,
            height,
            'No coupons available',
            'Check back later for new offers!',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(width * 0.04),
          itemCount: coupons.length,
          itemBuilder: (context, i) => CouponCardUser(
            coupon: coupons[i],
            showApplyButton: false,
            onApply: () {},
          ),
        );
      },
    );
  }

  Widget _buildUsedCoupons(double width, double height) {
    if (_user == null) {
      return _buildEmptyState(
          width, height, 'Please login', 'Login to see your used coupons');
    }

    return StreamBuilder<List<CouponModel>>(
      stream: _service.getUserUsedCoupons(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        return ListView.builder(
          padding: EdgeInsets.all(width * 0.04),
          itemCount: coupons.length,
          itemBuilder: (context, i) => CouponCardUser(
            coupon: coupons[i],
            showApplyButton: false,
            isUsed: true,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(double width, double height, String title,
      String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.1),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_offer,
                size: width * 0.15, color: AppColors.primary),
          ),
          SizedBox(height: height * 0.03),
          Text(
            title,
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: width * 0.035,
            ),
          ),
        ],
      ),
    );
  }
}