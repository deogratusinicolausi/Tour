
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turiva/models/booking_model.dart';
import 'package:turiva/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../backup_payment_20261011/payment_service.dart';


class PaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentScreen({
    super.key,
    required this.booking,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _service = PaymentService();
  final TextEditingController _phoneController =
  TextEditingController();

  String _selectedMethod = 'mobile_money';
  String _selectedNetwork = 'mpesa';
  bool _isLoading = false;

  double get _totalAmount {
    return widget.booking.finalAmount > 0
        ? widget.booking.finalAmount
        : widget.booking.amount;
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    _phoneController.text = user?.phoneNumber ?? '';
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
  }

  Future<void> _pay() async {
    if (_isLoading) return;

    if (_totalAmount <= 0 || !_totalAmount.isFinite) {
      _showMessage('The booking amount is invalid.', isError: true);
      return;
    }

    final phone = _phoneController.text.trim();

    if (_selectedMethod == 'mobile_money' && phone.isEmpty) {
      _showMessage(
        'Please enter your mobile money phone number.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _service.initiatePayment(
        bookingId: widget.booking.id,
        paymentMethod: _selectedMethod,
        paymentNetwork: _selectedNetwork,
        phoneNumber: phone,
        amount: _totalAmount,
        currency: widget.booking.currency,
      );

      if (!mounted) return;

      if (result == null || result['success'] != true) {
        final error = result?['error']?.toString();

        _showMessage(
          error == null || error.isEmpty
              ? 'Unable to initiate payment. Please try again.'
              : error,
          isError: true,
        );
        return;
      }

      final redirectValue = result['redirectUrl'];
      final redirectUrl = redirectValue?.toString().trim() ?? '';

      if (redirectUrl.isEmpty) {
        _showMessage(
          'The payment provider did not return a checkout link.',
          isError: true,
        );
        return;
      }

      final uri = Uri.tryParse(redirectUrl);

      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty) {
        _showMessage(
          'The payment provider returned an invalid checkout link.',
          isError: true,
        );
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      if (!launched) {
        _showMessage(
          'Could not open the payment page. Please try again.',
          isError: true,
        );
        return;
      }

      _showMessage(
        'Checkout opened. Complete your payment and wait for confirmation.',
      );
    } catch (e) {
      debugPrint('Payment screen error: $e');

      _showMessage(
        'Something went wrong while starting payment. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

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

            Text(
              '💳 Choose Payment Method',
              style: TextStyle(
                fontSize: width * 0.042,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.02),

            Text(
              '📱 Mobile Money',
              style: TextStyle(
                fontSize: width * 0.035,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: height * 0.01),

            ..._buildNetworks(
              [
                {'id': 'mpesa', 'name': 'M-Pesa'},
                {'id': 'airtel', 'name': 'Airtel Money'},
                {'id': 'tigo', 'name': 'Mixx by Yas'},
                {'id': 'halotel', 'name': 'HaloPesa'},
              ],
              'mobile_money',
              width,
            ),

            SizedBox(height: height * 0.02),

            Text(
              '💳 Cards',
              style: TextStyle(
                fontSize: width * 0.035,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: height * 0.01),

            ..._buildNetworks(
              [
                {'id': 'visa', 'name': 'Visa'},
                {'id': 'mastercard', 'name': 'Mastercard'},
              ],
              'card',
              width,
            ),

            SizedBox(height: height * 0.03),

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
                enabled: !_isLoading,
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
                  Flexible(
                    child: Text(
                      '${widget.booking.currency} ${_totalAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.03),

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
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
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

  List<Widget> _buildNetworks(
      List<Map<String, String>> networks,
      String method,
      double width,
      ) {
    return networks.map((network) {
      final id = network['id']!;
      final name = network['name']!;

      final isSelected =
          _selectedMethod == method && _selectedNetwork == id;

      return GestureDetector(
        onTap: _isLoading
            ? null
            : () {
          setState(() {
            _selectedMethod = method;
            _selectedNetwork = id;
          });
        },
        child: Container(
          margin: EdgeInsets.only(bottom: width * 0.02),
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                method == 'mobile_money'
                    ? Icons.phone_android
                    : Icons.credit_card,
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey,
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade800,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: width * 0.05,
                ),
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
          _row(
            'Amount',
            '${widget.booking.currency} ${widget.booking.amount.toStringAsFixed(0)}',
            width,
          ),
          if (widget.booking.couponDiscount > 0)
            _row(
              'Discount',
              '-${widget.booking.currency} ${widget.booking.couponDiscount.toStringAsFixed(0)}',
              width,
            ),
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
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
