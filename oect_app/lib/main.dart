import 'package:flutter/material.dart';
import 'package:OECT/screens/SplashScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures proper Flutter setup
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
