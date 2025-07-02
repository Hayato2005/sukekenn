import 'package:flutter/material.dart';
import 'package:sukekenn/detailed_filter_screen.dart'; // 新規作成

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('フィルター'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ここに各画面に応じたフィルター項目が入る
            ListTile(title: const Text('場所'), trailing: const Text('すべて >'), onTap: () {}),
            const Divider(height: 1),
            ListTile(title: const Text('ジャンル'), trailing: const Text('すべて >'), onTap: () {}),
            const Divider(height: 1),
            ListTile(title: const Text('時間帯'), trailing: const Text('すべて >'), onTap: () {}),
            const SizedBox(height: 24),
            // 詳細絞り込み画面へのボタン
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.tune),
                label: const Text('さらに詳細な条件で絞り込む'),
                onPressed: () {
                  Navigator.of(context).pop(); // いったんダイアログを閉じる
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DetailedFilterScreen()));
                },
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () {}, child: const Text('リセット')),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('適用')),
      ],
    );
  }
}