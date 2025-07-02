import 'package:flutter/material.dart';
import 'package:sukekenn/archived_chats_screen.dart'; // 新規作成
import 'package:sukekenn/individual_chat_screen.dart'; // 新規作成
import 'package:sukekenn/new_matchings_screen.dart'; // 新規作成

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // (State変数、ヘルパーメソッドは前回のコードから変更ありません)
  bool _isSelectionMode = false;
  final List<Map<String, dynamic>> _selectedChats = [];
  final bool _hasFriendChatNotification = true;
  final int _archivedNotifications = 5;

  Widget _buildFriendChatIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.person_outline),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_rounded, size: 12, color: Colors.blueAccent),
          ),
        ),
        if (_hasFriendChatNotification)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('一括設定'),
            onPressed: _selectedChats.isEmpty ? null : () {},
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('削除'),
            onPressed: _selectedChats.isEmpty ? null : () {},
          ),
        ],
      ),
    );
  }
  
  String _formatParticipants(List<String> participants) {
    if (participants.isEmpty) return '';
    return '(${participants.join(', ')})';
  }

  @override
  Widget build(BuildContext context) {
    // (ダミーデータは前回のコードから変更ありません)
    final chats = List.generate(
      20,
      (index) => {
        'id': 'chat_$index',
        'scheduleTitle': '渋谷でランチミーティング',
        'participants': ['田中 圭', '佐藤 健', '鈴木 一郎', '山田 花子'].sublist(0, (index % 4) + 1),
        'lastMessage': index % 3 == 0 ? 'ありがとうございます！楽しみにしています。' : '明日の件ですが、よろしくお願いします。',
        'time': '1${index}:30',
        'unread': index % 4,
        'avatarUrl': 'https://i.pravatar.cc/150?img=${index + 1}',
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(icon: _buildFriendChatIcon(), onPressed: () {}),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.cancel : Icons.check_box_outline_blank),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) _selectedChats.clear();
              });
            },
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_add), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.new_releases, color: Colors.green),
            title: const Text('新規マッチング'),
            trailing: const Badge(label: Text('3'), backgroundColor: Colors.green),
            onTap: () {
              // ★★★ 新規マッチング画面へ遷移 ★★★
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewMatchingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined, color: Colors.grey),
            title: const Text('アーカイブチャット'),
            trailing: _archivedNotifications > 0
                ? Badge(label: Text('$_archivedNotifications'), backgroundColor: Colors.red)
                : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              // ★★★ アーカイブ画面へ遷移 ★★★
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArchivedChatsScreen()));
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final bool isSelected = _selectedChats.any((c) => c['id'] == chat['id']);

                return InkWell(
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedChats.removeWhere((c) => c['id'] == chat['id']);
                        } else {
                          _selectedChats.add(chat);
                        }
                      });
                    } else {
                      // ★★★ 個別チャット画面へ遷移 ★★★
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => IndividualChatScreen(
                          scheduleTitle: chat['scheduleTitle'] as String,
                        ),
                      ));
                    }
                  },
                  child: Container(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                    // ★★★ Paddingを追加してセルの縦幅を調整 ★★★
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24, // 少し大きく
                          backgroundImage: NetworkImage(chat['avatarUrl'] as String),
                        ),
                        const SizedBox(width: 16), // 少し広く
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    chat['scheduleTitle'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatParticipants(chat['participants'] as List<String>),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat['lastMessage'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(chat['time'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            if ((chat['unread'] as int) > 0)
                              Badge(
                                label: Text('${chat['unread']}'),
                                backgroundColor: Colors.red,
                              )
                            else
                              const SizedBox(height: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSelectionMode) _buildActionBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}