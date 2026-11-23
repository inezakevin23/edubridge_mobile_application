import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../domain/entities/auth_user.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../providers/auth_error_message.dart';
import '../providers/auth_providers.dart';

class CompleteAccountPage extends ConsumerStatefulWidget {
  const CompleteAccountPage({super.key});

  @override
  ConsumerState<CompleteAccountPage> createState() =>
      _CompleteAccountPageState();
}

class _CompleteAccountPageState extends ConsumerState<CompleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  UserRole _role = UserRole.talent;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .completeAccountSetup(
            role: _role,
            displayName: _displayName.text.trim(),
          );
      await refreshAuthState(ref);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Complete account setup'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await ref.read(authControllerProvider).signOut();
                    if (context.mounted) context.go('/sign-in');
                  },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'One more step',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Firebase login exists, but EduBridge needs an account type '
                    'and profile before you can continue.',
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.talent,
                        label: Text('Talent'),
                      ),
                      ButtonSegment(
                        value: UserRole.company,
                        label: Text('Company'),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: _busy
                        ? null
                        : (selection) =>
                              setState(() => _role = selection.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayName,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _role == UserRole.company
                          ? 'Company name'
                          : 'Full name',
                    ),
                    validator: (value) => Validators.requiredText(
                      value,
                      label: _role == UserRole.company
                          ? 'Company name'
                          : 'Full name',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _completeSetup,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Complete setup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
