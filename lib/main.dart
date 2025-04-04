import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:remixicon/remixicon.dart'; // Remix Icons
import 'misc/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Track the selected index for the bottom navigation
  int _selectedIndex = 0;

  // Function to handle item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // List of widgets corresponding to the selected index
  final List<Widget> _pages = [
    Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.topLeft,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    "Account Balance",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  IconButton.outlined(
                      onPressed: () {}, icon: const Icon(RemixIcons.eye_line))
                ],
              ),
              const Spacer(),
              const Text(
                "N5,000",
                style: TextStyle(fontSize: 50),
              ),
              const Spacer(),
              const Spacer()
            ],
          ),
          height: 250,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.secondaryContainer,
          ),
        )
      ],
    ),
    const Center(child: Text("History Screen", style: TextStyle(fontSize: 24))),
    const Center(
        child: Text("Settings Screen", style: TextStyle(fontSize: 36))),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("JiboMonie"),
          centerTitle: true, // Centers the title text
          backgroundColor: AppColors.background,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                debugPrint("Profile icon tapped!");
              },
              child: const CircleAvatar(
                radius: 20.0,
                backgroundImage: NetworkImage(
                    'https://marketplace.canva.com/MABGb6Bv-M4/1/thumbnail_large-1/canva-MABGb6Bv-M4.jpg'), // URL of the profile picture
              ),
            ),
          ),
        ),
        body: _pages[_selectedIndex],
        // Salomon Bottom Bar
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: <SalomonBottomBarItem>[
            SalomonBottomBarItem(
              icon: const Icon(RemixIcons.home_line),
              title: const Text("Home"),
              selectedColor: AppColors.secondary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(RemixIcons.history_line),
              title: const Text("History"),
              selectedColor: AppColors.secondary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(RemixIcons.settings_line),
              title: const Text("Settings"),
              selectedColor: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
