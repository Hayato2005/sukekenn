// lib/friend_screen.dart

import 'package:flutter/material.dart';
import 'package:sukekenn/friend_search_screen.dart';
import 'package:sukekenn/models/user_model.dart';
import 'package:sukekenn/repositories/friend_repository.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final _friendRepo = FriendRepository();
  
  late Future<List<AppUser>> _friendsFuture;
  late Future<List<AppUser>> _requestsFuture;

  bool _isSelectionMode = false;
  final Set<String> _selectedFriendIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _friendsFuture = _friendRepo.getFriends();
      _requestsFuture = _friendRepo.getPendingRequests();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFriendIds.clear();
      }
    });
  }

  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }
  
  // ### NOTE: ###
  // main_screen.dartのような親WidgetでBottomNavigationBarのタブが切り替わった際に、
  // このメソッドを呼び出して選択モードを強制的に解除する必要があります。
  // (例: GlobalKeyを使ってこのStateのメソッドを外部から呼び出す)
  void cancelSelectionMode() {
    if (_isSelectionMode) {
      _toggleSelectionMode();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド'),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.cancel : Icons.check_box_outline_blank),
            tooltip: _isSelectionMode ? '選択をキャンセル' : 'フレンドを選択',
            onPressed: _toggleSelectionMode,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'フレンド設定',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'フレンドを追加',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FriendSearchScreen()),
              );
            },
          ),
        ],
      ),
      // ### NOTE: ###
      // Scaffoldの`bottomSheet`プロパティを使用することで、
      // メインのナビゲーションバーの上に被らずにアクションバーを表示できます。
      bottomSheet: _isSelectionMode ? _buildBottomActionBar() : null,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          // アクションバーに隠れないように、下部に余白を追加
          padding: _isSelectionMode ? const EdgeInsets.only(bottom: 80) : EdgeInsets.zero,
          children: [
            _buildPendingRequestsSection(),
            _buildFriendsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsSection() {
    return FutureBuilder<List<AppUser>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        return ExpansionTile(
          title: Text('フレンド申請 (${snapshot.data!.length})'),
          children: snapshot.data!.map((user) => ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(user.photoUrl)),
            title: Text(user.displayName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(onPressed: (){}, child: const Text('拒否')),
                const SizedBox(width: 8),
                FilledButton(onPressed: (){}, child: const Text('承認')),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return FutureBuilder<List<AppUser>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('まだフレンドがいません。')));
        }
        final friends = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final isSelected = _selectedFriendIds.contains(friend.uid);

            return InkWell(
              onTap: () {
                if (_isSelectionMode) {
                  _toggleFriendSelection(friend.uid);
                } else { /* プロフィール詳細へ */ }
              },
              child: Container(
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    if (_isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleFriendSelection(friend.uid),
                        ),
                      ),
                    CircleAvatar(backgroundImage: NetworkImage(friend.photoUrl)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(friend.displayName, style: const TextStyle(fontSize: 16))),
                    if (!_isSelectionMode)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined)),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline)),
                        ],
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 選択モード時に表示されるボトムアクションバー
  Widget _buildBottomActionBar() {
    final bool hasSelection = _selectedFriendIds.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0,-2))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.group_add_outlined, 'グループ作成', hasSelection ? () {} : null),
          _buildActionButton(Icons.settings_outlined, '一括設定', hasSelection ? () {} : null),
          _buildActionButton(Icons.delete_outline, '一括削除', hasSelection ? () {} : null, color: hasSelection ? Colors.red : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onPressed, {Color? color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onPressed == null ? Colors.grey : (color ?? Theme.of(context).primaryColor)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: onPressed == null ? Colors.grey : (color ?? Theme.of(context).primaryColor), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}