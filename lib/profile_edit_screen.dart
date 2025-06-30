import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _displayNameController = TextEditingController();
  final _idController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = _displayNameController.text.trim();
    final id = _idController.text.trim();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("表示名は必須です")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // IDが未入力なら自動で生成（uidの一部を利用など）
    final generatedId = user.uid.substring(0, 6);
    final finalId = id.isEmpty ? generatedId : id;

    // ID重複確認（自分自身のIDは除外する）
    final idSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('id', isEqualTo: finalId)
    .get();

    if (idSnapshot.docs.any((doc) => doc.id != user.uid)) {
     setState(() => _isLoading = false);
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text("このIDは既に使われています")),
     );
     return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'displayName': displayName,
      'id': finalId,
    });

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("プロフィール設定")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: "表示名"),
            ),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: "ID（任意）"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text("保存して続行"),
                  ),
          ],
        ),
      ),
    );
  }
}
