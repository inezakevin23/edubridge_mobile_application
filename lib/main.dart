import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/dashboards/presentation/pages/talent_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }
  runApp(const ProviderScope(child: EduBridgeApp()));
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E121A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C3BED),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF1E2235),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E121A),
          elevation: 0,
        ),
      ),
      home: const TalentDashboardPage(),
    );
  }
}
