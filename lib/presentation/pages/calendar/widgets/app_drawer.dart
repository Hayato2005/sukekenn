// lib/presentation/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sukekenn/application/providers/calendar_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFormat = ref.watch(calendarFormatProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              '表示切替',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          if (currentFormat != CalendarFormat.month)
            ListTile(
              leading: const Icon(Icons.calendar_view_month),
              title: const Text('月表示'),
              onTap: () {
                ref.read(calendarFormatProvider.notifier).state =
                    CalendarFormat.month;
                Navigator.pop(context); // ドロワーを閉じる
              },
            ),
          if (currentFormat != CalendarFormat.week)
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('週表示'),
              onTap: () {
                ref.read(calendarFormatProvider.notifier).state = CalendarFormat.week;
                Navigator.pop(context); // ドロワーを閉じる
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('自由範囲 (未実装)'),
            onTap: () {
              // TODO: 自由範囲選択UI
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}