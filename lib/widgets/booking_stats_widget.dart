import 'package:flutter/material.dart';
import '../utils/colors.dart';

class BookingStatsWidget extends StatelessWidget {
  final Map<String, int> stats;

  const BookingStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      color: AppColors.primary,
      child: Column(
        children: [
          // Top row: Total + Revenue
          Row(
            children: [
              Expanded(
                child: _bigStatCard(
                  '📊',
                  'Total Bookings',
                  stats['total']?.toString() ?? '0',
                  Colors.white,
                  width,
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: _bigStatCard(
                  '💰',
                  'Revenue',
                  '\$${stats['revenue'] ?? 0}',
                  AppColors.accentGold,
                  width,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          // Bottom row: Status counts
          Row(
            children: [
              _smallStatCard(
                '⏳',
                'Pending',
                stats['pending'] ?? 0,
                Colors.orange,
                width,
              ),
              _smallStatCard(
                '✅',
                'Confirmed',
                stats['confirmed'] ?? 0,
                Colors.green,
                width,
              ),
              _smallStatCard(
                '❌',
                'Cancelled',
                stats['cancelled'] ?? 0,
                Colors.red,
                width,
              ),
              _smallStatCard(
                '✔️',
                'Completed',
                stats['completed'] ?? 0,
                Colors.blue,
                width,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigStatCard(
      String emoji,
      String label,
      String value,
      Color color,
      double width,
      ) {
    return Container(
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: width * 0.07)),
          SizedBox(width: width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.026,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStatCard(
      String emoji,
      String label,
      int value,
      Color color,
      double width,
      ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(
          vertical: width * 0.025,
          horizontal: width * 0.01,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: width * 0.04)),
            SizedBox(height: width * 0.005),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.022,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}