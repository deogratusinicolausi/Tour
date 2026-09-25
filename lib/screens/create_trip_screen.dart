import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../utils/colors.dart';
import 'trip_itinerary_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripService = TripService();
  final _user = FirebaseAuth.instance.currentUser;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _travelersController = TextEditingController(text: '2');

  DateTime? _startDate;
  DateTime? _endDate;
  String _currency = 'USD';
  bool _isLoading = false;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 1;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showError('Please select start and end dates');
      return;
    }
    if (_user == null) {
      _showError('Please login first');
      return;
    }

    setState(() => _isLoading = true);

    // Create empty days
    final days = List.generate(
      _totalDays,
          (i) => TripDay(dayNumber: i + 1),
    );

    final trip = TripModel(
      id: '',
      userId: _user!.uid,
      userName: _user!.displayName ?? 'User',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      totalDays: _totalDays,
      totalTravelers: int.tryParse(_travelersController.text) ?? 1,
      currency: _currency,
      days: days,
    );

    final id = await _tripService.createTrip(trip);

    setState(() => _isLoading = false);

    if (id != null && mounted) {
      final createdTrip = TripModel(
        id: id,
        userId: trip.userId,
        userName: trip.userName,
        title: trip.title,
        description: trip.description,
        startDate: trip.startDate,
        endDate: trip.endDate,
        totalDays: trip.totalDays,
        totalTravelers: trip.totalTravelers,
        currency: trip.currency,
        days: trip.days,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripItineraryScreen(trip: createdTrip),
        ),
      );
    } else {
      _showError('Failed to create trip');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _travelersController.dispose();
    super.dispose();
  }

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
                        '✈️ Create Trip',
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
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('📝 Trip Details', width),
                          SizedBox(height: height * 0.015),
                          _buildField(_titleController, 'Trip Title', Icons.title,
                              hint: 'e.g. Tanzania Adventure 2026',
                              validator: (v) => v!.isEmpty ? 'Title required' : null),
                          SizedBox(height: height * 0.015),
                          _buildField(_descriptionController, 'Description',
                              Icons.description,
                              maxLines: 3),
                          SizedBox(height: height * 0.015),
                          _buildField(_travelersController, 'Total Travelers',
                              Icons.people,
                              keyboardType: TextInputType.number),

                          SizedBox(height: height * 0.025),

                          _sectionTitle('📅 Trip Dates', width),
                          SizedBox(height: height * 0.015),
                          Row(
                            children: [
                              Expanded(
                                child: _dateBox(
                                  'Start Date',
                                  _startDate,
                                  Icons.calendar_today,
                                      () => _pickDate(isStart: true),
                                  width,
                                ),
                              ),
                              SizedBox(width: width * 0.03),
                              Expanded(
                                child: _dateBox(
                                  'End Date',
                                  _endDate,
                                  Icons.event,
                                      () => _pickDate(isStart: false),
                                  width,
                                ),
                              ),
                            ],
                          ),
                          if (_startDate != null && _endDate != null) ...[
                            SizedBox(height: height * 0.015),
                            Container(
                              padding: EdgeInsets.all(width * 0.04),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15), // GLASS
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timelapse,
                                      color: AppColors.accentGold, size: 24), // GOLD
                                  SizedBox(width: width * 0.03),
                                  Text(
                                    '$_totalDays day${_totalDays > 1 ? 's' : ''} trip',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.045,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: height * 0.03),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGold, // GOLD
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 5,
                                shadowColor: AppColors.accentGold.withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.black) // BLACK spinner
                                  : const Text(
                                '🚀 CREATE TRIP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // BLACK text
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.05),
                        ],
                      ),
                    ),
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
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: Colors.white, // WHITE
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        String? hint,
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white), // WHITE text
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15), // GLASS
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 2), // GOLD
        ),
      ),
    );
  }

  Widget _dateBox(
      String label,
      DateTime? date,
      IconData icon,
      VoidCallback onTap,
      double width,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // GLASS
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppColors.accentGold : Colors.white.withOpacity(0.3), // GOLD when selected
            width: date != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: width * 0.04, color: Colors.white70), // WHITE70
                SizedBox(width: width * 0.01),
                Text(label,
                    style: TextStyle(
                      color: Colors.white70, // WHITE70
                      fontSize: width * 0.028,
                    )),
              ],
            ),
            SizedBox(height: width * 0.01),
            Text(
              date != null
                  ? DateFormat('dd MMM yyyy').format(date)
                  : 'Select',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.035,
                color: date != null ? Colors.white : Colors.white70, // WHITE/WHITE70
              ),
            ),
          ],
        ),
      ),
    );
  }
}