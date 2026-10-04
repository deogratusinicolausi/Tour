import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/coupon_model.dart';
import '../utils/colors.dart';

class CouponCardUser extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback? onApply;
  final bool showApplyButton;
  final bool isUsed;

  const CouponCardUser({
    super.key,
    required this.coupon,
    this.onApply,
    this.showApplyButton = true,
    this.isUsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isExpiringSoon = coupon.daysLeft <= 3 && coupon.daysLeft >= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          margin: EdgeInsets.only(bottom: height * 0.015),
          decoration: BoxDecoration(
            // 🪟 Glass background
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUsed
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // ⭐️ LEFT SIDE — Discount panel
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    width: width * 0.25,
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: width * 0.05),
                    decoration: BoxDecoration(
                      gradient: isUsed
                          ? LinearGradient(colors: [
                        Colors.grey.shade500.withOpacity(0.7),
                        Colors.grey.shade700.withOpacity(0.7),
                      ])
                          : AppColors.goldGradient,
                      boxShadow: isUsed
                          ? []
                          : [
                        BoxShadow(
                          color: AppColors.accentGold
                              .withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            coupon.discountType == 'percentage'
                                ? '${coupon.discountValue.toStringAsFixed(0)}%'
                                : '\$${coupon.discountValue.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: width * 0.028,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          if (isExpiringSoon && !isUsed) ...[
                            SizedBox(height: height * 0.005),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                '🔥 ${coupon.daysLeft}d left',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ⭐️ RIGHT SIDE — Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.035),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          coupon.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.038,
                            color: Colors.white, // ✅ White on glass
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: height * 0.005),

                        // Description
                        if (coupon.description.isNotEmpty)
                          Text(
                            coupon.description,
                            style: TextStyle(
                              fontSize: width * 0.03,
                              color: Colors.white70, // ✅ Soft white
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        SizedBox(height: height * 0.008),

                        // Code + Copy
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: coupon.code));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '📋 Code copied: ${coupon.code}'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(
                                        milliseconds: 1500),
                                    behavior:
                                    SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold
                                          .withOpacity(0.2),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.accentGold
                                            .withOpacity(0.6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.copy,
                                            size: width * 0.03,
                                            color:
                                            AppColors.accentGold),
                                        SizedBox(width: width * 0.01),
                                        Text(
                                          coupon.code,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: width * 0.032,
                                            color:
                                            AppColors.accentGold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: height * 0.008),

                        // Expiry + Min
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: width * 0.03,
                                color: Colors.white70),
                            SizedBox(width: width * 0.01),
                            Text(
                              coupon.expiryText,
                              style: TextStyle(
                                fontSize: width * 0.026,
                                color: isExpiringSoon && !isUsed
                                    ? Colors.redAccent
                                    : Colors.white70,
                                fontWeight: isExpiringSoon
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (coupon.minAmount > 0) ...[
                              SizedBox(width: width * 0.03),
                              Icon(Icons.shopping_cart,
                                  size: width * 0.03,
                                  color: Colors.white70),
                              SizedBox(width: width * 0.01),
                              Text(
                                'Min ${coupon.currency} ${coupon.minAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: width * 0.026,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Apply button
                        if (showApplyButton &&
                            onApply != null &&
                            !isUsed) ...[
                          SizedBox(height: height * 0.01),
                          GestureDetector(
                            onTap: onApply,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: height * 0.008,
                                  horizontal: width * 0.04),
                              decoration: BoxDecoration(
                                gradient: AppColors.mainGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'APPLY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.028,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Used badge
                        if (isUsed) ...[
                          SizedBox(height: height * 0.01),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 6, sigmaY: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  '✅ ALREADY USED',
                                  style: TextStyle(
                                    fontSize: width * 0.024,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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
}