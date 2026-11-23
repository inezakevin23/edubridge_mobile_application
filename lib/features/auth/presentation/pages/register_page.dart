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
import '../widgets/public_bottom_navigation.dart';

const _africanCountries = [
  'Algeria',
  'Angola',
  'Benin',
  'Botswana',
  'Burkina Faso',
  'Burundi',
  'Cabo Verde',
  'Cameroon',
  'Central African Republic',
  'Chad',
  'Comoros',
  'Congo',
  "Cote d'Ivoire",
  'Democratic Republic of the Congo',
  'Djibouti',
  'Egypt',
  'Equatorial Guinea',
  'Eritrea',
  'Eswatini',
  'Ethiopia',
  'Gabon',
  'Gambia',
  'Ghana',
  'Guinea',
  'Guinea-Bissau',
  'Kenya',
  'Lesotho',
  'Liberia',
  'Libya',
  'Madagascar',
  'Malawi',
  'Mali',
  'Mauritania',
  'Mauritius',
  'Morocco',
  'Mozambique',
  'Namibia',
  'Niger',
  'Nigeria',
  'Rwanda',
  'Sao Tome and Principe',
  'Senegal',
  'Seychelles',
  'Sierra Leone',
  'Somalia',
  'South Africa',
  'South Sudan',
  'Sudan',
  'Tanzania',
  'Togo',
  'Tunisia',
  'Uganda',
  'Zambia',
  'Zimbabwe',
];

const _studentStatuses = [
  'Student',
  'Graduate',
  'Freelancer',
  'Job Seeker',
  'Professional',
];

const _starterSkills = [
  'UI/UX Design',
  'Python',
  'Data Analysis',
  'Product Strategy',
];

const _businessTypes = [
  'Startup',
  'SME',
  'Corporation',
  'NGO',
  'Government',
  'Educational',
];

