import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Sample pages for navigation
  final List<Widget> _pages = [
    const Center(child: Text("Categories Page")),
    const Center(child: Text("Favorites Page")),
    const Center(child: Text("Settings Page")),
    const Center(child: Text("Profile Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 168, 88, 83),
        title: const Text("موسوعة أحاديث الزكاة", 
               style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 4,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xffecbd79),
        unselectedItemColor: const Color.fromARGB(255, 26, 23, 23),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "settings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: "info",
          ),
        ],
      ),
    );
  }
}