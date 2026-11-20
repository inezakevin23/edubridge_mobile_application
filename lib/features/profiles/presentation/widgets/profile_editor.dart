import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
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

  @override
  Widget build(BuildContext context) {
    final company = widget.isCompany;
    return Scaffold(
      appBar: AppBar(
        title: Text(company ? 'Company profile' : 'Talent profile'),
      ),
      body: Center(
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
      ),
    );
  }
}
