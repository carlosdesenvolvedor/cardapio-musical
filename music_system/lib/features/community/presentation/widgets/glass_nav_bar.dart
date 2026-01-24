import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:music_system/config/theme/app_theme.dart';

class GlassmorphismNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassmorphismNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The Glass Container
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.album_outlined, Icons.album),
                    _buildNavItem(1, Icons.explore_outlined, Icons.explore),
                    const SizedBox(width: 50), // Spacer for center FAB
                    _buildNavItem(
                        3, Icons.headphones_outlined, Icons.headphones),
                    _buildNavItem(4, Icons.person_outline, Icons.person),
                  ],
                ),
              ),
            ),
          ),

          // Center CREATE Button (Physical location higher up)
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CREATE',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          isSelected ? filledIcon : outlineIcon,
          color: isSelected ? AppTheme.primaryColor : Colors.white60,
          size: 26,
        ),
      ),
    );
  }
}
