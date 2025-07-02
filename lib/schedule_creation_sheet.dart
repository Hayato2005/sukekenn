import 'package:flutter/material.dart';

class ScheduleCreationSheet extends StatefulWidget {
  final ScrollController controller;
  const ScheduleCreationSheet({super.key, required this.controller});

  @override
  State<ScheduleCreationSheet> createState() => _ScheduleCreationSheetState();
}

class _ScheduleCreationSheetState extends State<ScheduleCreationSheet> {
  @override
  Widget build(BuildContext context) {
    // 外観が分かるように仮のUIを配置
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定の追加/編集'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 保存処理
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          )
        ],
      ),
      body: ListView(
        controller: widget.controller,
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('（ここにアプリ概要通りの入力項目が入ります）', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'タイトル',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
           ListTile(
            title: const Text('日時'),
            subtitle: const Text('2025年7月2日 19:00 - 20:00'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
           ListTile(
            title: const Text('詳細設定'),
             subtitle: const Text('募集人数、場所、ジャンルなど'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
           const Divider(),
        ],
      ),
    );
  }
}