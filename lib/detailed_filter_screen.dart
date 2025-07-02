import 'package:flutter/material.dart';

class DetailedFilterScreen extends StatefulWidget {
  const DetailedFilterScreen({super.key});

  @override
  State<DetailedFilterScreen> createState() => _DetailedFilterScreenState();
}

class _DetailedFilterScreenState extends State<DetailedFilterScreen> {
  RangeValues _ageValues = const RangeValues(20, 40);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: const Text('詳細な絞り込み'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('適用')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- イベントの条件 ---
          Text('イベントの条件', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const ListTile(title: Text('募集人数'), subtitle: Text('下限・上限を設定')),
          const ListTile(title: Text('予算'), subtitle: Text('上限を設定')),
          const SizedBox(height: 24),
          
          // --- イベント作成者の条件 ---
          Text('イベント作成者の条件', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('年齢'),
            subtitle: RangeSlider(
              values: _ageValues,
              min: 18,
              max: 80,
              divisions: 62,
              labels: RangeLabels('${_ageValues.start.round()}', '${_ageValues.end.round()}'),
              onChanged: (values) => setState(() => _ageValues = values),
            ),
          ),
          const ListTile(title: Text('性別'), subtitle: Text('問わない / 男性 / 女性')),
          ListTile(title: const Text('職業'), trailing: const Text('未設定 >'), onTap: () {}),
          const Divider(height: 1),
          ListTile(title: const Text('学歴'), trailing: const Text('未設定 >'), onTap: () {}),
          const Divider(height: 1),
          ListTile(title: const Text('趣味'), trailing: const Text('未設定 >'), onTap: () {}),
        ],
      ),
    );
  }
}