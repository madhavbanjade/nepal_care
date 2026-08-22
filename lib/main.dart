import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nepal_care/screens/auth/auth_gate.dart';
import 'package:nepal_care/firebase_options.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //this is the firebase intilization optins for flutter.... hello
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//Google Sign-In should be initialized once, before your login/signup screen tries to use:
  await GoogleSignIn.instance.initialize(
    serverClientId: '679531876538-19jbuuaed5hmm1dpru3040m0f3r2rsv4.apps.googleusercontent.com'
  );
//changes
  runApp(const CareNepalApp());
}

class CareNepalApp extends StatelessWidget {
  const CareNepalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care-Nepal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
