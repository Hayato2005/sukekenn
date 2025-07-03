// lib/presentation/pages/calendar/widgets/week_drawer.dart

import 'package:flutter/material.dart';
import 'package:sukekenn/calendar_view_screen.dart'; // CalendarDisplayModeをインポート

class WeekDrawer extends StatelessWidget {
  final Function(CalendarDisplayMode) onNavigate;
  const WeekDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green, // 週表示用のテーマカラー
            ),
            child: Text(
              'カレンダーメニュー',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('月表示に切り替え'),
            onTap: () {
              // コールバックを呼び出して表示モードを切り替える
              onNavigate(CalendarDisplayMode.month);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: const Text('週表示'),
            tileColor: Colors.grey[300], // 現在の表示モードをハイライト
            onTap: () {
               onNavigate(CalendarDisplayMode.week);
            },
          ),
          // 他のメニュー項目...
        ],
      ),
    );
  }
}
