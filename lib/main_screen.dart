// lib/main_screen.dart

import 'package:flutter/material.dart';
import 'package:sukekenn/chat_screen.dart';
import 'package:sukekenn/friend_screen.dart';
import 'package:sukekenn/matching_screen.dart';
import 'package:sukekenn/my_page_screen.dart';
import 'package:sukekenn/calendar_view_screen.dart'; // ★ 新しい画面をインポート

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  // ★ CalendarHomeScreenをCalendarViewScreenに置き換える
  static const List<Widget> _pages = <Widget>[
    CalendarViewScreen(),
    ChatScreen(),
    FriendScreen(),
    MatchingScreen(),
    MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'チャット',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'フレンド',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'マッチング',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'マイページ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // アイテムが4つ以上の場合に必要
      ),
    );
  }
}