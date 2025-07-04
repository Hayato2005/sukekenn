// lib/models/user_model.dart

// アプリ内でユーザー情報を扱うためのモデル
class AppUser {
  final String uid; // Firebase AuthenticationのユニークID
  final String customId; // ユーザーが設定するID
  final String displayName;
  final String photoUrl;
  final List<String> friends; // フレンドのuidリスト
  final List<String> pendingFriendRequests; // 自分宛のフレンド申請のuidリスト
  final List<String> blockedUsers; // ブロックしたユーザーのuidリスト

  AppUser({
    required this.uid,
    required this.customId,
    required this.displayName,
    this.photoUrl = '', // デフォルト値
    this.friends = const [],
    this.pendingFriendRequests = const [],
    this.blockedUsers = const [],
  });

  // JSONへの変換（今回はローカル保存なので使わないが、将来の拡張用）
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'customId': customId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'friends': friends,
        'pendingFriendRequests': pendingFriendRequests,
        'blockedUsers': blockedUsers,
      };

  // JSONからの変換
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'],
        customId: json['customId'],
        displayName: json['displayName'],
        photoUrl: json['photoUrl'] ?? '',
        friends: List<String>.from(json['friends'] ?? []),
        pendingFriendRequests: List<String>.from(json['pendingFriendRequests'] ?? []),
        blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      );
}