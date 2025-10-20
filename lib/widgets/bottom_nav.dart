import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/games_page.dart';
import '../pages/calendar_page.dart';
import '../pages/chat_screen.dart';

class ImageBottomNav extends StatefulWidget {
  const ImageBottomNav({super.key});

  @override
  State<ImageBottomNav> createState() => _ImageBottomNavState();
}

class _ImageBottomNavState extends State<ImageBottomNav> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    GamesPage(),
    CalendarPage(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: _pages[_currentIndex]),


          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 110,
              width: double.infinity,
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Волна на фоне
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/36.png',
                        fit: BoxFit.cover,
                        height: 90,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),


                  Padding(
                    padding: EdgeInsets.only(
                      left: 25,
                      right: 25,
                      bottom:
                      MediaQuery.of(context).padding.bottom + 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(Icons.home, 0),
                        _buildNavItem(Icons.star, 1),
                        _buildNavItem(Icons.calendar_month, 2),
                        _buildNavItem(Icons.chat_bubble, 3),
                      ],
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


  Widget _buildNavItem(IconData icon, int index) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 63,
        height: 63,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFB6FF3B)
              : Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.black.withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }
}
