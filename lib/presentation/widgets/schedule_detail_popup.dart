// lib/presentation/widgets/schedule_detail_popup.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'package:sukekenn/schedule_creation_sheet.dart';

// ★ 戻り値を dynamic に変更。'deleted' や Schedule オブジェクトを返せるようにする
Future<dynamic> showScheduleDetailPopup(BuildContext context, Schedule schedule) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return _ScheduleDetailDialog(schedule: schedule);
    },
  );
}

class _ScheduleDetailDialog extends StatelessWidget {
  final Schedule schedule;
  const _ScheduleDetailDialog({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.access_time,
              text: '${DateFormat('y-MM-dd (E)', 'ja').format(schedule.date)}\n${_formatHour(schedule.startHour)} - ${_formatHour(schedule.endHour)}',
            ),
            // ... その他の詳細表示 ...
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // --- 削除ボタン ---
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  tooltip: '削除',
                  onPressed: () {
                    // ★ 'deleted' という文字列を返してポップアップを閉じる
                    Navigator.of(context).pop('deleted');
                  },
                ),
                const SizedBox(width: 8),
                // --- 編集ボタン ---
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '編集',
                  onPressed: () async {
                    Navigator.of(context).pop(); // まず詳細ポップアップを閉じる
                    // ★ 編集画面を開き、更新されたScheduleオブジェクトを受け取る
                    final updatedSchedule = await showModalBottomSheet<Schedule>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => ScheduleCreationSheet(
                        schedule: schedule, // 編集対象の予定を渡す
                        isQuickAddMode: false, onClose: ({Schedule? savedSchedule}) { }, // 編集時は必ずフル表示
                      ),
                    );
                    // ★★★ ここでは何もしない。結果の処理は呼び出し元の `calendar_view_screen.dart` で行う
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatHour(double hour) {
    final int h = hour.floor();
    final int m = ((hour - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}