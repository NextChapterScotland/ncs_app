import 'package:flutter/material.dart';
import 'package:next_chapter_scotland_app/utilities/main.dart';
import 'home_screen.dart';
import 'forum.dart';
import 'profile.dart';

class Navigation extends StatefulWidget {
  final bool isGuest;
  const Navigation({super.key, this.isGuest = false});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomePage(isGuest: widget.isGuest),
      Forum(isGuest: widget.isGuest, supabase: supabase),
      Profile(isGuest: widget.isGuest),
    ];
  }

  void _onTabTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Forum"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "User"),
        ],
      ),
    );
  }
}
