import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pages/role_select_page.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/parent_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );


    Timer(const Duration(seconds: 4), _checkUserStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  Future<void> _checkUserStatus() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final db = FirebaseDatabase.instance.ref();


    if (user == null) {
      _navigateWithFade(const RoleSelectPage());
      return;
    }


    final parentSnap = await db.child('parents/${user.uid}').get();
    final childSnap = await db.child('users/${user.uid}').get();

    if (!mounted) return;

    if (parentSnap.exists) {
      _navigateWithFade(const ParentNavWrapper());
    } else if (childSnap.exists) {
      _navigateWithFade(const ImageBottomNav());
    } else {
      _navigateWithFade(const RoleSelectPage());
    }
  }


  void _navigateWithFade(Widget nextPage) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, animation, __) =>
          FadeTransition(opacity: animation, child: nextPage),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [

            Container(
              height: size.height * 0.25,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFB6FF3B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.smart_toy_rounded,
                        size: 48, color: Colors.black87),
                    SizedBox(height: 8),
                    Text(
                      'Nexi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),


            Positioned(
              top: size.height * 0.28,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    'Привет! Я Некси 🤖',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Давай вместе научимся управлять деньгами —\nлегко, весело и умно!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),


            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 0),
                child: Image.asset(
                  'assets/34.png',
                  width: size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