const _industries = [
  'E-Commerce',
  'Financial Services',
  'Healthcare',
  'Education',
  'Agriculture',
  'Logistics',
  'Technology',
  'Energy',
  'Manufacturing',
  'Media',
  'Other',
];

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({this.initialRole = UserRole.talent, super.key});

  final UserRole initialRole;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _skillController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  late final UserRole _role;
  final Set<String> _skills = {..._starterSkills};
  int _step = 1;
  String _country = '';
  String _gender = '';
  String _studentStatus = _studentStatuses.first;
  String _businessType = 'Corporation';
  String _industry = '';
  String _skillInput = '';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _busy = false;
  String? _message;

  bool get _isCompany => _role == UserRole.company;
  Color get _accent => _isCompany ? AppTheme.accent : AppTheme.primary;
  List<String> get _stepLabels => _isCompany
      ? const ['Account', 'Organization', 'Documents', 'Representative']
      : const ['Account', 'Personal', 'Professional', 'Verify'];

  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole == UserRole.company
        ? UserRole.company
        : UserRole.talent;
  }

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _skillController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isCompany && _step == 3 && _skills.isEmpty) {
      setState(() => _message = 'Add at least one skill to continue.');
      return;
    }
    setState(() {
      _step++;
      _message = null;
    });
    _scrollToTop();
  }

  void _previousStep() {
    setState(() {
      _step = (_step - 1).clamp(1, 4);
      _message = null;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isCompany &&
        (!_controllers.containsKey('representativeName') ||
            _controller('representativeName').text.trim().isEmpty)) {
      setState(() => _message = 'Complete the representative information.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final account = await ref
          .read(authControllerProvider)
          .register(
            email: _controller('email').text.trim(),
            password: _controller('password').text,
            role: _role,
            displayName: _isCompany
                ? _controller('organizationName').text.trim()
                : _controller('fullName').text.trim(),
            profileDetails: _profileDetails(),
          );
      await refreshAuthState(ref);
      if (mounted) context.go(_dashboardPathForRole(account.role));
    } catch (error) {
      if (mounted) {
        setState(() => _message = authErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    if (_isCompany &&
        Validators.requiredText(
              _controller('organizationName').text,
              label: 'Company name',
            ) !=
            null) {
      setState(
        () =>
            _message = 'Enter your company name before continuing with Google.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final account = await ref
          .read(authControllerProvider)
          .signInWithGoogle(
            _role,
            displayName: _controller(
              _isCompany ? 'organizationName' : 'fullName',
            ).text.trim(),
          );
      await refreshAuthState(ref);
      if (mounted) context.go(_dashboardPathForRole(account.role));
    } catch (error) {
      if (mounted && !isGoogleSignInCancelled(error)) {
        setState(() => _message = authErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, Object?> _profileDetails() {
    const accountFields = {'email', 'password', 'confirmPassword'};
    final details = <String, Object?>{
      for (final entry in _controllers.entries)
        if (!accountFields.contains(entry.key))
          entry.key: entry.value.text.trim(),
      'registrationType': _isCompany ? 'company' : 'student',
    };
    if (_isCompany) {
      details['businessType'] = _businessType;
      details['industry'] = _industry == 'Other'
          ? _controller('otherIndustry').text.trim()
          : _industry;
    } else {
      details['country'] = _country;
      details['gender'] = _gender;
      details['currentStatus'] = _studentStatus;
      details['skills'] = _skills.toList(growable: false);
    }
    return details;
  }

  String _dashboardPathForRole(UserRole role) => switch (role) {
    UserRole.talent => '/talent/dashboard',
    UserRole.company => '/company/dashboard',
    UserRole.admin => '/admin/dashboard',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      bottomNavigationBar: PublicBottomNavigation(
        selectedIndex: _isCompany ? 1 : 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1000) {
              final panelWidth = (constraints.maxWidth * 0.42).clamp(
                390.0,
                544.0,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: panelWidth,
                    child: AuthBrandPanel(
                      title: _isCompany
                          ? "Find Africa's Best Emerging Talent"
                          : 'Your Career Passport Starts Here',
                      description: _isCompany
                          ? 'Post real business challenges and build your talent pipeline with verified, high-performing graduates.'
                          : "Create your profile, solve real challenges, and get hired by Africa's top companies.",
                      accentColor: _accent,
                      isRegistration: true,
                      fillHeight: true,
                    ),
                  ),
                  Expanded(child: _registrationForm()),
                ],
              );
            }
            return _registrationForm();
          },
        ),
      ),
    );
  }

  Widget _registrationForm() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 770),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _registrationHeader(),
              if (MediaQuery.sizeOf(context).width < 1000) ...[
                const SizedBox(height: 18),
                _alternateRegistrationLink(),
              ],
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader(
                      title: _stepTitle,
                      step: _step,
                      icon: _stepIcon,
                    ),
                    const SizedBox(height: 24),
                    _stepContent(),
                    if (_message != null) ...[
                      const SizedBox(height: 18),
                      _messageBox(_message!),
                    ],
                    const SizedBox(height: 28),
                    _stepActions(),
                    if (_step == 1) ...[
                      const SizedBox(height: 24),
                      _googleDivider(),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _registerWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF26334A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepTitle {
    if (_isCompany) {
      return switch (_step) {
        1 => 'Account Information',
        2 => 'Organization Information',
        3 => 'Registration & Verification Documents',
        _ => 'Authorized Representative',
      };
    }
    return switch (_step) {
      1 => 'Account Information',
      2 => 'Personal Information',
      3 => 'Professional Information',
      _ => 'Verification',
    };
  }

  IconData get _stepIcon {
    if (_step == 1) return Icons.key_rounded;
    if (_isCompany) {
      return switch (_step) {
        2 => Icons.business_outlined,
        3 => Icons.description_outlined,
        _ => Icons.people_outline_rounded,
      };
    }
    return switch (_step) {
      2 => Icons.person_outline_rounded,
      3 => Icons.work_outline_rounded,
      _ => Icons.verified_user_outlined,
    };
  }

  Widget _registrationHeader() {
    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: AppBackButton()),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCompany
                            ? Icons.business_outlined
                            : Icons.school_outlined,
                        color: _accent,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCompany
                            ? 'Company Registration'
                            : 'Student Registration',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(_stepLabels.length, (index) {
                      final current = index + 1 == _step;
                      final active = index + 1 <= _step;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == _stepLabels.length - 1 ? 0 : 9,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active
                                      ? _accent
                                      : const Color(0xFF1A2438),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: _accent.withValues(
                                              alpha: 0.42,
                                            ),
                                            blurRadius: 16,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _stepLabels[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: current
                                      ? _accent
                                      : const Color(0xFF7F8AA0),
                                  fontSize: AppTypography.caption,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _headerLink(
                    _isCompany
                        ? 'Registering as a student?'
                        : 'Registering a company?',
                    _isCompany ? 'Register Student' : 'Register Company',
                    _isCompany
                        ? '/student-registration'
                        : '/company-registration',
                    color: _accent,
                  ),
                  const SizedBox(height: 8),
                  _headerLink(
                    _isCompany
                        ? 'Already registered?'
                        : 'Already have an account?',
                    'Sign In',
                    '/login',
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _alternateRegistrationLink() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.06),
        border: Border.all(color: _accent.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        children: [
          Text(
            _isCompany
                ? 'Registering as a student? '
                : 'Registering a company? ',
            style: const TextStyle(color: Color(0xFFAAB4C3), fontSize: AppTypography.body),
          ),
          InkWell(
            onTap: () => context.go(
              _isCompany ? '/student-registration' : '/company-registration',
            ),
            child: Text(
              _isCompany ? 'Register Student' : 'Register Company',
              style: TextStyle(
                color: _accent,
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Text(
            '  ·  Already have an account? ',
            style: TextStyle(color: Color(0xFFAAB4C3), fontSize: AppTypography.body),
          ),
          InkWell(
            onTap: () => context.go('/login'),
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerLink(
    String prompt,
    String action,
    String route, {
    required Color color,
  }) {
    return Wrap(
      alignment: WrapAlignment.end,
      children: [
        Text(
          '$prompt ',
          style: const TextStyle(color: Color(0xFF8D99AE), fontSize: AppTypography.caption),
        ),
        InkWell(
          onTap: () => context.go(route),
          child: Text(
            action,
            style: TextStyle(
              color: color,
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required int step,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            border: Border.all(color: _accent.withValues(alpha: 0.23)),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: _accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          'Step $step/4',
          style: const TextStyle(
            color: Color(0xFF8D99AE),
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _stepContent() {
    if (_step == 1) return _accountStep();
    if (_isCompany) {
      return switch (_step) {
        2 => _companyOrganizationStep(),
        3 => _companyDocumentsStep(),
        _ => _companyRepresentativeStep(),
      };
    }
    return switch (_step) {
      2 => _studentPersonalStep(),
      3 => _studentProfessionalStep(),
      _ => _studentVerificationStep(),
    };
  }

  Widget _accountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField(
          'email',
          'Email',
          hint: _isCompany ? 'company@example.com' : 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
        const SizedBox(height: 18),
        _textField(
          'password',
          'Password (min 8 characters)',
          hint: 'Create a strong password',
          icon: Icons.lock_outline_rounded,
          obscureText: !_passwordVisible,
          onChanged: (_) => setState(() {}),
          validator: Validators.password,
          suffix: IconButton(
            tooltip: _passwordVisible ? 'Hide password' : 'Show password',
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
            icon: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _textField(
          'confirmPassword',
          'Confirm Password',
          hint: 'Repeat password',
          icon: Icons.lock_outline_rounded,
          obscureText: !_confirmPasswordVisible,
          validator: (value) =>
              Validators.confirmPassword(value, _controller('password').text),
          suffix: IconButton(
            tooltip: _confirmPasswordVisible
                ? 'Hide password'
                : 'Show password',
            onPressed: () => setState(
              () => _confirmPasswordVisible = !_confirmPasswordVisible,
            ),
            icon: Icon(
              _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _passwordStrength(),
        const SizedBox(height: 16),
        _infoBox(
          'Password must be at least 8 characters long and include letters and numbers for security.',
        ),
        if (_isCompany) ...[
          const SizedBox(height: 14),
          const Text(
            'Account activation takes up to 48 hours after document verification.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8D99AE), fontSize: AppTypography.caption),
          ),
        ],
      ],
    );
  }

  Widget _passwordStrength() {
    final password = _controller('password').text;
    final score = [
      password.length >= 8,
      RegExp('[A-Z]').hasMatch(password),
      RegExp('[0-9]').hasMatch(password),
      RegExp('[^A-Za-z0-9]').hasMatch(password),
    ].where((condition) => condition).length;
    final label = password.isEmpty
        ? 'Password strength will appear as you type.'
        : score <= 1
        ? 'Weak password — use at least 8 characters, numbers, and a symbol.'
        : score < 4
        ? 'Medium strength — add uppercase letters or a symbol to strengthen.'
        : 'Strong password — ready for account setup.';
    final labelColor = password.isEmpty
        ? const Color(0xFF8D99AE)
        : score <= 1
        ? const Color(0xFFF43F5E)
        : score < 4
        ? AppTheme.accent
        : const Color(0xFF22C55E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                decoration: BoxDecoration(
                  color: index < score ? labelColor : const Color(0xFF1A2438),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _studentPersonalStep() {
    final currentYear = DateTime.now().year;
    final graduationYears = List.generate(
      17,
      (index) => '${currentYear - 8 + index}',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _responsiveFields([
          _textField(
            'fullName',
            'Full Name',
            hint: 'Adebayo Oladipo',
            icon: Icons.person_outline_rounded,
            validator: _requiredValidator('Full name'),
          ),
          _textField(
            'username',
            'Username',
            hint: 'adebayo_o',
            icon: Icons.alternate_email_rounded,
            validator: _requiredValidator('Username'),
          ),
          _textField(
            'phone',
            'Phone Number',
            hint: '+234 800 000 0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _requiredValidator('Phone number'),
          ),
          _dropdown(
            label: 'Country',
            value: _country,
            options: _africanCountries,
            hint: 'Select country',
            icon: Icons.public_outlined,
            validator: _requiredValidator('Country'),
            onChanged: (value) => setState(() => _country = value ?? ''),
          ),
          _textField(
            'city',
            'City',
            hint: 'Lagos',
            icon: Icons.location_on_outlined,
            validator: _requiredValidator('City'),
          ),
          _dateOfBirthField(),
          _dropdown(
            label: 'Gender',
            value: _gender,
            options: const ['Male', 'Female'],
            hint: 'Select gender',
            icon: Icons.person_outline_rounded,
            validator: _requiredValidator('Gender'),
            onChanged: (value) => setState(() => _gender = value ?? ''),
          ),
          _dropdown(
            label: 'Graduation Year',
            value: _controller('graduationYear').text,
            options: graduationYears,
            hint: 'Select year',
            icon: Icons.school_outlined,
            optional: true,
            onChanged: (value) =>
                _controller('graduationYear').text = value ?? '',
          ),
        ]),
      ],
    );
  }

  Widget _dateOfBirthField() {
    final controller = _controller('dateOfBirth');
    return _textField(
      'dateOfBirth',
      'Date of Birth',
      hint: 'YYYY-MM-DD',
      icon: Icons.calendar_month_outlined,
      readOnly: true,
      validator: _requiredValidator('Date of birth'),
      onTap: () async {
        final now = DateTime.now();
        final initial = DateTime(now.year - 20, now.month, now.day);
        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: now,
        );
        if (date != null) {
          controller.text =
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  Widget _studentProfessionalStep() {
    final currentYear = DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Current Status', required: true),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: _studentStatuses
                .map((status) {
                  final selected = _studentStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: selected,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _studentStatus = status),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.16),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFFB894FF)
                            : const Color(0xFF9AA7BA),
                        fontSize: AppTypography.body,
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 16),
        _responsiveFields([
          _textField(
            'institution',
            'Institution / University',
            hint: 'University of Lagos',
            icon: Icons.account_balance_outlined,
            optional: true,
          ),
          _textField(
            'fieldOfStudy',
            'Field of Study',
            hint: 'Computer Science',
            icon: Icons.menu_book_outlined,
            optional: true,
          ),
          _dropdown(
            label: 'Graduation Year',
            value: _controller('graduationYear').text,
            options: List.generate(17, (index) => '${currentYear - 8 + index}'),
            hint: 'Select year',
            icon: Icons.school_outlined,
            optional: true,
            onChanged: (value) =>
                _controller('graduationYear').text = value ?? '',
          ),
          _textField(
            'yearsOfExperience',
            'Years of Experience',
            hint: 'e.g. 2',
            icon: Icons.work_outline_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            optional: true,
          ),
        ]),
        const SizedBox(height: 18),
        _skillsField(),
        const SizedBox(height: 18),
        _textField(
          'portfolio',
          'Portfolio Website',
          hint: 'https://yourportfolio.com',
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          optional: true,
          validator: Validators.website,
        ),
      ],
    );
  }

  Widget _skillsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Skills', required: true),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xF2182237),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _skills.map((skill) {
                  return InputChip(
                    label: Text(skill),
                    onDeleted: _busy
                        ? null
                        : () => setState(() => _skills.remove(skill)),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
                    labelStyle: const TextStyle(
                      color: Color(0xFFB894FF),
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIconColor: const Color(0xFFB894FF),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('registration_skill_input'),
                      controller: _skillController,
                      onChanged: (value) => _skillInput = value,
                      onSubmitted: (_) => _addSkill(),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Add skill...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _busy ? null : _addSkill,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(82, 42),
                      backgroundColor: const Color(0xFF26334A),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ],
              ),
              if (_skills.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Add at least one skill to continue.',
                    style: TextStyle(color: Color(0xFFF43F5E), fontSize: AppTypography.caption),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _addSkill() {
    final skill = _skillInput.trim();
    if (skill.isEmpty) return;
    setState(() {
      if (!_skills.any((value) => value.toLowerCase() == skill.toLowerCase())) {
        _skills.add(skill);
      }
      _skillInput = '';
      _skillController.clear();
    });
  }

  Widget _studentVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoBox(
          'Document uploads are turned off during testing. You can finish creating your account and add verification documents later.',
        ),
        const SizedBox(height: 18),
        const Text(
          'By registering, you agree to our Terms of Service and Privacy Policy.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8D99AE), fontSize: AppTypography.caption),
        ),
      ],
    );
  }

  Widget _companyOrganizationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField(
          'organizationName',
          'Organization Name',
          hint: 'Jumia Inc.',
          icon: Icons.business_outlined,
          validator: _requiredValidator('Organization name'),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Business Type', required: true),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _businessTypes.map((type) {
            final selected = _businessType == type;
            return ChoiceChip(
              label: Text(type),
              selected: selected,
              onSelected: _busy
                  ? null
                  : (_) => setState(() => _businessType = type),
              selectedColor: AppTheme.accent.withValues(alpha: 0.13),
              side: BorderSide(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              labelStyle: TextStyle(
                color: selected
                    ? const Color(0xFFF8B64C)
                    : const Color(0xFF9AA7BA),
                fontSize: AppTypography.body,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _responsiveFields([
          _dropdown(
            label: 'Industry',
            value: _industry,
            options: _industries,
            hint: 'Select industry',
            icon: Icons.work_outline_rounded,
            validator: _requiredValidator('Industry'),
            onChanged: (value) => setState(() => _industry = value ?? ''),
          ),
          _dropdown(
            label: 'Country',
            value: _country,
            options: _africanCountries,
            hint: 'Select country',
            icon: Icons.public_outlined,
            validator: _requiredValidator('Country'),
            onChanged: (value) => setState(() => _country = value ?? ''),
          ),
          if (_industry == 'Other')
            _textField(
              'otherIndustry',
              'Other Industry',
              hint: 'Enter industry',
              icon: Icons.work_outline_rounded,
              validator: _requiredValidator('Industry'),
            ),
          _textField(
            'city',
            'City',
            hint: 'Lagos',
            icon: Icons.location_on_outlined,
            validator: _requiredValidator('City'),
          ),
          _textField(
            'website',
            'Company Website',
            hint: 'https://company.com',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
            optional: true,
            validator: Validators.website,
          ),
          _textField(
            'username',
            'Organization Username',
            hint: 'jumia_inc',
            icon: Icons.alternate_email_rounded,
            validator: _requiredValidator('Username'),
          ),
          _textField(
            'phone',
            'Business Phone Number',
            hint: '+234 800 000 0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _requiredValidator('Phone number'),
          ),
          _textField(
            'description',
            'Company Description',
            hint: 'Briefly describe your organization, mission, and what kind of challenges you plan to post...',
            icon: Icons.notes_rounded,
            maxLines: 4,
            maxLength: 300,
            validator: _requiredValidator('Company description'),
          ),
        ]),
      ],
    );
  }

  Widget _companyDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoBox(
          'Document uploads are turned off during testing. You can finish creating your account and add business documents later.',
        ),
      ],
    );
  }

  Widget _companyRepresentativeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _responsiveFields([
          _textField(
            'representativeName',
            'Full Name',
            hint: 'Chidi Okeke',
            icon: Icons.person_outline_rounded,
            validator: _requiredValidator('Full name'),
          ),
          _textField(
            'representativeTitle',
            'Job Title',
            hint: 'Head of Talent Acquisition',
            icon: Icons.work_outline_rounded,
            validator: _requiredValidator('Job title'),
          ),
          _textField(
            'representativeUsername',
            'Representative Username',
            hint: 'chidi.company',
            icon: Icons.alternate_email_rounded,
            validator: _requiredValidator('Representative username'),
          ),
          _textField(
            'representativePhone',
            'Phone Number',
            hint: '+234 800 000 0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _requiredValidator('Phone number'),
          ),
        ]),
        const SizedBox(height: 18),
        _infoBox(
          'The authorized representative is legally responsible for all challenges and interactions posted through this account.',
        ),
      ],
    );
  }

  Widget _responsiveFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        const spacing = 18.0;
        final fieldWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: fields
              .map((field) => SizedBox(width: fieldWidth, child: field))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _textField(
    String keyName,
    String label, {
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool optional = false,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffix,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(
          label,
          required: !optional && validator != null,
          optional: optional,
        ),
        TextFormField(
          key: Key('registration_$keyName'),
          controller: _controller(keyName),
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          validator: validator,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: Colors.white, fontSize: AppTypography.body),
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            suffix: suffix,
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(
          label,
          required: !optional && validator != null,
          optional: optional,
        ),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          dropdownColor: const Color(0xFF182237),
          style: const TextStyle(color: Colors.white, fontSize: AppTypography.body),
          decoration: _inputDecoration(icon: icon),
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF8E9AAF), fontSize: AppTypography.body),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          validator: validator,
          onChanged: _busy ? null : onChanged,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? icon,
    Widget? suffix,
    bool alignLabelWithHint = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    );
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      suffixIcon: suffix,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xF2182237),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: _accent.withValues(alpha: 0.7)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFF43F5E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.3),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8E9AAF), fontSize: AppTypography.body),
      counterStyle: const TextStyle(color: Color(0xFF8D99AE), fontSize: AppTypography.caption),
    );
  }

  Widget _stepActions() {
    final isWide = MediaQuery.sizeOf(context).width >= 560;
    final backButton = OutlinedButton(
      onPressed: _busy || _step == 1 ? null : _previousStep,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(110, 48),
        backgroundColor: const Color(0xF2182237),
        foregroundColor: Colors.white,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: const Text('Back'),
    );
    final nextButton = FilledButton.icon(
      onPressed: _busy ? null : (_step == 4 ? _register : _nextStep),
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_step == 4 ? 'Register' : 'Next'),
      label: _busy
          ? const SizedBox.shrink()
          : const Icon(Icons.arrow_forward_rounded, size: 18),
      style: FilledButton.styleFrom(
        minimumSize: const Size(130, 48),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: _accent.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.w700),
      ),
    );

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1) backButton else const SizedBox.shrink(),
          nextButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nextButton,
        if (_step > 1) ...[const SizedBox(height: 10), backButton],
      ],
    );
  }

  Widget _infoBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.06),
        border: Border.all(color: _accent.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFAAB4C3),
                fontSize: AppTypography.caption,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: _isCompany ? const Color(0xFFF8D69A) : const Color(0xFFC9B8FF),
          fontSize: AppTypography.body,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _googleDivider() {
    return const Row(
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
    );
  }

  String? Function(String?) _requiredValidator(String label) =>
      (value) => Validators.requiredText(value, label: label);
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false, this.optional = false});

  final String label;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE6E8EF),
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (required)
            const Text(' *', style: TextStyle(color: Color(0xFFF43F5E))),
          if (optional)
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: Text(
                '(Optional)',
                style: TextStyle(color: Color(0xFF8D99AE), fontSize: AppTypography.caption),
              ),
            ),
        ],
      ),
    );
  }
}
