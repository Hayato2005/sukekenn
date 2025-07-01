import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_edit_screen.dart';
import 'main_screen.dart';

class CheckProfileScreen extends StatefulWidget {
  const CheckProfileScreen({super.key});

  @override
  State<CheckProfileScreen> createState() => _CheckProfileScreenState();
}

class _CheckProfileScreenState extends State<CheckProfileScreen> {
  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      // 未ログイン → 任意でログイン画面へ飛ばす場合はここにNavigator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("未ログインです")),
      );
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ユーザーデータがありません")),
      );
      return;
    }

    final data = doc.data()!;
    final hasDisplayName = data['displayName'] != null && data['displayName'].toString().isNotEmpty;
    final hasId = data['id'] != null && data['id'].toString().isNotEmpty;

    if (!hasDisplayName || !hasId) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
