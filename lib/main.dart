import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'screens/auth_screens.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    final prefs = await SharedPreferences.getInstance();

    final keepSignedIn = prefs.getBool('keep_signed_in') ?? true;

    if (!keepSignedIn && FirebaseAuth.instance.currentUser != null) {
      await Auth.logout();
    }
  } catch (_) {}

  runApp(const LipatApp());
}

class LipatApp extends StatelessWidget {
  const LipatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIPAT',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}
