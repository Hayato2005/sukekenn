// lib/friend_search_screen.dart

import 'package:flutter/material.dart';
import 'package:sukekenn/models/user_model.dart';
import 'package:sukekenn/repositories/friend_repository.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final _searchController = TextEditingController();
  final _friendRepo = FriendRepository();
  
  AppUser? _searchedUser;
  bool _isLoading = false;
  String _searchStatus = ''; // 検索結果の状態（申請済みなど）

  Future<void> _searchUser() async {
    final customId = _searchController.text.trim();
    if (customId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchedUser = null;
      _searchStatus = '';
    });

    final currentUser = await _friendRepo.getCurrentUser();
    
    // 自分自身を検索した場合
    if (currentUser?.customId == customId) {
      setState(() {
        _isLoading = false;
        _searchedUser = currentUser;
        _searchStatus = '自分です';
      });
      return;
    }

    final foundUser = await _friendRepo.findUserByCustomId(customId);
    
    if (foundUser != null) {
      // 関係性をチェック
      if (currentUser?.friends.contains(foundUser.uid) ?? false) {
        _searchStatus = 'フレンドです';
      } else {
        // TODO:自分が相手に申請済みかどうかのチェック
        // 現状はダミーのため、申請可能として表示
         _searchStatus = '追加可能';
      }
    } else {
       _searchStatus = '見つかりません';
    }

    setState(() {
      _isLoading = false;
      _searchedUser = foundUser;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンドを検索'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 検索バー ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'ユーザーIDで検索',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUser,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 検索結果 ---
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_searchedUser != null)
              _buildSearchResultCard(_searchedUser!, _searchStatus)
            else if (_searchStatus == '見つかりません')
              const Text('ユーザーが見つかりませんでした。'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(AppUser user, String status) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(user.photoUrl),
        ),
        title: Text(user.displayName),
        subtitle: Text('@${user.customId}'),
        trailing: _buildActionButton(user, status),
      ),
    );
  }

  Widget _buildActionButton(AppUser user, String status) {
    switch (status) {
      case '自分です':
        return const SizedBox.shrink(); // 何も表示しない
      case 'フレンドです':
        return const Text('フレンド', style: TextStyle(color: Colors.grey));
      case '申請済み': // 仕様書通りの「申請済み」ボタン
        return OutlinedButton(
          onPressed: () {
            // TODO: 申請取り消しダイアログ表示
             showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('申請の取り消し'),
                  content: Text('${user.displayName}さんへのフレンド申請を取り消しますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                    TextButton(
                      onPressed: () async {
                        await _friendRepo.cancelFriendRequest(user.uid);
                        Navigator.pop(context);
                        setState(() => _searchStatus = '追加可能'); // UIを更新
                      },
                      child: const Text('はい'),
                    ),
                  ],
                ),
              );
          },
          child: const Text('申請済み'),
        );
      default: // 追加可能
        return FilledButton(
          onPressed: () async {
            await _friendRepo.sendFriendRequest(user.uid);
            setState(() => _searchStatus = '申請済み'); // UIを更新
          },
          child: const Text('フレンドに追加'),
        );
    }
  }
}