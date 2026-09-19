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

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ⭐️ Left side - Discount
          Container(
            width: width * 0.25,
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.03, vertical: width * 0.05),
            decoration: BoxDecoration(
              gradient: isUsed
                  ? LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500])
                  : AppColors.goldGradient,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
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

          // ⭐️ Right side - Details
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
                      color: Colors.grey.shade900,
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
                        color: Colors.grey.shade600,
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
                          Clipboard.setData(
                              ClipboardData(text: coupon.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text('📋 Code copied: ${coupon.code}'),
                              backgroundColor: Colors.green,
                              duration:
                              const Duration(milliseconds: 1500),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.copy,
                                  size: width * 0.03,
                                  color: AppColors.primary),
                              SizedBox(width: width * 0.01),
                              Text(
                                coupon.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.032,
                                  color: AppColors.primary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.008),

                  // Expiry
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: width * 0.03, color: Colors.grey.shade500),
                      SizedBox(width: width * 0.01),
                      Text(
                        coupon.expiryText,
                        style: TextStyle(
                          fontSize: width * 0.026,
                          color: isExpiringSoon
                              ? Colors.red
                              : Colors.grey.shade500,
                          fontWeight: isExpiringSoon
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (coupon.minAmount > 0) ...[
                        SizedBox(width: width * 0.03),
                        Icon(Icons.shopping_cart,
                            size: width * 0.03,
                            color: Colors.grey.shade500),
                        SizedBox(width: width * 0.01),
                        Text(
                          'Min ${coupon.currency} ${coupon.minAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: width * 0.026,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Apply Button
                  if (showApplyButton && onApply != null && !isUsed) ...[
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

                  // Used Badge
                  if (isUsed) ...[
                    SizedBox(height: height * 0.01),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '✅ ALREADY USED',
                        style: TextStyle(
                          fontSize: width * 0.024,
                          color: Colors.grey.shade600,
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
        ],
      ),
    );
  }
}