// lib/presentation/widgets/schedule_detail_popup.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

// このポップアップが閉じたときに返す値を示す
// 'edit': 編集画面へ, 'deleted': 削除処理へ
Future<String?> showScheduleDetailPopup(BuildContext context, Schedule schedule) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(schedule.title),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(DateFormat('y年M月d日 (E)', 'ja').format(schedule.date)),
            ),
            if (!schedule.isAllDay)
              ListTile(
                leading: const Icon(Icons.access_time_outlined),
                title: Text(
                  '${TimeOfDay.fromDateTime(schedule.date.add(Duration(minutes: (schedule.startHour * 60).round()))).format(context)} - ${TimeOfDay.fromDateTime(schedule.date.add(Duration(minutes: (schedule.endHour * 60).round()))).format(context)}',
                ),
              ),
            if (schedule.scheduleType == ScheduleType.available)
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text('空き日程 (${schedule.matchingType.displayName})'),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('閉じる'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 削除ボタン
        TextButton(
          child: const Text('削除', style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.of(context).pop('deleted');
          },
        ),
        // 編集ボタン
        FilledButton(
          child: const Text('編集'),
          onPressed: () {
            Navigator.of(context).pop('edit');
          },
        ),
      ],
    ),
  );
}