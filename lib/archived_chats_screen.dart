import 'package:flutter/material.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アーカイブ'),
      ),
      body: Column(
        children: [
          // チャット一覧に戻るボタン
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('チャット一覧に戻る'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Text('ここにアーカイブされたチャットが表示されます。'),
            ),
          ),
        ],
      ),
    );
  }
}