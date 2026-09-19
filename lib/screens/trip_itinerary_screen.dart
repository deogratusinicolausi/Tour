import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../utils/colors.dart';
import 'add_trip_item_screen.dart';

class TripItineraryScreen extends StatefulWidget {
  final TripModel trip;

  const TripItineraryScreen({super.key, required this.trip});

  @override
  State<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends State<TripItineraryScreen> {
  final _tripService = TripService();

  TripModel get trip => widget.trip;

  double get _totalBudget => _tripService.calculateTripBudget(trip);

  Future<void> _addItem(int dayIndex) async {
    final result = await Navigator.push<TripItem>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTripItemScreen(),
      ),
    );

    if (result != null) {
      final updatedDays = List<TripDay>.from(trip.days);
      final updatedItems = List<TripItem>.from(updatedDays[dayIndex].items);
      updatedItems.add(result);

      updatedDays[dayIndex] = TripDay(
        dayNumber: updatedDays[dayIndex].dayNumber,
        title: updatedDays[dayIndex].title,
        notes: updatedDays[dayIndex].notes,
        items: updatedItems,
      );

      final updatedTrip = TripModel(
        id: trip.id,
        userId: trip.userId,
        userName: trip.userName,
        title: trip.title,
        description: trip.description,
        coverImage: trip.coverImage,
        startDate: trip.startDate,
        endDate: trip.endDate,
        totalDays: trip.totalDays,
        totalTravelers: trip.totalTravelers,
        totalBudget: _totalBudget,
        currency: trip.currency,
        days: updatedDays,
        status: trip.status,
      );

      await _tripService.updateTrip(updatedTrip);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripItineraryScreen(trip: updatedTrip),
          ),
        );
      }
    }
  }

  Future<void> _removeItem(int dayIndex, int itemIndex) async {
    final updatedDays = List<TripDay>.from(trip.days);
    final updatedItems = List<TripItem>.from(updatedDays[dayIndex].items);
    updatedItems.removeAt(itemIndex);

    updatedDays[dayIndex] = TripDay(
      dayNumber: updatedDays[dayIndex].dayNumber,
      title: updatedDays[dayIndex].title,
      notes: updatedDays[dayIndex].notes,
      items: updatedItems,
    );

    final updatedTrip = TripModel(
      id: trip.id,
      userId: trip.userId,
      userName: trip.userName,
      title: trip.title,
      description: trip.description,
      coverImage: trip.coverImage,
      startDate: trip.startDate,
      endDate: trip.endDate,
      totalDays: trip.totalDays,
      totalTravelers: trip.totalTravelers,
      totalBudget: _totalBudget,
      currency: trip.currency,
      days: updatedDays,
      status: trip.status,
    );

    await _tripService.updateTrip(updatedTrip);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripItineraryScreen(trip: updatedTrip),
        ),
      );
    }
  }

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
            expandedHeight: height * 0.25,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.mainGradient,
                ),
                child: Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        trip.dateRange,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.035,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Icon(Icons.people,
                              color: Colors.white70, size: width * 0.04),
                          SizedBox(width: width * 0.01),
                          Text(
                            '${trip.totalTravelers} travelers',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.03,
                            ),
                          ),
                          SizedBox(width: width * 0.04),
                          Icon(Icons.timelapse,
                              color: Colors.white70, size: width * 0.04),
                          SizedBox(width: width * 0.01),
                          Text(
                            '${trip.totalDays} days',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.03,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BUDGET CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money,
                        color: Colors.black, size: width * 0.1),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL BUDGET',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${trip.currency} ${_totalBudget.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: width * 0.08,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // DAYS LIST
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, dayIndex) {
                final day = trip.days[dayIndex];
                return _buildDayCard(day, dayIndex, width, height);
              },
              childCount: trip.days.length,
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: height * 0.05),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(
      TripDay day, int dayIndex, double width, double height) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: width * 0.04, vertical: height * 0.01),
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
          // Day header
          Container(
            padding: EdgeInsets.all(width * 0.04),
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: width * 0.12,
                  height: width * 0.12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.dayNumber}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.06,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day ${day.dayNumber}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${day.items.length} activities • ${trip.currency} ${day.dayBudget.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items
          if (day.items.isEmpty)
            Padding(
              padding: EdgeInsets.all(width * 0.08),
              child: Column(
                children: [
                  Icon(Icons.event_note,
                      size: width * 0.1, color: Colors.grey.shade300),
                  SizedBox(height: height * 0.01),
                  Text(
                    'No activities yet',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: width * 0.035,
                    ),
                  ),
                ],
              ),
            )
          else
            ...day.items.asMap().entries.map((entry) {
              final item = entry.value;
              return _buildTripItem(item, entry.key, dayIndex, width, height);
            }),

          // Add button
          Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: GestureDetector(
              onTap: () => _addItem(dayIndex),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: height * 0.015),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle,
                        color: AppColors.primary, size: width * 0.05),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Add Activity',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripItem(
      TripItem item, int itemIndex, int dayIndex, double width, double height) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: width * 0.04, vertical: height * 0.008),
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (item.itemImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.itemImage,
                width: width * 0.15,
                height: width * 0.15,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: width * 0.15,
                  height: width * 0.15,
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
                if (item.time.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: width * 0.03, color: AppColors.primary),
                      SizedBox(width: width * 0.01),
                      Text(item.time,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: width * 0.028,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.035,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.currency} ${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: width * 0.032,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () => _removeItem(dayIndex, itemIndex),
          ),
        ],
      ),
    );
  }
}