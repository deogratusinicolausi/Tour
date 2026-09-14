// import 'package:flutter/material.dart';
// import '../models/booking_model.dart';
// import '../services/firestore_service.dart';
// import '../utils/colors.dart';
// import '../widgets/booking_stats_widget.dart';
// import '../widgets/booking_details_sheet.dart';
//
// class BookingsListScreen extends StatefulWidget {
//   const BookingsListScreen({super.key});
//
//   @override
//   State<BookingsListScreen> createState() => _BookingsListScreenState();
// }
//
// class _BookingsListScreenState extends State<BookingsListScreen> {
//   final _service = FirestoreService();
//   final _searchController = TextEditingController();
//   String _searchQuery = '';
//   String _filterStatus = 'all';
//   Map<String, int> _stats = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadStats();
//   }
//
//   Future<void> _loadStats() async {
//     final stats = await _service.getBookingStats();
//     if (mounted) setState(() => _stats = stats);
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _confirmBooking(BookingModel b) async {
//     final ok = await _service.confirmBooking(b.id);
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(ok
//               ? '✅ Booking confirmed for ${b.userName}'
//               : '❌ Failed to confirm'),
//           backgroundColor: ok ? Colors.green : Colors.red,
//         ),
//       );
//       _loadStats();
//     }
//   }
//
//   Future<void> _cancelBooking(BookingModel b) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Cancel Booking?'),
//         content: Text(
//             'Cancel booking for "${b.itemName}" by ${b.userName}?'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No')),
//           TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: TextButton.styleFrom(foregroundColor: Colors.red),
//               child: const Text('Yes, Cancel')),
//         ],
//       ),
//     );
//     if (confirm == true) {
//       final ok = await _service.cancelBooking(b.id);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(ok ? '✅ Booking cancelled' : '❌ Failed'),
//             backgroundColor: ok ? Colors.orange : Colors.red,
//           ),
//         );
//         _loadStats();
//       }
//     }
//   }
//
//   Future<void> _completeBooking(BookingModel b) async {
//     final ok = await _service.completeBooking(b.id);
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(ok ? '✅ Booking completed' : '❌ Failed'),
//           backgroundColor: ok ? Colors.blue : Colors.red,
//         ),
//       );
//       _loadStats();
//     }
//   }
//
//   Future<void> _viewDetails(BookingModel b) async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => BookingDetailsSheet(
//         booking: b,
//         onConfirm: () => _confirmBooking(b),
//         onCancel: () => _cancelBooking(b),
//         onComplete: () => _completeBooking(b),
//       ),
//     );
//     _loadStats();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('📅 Bookings Management'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadStats,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // ⭐️ STATS
//           BookingStatsWidget(stats: _stats),
//
//           // ⭐️ SEARCH + FILTER
//           Container(
//             padding: EdgeInsets.all(width * 0.04),
//             color: AppColors.primary,
//             child: Column(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: (v) =>
//                         setState(() => _searchQuery = v.toLowerCase()),
//                     decoration: InputDecoration(
//                       hintText: 'Search by name, email, or item...',
//                       prefixIcon: const Icon(Icons.search),
//                       border: InputBorder.none,
//                       contentPadding:
//                       EdgeInsets.symmetric(vertical: height * 0.015),
//                       suffixIcon: _searchQuery.isNotEmpty
//                           ? IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           _searchController.clear();
//                           setState(() => _searchQuery = '');
//                         },
//                       )
//                           : null,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: height * 0.015),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       'all',
//                       'pending',
//                       'confirmed',
//                       'completed',
//                       'cancelled'
//                     ].map((status) {
//                       final isSelected = _filterStatus == status;
//                       return GestureDetector(
//                         onTap: () =>
//                             setState(() => _filterStatus = status),
//                         child: Container(
//                           margin: EdgeInsets.only(right: width * 0.02),
//                           padding: EdgeInsets.symmetric(
//                             horizontal: width * 0.04,
//                             vertical: height * 0.008,
//                           ),
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? AppColors.accentGold
//                                 : Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             status.toUpperCase(),
//                             style: TextStyle(
//                               color: isSelected
//                                   ? Colors.black
//                                   : Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: width * 0.028,
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // ⭐️ LIST
//           Expanded(
//             child: StreamBuilder<List<BookingModel>>(
//               stream: _service.getBookings(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState ==
//                     ConnectionState.waiting) {
//                   return const Center(
//                       child: CircularProgressIndicator());
//                 }
//
//                 final all = snapshot.data ?? [];
//                 final bookings = all.where((b) {
//                   final matchSearch = _searchQuery.isEmpty ||
//                       b.itemName.toLowerCase().contains(_searchQuery) ||
//                       b.userName.toLowerCase().contains(_searchQuery) ||
//                       b.userEmail.toLowerCase().contains(_searchQuery);
//                   final matchStatus = _filterStatus == 'all' ||
//                       b.bookingStatus == _filterStatus;
//                   return matchSearch && matchStatus;
//                 }).toList();
//
//                 if (bookings.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.inbox,
//                             size: width * 0.2,
//                             color: Colors.grey.shade300),
//                         const SizedBox(height: 20),
//                         Text(
//                           _searchQuery.isEmpty
//                               ? 'No bookings yet'
//                               : 'No results found',
//                           style: TextStyle(
//                             fontSize: width * 0.05,
//                             color: Colors.grey.shade600,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           _searchQuery.isEmpty
//                               ? 'Bookings will appear here'
//                               : 'Try a different search',
//                           style:
//                           TextStyle(color: Colors.grey.shade400),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 return ListView.builder(
//                   padding: EdgeInsets.all(width * 0.04),
//                   itemCount: bookings.length,
//                   itemBuilder: (context, i) =>
//                       _buildBookingCard(bookings[i], width, height),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBookingCard(
//       BookingModel b, double width, double height) {
//     Color statusColor;
//     IconData statusIcon;
//     switch (b.bookingStatus) {
//       case 'confirmed':
//         statusColor = Colors.green;
//         statusIcon = Icons.check_circle;
//         break;
//       case 'cancelled':
//         statusColor = Colors.red;
//         statusIcon = Icons.cancel;
//         break;
//       case 'completed':
//         statusColor = Colors.blue;
//         statusIcon = Icons.done_all;
//         break;
//       default:
//         statusColor = Colors.orange;
//         statusIcon = Icons.access_time;
//     }
//
//     return GestureDetector(
//       onTap: () => _viewDetails(b),
//       child: Container(
//         margin: EdgeInsets.only(bottom: height * 0.015),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             // Status strip
//             Container(
//               padding: EdgeInsets.symmetric(
//                   horizontal: width * 0.04, vertical: height * 0.012),
//               decoration: BoxDecoration(
//                 color: statusColor.withOpacity(0.1),
//                 borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(16)),
//               ),
//               child: Row(
//                 children: [
//                   Icon(statusIcon,
//                       color: statusColor, size: width * 0.045),
//                   SizedBox(width: width * 0.02),
//                   Text(
//                     b.bookingStatus.toUpperCase(),
//                     style: TextStyle(
//                       color: statusColor,
//                       fontWeight: FontWeight.bold,
//                       fontSize: width * 0.03,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (b.createdAt != null)
//                     Text(
//                       '${b.createdAt!.day}/${b.createdAt!.month}/${b.createdAt!.year}',
//                       style: TextStyle(
//                         fontSize: width * 0.026,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             // Body
//             Padding(
//               padding: EdgeInsets.all(width * 0.04),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       // Item image
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: b.itemImage.isNotEmpty
//                             ? Image.network(
//                           b.itemImage,
//                           width: width * 0.2,
//                           height: width * 0.2,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => Container(
//                             width: width * 0.2,
//                             height: width * 0.2,
//                             color: Colors.grey.shade200,
//                             child: const Icon(Icons.image),
//                           ),
//                         )
//                             : Container(
//                           width: width * 0.2,
//                           height: width * 0.2,
//                           color: Colors.grey.shade200,
//                           child: const Icon(Icons.image),
//                         ),
//                       ),
//                       SizedBox(width: width * 0.03),
//
//                       // Item info
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color:
//                                 AppColors.primary.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: Text(
//                                 b.itemType.toUpperCase(),
//                                 style: const TextStyle(
//                                   color: AppColors.primary,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             SizedBox(height: height * 0.005),
//                             Text(
//                               b.itemName,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: width * 0.04,
//                                 color: Colors.grey.shade800,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             SizedBox(height: height * 0.005),
//                             Row(
//                               children: [
//                                 Icon(Icons.person,
//                                     size: width * 0.03,
//                                     color: Colors.grey.shade500),
//                                 SizedBox(width: width * 0.01),
//                                 Expanded(
//                                   child: Text(
//                                     b.userName,
//                                     style: TextStyle(
//                                       fontSize: width * 0.028,
//                                       color: Colors.grey.shade600,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             if (b.userEmail.isNotEmpty)
//                               Row(
//                                 children: [
//                                   Icon(Icons.email,
//                                       size: width * 0.03,
//                                       color: Colors.grey.shade500),
//                                   SizedBox(width: width * 0.01),
//                                   Expanded(
//                                     child: Text(
//                                       b.userEmail,
//                                       style: TextStyle(
//                                         fontSize: width * 0.026,
//                                         color: Colors.grey.shade500,
//                                       ),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                           ],
//                         ),
//                       ),
//
//                       // Amount
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             '${b.currency} ${b.amount.toStringAsFixed(0)}',
//                             style: TextStyle(
//                               fontSize: width * 0.042,
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.primary,
//                             ),
//                           ),
//                           Text(
//                             '${b.guests} guest${b.guests > 1 ? 's' : ''}',
//                             style: TextStyle(
//                               fontSize: width * 0.026,
//                               color: Colors.grey.shade500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//
//                   SizedBox(height: height * 0.015),
//
//                   // Quick action buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _actionBtn(
//                           icon: Icons.visibility,
//                           label: 'Details',
//                           color: AppColors.primary,
//                           onTap: () => _viewDetails(b),
//                           width: width,
//                         ),
//                       ),
//                       if (b.bookingStatus == 'pending') ...[
//                         SizedBox(width: width * 0.02),
//                         Expanded(
//                           child: _actionBtn(
//                             icon: Icons.check,
//                             label: 'Confirm',
//                             color: Colors.green,
//                             onTap: () => _confirmBooking(b),
//                             width: width,
//                           ),
//                         ),
//                         SizedBox(width: width * 0.02),
//                         Expanded(
//                           child: _actionBtn(
//                             icon: Icons.close,
//                             label: 'Cancel',
//                             color: Colors.red,
//                             onTap: () => _cancelBooking(b),
//                             width: width,
//                           ),
//                         ),
//                       ] else if (b.bookingStatus == 'confirmed') ...[
//                         SizedBox(width: width * 0.02),
//                         Expanded(
//                           child: _actionBtn(
//                             icon: Icons.done_all,
//                             label: 'Complete',
//                             color: Colors.blue,
//                             onTap: () => _completeBooking(b),
//                             width: width,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _actionBtn({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//     required double width,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: width * 0.025),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: width * 0.04),
//             SizedBox(width: width * 0.01),
//             Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontSize: width * 0.028,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';  // ⭐ LAZIMA IWE HAPA
import '../utils/colors.dart';

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
      amount: _totalPrice,
      currency: widget.currency,
      specialRequests: _requestsController.text.trim(),
    );

    final id = await _bookingService.createBooking(booking);
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
                  _summaryRow('Total', '${widget.currency} ${_totalPrice.toStringAsFixed(0)}'),
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
                          '${widget.currency} ${_totalPrice.toStringAsFixed(0)}',
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
                        'CONFIRM BOOKING • ${widget.currency} ${_totalPrice.toStringAsFixed(0)}',
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