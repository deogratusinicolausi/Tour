import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_model.dart';
import '../utils/colors.dart';

class ReceiptScreen extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🧾 Receipt'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          children: [
            // ⭐️ RECEIPT CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // HEADER
                  _buildHeader(width, height),

                  // BODY
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('📋 Booking Details', width),
                        SizedBox(height: height * 0.01),
                        _detailRow('Receipt No', receipt.receiptNumber, width),
                        _detailRow(
                          'Date Issued',
                          receipt.createdAt != null
                              ? DateFormat('dd MMM yyyy, HH:mm')
                              .format(receipt.createdAt!)
                              : 'N/A',
                          width,
                        ),
                        _detailRow('Booking Status',
                            receipt.bookingStatus.toUpperCase(), width),

                        const Divider(height: 30),

                        _sectionTitle('👤 Customer', width),
                        SizedBox(height: height * 0.01),
                        _detailRow('Name', receipt.userName, width),
                        _detailRow('Email', receipt.userEmail, width),
                        _detailRow('Phone', receipt.userPhone, width),

                        const Divider(height: 30),

                        _sectionTitle('🎯 Item', width),
                        SizedBox(height: height * 0.01),
                        _detailRow('Type', receipt.itemType.toUpperCase(), width),
                        _detailRow('Name', receipt.itemName, width),
                        _detailRow(
                          'Travel Date',
                          receipt.travelDate != null
                              ? DateFormat('dd MMM yyyy')
                              .format(receipt.travelDate!)
                              : 'N/A',
                          width,
                        ),
                        _detailRow('Guests', '${receipt.guests}', width),

                        const Divider(height: 30),

                        _sectionTitle('💰 Payment', width),
                        SizedBox(height: height * 0.01),
                        _detailRow('Method', receipt.paymentMethod, width),
                        _detailRow('Status',
                            receipt.paymentStatus.toUpperCase(), width),
                        if (receipt.transactionId.isNotEmpty)
                          _detailRow('Transaction ID',
                              receipt.transactionId, width),

                        const Divider(height: 30),

                        _sectionTitle('💵 Amount Breakdown', width),
                        SizedBox(height: height * 0.01),
                        _amountRow('Base Amount',
                            '${receipt.currency} ${receipt.baseAmount.toStringAsFixed(0)}', width),
                        if (receipt.addonsAmount > 0)
                          _amountRow('Add-ons',
                              '${receipt.currency} ${receipt.addonsAmount.toStringAsFixed(0)}', width),
                        if (receipt.couponDiscount > 0)
                          _amountRow(
                            'Discount (${receipt.couponCode})',
                            '-${receipt.currency} ${receipt.couponDiscount.toStringAsFixed(0)}',
                            width,
                            color: Colors.green,
                          ),
                        const Divider(height: 20),
                        _amountRow(
                          'TOTAL',
                          '${receipt.currency} ${receipt.totalAmount.toStringAsFixed(0)}',
                          width,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  // FOOTER
                  _buildFooter(width, height),
                ],
              ),
            ),

            SizedBox(height: height * 0.03),

            // ⭐️ ACTIONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReceipt(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: EdgeInsets.symmetric(vertical: height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadReceipt(context),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: height * 0.02),
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
    );
  }

  Widget _buildHeader(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: width * 0.08,
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TURIVA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Payment Receipt',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: width * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03, vertical: width * 0.02),
                decoration: BoxDecoration(
                  color: receipt.paymentStatus == 'paid'
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  receipt.paymentStatus == 'paid' ? '✅ PAID' : '⏳ PENDING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Icon(Icons.explore, color: AppColors.primary, size: width * 0.1),
          SizedBox(height: height * 0.01),
          Text(
            'Thank you for choosing TURIVA!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              fontSize: width * 0.035,
            ),
          ),
          SizedBox(height: height * 0.005),
          Text(
            'Karibu Tanzania 🇹🇿',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: width * 0.03,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            'support@turiva.co.tz | +255 123 456 789',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: width * 0.026,
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
        fontWeight: FontWeight.bold,
        fontSize: width * 0.038,
        color: AppColors.primary,
      ),
    );
  }

  Widget _detailRow(String label, String value, double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width * 0.35,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: width * 0.032,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: width * 0.032,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value, double width,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? width * 0.042 : width * 0.034,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBold ? width * 0.048 : width * 0.034,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Sharing receipt...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Downloading receipt as PDF...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}