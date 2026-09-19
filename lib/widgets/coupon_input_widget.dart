import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../utils/colors.dart';

class CouponInputWidget extends StatefulWidget {
  final double amount;
  final String itemType;
  final Function(CouponModel?, double) onCouponApplied;

  const CouponInputWidget({
    super.key,
    required this.amount,
    required this.itemType,
    required this.onCouponApplied,
  });

  @override
  State<CouponInputWidget> createState() => _CouponInputWidgetState();
}

class _CouponInputWidgetState extends State<CouponInputWidget> {
  final _service = CouponService();
  final _controller = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  CouponModel? _appliedCoupon;
  double _discount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _applyCoupon() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a coupon code');
      return;
    }

    if (_user == null) {
      setState(() => _errorMessage = 'Please login first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.validateCoupon(
      code: _controller.text.trim(),
      amount: widget.amount,
      userId: _user!.uid,
      itemType: widget.itemType,
    );

    setState(() => _isLoading = false);

    if (result['valid'] == true) {
      setState(() {
        _appliedCoupon = result['coupon'] as CouponModel;
        _discount = result['discount'] as double;
        _errorMessage = null;
      });

      widget.onCouponApplied(_appliedCoupon, _discount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _appliedCoupon = null;
        _discount = 0;
        _errorMessage = result['message'];
      });
      widget.onCouponApplied(null, 0);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discount = 0;
      _controller.clear();
      _errorMessage = null;
    });
    widget.onCouponApplied(null, 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // ⭐️ If coupon applied
    if (_appliedCoupon != null) {
      return Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.green,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check,
                  color: Colors.white, size: width * 0.05),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _appliedCoupon!.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                          color: Colors.green.shade800,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'APPLIED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.022,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.005),
                  Text(
                    'You save ${_appliedCoupon!.currency} ${_discount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: width * 0.032,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _removeCoupon,
              icon: const Icon(Icons.close, color: Colors.red),
            ),
          ],
        ),
      );
    }

    // ⭐️ Coupon input
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _errorMessage != null
                  ? Colors.red
                  : Colors.grey.shade300,
              width: _errorMessage != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: width * 0.04),
                child: Icon(Icons.local_offer,
                    color: AppColors.accentGold, size: width * 0.06),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.038,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                      fontSize: width * 0.035,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: width * 0.03),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(width * 0.02),
                child: GestureDetector(
                  onTap: _isLoading ? null : _applyCoupon,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.05,
                        vertical: height * 0.012),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _isLoading
                        ? SizedBox(
                      width: width * 0.04,
                      height: width * 0.04,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                        : Text(
                      'APPLY',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.03,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: height * 0.008),
          Padding(
            padding: EdgeInsets.only(left: width * 0.02),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: width * 0.03,
              ),
            ),
          ),
        ],
      ],
    );
  }
}