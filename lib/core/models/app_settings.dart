// lib/core/models/app_settings.dart
import 'package:flutter/material.dart';

class AppSettings {
  final double calendarFontSizeMultiplier; // カレンダーの文字サイズ倍率 (例: 1.0 = デフォルト, 1.2 = 1.2倍)
  final bool isDarkMode; // ダークモード設定

  AppSettings({
    this.calendarFontSizeMultiplier = 1.0,
    this.isDarkMode = false, // システム設定に追従させる場合は別途ロジックが必要
  });

  // TODO: fromJson/toJson メソッドを追加 (Firestoreに保存する場合)

  AppSettings copyWith({
    double? calendarFontSizeMultiplier,
    bool? isDarkMode,
  }) {
    return AppSettings(
      calendarFontSizeMultiplier: calendarFontSizeMultiplier ?? this.calendarFontSizeMultiplier,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}