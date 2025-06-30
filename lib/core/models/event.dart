// lib/core/models/event.dart の新規作成

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Colorのために必要

// 予定のマッチング種別を定義
enum EventType {
  friend,       // フレンド
  anyone,       // 誰でも
  oppositeSex,  // 異性
  myGroup,      // マイグループ (アプリ概要にある自分用グループ)
  fixed,        // 固定予定 (マッチング対象外の自分用)
}

// EventTypeに表示名とデフォルトカラーを付与する拡張
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.friend:
        return 'フレンド';
      case EventType.anyone:
        return '誰でも';
      case EventType.oppositeSex:
        return '異性';
      case EventType.myGroup:
        return 'マイグループ';
      case EventType.fixed:
        return '固定予定';
    }
  }

  Color get defaultColor {
    switch (this) {
      case EventType.friend:
        return Colors.green.shade300; // グリーン系
      case EventType.anyone:
        return Colors.blue.shade300;  // ブルー系
      case EventType.oppositeSex:
        return Colors.red.shade300;   // レッド系
      case EventType.myGroup:
        return Colors.purple.shade300; // 仮のパープル
      case EventType.fixed:
        return Colors.grey.shade400;  // 固定予定はグレー
    }
  }
}

// 予定のデータモデル
class Event {
  final String id; // FirestoreのドキュメントID
  final String userId; // 予定を作成したユーザーのUID
  final String title;
  final DateTime startTime; // 予定の開始日時
  final DateTime endTime;   // 予定の終了日時
  final EventType type;    // 予定の種別 (フレンド、誰でも、異性、マイグループ、固定)
  final bool isPublic;     // 公開範囲（true: 公開、false: 非公開、固定予定の場合は常に非公開扱い）
  final int? minParticipants; // 募集人数 下限
  final int? maxParticipants; // 募集人数 上限
  final DateTime? recruitmentEndDate; // 募集期間終了日時
  final String? location; // 場所 (都道府県、市区町村など)
  final List<String>? genres; // ジャンル (複数選択可)
  final Map<String, dynamic>? matchingConditions; // 年齢、性別、職業などの詳細条件
  final List<String>? invitedFriendUids; // 招待されたフレンドのUIDリスト

  // Firestoreでの保存・取得時に便利なファクトリコンストラクタとtoJsonメソッド
  Event({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isPublic = true, // デフォルトは公開
    this.minParticipants,
    this.maxParticipants,
    this.recruitmentEndDate,
    this.location,
    this.genres,
    this.matchingConditions,
    this.invitedFriendUids,
  });

  // FirestoreのDocumentSnapshotからEventオブジェクトを作成
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => EventType.fixed, // デフォルト値
      ),
      isPublic: data['isPublic'] ?? true,
      minParticipants: data['minParticipants'] as int?,
      maxParticipants: data['maxParticipants'] as int?,
      recruitmentEndDate: (data['recruitmentEndDate'] as Timestamp?)?.toDate(),
      location: data['location'] as String?,
      genres: (data['genres'] as List?)?.map((e) => e as String).toList(),
      matchingConditions: data['matchingConditions'] as Map<String, dynamic>?,
      invitedFriendUids: (data['invitedFriendUids'] as List?)?.map((e) => e as String).toList(),
    );
  }

  // EventオブジェクトをFirestoreに保存できるMap形式に変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type.toString().split('.').last, // Enum名を文字列として保存
      'isPublic': isPublic,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'recruitmentEndDate': recruitmentEndDate != null ? Timestamp.fromDate(recruitmentEndDate!) : null,
      'location': location,
      'genres': genres,
      'matchingConditions': matchingConditions,
      'invitedFriendUids': invitedFriendUids,
    };
  }
}