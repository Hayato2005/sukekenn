// lib/presentation/widgets/schedule_detail_popup.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

/// 予定詳細ポップアップを表示するグローバル関数
/// Month/Week Calendar View の両方から呼び出す
Future<void> showScheduleDetailPopup(BuildContext context, Schedule schedule) {
  return showDialog(
    context: context,
    // ポップアップの外側をタップしたときに閉じる
    barrierDismissible: true,
    builder: (BuildContext context) {
      return _ScheduleDetailDialog(schedule: schedule);
    },
  );
}

/// ポップアップの本体
class _ScheduleDetailDialog extends StatelessWidget {
  final Schedule schedule;

  const _ScheduleDetailDialog({required this.schedule});

  @override
  Widget build(BuildContext context) {
    // 画面サイズに応じてポップアップの幅を調整
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 内容に合わせて高さを調整
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- タイトル ---
              Text(
                schedule.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // --- 日時 ---
              _buildDetailRow(
                icon: Icons.access_time,
                text: '${DateFormat('y-MM-dd (E)', 'ja').format(schedule.date)}\n${_formatHour(schedule.startHour)} - ${_formatHour(schedule.endHour)}',
              ),
              const Divider(height: 24),
              
              // --- 場所 (データがあれば表示) ---
              if (schedule.location != null && schedule.location!.isNotEmpty)
                _buildDetailRow(icon: Icons.location_on_outlined, text: schedule.location!),
              
              // --- 説明 (データがあれば表示) ---
              if (schedule.description != null && schedule.description!.isNotEmpty)
                _buildDetailRow(icon: Icons.notes, text: schedule.description!),
              
              const SizedBox(height: 24),

              // --- アクションボタン ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '編集',
                    onPressed: () {
                       Navigator.of(context).pop();
                       // TODO: 予定編集画面への遷移
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                    tooltip: '削除',
                    onPressed: () {
                       Navigator.of(context).pop();
                       // TODO: 削除処理
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 時間のフォーマット (例: 9.5 -> 09:30)
  String _formatHour(double hour) {
    final int h = hour.floor();
    final int m = ((hour - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // 詳細表示用のアイコン付き行ウィジェット
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