// lib/core/models/event.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestampのために必要

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
      case EventType.friend: return 'フレンド';
      case EventType.anyone: return '誰でも';
      case EventType.oppositeSex: return '異性';
      case EventType.myGroup: return 'マイグループ';
      case EventType.fixed: return '固定予定';
    }
  }

  // デフォルトカラーと文字色
  Color get defaultBackgroundColor {
    switch (this) {
      case EventType.friend: return const Color(0xFFCFB53B); // CFB53B (金色系)
      case EventType.anyone: return const Color(0xFF004080); // #004080 (濃い青)
      case EventType.oppositeSex: return const Color(0xFFAA2455); // #aa2455 (やや落ち着いた赤)
      case EventType.myGroup: return Colors.purple.shade300; // 仮
      case EventType.fixed: return Colors.grey.shade400;  // 仮
    }
  }

  Color get defaultTextColor {
    switch (this) {
      case EventType.friend: return Colors.black;
      case EventType.anyone: return Colors.white;
      case EventType.oppositeSex: return const Color(0xFFFDF5E6); // ライトベージュ
      case EventType.myGroup: return Colors.white; // 仮
      case EventType.fixed: return Colors.black; // 仮
    }
  }
}

// 予定の詳細条件（例）
class EventMatchingConditions {
  final List<int>? ages;
  final String? gender;
  final List<String>? professions;
  // ... その他、学歴、収入、出身地、予算、身長、体重、趣味など

  EventMatchingConditions({
    this.ages,
    this.gender,
    this.professions,
  });

  // TODO: fromJson/toJson メソッドを追加 (Map形式との変換)
  Map<String, dynamic> toJson() {
    return {
      'ages': ages,
      'gender': gender,
      'professions': professions,
      // ...
    };
  }
  factory EventMatchingConditions.fromJson(Map<String, dynamic> json) {
    return EventMatchingConditions(
      ages: (json['ages'] as List?)?.map((e) => e as int).toList(),
      gender: json['gender'] as String?,
      professions: (json['professions'] as List?)?.map((e) => e as String).toList(),
      // ...
    );
  }
}

class Event {
  final String id; // FirestoreのドキュメントID
  final String ownerId; // 予定を作成したユーザーのUID (以前の userId を ownerId に変更)
  final String title;
  final DateTime startTime; // 予定の開始日時
  final DateTime endTime;   // 予定の終了日時
  final EventType type;    // 予定の種別
  final bool isFixed; // 固定予定か空き予定か (typeがEventType.fixedならtrue)
  final bool isPublic;     // 公開範囲 (true:公開, false:非公開)
  final int? minParticipants; // 募集人数 下限
  final int? maxParticipants; // 募集人数 上限
  final DateTime? recruitmentDeadline; // 募集期間終了日時 (以前の recruitmentEndDate を変更)
  final String? locationPrefecture; // 場所 (都道府県)
  final String? locationCity; // 場所 (市区町村)
  final String? locationRange; // 場所 (範囲指定)
  final List<String>? genres; // ジャンル (複数選択可)
  final EventMatchingConditions? conditions; // 年齢、性別、職業などの詳細条件
  final List<String>? invitedFriends; // 招待されたフレンドのUIDリスト (以前の invitedFriendUids を変更)
  final Color backgroundColor; // 予定セルの背景色
  final Color textColor;     // 予定セルの文字色

  Event({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isFixed = false, // デフォルトはfalse。EventType.fixed なら true
    this.isPublic = true, // デフォルトは公開
    this.minParticipants,
    this.maxParticipants,
    this.recruitmentDeadline,
    this.locationPrefecture,
    this.locationCity,
    this.locationRange,
    this.genres,
    this.conditions,
    this.invitedFriends,
    Color? backgroundColor,
    Color? textColor,
  }) : this.backgroundColor = backgroundColor ?? type.defaultBackgroundColor,
       this.textColor = textColor ?? type.defaultTextColor;

  // FirestoreのDocumentSnapshotからEventオブジェクトを作成
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final EventType type = EventType.values.firstWhere(
      (e) => e.toString().split('.').last == (data['type'] as String),
      orElse: () => EventType.fixed, // デフォルト値
    );

    // カラーをint型で保存していると仮定
    final Color bgColor = (data['backgroundColor'] != null)
        ? Color(data['backgroundColor'] as int)
        : type.defaultBackgroundColor;
    final Color txtColor = (data['textColor'] != null)
        ? Color(data['textColor'] as int)
        : type.defaultTextColor;

    return Event(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '無題の予定',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      type: type,
      isFixed: data['isFixed'] ?? false,
      isPublic: data['isPublic'] ?? true,
      minParticipants: data['minParticipants'] as int?,
      maxParticipants: data['maxParticipants'] as int?,
      recruitmentDeadline: (data['recruitmentDeadline'] as Timestamp?)?.toDate(),
      locationPrefecture: data['locationPrefecture'] as String?,
      locationCity: data['locationCity'] as String?,
      locationRange: data['locationRange'] as String?,
      genres: (data['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      conditions: (data['conditions'] != null)
          ? EventMatchingConditions.fromJson(data['conditions'] as Map<String, dynamic>)
          : null,
      invitedFriends: (data['invitedFriends'] as List<dynamic>?)?.map((e) => e as String).toList(),
      backgroundColor: bgColor,
      textColor: txtColor,
    );
  }

  // EventオブジェクトをFirestoreに保存できるMap形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type.toString().split('.').last, // Enum名を文字列として保存
      'isFixed': isFixed,
      'isPublic': isPublic,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'recruitmentDeadline': recruitmentDeadline != null ? Timestamp.fromDate(recruitmentDeadline!) : null,
      'locationPrefecture': locationPrefecture,
      'locationCity': locationCity,
      'locationRange': locationRange,
      'genres': genres,
      'conditions': conditions?.toJson(),
      'invitedFriends': invitedFriends,
      'backgroundColor': backgroundColor.value, // Colorをintで保存
      'textColor': textColor.value,
    };
  }

  // 背景色に基づいて自動で文字色を決定するヘルパー
  static Color getAdaptiveTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  // コピーコンストラクタ（予定複製などで便利）
  Event copyWith({
    String? id,
    String? ownerId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    EventType? type,
    bool? isFixed,
    bool? isPublic,
    int? minParticipants,
    int? maxParticipants,
    DateTime? recruitmentDeadline,
    String? locationPrefecture,
    String? locationCity,
    String? locationRange,
    List<String>? genres,
    EventMatchingConditions? conditions,
    List<String>? invitedFriends,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Event(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      isFixed: isFixed ?? this.isFixed,
      isPublic: isPublic ?? this.isPublic,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      recruitmentDeadline: recruitmentDeadline ?? this.recruitmentDeadline,
      locationPrefecture: locationPrefecture ?? this.locationPrefecture,
      locationCity: locationCity ?? this.locationCity,
      locationRange: locationRange ?? this.locationRange,
      genres: genres ?? this.genres,
      conditions: conditions ?? this.conditions,
      invitedFriends: invitedFriends ?? this.invitedFriends,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }
}