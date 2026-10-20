import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan MediaQuery.sizeOf() yang lebih disarankan pada Flutter 3.10+
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final currentIndex = navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        if (navigationShell.currentIndex == 0) {
          Navigator.of(context).pop();
        } else {
          navigationShell.goBranch(0);
        }
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          body: navigationShell,
          extendBody: true,
          bottomNavigationBar: Container(
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 0,
            ),
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.01,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0b395e),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.home_rounded,
                  'Home',
                  currentIndex,
                  screenWidth,
                  screenHeight,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.favorite_rounded,
                  'Favorites',
                  currentIndex,
                  screenWidth,
                  screenHeight,
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.person_rounded,
                  'Profile',
                  currentIndex,
                  screenWidth,
                  screenHeight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context,
      int index,
      IconData icon,
      String label,
      int currentIndex,
      double screenWidth,
      double screenHeight,
      ) {
    final isActive = index == currentIndex;

    // GestureDetector diletakkan di luar agar tidak perlu ditulis dua kali
    // untuk kondisi aktif dan tidak aktif
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: isActive
          ? Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.025,
          horizontal: screenWidth * 0.045,
        ),
        decoration: BoxDecoration(
          color: const Color(0xff092c47),
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: screenWidth * 0.02,
              offset: Offset(0, screenHeight * 0.005),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: screenWidth * 0.04,
              ),
            ),
          ],
        ),
      )
          : Container(
        // Bagian ini ditambahkan karena kode aslinya terpotong
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.025,
          horizontal: screenWidth * 0.045,
        ),
        child: Icon(
          icon,
          color: Colors.white60, // Warna agak redup jika tidak aktif
          size: screenWidth * 0.06,
        ),
      ),
    );
  }
}