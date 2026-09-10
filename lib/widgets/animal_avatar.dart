import 'package:flutter/material.dart';

class AnimalAvatar extends StatelessWidget {
  final String animal;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimalAvatar({
    super.key,
    required this.animal,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.blue[700] : Colors.grey[200],
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.blue[700]!.withOpacity(0.4),
              blurRadius: 15,
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 30,
            ),
            const SizedBox(height: 2),
            Text(
              animal,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}