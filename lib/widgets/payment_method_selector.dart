import 'package:flutter/material.dart';
import '../utils/colors.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  final List<Map<String, String>> methods = const [
    {'value': 'Mpesa', 'label': 'M-Pesa', 'icon': '📱', 'color': 'E60000'},
    {'value': 'Tigo', 'label': 'Tigo Pesa', 'icon': '📱', 'color': '0055A5'},
    {'value': 'Airtel', 'label': 'Airtel Money', 'icon': '📱', 'color': 'FF0000'},
    {'value': 'Halopesa', 'label': 'HaloPesa', 'icon': '📱', 'color': 'F5A623'},
    {'value': 'Azampesa', 'label': 'AzamPesa', 'icon': '📱', 'color': '00A651'},
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: methods.map((method) {
        final isSelected = selectedMethod == method['value'];
        return GestureDetector(
          onTap: () => onChanged(method['value']!),
          child: Container(
            margin: EdgeInsets.only(bottom: width * 0.025),
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(method['icon']!, style: TextStyle(fontSize: width * 0.06)),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Text(
                    method['label']!,
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary, size: width * 0.06),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}