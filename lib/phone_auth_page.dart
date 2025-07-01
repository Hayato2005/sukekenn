import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});
  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;

  Future<void> _sendCode() async {
    String input = _phoneController.text.trim();
    String phoneNumber;

    if (input.startsWith('+')) {
      phoneNumber = input;
    } else if (input.startsWith('0')) {
      phoneNumber = '+81${input.substring(1)}';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("正しい電話番号を入力してください")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("送信失敗: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _verificationId = verificationId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("SMSコードを送信しました")),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("送信中にエラー: $e")),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId != null) {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text,
      );
      try {
        await FirebaseAuth.instance.signInWithCredential(credential);

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
          await userDoc.set({
            'uid': user.uid,
            'phoneNumber': user.phoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // 認証成功→MainScreenへ遷移
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("認証失敗: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('電話番号認証')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: '電話番号を入力'),
              keyboardType: TextInputType.phone,
            ),
            ElevatedButton(
              onPressed: _sendCode,
              child: const Text('SMSコードを送信'),
            ),
            if (_verificationId != null) ...[
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'SMSコードを入力'),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                onPressed: _verifyCode,
                child: const Text('認証する'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
