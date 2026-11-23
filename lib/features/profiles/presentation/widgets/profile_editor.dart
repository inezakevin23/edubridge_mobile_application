import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_profile.dart';
import '../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import 'profile_header.dart';
import 'profile_text_field.dart';

class ProfileEditor extends ConsumerStatefulWidget {
  const ProfileEditor({
    super.key,
    required this.userId,
    required this.role,
    required this.email,
    required this.initialName,
    required this.profile,
    required this.isCompany,
  });

  final String userId;
  final String role;
  final String email;
  final String initialName;
  final UserProfile? profile;
  final bool isCompany;

  @override
  ConsumerState<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _photoUrl;
  late final TextEditingController _bio;
  late final TextEditingController _headline;
  late final TextEditingController _location;
  late final TextEditingController _education;
  late final TextEditingController _companyDescription;
  late final TextEditingController _industry;
  late final TextEditingController _website;
  bool _saving = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p?.displayName ?? widget.initialName);
    _photoUrl = TextEditingController(text: p?.photoUrl ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
    _headline = TextEditingController(text: p?.headline ?? '');
    _location = TextEditingController(text: p?.location ?? '');
    _education = TextEditingController(text: p?.education ?? '');
    _companyDescription = TextEditingController(
      text: p?.companyDescription ?? '',
    );
    _industry = TextEditingController(text: p?.industry ?? '');
    _website = TextEditingController(text: p?.website ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _photoUrl.dispose();
    _bio.dispose();
    _headline.dispose();
    _location.dispose();
    _education.dispose();
    _companyDescription.dispose();
    _industry.dispose();
    _website.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _websiteValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      return 'Enter a valid URL beginning with https:// or http://.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profile = UserProfile(
      userId: widget.userId,
      role: widget.role,
      displayName: _name.text.trim(),
      photoUrl: _photoUrl.text.trim(),
      bio: _bio.text.trim(),
      headline: _headline.text.trim(),
      location: _location.text.trim(),
      education: _education.text.trim(),
      companyDescription: _companyDescription.text.trim(),
      industry: _industry.text.trim(),
      website: _website.text.trim(),
      createdAt: widget.profile?.createdAt,
    );
    try {
      await ref.read(saveProfileUseCaseProvider)(profile);
      ref.invalidate(profileByIdProvider(widget.userId));
      ref.invalidate(profileStreamProvider(widget.userId));
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEditing() {
    final profile = widget.profile;
    _name.text = profile?.displayName ?? widget.initialName;
    _photoUrl.text = profile?.photoUrl ?? '';
    _bio.text = profile?.bio ?? '';
    _headline.text = profile?.headline ?? '';
    _location.text = profile?.location ?? '';
    _education.text = profile?.education ?? '';
    _companyDescription.text = profile?.companyDescription ?? '';
    _industry.text = profile?.industry ?? '';
    _website.text = profile?.website ?? '';
    setState(() => _editing = false);
  }

  Map<String, Object?> get _registrationDetails =>
      widget.profile?.registrationDetails ?? const {};

  String _detail(String key, {String fallback = ''}) {
    final value = _registrationDetails[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback.trim();
  }

  String _firstValue(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  List<String> get _profileSkills {
    final skills = _registrationDetails['skills'];
    if (skills is! List) return const [];
    return skills
        .whereType<String>()
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList(growable: false);
  }

  Widget _profileOverview(BuildContext context) {
    final profile = widget.profile;
    final industry = _firstValue([profile?.industry, _detail('industry')]);
    final location = _firstValue([
      profile?.location,
      [
        _detail('city'),
        _detail('country'),
      ].where((value) => value.isNotEmpty).join(', '),
    ]);
    final subtitle = widget.isCompany
        ? _firstValue([industry, _detail('businessType'), 'Company account'])
        : [
            _detail('currentStatus', fallback: 'Talent'),
            _firstValue([_detail('fieldOfStudy'), profile?.headline ?? '']),
          ].where((value) => value.isNotEmpty).join(' · ');
    final about = widget.isCompany
        ? _firstValue([
            profile?.companyDescription,
            _detail('description'),
            profile?.bio,
          ])
        : _firstValue([profile?.bio, profile?.headline]);

    if (widget.isCompany) {
      return _companyProfileOverview(
        industry: industry,
        location: location,
        about: about,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _ProfileBadge(
                label: widget.isCompany ? 'Company account' : 'Talent account',
                isCompany: widget.isCompany,
              ),
            ),
            const SizedBox(height: 10),
            ProfileHeader(
              name: _name.text,
              subtitle: subtitle,
              photoUrl: _photoUrl.text,
              isCompany: widget.isCompany,
            ),
            const SizedBox(height: 14),
            _ProfileSection(
              child: _ContactDetails(
                email: widget.email,
                phone: _detail('phone'),
                location: location,
                website: widget.isCompany
                    ? _firstValue([profile?.website, _detail('website')])
                    : '',
              ),
            ),
            const SizedBox(height: 9),
            _ProfileSection(
              title: widget.isCompany ? 'Company Overview' : 'About',
              child: Text(
                about.isEmpty
                    ? 'Add a short introduction to your profile.'
                    : about,
                style: const TextStyle(
                  color: Color(0xFF8F94A5),
                  fontSize: AppTypography.caption,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 9),
            if (widget.isCompany)
              _companyDetailsSection(industry)
            else ...[
              _talentRecognitionSection(profile),
              const SizedBox(height: 9),
              _talentEducationSection(profile),
              const SizedBox(height: 9),
              _talentSkillsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _companyProfileOverview({
    required String industry,
    required String location,
    required String about,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _CompanyProfileHeading(
              name: _name.text,
              location: location,
              industry: industry,
              photoUrl: _photoUrl.text,
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              backgroundColor: const Color(0xFF111827),
              padding: const EdgeInsets.all(16),
              child: _ContactDetails(
                email: widget.email,
                phone: _detail('phone'),
                location: location,
              ),
            ),
            const SizedBox(height: 12),
            _ProfileSection(
              title: 'Company Overview',
              padding: const EdgeInsets.all(16),
              child: Text(
                about.isEmpty
                    ? 'Add a short introduction to your profile.'
                    : about,
                style: const TextStyle(
                  color: Color(0xFF8F94A5),
                  fontSize: AppTypography.body,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _companyDetailsSection(industry),
          ],
        ),
      ),
    );
  }

  Widget _talentRecognitionSection(UserProfile? profile) {
    final experience = _detail('yearsOfExperience', fallback: '0');
    final years = double.tryParse(experience)
        ?.toStringAsFixed(experience.contains('.') ? 1 : 0);
    return _ProfileSection(
      title: 'Recognition',
      child: Row(
        children: [
          Expanded(
            child: _ProfileMetric(
              label: 'Score points',
              value: (profile?.scorePoints ?? 0).toString(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ProfileMetric(
              label: 'Experience',
              value: '${years ?? '0'} yrs',
            ),
          ),
        ],
      ),
    );
  }

  Widget _talentEducationSection(UserProfile? profile) {
    return _ProfileSection(
      title: 'Education & Work',
      child: _ProfileInfoGrid(
        items: [
          (
            'Institution',
            _detail('institution', fallback: profile?.education ?? ''),
          ),
          ('Field of study', _detail('fieldOfStudy')),
          ('Graduation year', _detail('graduationYear')),
          ('Current status', _detail('currentStatus')),
        ],
      ),
    );
  }

  Widget _talentSkillsSection() {
    final skills = _profileSkills;
    return _ProfileSection(
      title: 'Skills',
      child: skills.isEmpty
          ? const Text(
              'Add your skills to showcase your strengths.',
              style: TextStyle(
                color: Color(0xFF8F94A5),
                fontSize: AppTypography.caption,
              ),
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills
                  .map((skill) => _SkillBadge(label: skill))
                  .toList(growable: false),
            ),
    );
  }

  Widget _companyDetailsSection(String industry) {
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: _ProfileSection(
              title: 'Business Type',
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _detail('businessType', fallback: 'Not provided'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (industry.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      industry,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF85899A),
                        fontSize: AppTypography.caption,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Organization Details',
          padding: const EdgeInsets.all(16),
          child: _ProfileInfoGrid(
            items: [
              (
                'Organization name',
                _detail('organizationName', fallback: _name.text),
              ),
              ('Industry', industry),
              (
                'Website',
                _firstValue([widget.profile?.website, _detail('website')]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Authorized Representative',
          padding: const EdgeInsets.all(16),
          child: _ProfileInfoGrid(
            items: [
              ('Representative', _detail('representativeName')),
              ('Role', _detail('representativeTitle')),
              ('Corporate email', widget.email),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editForm(BuildContext context) {
    final company = widget.isCompany;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ProfileHeader(
                name: _name.text,
                subtitle: widget.email,
                photoUrl: _photoUrl.text,
                isCompany: company,
              ),
              const SizedBox(height: 28),
              Text(
                'Basic information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ProfileTextField(
                controller: _name,
                label: company ? 'Company name' : 'Full name',
                validator: _required,
              ),
              const SizedBox(height: 14),
              ProfileTextField(
                controller: _photoUrl,
                label: 'Profile image URL',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              if (company) ...[
                ProfileTextField(
                  controller: _companyDescription,
                  label: 'Company description',
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                ProfileTextField(controller: _industry, label: 'Industry'),
                const SizedBox(height: 14),
                ProfileTextField(
                  controller: _website,
                  label: 'Company website',
                  keyboardType: TextInputType.url,
                  validator: _websiteValidator,
                ),
              ] else ...[
                ProfileTextField(
                  controller: _headline,
                  label: 'Professional headline',
                  hint: 'e.g. Aspiring Software Developer',
                ),
                const SizedBox(height: 14),
                ProfileTextField(
                  controller: _bio,
                  label: 'About me',
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                ProfileTextField(controller: _location, label: 'Location'),
                const SizedBox(height: 14),
                ProfileTextField(controller: _education, label: 'Education'),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.isCompany;
    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: widget.userId,
        scorePoints: company ? null : widget.profile?.scorePoints ?? 0,
        compactScore: true,
        trailingLabel: company ? 'Post Challenge' : null,
        onTrailingTap: company
            ? () => context.go('/company/challenges/create')
            : null,
        showBackButton: true,
        backFallbackPath: company ? '/company/dashboard' : '/talent/dashboard',
        onEditTap: () =>
            _editing ? _cancelEditing() : setState(() => _editing = true),
        isEditing: _editing,
      ),
      bottomNavigationBar: DashboardNavigation(
        currentIndex: 3,
        isCompany: company,
        onIndexChanged: (index) {
          switch (index) {
            case 0:
              context.go(company ? '/company/dashboard' : '/talent/dashboard');
            case 1:
              context.go(
                company ? '/company/challenges/manage' : '/challenges',
              );
            case 2:
              context.go(
                company ? '/company/submissions' : '/talent/submissions',
              );
            case 3:
              context.go(company ? '/company/profile' : '/talent/profile');
          }
        },
      ),
      body: _editing ? _editForm(context) : _profileOverview(context),
    );
  }
}

class _CompanyProfileHeading extends StatelessWidget {
  const _CompanyProfileHeading({
    required this.name,
    required this.location,
    required this.industry,
    required this.photoUrl,
  });

  final String name;
  final String location;
  final String industry;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Company name' : name.trim();
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 56,
            height: 56,
            child: photoUrl.trim().isEmpty
                ? Container(
                    color: const Color(0xFF392719),
                    alignment: Alignment.center,
                    child: Text(
                      initials.isEmpty ? 'CO' : initials,
                      style: const TextStyle(
                        color: Color(0xFFFFB423),
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF392719),
                      alignment: Alignment.center,
                      child: Text(
                        initials.isEmpty ? 'CO' : initials,
                        style: const TextStyle(
                          color: Color(0xFFFFB423),
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF15372B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Company account',
                  style: TextStyle(
                    color: Color(0xFF56D49B),
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (location.isNotEmpty)
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD8DBE5),
                    fontSize: AppTypography.caption,
                  ),
                ),
              if (industry.isNotEmpty)
                Text(
                  industry,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF85899A),
                    fontSize: AppTypography.caption,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.label, required this.isCompany});

  final String label;
  final bool isCompany;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF392719),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: isCompany ? const Color(0xFFFFB423) : const Color(0xFFC09AFF),
        fontSize: AppTypography.micro,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    this.title,
    this.backgroundColor = const Color(0xFF202434),
    this.padding = const EdgeInsets.all(13),
    required this.child,
  });

  final String? title;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF2A3042)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        child,
      ],
    ),
  );
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails({
    required this.email,
    required this.phone,
    required this.location,
    this.website = '',
  });

  final String email;
  final String phone;
  final String location;
  final String website;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Email', email, Icons.mail_outline_rounded),
      ('Phone', phone, Icons.phone_outlined),
      ('Location', location, Icons.location_on_outlined),
      if (website.isNotEmpty) ('Website', website, Icons.language_rounded),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$3, size: 16, color: const Color(0xFF7F8495)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF818697),
                                fontSize: AppTypography.micro,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$2.isEmpty ? 'Not provided' : item.$2,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE0E2E9),
                                fontSize: AppTypography.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF11141D),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF85899A),
            fontSize: AppTypography.micro,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTypography.title,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProfileInfoGrid extends StatelessWidget {
  const _ProfileInfoGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF818697),
                          fontSize: AppTypography.micro,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$2.isEmpty ? 'Not provided' : item.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE0E2E9),
                          fontSize: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SkillBadge extends StatelessWidget {
  const _SkillBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 92, maxWidth: 220),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF30204E),
      border: Border.all(color: const Color(0xFF7244C2)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFC09AFF),
        fontSize: AppTypography.micro,
      ),
    ),
  );
}
