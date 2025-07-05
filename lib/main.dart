import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'root_page.dart'; // 인증 상태를 기준으로 화면 결정
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ⬅️ 이거 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  // ⬇️ Firestore 인스턴스 초기화 (선택적: 나중에 쓸 때 유용)
  final FirebaseFirestore db = FirebaseFirestore.instance;

  runApp(const ChalkCrewApp());
}

class ChalkCrewApp extends StatelessWidget {
  const ChalkCrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChalkCrew',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.white,
          secondary: Colors.grey[700],
        ),
      ),
      home: const RootPage(), // 인증 흐름 시작점
    );
  }
}
