// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:sukekenn/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sukekenn/check_profile_screen.dart';
// 以下のインポートはmain_screen.dart で管理するため削除またはコメントアウト
// import 'package:sukekenn/calendar_home_screen.dart';
// import 'package:sukekenn/chat_screen.dart';
// import 'package:sukekenn/friend_screen.dart';
// import 'package:sukekenn/matching_screen.dart';
// import 'package:sukekenn/my_page_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 新規追加

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja'); // 日本語ロケール初期化

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print('Firebase initialize error: $e');
  }

  // ここをProviderScopeでラップ
  runApp(
    const ProviderScope( // ProviderScopeでMyAppをラップ
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // ダークモード対応のために MaterialApp を ConsumerWidget にすることも検討
    // final appSettings = ref.watch(appSettingsProvider);
    return MaterialApp(
      title: 'Sukekenn',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, // デフォルトライトモード
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark, // デフォルトダークモード
      ),
      // themeMode: appSettings.isDarkMode ? ThemeMode.dark : ThemeMode.light, // appSettingsProviderと連携する場合
      home: const CheckProfileScreen(), // 最初の画面
    );
  }
}

// PhoneAuthPage のコードはそのまま
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
      phoneNumber = input; // 国番号付き
    } else if (input.startsWith('0')) {
      phoneNumber = '+81${input.substring(1)}'; // 日本番号を国際化
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
          setState(() {
            _verificationId = verificationId;
          });
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
        SnackBar(content: Text("送信中にエラーが発生しました: $e")),
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
          final userData = {
            'uid': user.uid,
            'phoneNumber': user.phoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
          };
          await userDoc.set(userData, SetOptions(merge: true));
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CheckProfileScreen()),
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