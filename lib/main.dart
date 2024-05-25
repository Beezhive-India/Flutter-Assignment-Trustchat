import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trustchat/auth_screen.dart';
import 'package:trustchat/video_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthScreen(),
      routes: {
        '/video_call': (context) => VideoCallScreen(),
      },
    );
  }
}
