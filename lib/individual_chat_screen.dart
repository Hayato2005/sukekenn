import 'package:flutter/material.dart';

class IndividualChatScreen extends StatefulWidget {
  final String scheduleTitle;
  const IndividualChatScreen({super.key, required this.scheduleTitle});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {'text': 'こんにちは！よろしくお願いします！', 'isMe': false, 'time': '10:01'},
    {'text': 'こちらこそ、よろしくお願いします。明日の12時に渋谷駅ハチ公前で大丈夫ですか？', 'isMe': true, 'time': '10:02'},
    {'text': 'はい、大丈夫です！服装は青いシャツに黒いパンツで行きますね。', 'isMe': false, 'time': '10:03'},
    {'text': '承知しました。楽しみにしています！', 'isMe': true, 'time': '10:04'},
  ];
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheduleTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // 下から表示
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages.reversed.toList()[index];
                final isMe = message['isMe'] as bool;
                return _buildMessageBubble(
                  text: message['text'] as String,
                  isMe: isMe,
                  time: message['time'] as String,
                );
              },
            ),
          ),
          _buildMessageInputBar(),
        ],
      ),
    );
  }

  // メッセージの吹き出しUI
  Widget _buildMessageBubble({required String text, required bool isMe, required String time}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (isMe) const SizedBox(width: 4),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ),
          ),
          if (!isMe) const SizedBox(width: 4),
          if (!isMe) Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  // メッセージ入力バー
  Widget _buildMessageInputBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {}),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'メッセージを入力',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                // TODO: メッセージ送信処理
              },
            ),
          ],
        ),
      ),
    );
  }
}