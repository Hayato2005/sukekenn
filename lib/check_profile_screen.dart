import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_edit_screen.dart';
import 'main_screen.dart';

class CheckProfileScreen extends StatelessWidget {
  const CheckProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("未ログインです")),
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
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("ユーザーデータがありません")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hasDisplayName = data['displayName'] != null && data['displayName'].toString().isNotEmpty;
        final hasId = data['id'] != null && data['id'].toString().isNotEmpty;

        if (!hasDisplayName || !hasId) {
          // プロフィール未設定 → 設定画面へ
          return const ProfileEditScreen();
        } else {
          // 設定済み → ホームへ
          return const MainScreen();
        }
      },
    );
  }
}
