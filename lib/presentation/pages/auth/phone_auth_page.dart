// lib/presentation/pages/auth/phone_auth_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});
  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;

    setState(() => _isLoading = true);

    String input = _phoneController.text.trim();
    String phoneNumber;

    if (input.startsWith('+')) {
      phoneNumber = input;
    } else if (input.startsWith('0')) {
      phoneNumber = '+81${input.substring(1)}';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("正しい形式の電話番号を入力してください")),
      );
      setState(() => _isLoading = false);
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() => _isLoading = true);
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("エラー: ${e.message}")),
          );
          setState(() => _isLoading = false);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if(mounted){
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("確認コードを送信しました")),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // タイムアウトした場合の処理
      },
    );
  }

  Future<void> _verifyCode() async {
     FocusScope.of(context).unfocus();
    if (_verificationId == null || _smsCodeController.text.trim().isEmpty) {
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _smsCodeController.text.trim(),
    );
    
    await _signInWithCredential(credential);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("認証に失敗しました: ${e.code}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('電話番号でログイン')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '電話番号',
                hintText: '09012345678',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !_codeSent,
            ),
            const SizedBox(height: 16),
            if (!_codeSent)
              ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0)) : const Text('確認コードを送信'),
              ),
            
            if (_codeSent) ...[
              TextField(
                controller: _smsCodeController,
                decoration: const InputDecoration(
                  labelText: '確認コード',
                  hintText: 'SMSに届いた6桁の数字',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0)) : const Text('認証して次へ'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _codeSent = false;
                    _verificationId = null;
                  });
                },
                child: const Text('電話番号を再入力する'),
              )
            ],
          ],
        ),
      ),
    );
  }
}