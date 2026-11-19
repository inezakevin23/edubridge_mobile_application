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
import '../../features/profiles/presentation/pages/profile_page.dart';

/// Notifies GoRouter when Firebase/Riverpod authentication state changes,
/// without constructing a new router for every login-state event.
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
  if (location.startsWith('/feedback/company/')) {
    return role == UserRole.company;
  }
  if (location.startsWith('/feedback/talent/')) {
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
      GoRoute(path: '/', builder: (_, __) => const LandingPage()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: '/complete-account',
        builder: (_, __) => const CompleteAccountPage(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const _HomeRouteFallback()),
      GoRoute(
        path: '/talent/dashboard',
        builder: (_, __) => const RoleDashboardPage(role: UserRole.talent),
      ),
      GoRoute(
        path: '/company/dashboard',
        builder: (_, __) => const RoleDashboardPage(role: UserRole.company),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => const RoleDashboardPage(role: UserRole.admin),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
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
