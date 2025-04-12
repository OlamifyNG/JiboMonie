import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(
        child: Text("Dashboard", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Wallet", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Profile", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B3628),
              Color(0xFF002218),
              Color(0xFF081613),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _pages[_currentIndex],
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("JiboMonie",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),
                          Icon(Icons.notifications, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white.withOpacity(0.1),
            selectedItemColor: Colors.greenAccent[400],
            unselectedItemColor: Colors.white60,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(RemixIcons.home_line),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(RemixIcons.wallet_line),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(RemixIcons.user_line),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
