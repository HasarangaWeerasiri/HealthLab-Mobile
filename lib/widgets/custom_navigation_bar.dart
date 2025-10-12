import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF366A49).withOpacity(0.3), // Transparent background
        borderRadius: BorderRadius.circular(35),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, 'assets/icons/home (2).png'),
            _buildNavItem(1, 'assets/icons/chemistry.png'),
            _buildNavItem(2, 'assets/icons/plus.png'),
            _buildNavItem(3, 'assets/icons/user (3).png'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath) {
    final isSelected = selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFEDFDDE) 
                : const Color(0xFF1F412A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              iconPath,
              width: 28,
              height: 28,
              color: isSelected 
                  ? Colors.black.withOpacity(0.8) // Dark for selected
                  : Colors.white.withOpacity(0.6), // Light with 60% opacity for unselected
            ),
          ),
        ),
      ),
    );
  }
}
