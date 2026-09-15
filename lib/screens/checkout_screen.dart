import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../utils/colors.dart';
import 'itinerary_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final TripCartModel cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cartService = CartService();
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _requestsController = TextEditingController();

  DateTime? _startDate;
  String _paymentMethod = 'Cash on Arrival';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash on Arrival',
    'M-Pesa',
    'Tigo Pesa',
    'Airtel Money',
    'Bank Transfer',
    'Credit Card',
  ];

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _nameController.text = _user!.displayName ?? '';
      _emailController.text = _user!.email ?? '';
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme:
            const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select travel start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_user == null) return;
    setState(() => _isLoading = true);

    try {
      // Create bookings for each item
      final bookingIds = <String>[];
      for (var item in widget.cart.items) {
        final bookingRef = await _firestore.collection('bookings').add({
          'userId': _user!.uid,
          'userName': _nameController.text.trim(),
          'userEmail': _emailController.text.trim(),
          'userPhone': _phoneController.text.trim(),
          'itemType': item.itemType,
          'itemId': item.itemId,
          'itemName': item.itemName,
          'itemImage': item.itemImage,
          'travelDate': Timestamp.fromDate(_startDate!),
          'guests': item.guests,
          'quantity': item.quantity,
          'amount': item.totalPrice,
          'currency': item.currency,
          'paymentStatus': 'pending',
          'bookingStatus': 'pending',
          'paymentMethod': _paymentMethod,
          'specialRequests': _requestsController.text.trim(),
          'isBulkBooking': true,
          'bulkBookingId': 'BULK_${DateTime.now().millisecondsSinceEpoch}',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        bookingIds.add(bookingRef.id);
      }

      // Create order record
      final orderRef = await _firestore.collection('orders').add({
        'userId': _user!.uid,
        'userName': _nameController.text.trim(),
        'userEmail': _emailController.text.trim(),
        'userPhone': _phoneController.text.trim(),
        'bookingIds': bookingIds,
        'items': widget.cart.items.map((e) => e.toMap()).toList(),
        'totalAmount': widget.cart.totalAmount,
        'currency': widget.cart.currency,
        'travelDate': Timestamp.fromDate(_startDate!),
        'paymentMethod': _paymentMethod,
        'paymentStatus': 'pending',
        'orderStatus': 'pending',
        'specialRequests': _requestsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log activity for admin
      await _firestore.collection('activities').add({
        'type': 'order',
        'action': 'created',
        'title':
        'New Order: ${widget.cart.itemCount} items',
        'description':
        '${_nameController.text} placed an order for ${widget.cart.currency} ${widget.cart.totalAmount.toStringAsFixed(0)}',
        'userId': _user!.uid,
        'userName': _nameController.text,
        'itemId': orderRef.id,
        'itemType': 'order',
        'icon': '🛒',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear cart
      await _cartService.clearCart(_user!.uid);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ItineraryScreen(
              orderId: orderRef.id,
              bookingIds: bookingIds,
              startDate: _startDate!,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💳 Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1
              _stepHeader('1', '👤 Traveler Information', width),
              SizedBox(height: height * 0.015),
              _buildField(_nameController, 'Full Name', Icons.person,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: height * 0.015),
              _buildField(_emailController, 'Email', Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: height * 0.015),
              _buildField(_phoneController, 'Phone', Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null),

              SizedBox(height: height * 0.03),

              // Step 2
              _stepHeader('2', '📅 Travel Date', width),
              SizedBox(height: height * 0.015),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _startDate != null
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(width * 0.025),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.calendar_today,
                            color: AppColors.primary,
                            size: width * 0.05),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: width * 0.028,
                              ),
                            ),
                            Text(
                              _startDate != null
                                  ? DateFormat('EEEE, dd MMM yyyy')
                                  .format(_startDate!)
                                  : 'Tap to select',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.038,
                                color: _startDate != null
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: height * 0.03),

              // Step 3
              _stepHeader('3', '💰 Payment Method', width),
              SizedBox(height: height * 0.015),
              ..._paymentMethods.map((method) {
                return GestureDetector(
                  onTap: () => setState(() => _paymentMethod = method),
                  child: Container(
                    margin: EdgeInsets.only(bottom: height * 0.01),
                    padding: EdgeInsets.all(width * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == method
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: _paymentMethod == method ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: width * 0.05,
                          height: width * 0.05,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _paymentMethod == method
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: _paymentMethod == method
                              ? Center(
                            child: Container(
                              width: width * 0.025,
                              height: width * 0.025,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                              : null,
                        ),
                        SizedBox(width: width * 0.03),
                        Text(
                          method,
                          style: TextStyle(
                            fontSize: width * 0.035,
                            fontWeight: _paymentMethod == method
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: height * 0.03),

              // Step 4
              _stepHeader('4', '💬 Special Requests', width),
              SizedBox(height: height * 0.015),
              _buildField(_requestsController, 'Notes (optional)',
                  Icons.message,
                  maxLines: 3),

              SizedBox(height: height * 0.03),

              // Order Summary
              Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: width * 0.035,
                          ),
                        ),
                        Text(
                          '${widget.cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.01),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    SizedBox(height: height * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${widget.cart.currency} ${widget.cart.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.065,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.03),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'CONFIRM BOOKING',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(String step, String title, double width) {
    return Row(
      children: [
        Container(
          width: width * 0.08,
          height: width * 0.08,
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.038,
              ),
            ),
          ),
        ),
        SizedBox(width: width * 0.03),
        Text(
          title,
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}