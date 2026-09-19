import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../utils/colors.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../widgets/coupon_input_widget.dart';
import '../services/payment_service.dart';
import '../widgets/payment_method_selector.dart';
import '../services/receipt_service.dart';
import 'receipt_screen.dart';

class BookingScreen extends StatefulWidget {
  final String itemType;
  final String itemId;
  final String itemName;
  final String itemImage;
  final double price;
  final String currency;

  const BookingScreen({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.itemImage,
    required this.price,
    required this.currency,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();
  final _user = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _requestsController = TextEditingController();

  DateTime? _travelDate;
  int _guests = 1;
  bool _isLoading = false;

  // ⭐️ Add-ons
  bool _addGuide = false;
  bool _addTransport = false;
  bool _addMeals = false;

  CouponModel? _appliedCoupon;
  double _discount = 0;
  double get _finalTotal => _totalPrice - _discount;

  // ⭐️ PAYMENT VARIABLES
  String _paymentMethod = 'Mpesa';
  final _paymentPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final _user = this._user;
    if (_user != null) {
      _nameController.text = _user.displayName ?? '';
      _emailController.text = _user.email ?? '';
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
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _travelDate = picked);
  }

  double get _basePrice => widget.price * _guests;
  double get _addonsPrice {
    double total = 0;
    if (_addGuide) total += 50;
    if (_addTransport) total += 80;
    if (_addMeals) total += 40;
    return total * _guests;
  }
  double get _totalPrice => _basePrice + _addonsPrice;

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select travel date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ⭐️ PROCESS PAYMENT KWANZA
    if (_paymentMethod != 'cash') {
      if (_paymentPhoneController.text.trim().isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please enter your phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ⭐️ PROCESS PAYMENT KWANZA (kupitia Cloud Function)
      final paymentService = PaymentService();
      final response = await paymentService.initiatePayment(
        mobileNumber: _paymentPhoneController.text.trim(),
        amount: _finalTotal.toStringAsFixed(0),
        externalId: 'TURIVA-${DateTime.now().millisecondsSinceEpoch}',
        provider: _paymentMethod,
      );

      if (response['success'] != true) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Payment failed: ${response['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final couponService = CouponService();

    final booking = BookingModel(
      id: '',
      userId: _user!.uid,
      userName: _nameController.text.trim(),
      userEmail: _emailController.text.trim(),
      userPhone: _phoneController.text.trim(),
      itemType: widget.itemType,
      itemId: widget.itemId,
      itemName: widget.itemName,
      itemImage: widget.itemImage,
      travelDate: _travelDate,
      guests: _guests,
      amount: _finalTotal,
      currency: widget.currency,
      specialRequests: _requestsController.text.trim(),
      couponCode: _appliedCoupon?.code ?? '',
      couponDiscount: _discount,
      finalAmount: _finalTotal,
      paymentMethod: _paymentMethod,
    );

    final id = await _bookingService.createBooking(booking);

    if (id != null && _appliedCoupon != null) {
      await couponService.applyCoupon(
        couponId: _appliedCoupon!.id,
        userId: _user!.uid,
      );
    }

    // ⭐️ CREATE RECEIPT
    if (id != null) {
      final receiptService = ReceiptService();
      final receipt = await receiptService.createFromBooking(
        bookingId: id,
        userId: _user!.uid,
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        itemType: widget.itemType,
        itemName: widget.itemName,
        itemImage: widget.itemImage,
        travelDate: _travelDate,
        guests: _guests,
        baseAmount: _basePrice,
        addonsAmount: _addonsPrice,
        couponDiscount: _discount,
        couponCode: _appliedCoupon?.code ?? '',
        totalAmount: _finalTotal,
        currency: widget.currency,
        paymentMethod: _paymentMethod,
        paymentStatus: 'pending',
        transactionId: '',
        bookingStatus: 'pending',
      );

      if (receipt != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(receipt: receipt),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (id != null) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Booking failed. Try again.'),
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
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 70),
            ),
            const SizedBox(height: 24),
            const Text(
              '🎉 Booking Confirmed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your booking for "${widget.itemName}" has been submitted.\n\nAdmin will confirm shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _summaryRow('Item', widget.itemName),
                  _summaryRow('Guests', '$_guests'),
                  _summaryRow('Total', '${widget.currency} ${_finalTotal.toStringAsFixed(0)}'),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📅 Complete Your Booking'),
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
              // ⭐️ ITEM CARD
              _buildItemCard(width, height),
              SizedBox(height: height * 0.025),

              // ⭐️ STEP 1: CONTACT INFO
              _stepHeader('1', '👤 Contact Information', width),
              SizedBox(height: height * 0.015),
              _buildField(_nameController, 'Full Name', Icons.person,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: height * 0.015),
              _buildField(_emailController, 'Email Address', Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  !v!.contains('@') ? 'Invalid email' : null),
              SizedBox(height: height * 0.015),
              _buildField(_phoneController, 'Phone Number', Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null),

              SizedBox(height: height * 0.03),

              // ⭐️ STEP 2: TRAVEL DETAILS
              _stepHeader('2', '✈️ Travel Details', width),
              SizedBox(height: height * 0.015),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _travelDate != null
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
                            color: AppColors.primary, size: width * 0.05),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Travel Date',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: width * 0.028,
                              ),
                            ),
                            Text(
                              _travelDate != null
                                  ? DateFormat('EEEE, dd MMM yyyy')
                                  .format(_travelDate!)
                                  : 'Tap to select',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.038,
                                color: _travelDate != null
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: width * 0.035,
                          color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),

              SizedBox(height: height * 0.015),

              // Guests picker
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.025),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.people,
                          color: AppColors.primary, size: width * 0.05),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of Guests',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: width * 0.028,
                            ),
                          ),
                          Text(
                            '$_guests guest${_guests > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_guests > 1) setState(() => _guests--);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _guests > 1
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.remove,
                            color: _guests > 1
                                ? Colors.white
                                : Colors.grey,
                            size: 20),
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                    GestureDetector(
                      onTap: () => setState(() => _guests++),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.03),

              // ⭐️ STEP 3: ADD-ONS
              _stepHeader('3', '🎁 Add-ons (Optional)', width),
              SizedBox(height: height * 0.015),
              _buildAddon(
                '🧑‍🏫 Professional Guide',
                '\$50 per guest',
                _addGuide,
                    (v) => setState(() => _addGuide = v),
                width,
              ),
              _buildAddon(
                '🚐 Transport Service',
                '\$80 per guest',
                _addTransport,
                    (v) => setState(() => _addTransport = v),
                width,
              ),
              _buildAddon(
                '🍽️ Meals Package',
                '\$40 per guest',
                _addMeals,
                    (v) => setState(() => _addMeals = v),
                width,
              ),

              SizedBox(height: height * 0.03),

              // ⭐️ STEP 4: SPECIAL REQUESTS
              _stepHeader('4', '💬 Special Requests', width),
              SizedBox(height: height * 0.015),
              _buildField(
                _requestsController,
                'Any special requests...',
                Icons.message,
                maxLines: 3,
              ),

              SizedBox(height: height * 0.03),

              // ⭐️ STEP 5: COUPON
              _stepHeader('5', '🎁 Coupon Code', width),
              SizedBox(height: height * 0.015),
              CouponInputWidget(
                amount: _totalPrice,
                itemType: widget.itemType,
                onCouponApplied: (coupon, discount) {
                  setState(() {
                    _appliedCoupon = coupon;
                    _discount = discount;
                  });
                },
              ),
              SizedBox(height: height * 0.03),

              // ⭐️ STEP 6: PAYMENT METHOD
              _stepHeader('6', '💳 Payment Method', width),
              SizedBox(height: height * 0.015),
              PaymentMethodSelector(
                selectedMethod: _paymentMethod,
                onChanged: (value) {
                  setState(() => _paymentMethod = value);
                },
              ),
              SizedBox(height: height * 0.015),

              // Phone Number Field (kwa Mobile Money)
              TextField(
                controller: _paymentPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (e.g. 255712345678)',
                  prefixIcon: const Icon(Icons.phone_android),
                  hintText: '2557XXXXXXXX',
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
              ),

              SizedBox(height: height * 0.03),

              // ⭐️ PRICE BREAKDOWN
              Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      '💰 PRICE BREAKDOWN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    const Divider(height: 20),
                    _priceRow(
                      'Base price (${widget.price.toStringAsFixed(0)} × $_guests)',
                      '${widget.currency} ${_basePrice.toStringAsFixed(0)}',
                    ),
                    if (_addGuide)
                      _priceRow('Guide', '${widget.currency} ${(50 * _guests).toStringAsFixed(0)}'),
                    if (_addTransport)
                      _priceRow('Transport', '${widget.currency} ${(80 * _guests).toStringAsFixed(0)}'),
                    if (_addMeals)
                      _priceRow('Meals', '${widget.currency} ${(40 * _guests).toStringAsFixed(0)}'),

                    if (_discount > 0) ...[
                      _priceRow(
                        'Discount (${_appliedCoupon!.code})',
                        '-${widget.currency} ${_discount.toStringAsFixed(0)}',
                      ),
                    ],

                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${widget.currency} ${_finalTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.03),

              // ⭐️ SUBMIT
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
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
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'CONFIRM BOOKING • ${widget.currency} ${_finalTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
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

  Widget _buildItemCard(double width, double height) {
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
          if (widget.itemImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.itemImage,
                width: width * 0.2,
                height: width * 0.2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: width * 0.2,
                  height: width * 0.2,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image),
                ),
              ),
            ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.042,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: height * 0.005),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.itemType.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.price > 0) ...[
                  SizedBox(height: height * 0.005),
                  Text(
                    '${widget.currency} ${widget.price.toStringAsFixed(0)} per person',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.032,
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
            fontSize: width * 0.042,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildAddon(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      double width,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.02),
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.03, vertical: width * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.primary : Colors.grey.shade300,
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.035,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: width * 0.028,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
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