import 'package:flutter/material.dart';
import 'package:sukekenn/calendar_home_screen.dart';
import 'package:sukekenn/chat_screen.dart';
import 'package:sukekenn/friend_screen.dart';
import 'package:sukekenn/matching_screen.dart';
import 'package:sukekenn/my_page_screen.dart';

class MainScreen extends StatefulWidget {
  // initialIndexを受け取れるようにコンストラクタを修正
  const MainScreen({super.key, this.initialIndex = 0});

  // 他の画面から遷移してくる際に、開きたいタブのインデックスを指定できるようにする
  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  static const List<Widget> _pages = <Widget>[
    CalendarHomeScreen(),
    ChatScreen(),
    FriendScreen(),
    MatchingScreen(),
    MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 受け取ったinitialIndexで選択されているタブを初期化
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'チャット',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'フレンド',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'マッチング',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'マイページ',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // ラベルを常に表示
        selectedItemColor: Colors.blueAccent, // 選択中アイテムの色
        unselectedItemColor: Colors.grey, // 非選択アイテムの色
      ),
    );
  }
}