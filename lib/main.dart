import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'presentation/pages/auth/phone_auth_page.dart';
import 'presentation/pages/auth/check_profile_screen.dart';
import 'presentation/pages/calendar/calendar_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("--- アプリ起動 ---");

  await initializeDateFormatting('ja'); // ← ここで初期化！

  try {
    if (Firebase.apps.isEmpty) {
      print("--- Firebase初期化を開始 ---");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("--- Firebase初期化完了 ---");
    } else {
      print("--- 既存のFirebaseインスタンスを使用 ---");
      Firebase.app();
    }
  } catch (e, st) {
    print("--- Firebase初期化中にエラー: $e ---");
    print(st);
  }

  runApp(
    const ProviderScope( // ← ここで包む
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const InitialScreenSelector(),
    );
  }
}

class InitialScreenSelector extends StatelessWidget {
  const InitialScreenSelector({super.key});

  /// Firestoreなどにプロフィール完了情報があるか確認するメソッド
  Future<bool> _checkProfileCompleted(User user) async {
    // TODO: Firestore等で該当ユーザーのプロフィール情報を取得して、
    // 登録完了しているか判定するロジックに置き換えること
    // 仮で「ユーザーIDが偶数なら完了済」として動作確認できるようにする
    return user.uid.hashCode % 2 == 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ローディング中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 未認証 → 電話認証画面へ
        if (!snapshot.hasData) {
          return const PhoneAuthPage();
        }

        // 認証済み → Firestoreのプロフィール確認
        return FutureBuilder<bool>(
          future: _checkProfileCompleted(snapshot.data!),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (profileSnapshot.hasData && profileSnapshot.data == true) {
              // プロフィール完了済み → ホーム画面へ
              return const CalendarPage();
            } else {
              // プロフィール未完了 → プロフィール作成へ
              return const CheckProfileScreen();
            }
          },
        );
      },
    );
  }
}
