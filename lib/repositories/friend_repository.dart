// lib/repositories/friend_repository.dart

import 'package:sukekenn/models/user_model.dart';

// 現状はダミーデータで動作。将来的にはSharedPreferencesやFirestoreに置き換え
class FriendRepository {
  // シングルトンパターン
  static final FriendRepository _instance = FriendRepository._internal();
  factory FriendRepository() => _instance;
  FriendRepository._internal();

  // === より実践的なダミーデータ ===
  // ログイン中のユーザーは 'user_c' (山田 花子) とする
  final String _currentUserId = 'user_c';

  // アプリ内に存在する全ユーザーのダミーリスト
  final Map<String, AppUser> _users = {
    'user_a': AppUser(uid: 'user_a', customId: 'taro', displayName: '田中 太郎', photoUrl: 'https://i.pravatar.cc/150?img=1'),
    'user_b': AppUser(uid: 'user_b', customId: 'jiro', displayName: '鈴木 次郎', photoUrl: 'https://i.pravatar.cc/150?img=2'),
    'user_c': AppUser(
        uid: 'user_c',
        customId: 'hanako',
        displayName: '山田 花子',
        photoUrl: 'https://i.pravatar.cc/150?img=3',
        // --- ログインユーザーのデータ ---
        friends: ['user_a', 'user_b'], // 太郎と次郎はフレンド
        pendingFriendRequests: ['user_d'] // 三郎から申請が来ている
    ),
    'user_d': AppUser(uid: 'user_d', customId: 'saburo', displayName: '佐藤 三郎', photoUrl: 'https://i.pravatar.cc/150?img=4'),
  };


  Future<AppUser?> getCurrentUser() async {
    return _users[_currentUserId];
  }

  Future<AppUser?> findUserByCustomId(String customId) async {
    try {
      return _users.values.firstWhere((user) => user.customId == customId);
    } catch (e) {
      return null;
    }
  }

  // === 実際にダミーデータを処理するように修正 ===
  Future<List<AppUser>> getFriends() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return [];
    // currentUserのfriendsリストに含まれるuidを持つユーザーを返す
    return currentUser.friends.map((friendId) => _users[friendId]).whereType<AppUser>().toList();
  }
  
  Future<List<AppUser>> getPendingRequests() async {
     final currentUser = await getCurrentUser();
     if (currentUser == null) return [];
     // currentUserのpendingFriendRequestsリストに含まれるuidを持つユーザーを返す
     return currentUser.pendingFriendRequests.map((requestUserId) => _users[requestUserId]).whereType<AppUser>().toList();
  }

  // 以下、ダミーデータに対する操作。実際にはFirestoreやローカルDBの更新処理を記述
  Future<void> sendFriendRequest(String targetUserId) async {
    print('$_currentUserId が $targetUserId にフレンド申請を送信しました');
  }
  
  Future<void> cancelFriendRequest(String targetUserId) async {
    print('$targetUserId へのフレンド申請を取り消しました');
  }

  Future<void> acceptFriendRequest(String requestUserId) async {
     print('$requestUserId からにフレンド申請を承認しました');
  }
  
  Future<void> declineFriendRequest(String requestUserId) async {
    print('$requestUserId からのフレンド申請を拒否しました');
  }
  
  Future<void> removeFriend(String friendId) async {
    print('$friendId をフレンドから削除しました');
  }
}