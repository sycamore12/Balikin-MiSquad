import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'firebase_options.dart';
import 'screens/wrapper.dart'; 
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Start Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Start Supabase
  // GO TO: Supabase Dashboard -> Project Settings -> API
  await Supabase.initialize(
    url: 'https://ovfonkrvyfyxkmabwxga.supabase.co',       // Paste URL here
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92Zm9ua3J2eWZ5eGttYWJ3eGdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2NDQ0MTUsImV4cCI6MjA4MTIyMDQxNX0.qm6w2EisItuC-qv9fTuZVw-r4Mu8d8vO9vY4o_WcGuU', // Paste "anon" / "public" key here
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balikin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        fontFamily: 'SFProDisplay',
      ),
      home: const SplashScreen(), // Start here!
    );
  }
}