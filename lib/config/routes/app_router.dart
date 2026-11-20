import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/pages/complete_account_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/landing_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_dashboard_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/challenges/presentation/pages/company/create_challenge_page.dart';
import '../../features/challenges/presentation/pages/company/manage_challenges_page.dart';
import '../../features/challenges/presentation/pages/talent/challenge_detail_page.dart';
import '../../features/challenges/presentation/pages/talent/challenges_page.dart';
import '../../features/dashboards/presentation/pages/company_dashboard_page.dart';
import '../../features/dashboards/presentation/pages/talent/talent_dashboard_page.dart';
import '../../features/feedback/presentation/pages/company_feedback_page.dart';
import '../../features/feedback/presentation/pages/talent_feedback_page.dart';
import '../../features/profiles/presentation/pages/company_profile_page.dart';
import '../../features/profiles/presentation/pages/talent_profile_page.dart';
import '../../features/submissions/presentation/pages/company/company_submissions_page.dart';
import '../../features/submissions/presentation/pages/company/submission_detail_page.dart';
import '../../features/submissions/presentation/pages/talent/talent_solution_page.dart';
import '../../features/submissions/presentation/pages/talent/talent_submissions_page.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

String dashboardPathForRole(UserRole role) {
  switch (role) {
    case UserRole.company:
      return '/company/dashboard';
    case UserRole.admin:
      return '/admin/dashboard';
    case UserRole.talent:
      return '/talent/dashboard';
  }
}

/// Keeps feature entry points role-specific even when users enter URLs directly.
bool canAccessRoleFeatureRoute(UserRole role, String location) {
  if (location.startsWith('/company/') ||
      location.startsWith('/feedback/company/')) {
    return role == UserRole.company;
  }
  if (location.startsWith('/talent/') ||
      location.startsWith('/feedback/talent/')) {
    return role == UserRole.talent;
  }
  return true;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (previous, next) {
    refreshNotifier.refresh();
  });

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final auth = ref.read(authStateProvider);
      final isPublicAuthPage = const {
        '/',
        '/sign-in',
        '/register',
        '/forgot-password',
      }.contains(location);

      // Do not redirect while Firebase is resolving persisted credentials.
      if (auth.isLoading && !auth.hasValue) return null;
      if (auth.hasError) {
        return isPublicAuthPage ? null : '/sign-in';
      }

      final user = auth.value;
      if (user == null) {
        return isPublicAuthPage ? null : '/sign-in';
      }

      if (user.requiresAccountSetup) {
        return location == '/complete-account' ? null : '/complete-account';
      }

      if (user.requiresEmailVerification) {
        return location == '/verify-email' ? null : '/verify-email';
      }

      // Role-specific feature routes must be protected in the router as well
      // as in Firestore rules. This includes the Member 4 feedback pages.
      if (!canAccessRoleFeatureRoute(user.role, location)) {
        return dashboardPathForRole(user.role);
      }

      // Dashboard routes are role-specific. Do not let a Talent account open
      // the Company or Admin dashboard merely by typing its route manually.
      if (location.endsWith('/dashboard') &&
          location != dashboardPathForRole(user.role)) {
        return dashboardPathForRole(user.role);
      }

      if (isPublicAuthPage ||
          location == '/verify-email' ||
          location == '/complete-account' ||
          location == '/home') {
        return dashboardPathForRole(user.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingPage()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: '/complete-account',
        builder: (context, state) => const CompleteAccountPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _HomeRouteFallback(),
      ),
      GoRoute(
        path: '/talent/dashboard',
        builder: (context, state) => const TalentDashboardPage(),
      ),
      GoRoute(
        path: '/company/dashboard',
        builder: (context, state) => const _CompanyDashboardRoute(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) =>
            const RoleDashboardPage(role: UserRole.admin),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const _ProfileRoute(),
      ),
      GoRoute(
        path: '/talent/profile',
        builder: (context, state) => const TalentProfilePage(),
      ),
      GoRoute(
        path: '/company/profile',
        builder: (context, state) => const CompanyProfilePage(),
      ),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesPage(),
      ),
      GoRoute(
        path: '/challenges/:challengeId',
        builder: (context, state) => ChallengeDetailPage(
          challengeId: state.pathParameters['challengeId']!,
        ),
      ),
      GoRoute(
        path: '/company/challenges/create',
        builder: (context, state) => const _CreateChallengeRoute(),
      ),
      GoRoute(
        path: '/company/challenges/manage',
        builder: (context, state) => const _ManageChallengesRoute(),
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
      GoRoute(
        path: '/talent/submissions',
        builder: (context, state) => const TalentSubmissionsPage(),
      ),
      GoRoute(
        path: '/talent/solution/:challengeId',
        builder: (context, state) => TalentSolutionPage(
          challengeId: state.pathParameters['challengeId']!,
        ),
      ),
      GoRoute(
        path: '/feedback/talent/:submissionId',
        builder: (context, state) => TalentFeedbackPage(
          submissionId: state.pathParameters['submissionId']!,
        ),
      ),
      GoRoute(
        path: '/feedback/company/:submissionId',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return CompanyFeedbackPage(
            submissionId: state.pathParameters['submissionId']!,
            challengeId: query['challengeId'] ?? '',
            talentId: query['talentId'] ?? '',
            talentName: query['talentName'] ?? 'Talent',
            challengeTitle: query['challengeTitle'] ?? 'Challenge',
          );
        },
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});

class _HomeRouteFallback extends ConsumerWidget {
  const _HomeRouteFallback();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Unable to load account: $error'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        return RoleDashboardPage(role: user.role);
      },
    );
  }
}

class _ProfileRoute extends ConsumerWidget {
  const _ProfileRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Unable to load profile: $error'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        if (user.role == UserRole.company) {
          return const CompanyProfilePage();
        }
        if (user.role == UserRole.talent) {
          return const TalentProfilePage();
        }
        return const Scaffold(
          body: Center(child: Text('Admin profiles are not available yet.')),
        );
      },
    );
  }
}

class _CompanyDashboardRoute extends ConsumerWidget {
  const _CompanyDashboardRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Unable to load dashboard: $error')),
      ),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        return CompanyDashboardPage(companyId: user.id);
      },
    );
  }
}

class _CreateChallengeRoute extends ConsumerWidget {
  const _CreateChallengeRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Unable to load account: $error'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        return CreateChallengePage(companyId: user.id);
      },
    );
  }
}

class _ManageChallengesRoute extends ConsumerWidget {
  const _ManageChallengesRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Unable to load account: $error'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        return ManageChallengesPage(companyId: user.id);
      },
    );
  }
}
