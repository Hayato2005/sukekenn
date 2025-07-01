// lib/main_screen.dart の全文

import 'package:flutter/material.dart';
import 'package:sukekenn/presentation/pages/calendar/calendar_page.dart'; // 修正点：新しいカレンダーページをインポート
import 'chat_screen.dart';
import 'friend_screen.dart';
import 'matching_screen.dart';
import 'my_page_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 修正点：呼び出すウィジェットを CalendarHomeScreen から CalendarPage に変更
  final List<Widget> _pages = [
    const CalendarPage(), 
    const ChatScreen(),
    const FriendScreen(),
    const MatchingScreen(),
    const MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'チャット'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'フレンド'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'マッチング'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}