// lib/presentation/pages/auth/check_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sukekenn/main_screen.dart';
import 'package:sukekenn/presentation/pages/auth/profile_edit_screen.dart';

class CheckProfileScreen extends StatelessWidget {
  const CheckProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("未ログインです。アプリを再起動してください。")),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("エラーが発生しました: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ProfileEditScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hasDisplayName = data.containsKey('displayName') && data['displayName'] != null && data['displayName'].toString().isNotEmpty;

        if (!hasDisplayName) {
          // --- 修正点：呼び出すクラス名を正しいものに修正 ---
          return const ProfileEditScreen();
        } else {
          // 設定済み → メイン画面へ
          return const MainScreen();
        }
      },
    );
  }
}