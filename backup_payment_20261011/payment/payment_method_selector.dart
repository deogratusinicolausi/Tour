import 'package:flutter/material.dart';
import '../../utils/colors.dart';

/// ⭐ Payment Method Selector
/// Onyesho la mobile money + cards
class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;      // 'mobile_money' au 'card'
  final String selectedNetwork;     // 'mpesa', 'airtel', 'tigo', 'visa', n.k.
  final Function(String method, String network) onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.selectedNetwork,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💳 Choose Payment Method',
          style: TextStyle(
            fontSize: width * 0.042,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: width * 0.03),

        // ⭐ Mobile Money Section
        _sectionTitle('📱 Mobile Money', width),
        SizedBox(height: width * 0.02),
        _buildNetworkGrid(
          context,
          width,
          method: 'mobile_money',
          networks: [
            {'id': 'mpesa', 'name': 'M-Pesa', 'emoji': '📱', 'color': Colors.red},
            {'id': 'airtel', 'name': 'Airtel Money', 'emoji': '📱', 'color': Colors.redAccent},
            {'id': 'tigo', 'name': 'Mixx by Yas', 'emoji': '📱', 'color': Colors.blue},
            {'id': 'halotel', 'name': 'HaloPesa', 'emoji': '📱', 'color': Colors.orange},
          ],
        ),

        SizedBox(height: width * 0.04),

        // ⭐ Cards Section
        _sectionTitle('💳 Cards', width),
        SizedBox(height: width * 0.02),
        _buildNetworkGrid(
          context,
          width,
          method: 'card',
          networks: [
            {'id': 'visa', 'name': 'Visa', 'emoji': '💳', 'color': Colors.blue},
            {'id': 'mastercard', 'name': 'Mastercard', 'emoji': '💳', 'color': Colors.red},
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.035,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildNetworkGrid(
    BuildContext context,
    double width, {
    required String method,
    required List<Map<String, dynamic>> networks,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: width * 0.03,
        mainAxisSpacing: width * 0.03,
        childAspectRatio: 2.2,
      ),
      itemCount: networks.length,
      itemBuilder: (context, i) {
        final network = networks[i];
        final isSelected =
            selectedMethod == method && selectedNetwork == network['id'];

        return GestureDetector(
          onTap: () => onChanged(method, network['id']),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: width * 0.03),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  network['emoji'],
                  style: TextStyle(fontSize: width * 0.06),
                ),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    network['name'],
                    style: TextStyle(
                      fontSize: width * 0.03,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: width * 0.05,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
