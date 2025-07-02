import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ScheduleCreationSheet extends StatefulWidget {
  final ScrollController controller;
  const ScheduleCreationSheet({super.key, required this.controller});

  @override
  State<ScheduleCreationSheet> createState() => _ScheduleCreationSheetState();
}

enum ScheduleType { free, fixed }

class _ScheduleCreationSheetState extends State<ScheduleCreationSheet> {
  ScheduleType _scheduleType = ScheduleType.fixed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: const Text('予定の追加'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
      body: ListView(
        controller: widget.controller,
        padding: const EdgeInsets.all(16.0),
        children: [
          // 予定タイプ選択
          CupertinoSlidingSegmentedControl<ScheduleType>(
            groupValue: _scheduleType,
            onValueChanged: (value) {
              if (value != null) setState(() => _scheduleType = value);
            },
            children: const {
              ScheduleType.fixed: Padding(padding: EdgeInsets.all(8), child: Text('固定予定')),
              ScheduleType.free: Padding(padding: EdgeInsets.all(8), child: Text('空き日程')),
            },
          ),
          const SizedBox(height: 24),
          const TextField(decoration: InputDecoration(labelText: 'タイトル', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          // --- 基本設定 ---
          ListTile(title: const Text('日付'), trailing: const Text('2025年7月3日 >'), onTap: () {}),
          const Divider(height: 1),
          ListTile(title: const Text('時刻'), trailing: const Text('19:00 - 20:00 >'), onTap: () {}),
          const Divider(height: 1),
          ListTile(title: const Text('繰り返し'), trailing: const Text('なし >'), onTap: () {}),
          const Divider(height: 1),
          ListTile(title: const Text('場所'), trailing: const Text('未設定 >'), onTap: () {}),
          const Divider(height: 1),
          ListTile(
            title: const Text('色タグ'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ]),
            onTap: () {},
          ),
          const Divider(height: 1),
          // --- 「空き日程」選択時のみ表示 ---
          if (_scheduleType == ScheduleType.free)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('マッチング設定', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(title: const Text('マッチング種別'), trailing: const Text('誰でも >'), onTap: () {}),
                const Divider(height: 1),
                SwitchListTile(title: const Text('公開範囲'), value: true, onChanged: (val) {}, secondary: const Icon(Icons.public)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.group_add), title: const Text('メンバーを招待'), onTap: () {}),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.tune), title: const Text('詳細設定'), onTap: () {}),
                const Divider(height: 1),
              ],
            ),
        ],
      ),
    );
  }
}