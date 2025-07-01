import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_edit_screen.dart';
import 'calendar_home_screen.dart';
import 'chat_screen.dart';
import 'friend_screen.dart';
import 'matching_screen.dart';
import 'my_page_screen.dart';
import 'week_view_screen.dart'; // 週表示のインポート


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CalendarHomeScreen(),
    const ChatScreen(),
    const FriendScreen(),
    const MatchingScreen(),
    const MyPageScreen(),
  ];

  void switchToPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: switchToPage,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'チャット'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'フレンド'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'マッチング'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}

