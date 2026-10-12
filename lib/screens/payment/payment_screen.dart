import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../services/payment_service.dart';
import '../../utils/colors.dart';

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

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      final redirectUrl = result['redirectUrl'];
      if (redirectUrl != null && redirectUrl.toString().isNotEmpty) {
        // ⭐ Open PesaPal redirect
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Payment initiated'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['error'] ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
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
            _buildSummary(width),
            SizedBox(height: height * 0.03),

            // ⭐ Payment Method
            Text('💳 Choose Payment Method',
                style: TextStyle(
                    fontSize: width * 0.042,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: height * 0.02),

            // Mobile Money
            Text('📱 Mobile Money',
                style: TextStyle(
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            SizedBox(height: height * 0.01),
            ..._buildNetworks([
              {'id': 'mpesa', 'name': 'M-Pesa'},
              {'id': 'airtel', 'name': 'Airtel Money'},
              {'id': 'tigo', 'name': 'Mixx by Yas'},
              {'id': 'halotel', 'name': 'HaloPesa'},
            ], 'mobile_money', width),

            SizedBox(height: height * 0.02),

            // Cards
            Text('💳 Cards',
                style: TextStyle(
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            SizedBox(height: height * 0.01),
            ..._buildNetworks([
              {'id': 'visa', 'name': 'Visa'},
              {'id': 'mastercard', 'name': 'Mastercard'},
            ], 'card', width),

            SizedBox(height: height * 0.03),

            // Phone Input
            if (_selectedMethod == 'mobile_money') ...[
              Text('📱 Phone Number',
                  style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold)),
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

            // Total
            Container(
              padding: EdgeInsets.all(width * 0.05),
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  Text(
                    '${widget.booking.currency} ${(widget.booking.finalAmount > 0 ? widget.booking.finalAmount : widget.booking.amount).toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.03),

            // Pay Button
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
                            letterSpacing: 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNetworks(
      List<Map<String, String>> networks, String method, double width) {
    return networks.map((network) {
      final isSelected = _selectedMethod == method &&
          _selectedNetwork == network['id'];
      return GestureDetector(
        onTap: () => setState(() {
          _selectedMethod = method;
          _selectedNetwork = network['id']!;
        }),
        child: Container(
          margin: EdgeInsets.only(bottom: width * 0.02),
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                method == 'mobile_money'
                    ? Icons.phone_android
                    : Icons.credit_card,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Text(
                  network['name']!,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade800,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: AppColors.primary, size: width * 0.05),
            ],
          ),
        ),
      );
    }).toList();
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
          _row('Guests', '${widget.booking.guests}', width),
          _row('Amount',
              '${widget.booking.currency} ${widget.booking.amount.toStringAsFixed(0)}',
              width),
          if (widget.booking.couponDiscount > 0)
            _row(
                'Discount',
                '-${widget.booking.currency} ${widget.booking.couponDiscount.toStringAsFixed(0)}',
                width),
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
