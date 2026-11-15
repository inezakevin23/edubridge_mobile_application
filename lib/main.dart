import 'package:edubridge_mobile_application/features/challenges/presentation/pages/talent/challenges_page.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/pages/talent/challenge_detail_page.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/pages/company/create_challenge_page.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/pages/company/manage_challenges_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // challenge feature
      routes: {
        '/': (context) => const ChallengesPage(),
        '/challenge-detail': (context) =>
            const ChallengeDetailPage(challengeId: 'challengeId'),
        '/create-challenge': (context) =>
            const CreateChallengePage(companyId: 'companyId'),
        '/manage-challenges': (context) =>
            const ManageChallengesPage(companyId: 'companyId'),
      },
    );
  }
}
