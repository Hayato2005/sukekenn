import 'package:flutter/material.dart';
import 'package:sukekenn/calendar_home_screen.dart';
import 'package:sukekenn/week_view_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarHomeScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('週表示カレンダー'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeekViewScreen(startDate: DateTime.now()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
