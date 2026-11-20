import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/challenges/presentation/pages/company/create_challenge_page.dart';
import 'features/challenges/presentation/pages/company/manage_challenges_page.dart';
import 'features/challenges/presentation/pages/talent/challenge_detail_page.dart';
import 'features/challenges/presentation/pages/talent/challenges_page.dart';
import 'features/dashboards/presentation/pages/company_dashboard_page.dart';
import 'features/dashboards/presentation/pages/talent_dashboard_page.dart';
import 'features/submissions/presentation/pages/company/company_submissions_page.dart';
import 'features/submissions/presentation/pages/company/submission_detail_page.dart';
import 'features/submissions/presentation/pages/talent/talent_solution_page.dart';
import 'features/submissions/presentation/pages/talent/talent_submissions_page.dart';
import 'firebase_options.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TalentDashboardPage(),
    ),
    GoRoute(
      path: '/talent/dashboard',
      builder: (context, state) => const TalentDashboardPage(),
    ),
    GoRoute(
      path: '/challenges',
      builder: (context, state) => const ChallengesPage(),
    ),
    GoRoute(
      path: '/challenges/:challengeId',
      builder: (context, state) => ChallengeDetailPage(
        challengeId: state.pathParameters['challengeId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/challenge-detail',
      builder: (context, state) =>
          const ChallengeDetailPage(challengeId: 'challengeId'),
    ),
    GoRoute(
      path: '/create-challenge',
      builder: (context, state) =>
          const CreateChallengePage(companyId: 'companyId'),
    ),
    GoRoute(
      path: '/manage-challenges',
      builder: (context, state) =>
          const ManageChallengesPage(companyId: 'companyId'),
    ),
    GoRoute(
      path: '/company/dashboard',
      builder: (context, state) =>
          const CompanyDashboardPage(companyId: 'companyId'),
    ),
    GoRoute(
      path: '/talent/solution/:challengeId',
      builder: (context, state) => TalentSolutionPage(
        challengeId: state.pathParameters['challengeId']!,
      ),
    ),
    GoRoute(
      path: '/talent/submissions',
      builder: (context, state) => const TalentSubmissionsPage(),
    ),
    GoRoute(
      path: '/company/submissions',
      builder: (context, state) => const CompanySubmissionsPage(),
    ),
    GoRoute(
      path: '/submissions/:submissionId',
      builder: (context, state) => SubmissionDetailPage(
        submissionId: state.pathParameters['submissionId']!,
      ),
    ),
  ],
);

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
    return MaterialApp.router(
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
      routerConfig: _router,
    );
  }
}

typedef MyApp = EduBridgeApp;

