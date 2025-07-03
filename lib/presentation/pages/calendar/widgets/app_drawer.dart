// lib/presentation/pages/calendar/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:sukekenn/calendar_view_screen.dart'; // CalendarDisplayMode をインポートするため

class AppDrawer extends StatelessWidget {
  // 現在の表示モードと、モードを切り替えるための関数を親から受け取る
  final CalendarDisplayMode currentMode;
  final Function(CalendarDisplayMode) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentMode,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('表示切替', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('月表示カレンダー'),
              // 現在のモードが月表示ならタイルをハイライト表示する
              tileColor: currentMode == CalendarDisplayMode.month ? Colors.grey[300] : null,
              onTap: () {
                // コールバック関数を呼び出して表示モードを切り替える
                onNavigate(CalendarDisplayMode.month);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('週表示カレンダー'),
              // 現在のモードが週表示ならタイルをハイライト表示する
              tileColor: currentMode == CalendarDisplayMode.week ? Colors.grey[300] : null,
              onTap: () {
                // コールバック関数を呼び出して表示モードを切り替える
                onNavigate(CalendarDisplayMode.week);
              },
            ),
          ],
        ),
      ),
    );
  }
}