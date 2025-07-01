// lib/presentation/pages/auth/profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _idController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
        setState(() => _isLoading = false);
        return;
    }

    final displayName = _displayNameController.text.trim();
    final id = _idController.text.trim();

    try {
      final idSnapshot = await FirebaseFirestore.instance.collection('users').where('id', isEqualTo: id).limit(1).get();
      if (idSnapshot.docs.isNotEmpty && idSnapshot.docs.first.id != user.uid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("このIDは既に使用されています")));
        setState(() => _isLoading = false);
        return;
      }
      
      // プロフィール情報をFirestoreに保存
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'id': id,
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 保存後の画面遷移はmain.dartのStreamBuilderが自動的に検知して行うので、ここでの遷移コードは不要

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラーが発生しました: $e")));
    } finally {
       if (mounted) {
        setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("プロフィール設定"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: "表示名", border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? '表示名を入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: "ユーザーID", border: OutlineInputBorder(), hintText: '半角英数字と_のみ'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'ユーザーIDを入力してください';
                  if (!RegExp(r'^[a-zA-Z0-9_]{4,15}$').hasMatch(value)) return '4〜15文字の半角英数字と_のみ使用できます';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const CircularProgressIndicator() : const Text("保存して開始する"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}