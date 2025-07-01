import 'package:flutter/material.dart';
import 'package:sukekenn/calendar_home_screen.dart';
import 'package:sukekenn/main_screen.dart';

class WeekDrawer extends StatelessWidget {
  const WeekDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('週表示メニュー', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('月表示に切り替え'),
              onTap: () {
                Navigator.pushAndRemoveUntil( // popからpushAndRemoveUntilに変更
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (Route<dynamic> route) => false, // これまでのルートを全てクリア
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
