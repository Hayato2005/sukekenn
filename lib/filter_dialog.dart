import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('絞り込みフィルター'),
      // スクロール可能なコンテンツ
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('（ここにアプリ概要通りの絞り込み項目が入ります）', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            const Text('期間', style: TextStyle(fontWeight: FontWeight.bold)),
            const Row(children: [ Expanded(child: Text('開始: 未設定')), Expanded(child: Text('終了: 未設定'))]),
            const Divider(height: 24),
            const Text('場所', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('未設定'),
            const Divider(height: 24),
            const Text('ジャンル', style: TextStyle(fontWeight: FontWeight.bold)),
            const Wrap(
              spacing: 8.0,
              children: [
                Chip(label: Text('カフェ')),
                Chip(label: Text('ランチ')),
                Chip(label: Text('飲み会')),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // TODO: リセット処理
          },
          child: const Text('リセット'),
        ),
        FilledButton(
          onPressed: () {
            // TODO: 絞り込み実行
            Navigator.of(context).pop();
          },
          child: const Text('この条件で絞り込む'),
        ),
      ],
    );
  }
}