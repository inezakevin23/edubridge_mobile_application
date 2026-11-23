import 'package:edubridge_mobile_application/config/routes/app_router.dart';
import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/auth/domain/entities/auth_user.dart';
import 'package:edubridge_mobile_application/features/auth/domain/repositories/auth_repository.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/pages/register_page.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/widgets/public_bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> enterRegistrationText(
    WidgetTester tester,
    String field,
    String value,
  ) async {
    final finder = find.byKey(Key('registration_$field'));
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  GoRouter registrationRouter({required bool startAsCompany}) => GoRouter(
    initialLocation: startAsCompany
        ? '/company-registration'
        : '/student-registration',
    routes: [
      GoRoute(
        path: '/student-registration',
        builder: (context, state) =>
            const RegisterPage(initialRole: UserRole.talent),
      ),
      GoRoute(
        path: '/company-registration',
        builder: (context, state) =>
            const RegisterPage(initialRole: UserRole.company),
      ),
      GoRoute(
        path: '/talent/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Text('Talent dashboard')),
      ),
      GoRoute(
        path: '/company/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Text('Company dashboard')),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Text('Admin dashboard')),
      ),
    ],
  );

  testWidgets('sign-in page shows branded role selection and credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const SignInPage()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byTooltip('Go back'), findsOneWidget);
  });

  testWidgets('Google sign-in cancellation returns without an error', (
    tester,
  ) async {
    final repository = _GoogleCancellationAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.dark, home: const SignInPage()),
      ),
    );

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(repository.wasCalled, isTrue);
    expect(find.text('Google sign-in was cancelled.'), findsNothing);
    expect(find.byTooltip('Go back'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('student registration shows its four-step flow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const RegisterPage()),
      ),
    );

    expect(find.text('Student Registration'), findsOneWidget);
    expect(find.text('Account Information'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Professional'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.byType(PublicBottomNavigation), findsOneWidget);
  });

  testWidgets('student professional status options stay laid out on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const RegisterPage()),
      ),
    );

    await enterRegistrationText(tester, 'email', 'student@example.com');
    await enterRegistrationText(tester, 'password', 'StrongPass123!');
    await enterRegistrationText(tester, 'confirmPassword', 'StrongPass123!');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await enterRegistrationText(tester, 'fullName', 'Test Student');
    await enterRegistrationText(tester, 'username', 'test_student');
    await enterRegistrationText(tester, 'phone', '+2348000000000');
    await enterRegistrationText(tester, 'city', 'Lagos');

    final countryDropdown = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(countryDropdown);
    await tester.tap(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Algeria'));
    await tester.pumpAndSettle();

    final dateOfBirth = find.byKey(const Key('registration_dateOfBirth'));
    await tester.ensureVisible(dateOfBirth);
    await tester.tap(dateOfBirth);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final genderDropdown = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(genderDropdown);
    await tester.tap(genderDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final statusLabel = tester.getRect(find.text('Current Status'));
    final institutionLabel = tester.getRect(
      find.text('Institution / University'),
    );
    expect(statusLabel.bottom, lessThan(institutionLabel.top));
    expect(find.byType(ListView), findsOneWidget);
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('company registration shows its company-specific flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const RegisterPage(initialRole: UserRole.company),
        ),
      ),
    );

    expect(find.text('Company Registration'), findsOneWidget);
    expect(find.text('Account Information'), findsOneWidget);
    expect(find.text('Organization'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Representative'), findsOneWidget);
    expect(find.byType(PublicBottomNavigation), findsOneWidget);
  });

  testWidgets('student registration automatically opens Talent dashboard', (
    tester,
  ) async {
    final repository = _RegistrationAuthRepository();
    final router = registrationRouter(startAsCompany: false);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith(
            (ref) => Stream.value(repository._user),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            ref.watch(authStateProvider);
            return MaterialApp.router(
              theme: AppTheme.dark,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterRegistrationText(tester, 'email', 'student@example.com');
    await enterRegistrationText(tester, 'password', 'StrongPass123!');
    await enterRegistrationText(tester, 'confirmPassword', 'StrongPass123!');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await enterRegistrationText(tester, 'fullName', 'Test Student');
    await enterRegistrationText(tester, 'username', 'test_student');
    await enterRegistrationText(tester, 'phone', '+2348000000000');
    await enterRegistrationText(tester, 'city', 'Lagos');

    final countryDropdown = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(countryDropdown);
    await tester.tap(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Algeria').last);
    await tester.pumpAndSettle();

    final dateOfBirth = find.byKey(const Key('registration_dateOfBirth'));
    await tester.ensureVisible(dateOfBirth);
    await tester.tap(dateOfBirth);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final genderDropdown = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(genderDropdown);
    await tester.tap(genderDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pump(const Duration(seconds: 1));

    expect(repository.registeredRole, UserRole.talent);
    expect(find.text('Talent dashboard'), findsOneWidget);
    expect(find.text('One more step'), findsNothing);
  });

  testWidgets('company registration automatically opens Company dashboard', (
    tester,
  ) async {
    final repository = _RegistrationAuthRepository();
    final router = registrationRouter(startAsCompany: true);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith(
            (ref) => Stream.value(repository._user),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            ref.watch(authStateProvider);
            return MaterialApp.router(
              theme: AppTheme.dark,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterRegistrationText(tester, 'email', 'company@example.com');
    await enterRegistrationText(tester, 'password', 'StrongPass123!');
    await enterRegistrationText(tester, 'confirmPassword', 'StrongPass123!');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await enterRegistrationText(tester, 'organizationName', 'Example Company');
    await enterRegistrationText(tester, 'city', 'Lagos');
    await enterRegistrationText(tester, 'username', 'example_company');
    await enterRegistrationText(tester, 'phone', '+2348000000000');
    await enterRegistrationText(
      tester,
      'description',
      'A company building useful products for Africa.',
    );

    final industryDropdown = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(industryDropdown);
    await tester.tap(industryDropdown);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Technology').last);
    await tester.tap(find.text('Technology').last);
    await tester.pumpAndSettle();

    final countryDropdown = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(countryDropdown);
    await tester.tap(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Algeria').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await enterRegistrationText(
      tester,
      'representativeName',
      'Company Representative',
    );
    await enterRegistrationText(tester, 'representativeTitle', 'Director');
    await enterRegistrationText(
      tester,
      'representativeUsername',
      'company_director',
    );
    await enterRegistrationText(
      tester,
      'representativePhone',
      '+2348000000001',
    );
    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pump(const Duration(seconds: 1));

    expect(repository.registeredRole, UserRole.company);
    expect(find.text('Company dashboard'), findsOneWidget);
    expect(find.text('One more step'), findsNothing);
  });

  testWidgets('registration page remains open while account setup resolves', (
    tester,
  ) async {
    final repository = _RegistrationAuthRepository()
      .._user = const AuthUser(
        id: 'incomplete-user',
        email: 'student@example.com',
        role: UserRole.talent,
        requiresAccountSetup: true,
      );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authStateProvider.overrideWith((ref) => Stream.value(repository._user)),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go('/student-registration');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Registration'), findsOneWidget);
    expect(find.text('One more step'), findsNothing);
  });
}

class _RegistrationAuthRepository implements AuthRepository {
  AuthUser? _user;
  UserRole? registeredRole;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(_user);

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required UserRole role,
    required String displayName,
    Map<String, Object?> profileDetails = const {},
  }) async {
    registeredRole = role;
    _user = AuthUser(
      id: 'new-user',
      email: email,
      role: role,
      displayName: displayName,
    );
    return _user!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GoogleCancellationAuthRepository implements AuthRepository {
  bool wasCalled = false;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<AuthUser> signInWithGoogle({
    required UserRole newAccountRole,
    String displayName = '',
  }) async {
    wasCalled = true;
    throw FirebaseAuthException(code: 'google-sign-in-cancelled');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
