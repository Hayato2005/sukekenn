// lib/presentation/pages/calendar/widgets/event_detail_popup.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/core/models/event.dart'; // パスを修正
import 'package:sukekenn/presentation/pages/calendar/widgets/event_form.dart'; // パスを修正

class EventDetailPopup extends StatelessWidget {
  final Event event;

  const EventDetailPopup({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(event.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('日時', '${DateFormat('yyyy年M月d日 HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'),
            _buildDetailRow('マッチング種別', event.type.displayName),
            _buildDetailRow('種類', event.isFixed ? '固定予定' : '空き日程'),
            _buildDetailRow('公開範囲', event.isPublic ? '公開' : '非公開'),
            if (event.minParticipants != null || event.maxParticipants != null)
              _buildDetailRow('募集人数', '${event.minParticipants ?? ''}〜${event.maxParticipants ?? ''}人'),
            if (event.recruitmentDeadline != null)
              _buildDetailRow('募集期間', DateFormat('yyyy年M月d日').format(event.recruitmentDeadline!)),
            if (event.locationPrefecture != null)
              _buildDetailRow('場所', '${event.locationPrefecture ?? ''} ${event.locationCity ?? ''} ${event.locationRange ?? ''}'),
            if (event.genres != null && event.genres!.isNotEmpty)
              _buildDetailRow('ジャンル', event.genres!.join(', ')),

            // 詳細条件の折りたたみUI
            ExpansionTile(
              title: const Text('詳細条件', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                _buildDetailRow('年齢', (event.conditions?.ages != null && event.conditions!.ages!.isNotEmpty) ? event.conditions!.ages!.join(', ') : '指定なし'),
                _buildDetailRow('性別', event.conditions?.gender ?? '指定なし'),
                _buildDetailRow('職業', (event.conditions?.professions != null && event.conditions!.professions!.isNotEmpty) ? event.conditions!.professions!.join(', ') : '指定なし'),
                // TODO: 他の詳細条件を追加
              ],
            ),

            const SizedBox(height: 10),
            // TODO: 参加者表示 (少人数なら全員、多い場合は「+他◯人」)
            Text('参加者: [参加者1の名前], [参加者2の名前] (+他X人)', style: TextStyle(fontSize: 14)),

            const SizedBox(height: 10),
            // TODO: 出欠管理機能 (各参加者のステータス設定、主催者への通知)
            Text('出欠管理: (ここにUIを実装)', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 編集ボタン
            IconButton(
              icon: const Icon(Icons.edit), // ✏️
              onPressed: () {
                Navigator.pop(context); // ポップアップを閉じる
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => EventFormPage(event: event))); // 予定編集画面へ
              },
            ),
            // 削除ボタン
            IconButton(
              icon: const Icon(Icons.delete), // 🗑️
              onPressed: () {
                Navigator.pop(context); // ポップアップを閉じる
                // TODO: 削除確認ダイアログ表示と削除ロジック
                // 例: Provider経由で削除
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('閉じる'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}