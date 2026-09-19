import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../utils/colors.dart';
import 'cancel_booking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _service = BookingService();
  final _user = FirebaseAuth.instance.currentUser;
  String _filter = 'all';

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': '📋 All'},
    {'value': 'pending', 'label': '⏳ Pending'},
    {'value': 'confirmed', 'label': '✅ Confirmed'},
    {'value': 'completed', 'label': '🎉 Completed'},
    {'value': 'cancelled', 'label': '❌ Cancelled'},
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📅 My Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _user == null
          ? _buildLoginPrompt(width, height)
          : Column(
        children: [
          // FILTERS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _filter == f['value'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filter = f['value']!),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: height * 0.008),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGold
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.028,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _service.getUserBookings(_user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                var bookings = snapshot.data ?? [];
                if (_filter != 'all') {
                  bookings = bookings
                      .where((b) => b.bookingStatus == _filter)
                      .toList();
                }

                if (bookings.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: bookings.length,
                  itemBuilder: (context, i) =>
                      _buildBookingCard(bookings[i], width, height),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline,
              size: width * 0.2, color: Colors.grey.shade300),
          SizedBox(height: height * 0.02),
          Text(
            'Please Login',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
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
            child: Icon(Icons.event_busy,
                size: width * 0.15, color: AppColors.primary),
          ),
          SizedBox(height: height * 0.03),
          Text(
            _filter == 'all'
                ? 'No bookings yet'
                : 'No $_filter bookings',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            'Start exploring Tanzania! 🇹🇿',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: width * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel b, double width, double height) {
    Color statusColor;
    IconData statusIcon;
    switch (b.bookingStatus) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancellation_requested':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    final canCancel = b.bookingStatus == 'pending' ||
        b.bookingStatus == 'confirmed';

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // STATUS STRIP
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.012,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: width * 0.045),
                SizedBox(width: width * 0.02),
                Text(
                  b.bookingStatus.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.03,
                  ),
                ),
                const Spacer(),
                if (b.createdAt != null)
                  Text(
                    DateFormat('dd MMM yyyy').format(b.createdAt!),
                    style: TextStyle(
                      fontSize: width * 0.026,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // BODY
          Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: b.itemImage.isNotEmpty
                      ? Image.network(
                    b.itemImage,
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

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b.itemType.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        b.itemName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                          color: Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: height * 0.008),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: width * 0.03,
                              color: Colors.grey.shade500),
                          SizedBox(width: width * 0.01),
                          Text(
                            b.travelDate != null
                                ? DateFormat('dd MMM yyyy')
                                .format(b.travelDate!)
                                : 'No date',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.people,
                              size: width * 0.03,
                              color: Colors.grey.shade500),
                          SizedBox(width: width * 0.01),
                          Text(
                            '${b.guests}',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (b.couponCode.isNotEmpty) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            Icon(Icons.local_offer,
                                size: width * 0.03,
                                color: Colors.green),
                            SizedBox(width: width * 0.01),
                            Text(
                              'Coupon: ${b.couponCode}',
                              style: TextStyle(
                                fontSize: width * 0.026,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AMOUNT
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.012,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(canCancel ? 0 : 16),
                bottomRight: Radius.circular(canCancel ? 0 : 16),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Total: ',
                  style: TextStyle(fontSize: 13),
                ),
                Text(
                  '${b.currency} ${b.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: width * 0.04,
                  ),
                ),
                if (b.couponDiscount > 0) ...[
                  SizedBox(width: width * 0.02),
                  Text(
                    '(-${b.currency} ${b.couponDiscount.toStringAsFixed(0)})',
                    style: TextStyle(
                      fontSize: width * 0.03,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: b.paymentStatus == 'paid'
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    b.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: b.paymentStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CANCEL BUTTON
          if (canCancel)
            // ⭐️ CANCEL BUTTON
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.04,
                vertical: height * 0.012,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CancelBookingScreen(booking: b),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: height * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: width * 0.05),
                      SizedBox(width: width * 0.02),
                      Text(
                        'Cancel Booking',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // CANCELLATION REQUESTED MESSAGE
          if (b.bookingStatus == 'cancellation_requested')
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.04,
                vertical: height * 0.012,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Container(
                padding: EdgeInsets.all(width * 0.035),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top,
                        color: Colors.orange, size: width * 0.05),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: Text(
                        'Cancellation request pending admin approval',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}