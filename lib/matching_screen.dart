// lib/matching_screen.dart
import 'package:flutter/material.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  bool _isCalendarView = false; // 表示モード（リスト or カレンダー）

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('マッチング'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '誰でも'),
              Tab(text: '異性'),
              Tab(text: 'フレンド'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
              onPressed: () {
                setState(() {
                  _isCalendarView = !_isCalendarView;
                });
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildMatchingContent('誰でも', _isCalendarView),
            _buildMatchingContent('異性', _isCalendarView),
            _buildMatchingContent('フレンド', _isCalendarView),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingContent(String category, bool isCalendar) {
    if (isCalendar) {
      // TODO: ここにマッチング用のカレンダー表示を実装
      return Center(child: Text('$category のカレンダー表示'));
    } else {
      // 掲示板（リスト）表示
      return ListView.builder(
        itemCount: 10, // ダミーデータ
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('$category のイベント ${index + 1}'),
              subtitle: const Text('7月5日 12:00-13:00\n東京都渋谷区'),
              trailing: const Text('1/3人'),
              onTap: () {
                // TODO: イベント詳細画面へ遷移
              },
            ),
          );
        },
      );
    }
  }
}