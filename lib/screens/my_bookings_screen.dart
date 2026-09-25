import 'package:flutter/material.dart';
import 'dart:ui';
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
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.55),
          ),
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM TOP HEADER ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.01,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '📅 My Bookings',
                        style: TextStyle(
                          fontSize: width * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- REST OF YOUR CONTENT ---
                Expanded(
                  child: _user == null
                      ? _buildLoginPrompt(width, height)
                      : Column(
                          children: [
                            // FILTERS (Modified below)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.04, vertical: height * 0.01),
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
                                              : Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.accentGold
                                                : Colors.white.withOpacity(0.3),
                                          ),
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
                                        child: CircularProgressIndicator(color: Colors.white));
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
                ),
              ],
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
              size: width * 0.2, color: Colors.white70),
          SizedBox(height: height * 0.02),
          Text(
            'Please Login',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(width * 0.1),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy,
                size: width * 0.15, color: Colors.white70),
            SizedBox(height: height * 0.03),
            Text(
              _filter == 'all'
                  ? 'No bookings yet'
                  : 'No $_filter bookings',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Start exploring Tanzania! 🇹🇿',
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.035,
              ),
            ),
          ],
        ),
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
        color: Colors.white.withOpacity(0.15), // GLASS
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: statusColor.withOpacity(0.15), // Slightly stronger for status
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: width * 0.045),
                SizedBox(width: width * 0.02),
                Text(
                  b.bookingStatus.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    color: Colors.white, // WHITE
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
                      color: Colors.white70, // WHITE70
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
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(Icons.image, color: Colors.white70),
                    ),
                  )
                      : Container(
                    width: width * 0.2,
                    height: width * 0.2,
                    color: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.image, color: Colors.white70),
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
                          color: Colors.white.withOpacity(0.2), // GLASS
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b.itemType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, // WHITE
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
                          color: Colors.white, // WHITE
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: height * 0.008),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: width * 0.03,
                              color: Colors.white70),
                          SizedBox(width: width * 0.01),
                          Text(
                            b.travelDate != null
                                ? DateFormat('dd MMM yyyy')
                                .format(b.travelDate!)
                                : 'No date',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.people,
                              size: width * 0.03,
                              color: Colors.white70),
                          SizedBox(width: width * 0.01),
                          Text(
                            '${b.guests}',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.white70,
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
                                color: Colors.green.shade300),
                            SizedBox(width: width * 0.01),
                            Text(
                              'Coupon: ${b.couponCode}',
                              style: TextStyle(
                                fontSize: width * 0.026,
                                color: Colors.green.shade300,
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
              color: Colors.white.withOpacity(0.1), // GLASS
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(canCancel ? 0 : 16),
                bottomRight: Radius.circular(canCancel ? 0 : 16),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Total: ',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  '${b.currency} ${b.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold, // GOLD
                    fontSize: width * 0.04,
                  ),
                ),
                if (b.couponDiscount > 0) ...[
                  SizedBox(width: width * 0.02),
                  Text(
                    '(-${b.currency} ${b.couponDiscount.toStringAsFixed(0)})',
                    style: TextStyle(
                      fontSize: width * 0.03,
                      color: Colors.green.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: b.paymentStatus == 'paid'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    b.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: b.paymentStatus == 'paid'
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.04,
                vertical: height * 0.012,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), // GLASS
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
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
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: width * 0.02),
                      Text(
                        'Cancel Booking',
                        style: TextStyle(
                          color: Colors.red.shade200,
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), // GLASS
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(width * 0.035),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top,
                        color: Colors.orange.shade300, size: width * 0.05),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: Text(
                        'Cancellation request pending admin approval',
                        style: TextStyle(
                          color: Colors.orange.shade200,
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