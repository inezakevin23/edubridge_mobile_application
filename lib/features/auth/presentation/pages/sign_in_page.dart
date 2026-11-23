import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../domain/entities/auth_user.dart';
import '../providers/auth_error_message.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_brand_panel.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _googleRole = UserRole.talent;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .signIn(_email.text.trim(), _password.text);
      await refreshAuthState(ref);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).signInWithGoogle(_googleRole);
      await refreshAuthState(ref);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted && !isGoogleSignInCancelled(error)) {
        setState(() => _error = authErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1000) {
              final panelWidth = (constraints.maxWidth * 0.42).clamp(
                430.0,
                594.0,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: panelWidth,
                    child: const AuthBrandPanel(
                      title: 'Build Your Future\nwith Real Challenges',
                      description: 'Join thousands of African students and companies solving real problems together.',
                      fillHeight: true,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 48,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: _signInForm(context),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandPanel(
                    title: 'Build Your Future\nwith Real Challenges',
                    description: 'Join thousands of African students and companies solving real problems together.',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: _signInForm(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _signInForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: AppBackButton()),
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: AppTypography.display,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in to your EduBridge account',
            style: TextStyle(color: Color(0xFF9AA7BA), fontSize: AppTypography.title),
          ),
          const SizedBox(height: 48),
          _roleToggle(),
          const SizedBox(height: 36),
          _field(
            key: const Key('sign_in_email'),
            controller: _email,
            label: 'Email Address',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ),
          const SizedBox(height: 24),
          _field(
            key: const Key('sign_in_password'),
            controller: _password,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            suffix: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password is required.' : null,
            onSubmitted: (_) => _signIn(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9B6CFF),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1AF43F5E),
                border: Border.all(color: const Color(0x4DF43F5E)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFFDA4AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 62,
            child: FilledButton.icon(
              key: const Key('sign_in_submit'),
              onPressed: _busy ? null : _signIn,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
              label: _busy
                  ? const SizedBox.shrink()
                  : const Icon(Icons.arrow_forward_rounded, size: 20),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFF26334A))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(color: Color(0xFF9AA7BA), fontSize: AppTypography.caption),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFF26334A))),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _busy ? null : _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF26334A)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: Color(0xFF9AA7BA), fontSize: AppTypography.body),
              ),
              TextButton(
                onPressed: _busy ? null : () => context.go('/register'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9B6CFF),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Create one — it's free",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleToggle() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xE61A2338),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, spreadRadius: -8),
        ],
      ),
      child: Row(
        children: [
          _roleButton(UserRole.talent, 'Student', Icons.school_outlined),
          _roleButton(UserRole.company, 'Company', Icons.business_outlined),
        ],
      ),
    );
  }

  Widget _roleButton(UserRole role, String label, IconData icon) {
    final selected = _googleRole == role;
    return Expanded(
      child: InkWell(
        onTap: _busy ? null : () => setState(() => _googleRole = role),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x4D4C1D95),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : const Color(0xFF9AA7BA),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF9AA7BA),
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    bool obscureText = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          key: key,
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xF2182237),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.65),
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(color: Color(0xFFF43F5E)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(
                color: Color(0xFFF43F5E),
                width: 1.3,
              ),
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: AppTypography.title),
        ),
      ],
    );
  }
}
