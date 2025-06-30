// lib/presentation/providers/app_settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sukekenn/core/models/app_settings.dart'; // パスを修正

// アプリ設定を管理するプロバイダ
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  // TODO: ここでFirestoreなどからユーザーの設定をロードするロジックを実装
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings());

  void updateCalendarFontSizeMultiplier(double multiplier) {
    state = state.copyWith(calendarFontSizeMultiplier: multiplier);
    // TODO: Firestoreなどにも設定を保存するロジックを追加
  }

  void toggleDarkMode(bool isDarkMode) {
    state = state.copyWith(isDarkMode: isDarkMode);
    // TODO: Firestoreなどにも設定を保存するロジックを追加
  }
}