// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:intl/intl.dart';
// import '../models/booking_model.dart';
// import '../utils/colors.dart';
//
// class BookingDetailsSheet extends StatelessWidget {
//   final BookingModel booking;
//   final VoidCallback onConfirm;
//   final VoidCallback onCancel;
//   final VoidCallback onComplete;
//
//   const BookingDetailsSheet({
//     super.key,
//     required this.booking,
//     required this.onConfirm,
//     required this.onCancel,
//     required this.onComplete,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final height = MediaQuery.of(context).size.height;
//
//     Color statusColor;
//     IconData statusIcon;
//     switch (booking.bookingStatus) {
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
//     return DraggableScrollableSheet(
//       initialChildSize: 0.9,
//       minChildSize: 0.5,
//       maxChildSize: 0.95,
//       builder: (_, controller) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Column(
//             children: [
//               // Handle
//               Container(
//                 margin: EdgeInsets.only(top: height * 0.015),
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//
//               // Header
//               Padding(
//                 padding: EdgeInsets.all(width * 0.05),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(width * 0.03),
//                       decoration: BoxDecoration(
//                         color: statusColor.withOpacity(0.15),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(statusIcon,
//                           color: statusColor, size: width * 0.06),
//                     ),
//                     SizedBox(width: width * 0.03),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Booking Details',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             booking.id.substring(0, 8).toUpperCase(),
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//               ),
//               const Divider(height: 1),
//
//               Expanded(
//                 child: SingleChildScrollView(
//                   controller: controller,
//                   padding: EdgeInsets.all(width * 0.05),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // STATUS BADGES
//                       Row(
//                         children: [
//                           _statusBadge(
//                               'Booking', booking.bookingStatus, statusColor),
//                           SizedBox(width: width * 0.02),
//                           _statusBadge(
//                             'Payment',
//                             booking.paymentStatus,
//                             booking.paymentStatus == 'paid'
//                                 ? Colors.green
//                                 : Colors.orange,
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: height * 0.025),
//
//                       // ITEM
//                       _sectionTitle('📦 Item Details', width),
//                       Container(
//                         padding: EdgeInsets.all(width * 0.04),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             if (booking.itemImage.isNotEmpty)
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(10),
//                                 child: Image.network(
//                                   booking.itemImage,
//                                   width: width * 0.2,
//                                   height: width * 0.2,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (_, __, ___) => Container(
//                                     width: width * 0.2,
//                                     height: width * 0.2,
//                                     color: Colors.grey.shade200,
//                                     child: const Icon(Icons.image),
//                                   ),
//                                 ),
//                               ),
//                             SizedBox(width: width * 0.03),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     booking.itemName,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 5),
//                                   Text(
//                                     booking.itemType.toUpperCase(),
//                                     style: const TextStyle(
//                                       color: AppColors.primary,
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: height * 0.025),
//
//                       // GUEST INFO
//                       _sectionTitle('👤 Guest Information', width),
//                       _detailRow('Name', booking.userName, width),
//                       _detailRow(
//                         'Email',
//                         booking.userEmail.isNotEmpty
//                             ? booking.userEmail
//                             : 'N/A',
//                         width,
//                       ),
//                       _detailRow(
//                         'Phone',
//                         booking.userPhone.isNotEmpty
//                             ? booking.userPhone
//                             : 'N/A',
//                         width,
//                       ),
//                       SizedBox(height: height * 0.015),
//
//                       // Contact Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () async {
//                                 if (booking.userPhone.isNotEmpty) {
//                                   final uri =
//                                   Uri.parse('tel:${booking.userPhone}');
//                                   if (await canLaunchUrl(uri)) {
//                                     await launchUrl(uri);
//                                   }
//                                 }
//                               },
//                               icon: const Icon(Icons.phone, size: 18),
//                               label: const Text('Call'),
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: Colors.green,
//                                 side: const BorderSide(color: Colors.green),
//                                 padding:
//                                 EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: width * 0.03),
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () async {
//                                 if (booking.userEmail.isNotEmpty) {
//                                   final uri = Uri.parse(
//                                       'mailto:${booking.userEmail}');
//                                   if (await canLaunchUrl(uri)) {
//                                     await launchUrl(uri);
//                                   }
//                                 }
//                               },
//                               icon: const Icon(Icons.email, size: 18),
//                               label: const Text('Email'),
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: Colors.blue,
//                                 side: const BorderSide(color: Colors.blue),
//                                 padding:
//                                 EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: height * 0.025),
//
//                       // TRAVEL DETAILS
//                       _sectionTitle('✈️ Travel Details', width),
//                       _detailRow(
//                         'Travel Date',
//                         booking.travelDate != null
//                             ? DateFormat('EEEE, dd MMM yyyy')
//                             .format(booking.travelDate!)
//                             : 'N/A',
//                         width,
//                       ),
//                       _detailRow('Guests', '${booking.guests}', width),
//                       _detailRow(
//                         'Booked On',
//                         booking.createdAt != null
//                             ? DateFormat('dd MMM yyyy, HH:mm')
//                             .format(booking.createdAt!)
//                             : 'N/A',
//                         width,
//                       ),
//                       SizedBox(height: height * 0.025),
//
//                       // PAYMENT
//                       _sectionTitle('💰 Payment', width),
//                       Container(
//                         padding: EdgeInsets.all(width * 0.04),
//                         decoration: BoxDecoration(
//                           gradient: AppColors.mainGradient,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           mainAxisAlignment:
//                           MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment:
//                               CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'TOTAL AMOUNT',
//                                   style: TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 11,
//                                     letterSpacing: 1,
//                                   ),
//                                 ),
//                                 Text(
//                                   '${booking.currency} ${booking.amount.toStringAsFixed(0)}',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Icon(Icons.attach_money,
//                                 color: Colors.white, size: 40),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: height * 0.015),
//                       _detailRow(
//                         'Payment Status',
//                         booking.paymentStatus.toUpperCase(),
//                         width,
//                       ),
//                       SizedBox(height: height * 0.025),
//
//                       // SPECIAL REQUESTS
//                       if (booking.specialRequests.isNotEmpty) ...[
//                         _sectionTitle('💬 Special Requests', width),
//                         Container(
//                           padding: EdgeInsets.all(width * 0.04),
//                           decoration: BoxDecoration(
//                             color: Colors.orange.shade50,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                                 color: Colors.orange.shade200),
//                           ),
//                           child: Text(
//                             booking.specialRequests,
//                             style: TextStyle(
//                               color: Colors.grey.shade800,
//                               fontSize: 14,
//                               height: 1.5,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: height * 0.025),
//                       ],
//
//                       // ACTIONS
//                       if (booking.bookingStatus == 'pending') ...[
//                         _sectionTitle('⚡ Actions', width),
//                         SizedBox(height: height * 0.01),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               onConfirm();
//                             },
//                             icon: const Icon(Icons.check,
//                                 color: Colors.white),
//                             label: const Text(
//                               'CONFIRM BOOKING',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: height * 0.01),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: OutlinedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               onCancel();
//                             },
//                             icon: const Icon(Icons.close,
//                                 color: Colors.red),
//                             label: const Text(
//                               'CANCEL BOOKING',
//                               style: TextStyle(
//                                 color: Colors.red,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             style: OutlinedButton.styleFrom(
//                               side: const BorderSide(
//                                   color: Colors.red, width: 2),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ] else if (booking.bookingStatus ==
//                           'confirmed') ...[
//                         _sectionTitle('⚡ Actions', width),
//                         SizedBox(height: height * 0.01),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               onComplete();
//                             },
//                             icon: const Icon(Icons.done_all,
//                                 color: Colors.white),
//                             label: const Text(
//                               'MARK AS COMPLETED',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//
//                       SizedBox(height: height * 0.03),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _statusBadge(String label, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             '$label: ',
//             style: TextStyle(
//               color: color,
//               fontSize: 11,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Text(
//             value.toUpperCase(),
//             style: TextStyle(
//               color: color,
//               fontSize: 11,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _sectionTitle(String title, double width) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: width * 0.04,
//           fontWeight: FontWeight.bold,
//           color: AppColors.primary,
//         ),
//       ),
//     );
//   }
//
//   Widget _detailRow(String label, String value, double width) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: width * 0.32,
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: width * 0.032,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: width * 0.032,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }