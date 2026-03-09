import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'features/logbook/models/log_model.dart';
import 'features/onboarding/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load file .env
  await dotenv.load(fileName: ".env");

  // 2. Inisialisasi Hive
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter()); // Mendaftarkan adapter otomatis
  
  // 3. Buka kotak penyimpanan offline
  await Hive.openBox<LogModel>('offline_logs');

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logbook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}