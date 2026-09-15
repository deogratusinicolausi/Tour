import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';

class ItineraryScreen extends StatelessWidget {
  final String orderId;
  final List<String> bookingIds;
  final DateTime startDate;

  const ItineraryScreen({
    super.key,
    required this.orderId,
    required this.bookingIds,
    required this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // HEADER
          SliverAppBar(
            expandedHeight: height * 0.3,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.mainGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.06),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle,
                          color: Colors.white, size: width * 0.15),
                    ),
                    SizedBox(height: height * 0.02),
                    const Text(
                      '🎉 Booking Confirmed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      'Your digital itinerary is ready',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: width * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Info
                  Container(
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
                      children: [
                        _infoRow(
                          Icons.calendar_today,
                          'Start Date',
                          DateFormat('EEEE, dd MMM yyyy').format(startDate),
                          width,
                        ),
                        Divider(height: height * 0.03),
                        _infoRow(
                          Icons.confirmation_number,
                          'Order ID',
                          orderId.substring(0, 12).toUpperCase(),
                          width,
                        ),
                        Divider(height: height * 0.03),
                        _infoRow(
                          Icons.shopping_bag,
                          'Total Items',
                          '${bookingIds.length}',
                          width,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // Itinerary Title
                  Text(
                    '🗺️ Your Trip Itinerary',
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),

                  SizedBox(height: height * 0.015),

                  // Bookings List
                  ...bookingIds.asMap().entries.map((e) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(e.value)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }
                        final data =
                        snapshot.data!.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox();

                        return _buildDayCard(
                          e.key + 1,
                          data,
                          width,
                          height,
                        );
                      },
                    );
                  }),

                  SizedBox(height: height * 0.03),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Share itinerary
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding:
                            EdgeInsets.symmetric(vertical: height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.popUntil(
                                context, (r) => r.isFirst);
                          },
                          icon: const Icon(Icons.home, color: Colors.white),
                          label: const Text('Home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding:
                            EdgeInsets.symmetric(vertical: height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, double width) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.025),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: width * 0.05),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: width * 0.028,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.038,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(
      int day,
      Map<String, dynamic> booking,
      double width,
      double height,
      ) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day indicator
          Container(
            width: width * 0.2,
            padding: EdgeInsets.symmetric(vertical: height * 0.02),
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius:
              BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  'DAY',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.025,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(width * 0.035),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if ((booking['itemImage'] ?? '').toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            booking['itemImage'],
                            width: width * 0.12,
                            height: width * 0.12,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: width * 0.12,
                              height: width * 0.12,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 16),
                            ),
                          ),
                        ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (booking['itemType'] ?? '').toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.005),
                            Text(
                              booking['itemName'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.035,
                                color: Colors.grey.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.01),
                  Row(
                    children: [
                      Icon(Icons.people,
                          size: width * 0.035, color: Colors.grey.shade500),
                      SizedBox(width: width * 0.01),
                      Text(
                        '${booking['guests'] ?? 1} guests',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${booking['currency'] ?? 'USD'} ${(booking['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.038,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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