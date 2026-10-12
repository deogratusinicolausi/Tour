import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking_model.dart';
import '../../services/payment_service.dart';
import '../../utils/colors.dart';
import '../../widgets/payment/payment_method_selector.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _service = PaymentService();
  final _phoneController = TextEditingController();

  String _selectedMethod = 'mobile_money';
  String _selectedNetwork = 'mpesa';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _phoneController.text = user?.phoneNumber ?? '';
  }

  Future<void> _pay() async {
    if (_phoneController.text.isEmpty &&
        _selectedMethod == 'mobile_money') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _service.initiatePayment(
      bookingId: widget.booking.id,
      paymentMethod: _selectedMethod,
      paymentNetwork: _selectedNetwork,
      phoneNumber: _phoneController.text.trim(),
      amount: widget.booking.finalAmount > 0
          ? widget.booking.finalAmount
          : widget.booking.amount,
      currency: widget.booking.currency,
    );

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      // TODO: Show success/pending screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment initiated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Payment failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💳 Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ Booking Summary
            _buildSummary(width),

            SizedBox(height: height * 0.03),

            // ⭐ Payment Method Selector
            PaymentMethodSelector(
              selectedMethod: _selectedMethod,
              selectedNetwork: _selectedNetwork,
              onChanged: (method, network) {
                setState(() {
                  _selectedMethod = method;
                  _selectedNetwork = network;
                });
              },
            ),

            SizedBox(height: height * 0.03),

            // ⭐ Phone Input (kama mobile money)
            if (_selectedMethod == 'mobile_money') ...[
              Text(
                '📱 Phone Number',
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: height * 0.01),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '255712345678',
                  prefixIcon: const Icon(Icons.phone_android),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: height * 0.02),
            ],

            // ⭐ Total
            Container(
              padding: EdgeInsets.all(width * 0.05),
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${widget.booking.currency} ${(widget.booking.finalAmount > 0 ? widget.booking.finalAmount : widget.booking.amount).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.03),

            // ⭐ Pay Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'PAY NOW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.booking.itemName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: width * 0.045,
            ),
          ),
          SizedBox(height: width * 0.02),
          _row('Date', widget.booking.travelDate?.toString().split(' ')[0] ?? 'N/A', width),
          _row('Guests', '${widget.booking.guests}', width),
          _row('Amount', '${widget.booking.currency} ${widget.booking.amount.toStringAsFixed(0)}', width),
          if (widget.booking.couponDiscount > 0)
            _row('Discount', '-${widget.booking.currency} ${widget.booking.couponDiscount.toStringAsFixed(0)}', width),
        ],
      ),
    );
  }

  Widget _row(String label, String value, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
