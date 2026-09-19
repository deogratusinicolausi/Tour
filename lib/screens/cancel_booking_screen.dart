import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/cancellation_service.dart';
import '../utils/colors.dart';

class CancelBookingScreen extends StatefulWidget {
  final BookingModel booking;

  const CancelBookingScreen({super.key, required this.booking});

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  final _service = CancellationService();
  final _notesController = TextEditingController();

  String _selectedReason = 'change_plans';
  double _refundAmount = 0;
  String _refundPolicy = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic> _cancelCheck = {};

  final List<Map<String, String>> _reasons = [
    {'value': 'change_plans', 'label': '🔄 Change of plans', 'icon': '🔄'},
    {'value': 'emergency', 'label': '🚨 Emergency', 'icon': '🚨'},
    {'value': 'found_cheaper', 'label': '💰 Found cheaper option', 'icon': '💰'},
    {'value': 'weather', 'label': '🌧️ Weather concerns', 'icon': '🌧️'},
    {'value': 'health', 'label': '🏥 Health issues', 'icon': '🏥'},
    {'value': 'other', 'label': '📝 Other reason', 'icon': '📝'},
  ];

  @override
  void initState() {
    super.initState();
    _checkCancellation();
  }

  Future<void> _checkCancellation() async {
    final check = await _service.canCancelBooking(
      bookingId: widget.booking.id,
      travelDate: widget.booking.travelDate,
    );

    final refund = _service.calculateRefund(
      bookingAmount: widget.booking.amount,
      travelDate: widget.booking.travelDate,
    );

    final policy =
    _service.getRefundPolicy(widget.booking.travelDate);

    if (mounted) {
      setState(() {
        _cancelCheck = check;
        _refundAmount = refund;
        _refundPolicy = policy;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitCancellation() async {
    if (_cancelCheck['canCancel'] != true) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _service.requestCancellation(
        bookingId: widget.booking.id,
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userEmail: user.email ?? '',
        itemId: widget.booking.itemId,
        itemType: widget.booking.itemType,
        itemName: widget.booking.itemName,
        itemImage: widget.booking.itemImage,
        bookingAmount: widget.booking.amount,
        currency: widget.booking.currency,
        reason: _selectedReason,
        additionalNotes: _notesController.text.trim(),
        refundAmount: _refundAmount,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top,
                  color: Colors.orange, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cancellation Requested!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your cancellation request has been submitted. Admin will review and respond shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Refund: ${widget.booking.currency} ${_refundAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canCancel = _cancelCheck['canCancel'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('❌ Cancel Booking'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐️ BOOKING INFO
            _buildBookingInfo(width, height),

            SizedBox(height: height * 0.025),

            // ⭐️ IF CANNOT CANCEL
            if (!canCancel) ...[
              Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: width * 0.15),
                    SizedBox(height: height * 0.02),
                    Text(
                      'Cannot Cancel',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      _cancelCheck['message'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.035,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ⭐️ REFUND POLICY
              _buildRefundPolicy(width, height),

              SizedBox(height: height * 0.025),

              // ⭐️ REASON SELECTOR
              _sectionTitle('📝 Reason for Cancellation', width),
              SizedBox(height: height * 0.015),
              ..._reasons.map((reason) {
                final isSelected = _selectedReason == reason['value'];
                return GestureDetector(
                  onTap: () => setState(
                          () => _selectedReason = reason['value']!),
                  child: Container(
                    margin: EdgeInsets.only(bottom: height * 0.01),
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
                        Text(
                          reason['icon']!,
                          style: TextStyle(fontSize: width * 0.06),
                        ),
                        SizedBox(width: width * 0.03),
                        Expanded(
                          child: Text(
                            reason['label']!,
                            style: TextStyle(
                              fontSize: width * 0.035,
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
                          Icon(Icons.check_circle,
                              color: AppColors.primary,
                              size: width * 0.06),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: height * 0.015),

              // ⭐️ ADDITIONAL NOTES
              _sectionTitle('💬 Additional Notes (Optional)', width),
              SizedBox(height: height * 0.01),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell us more about your cancellation...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              SizedBox(height: height * 0.03),

              // ⭐️ SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCancellation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'REQUEST CANCELLATION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.02),

              // ⭐️ INFO
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: width * 0.05),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: Text(
                        'Admin will review your request within 24 hours.',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: height * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfo(double width, double height) {
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.booking.itemImage.isNotEmpty
                ? Image.network(
              widget.booking.itemImage,
              width: width * 0.2,
              height: width * 0.2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: width * 0.2,
                height: width * 0.2,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image),
              ),
            )
                : Container(
              width: width * 0.2,
              height: width * 0.2,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image),
            ),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.04,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: height * 0.008),
                Text(
                  '${widget.booking.currency} ${widget.booking.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.045,
                  ),
                ),
                if (widget.booking.travelDate != null) ...[
                  SizedBox(height: height * 0.005),
                  Text(
                    'Travel: ${DateFormat('dd MMM yyyy').format(widget.booking.travelDate!)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: width * 0.03,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundPolicy(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4caf50), Color(0xFF2e7d32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.attach_money,
                  color: Colors.white, size: width * 0.1),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REFUND AMOUNT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.booking.currency} ${_refundAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _refundPolicy,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: width * 0.03,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.015),
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Refund Policy:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.03,
                  ),
                ),
                SizedBox(height: height * 0.005),
                Text(
                  '• 7+ days before: 100% refund\n'
                      '• 3-6 days before: 75% refund\n'
                      '• 2 days before: 50% refund\n'
                      '• Less than 2 days: No refund',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: width * 0.028,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.04,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }
}