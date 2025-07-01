import 'package:flutter/material.dart';
import 'package:sukekenn/week_view_screen.dart';

class MonthDrawer extends StatelessWidget {
  const MonthDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('月表示メニュー', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('週表示に切り替え'),
              onTap: () {
                Navigator.push( // ここを push に変更
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeekViewScreen(startDate: DateTime.now()),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('自由選択範囲に切り替え'),
              onTap: () {
                // TODO: 自由選択画面ができたらここで遷移
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('自由選択範囲画面は未実装です')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
