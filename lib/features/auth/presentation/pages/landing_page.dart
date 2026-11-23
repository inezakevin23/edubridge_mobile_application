import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../challenges/domain/entities/challenge.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../widgets/public_bottom_navigation.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const PublicBottomNavigation(selectedIndex: 0),
      body: Stack(
        children: [
          const Positioned(
            top: -180,
            left: -180,
            child: _AmbientGlow(size: 560, opacity: 0.18),
          ),
          const Positioned(
            top: 460,
            right: -260,
            child: _AmbientGlow(size: 540, opacity: 0.1),
          ),
          CustomScrollView(
            slivers: [
              const _LandingNavigation(),
              const SliverToBoxAdapter(child: _HeroSection()),
              const SliverToBoxAdapter(child: _FeaturesSection()),
              const SliverToBoxAdapter(child: _LatestChallengesSection()),
              const SliverToBoxAdapter(child: _LandingFooter()),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandingNavigation extends StatelessWidget {
  const _LandingNavigation();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 72,
      backgroundColor: AppTheme.pageBackground.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: InkWell(
          onTap: () => context.go('/'),
          borderRadius: BorderRadius.circular(12),
          child: const _Brand(),
        ),
      ),
      actions: [
        if (isWide) ...[
          _NavigationLink(
            label: 'For Interns',
            onPressed: () => context.go('/talent/dashboard'),
          ),
          _NavigationLink(
            label: 'For Companies',
            onPressed: () => context.go('/company/dashboard'),
          ),
          _NavigationLink(
            label: 'Challenges',
            onPressed: () => context.go('/challenges'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.go('/register'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Get Started'),
          ),
        ] else
          PopupMenuButton<String>(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu_rounded),
            onSelected: (route) => context.go(route),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: '/talent/dashboard',
                child: Text('For Interns'),
              ),
              PopupMenuItem(
                value: '/company/dashboard',
                child: Text('For Companies'),
              ),
              PopupMenuItem(value: '/challenges', child: Text('Challenges')),
              PopupMenuItem(value: '/login', child: Text('Sign In')),
              PopupMenuItem(value: '/register', child: Text('Get Started')),
            ],
          ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            'assets/images/edubridge-logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'EduBridge',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTypography.title,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NavigationLink extends StatelessWidget {
  const _NavigationLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF9AA7BA),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: Text(label),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 800;
    final headingSize = width >= 1100
        ? 64.0
        : width >= 800
        ? 52.0
        : 38.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, isWide ? 88 : 64, 24, isWide ? 84 : 68),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18233D),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFF283655)),
                ),
                child: const Text(
                  'Bridging the gap between education and employment in Africa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFACC15),
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (isWide)
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: headingSize,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Transforming Real-World\nChallenges into ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: _GradientText(
                          'Career Opportunities',
                          fontSize: headingSize,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Column(
                  children: [
                    Text(
                      'Transforming Real-World\nChallenges into',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: headingSize,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    _GradientText(
                      'Career Opportunities',
                      fontSize: headingSize,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: const Text(
                  'Connect with top companies by solving real business problems. earn reputation, and fast-track your career across the continent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9AA7BA),
                    fontSize: AppTypography.title,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Flex(
                direction: width >= 560 ? Axis.horizontal : Axis.vertical,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeroButton(
                    label: 'Start Solving Challenges',
                    route: '/challenges',
                    primary: true,
                    expand: width < 560,
                  ),
                  SizedBox(
                    width: width >= 560 ? 20 : 0,
                    height: width >= 560 ? 0 : 14,
                  ),
                  _HeroButton(
                    label: 'Post a Challenge',
                    route: '/company/challenges/create',
                    primary: false,
                    expand: width < 560,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.fontSize,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFFB923C)],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.12,
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.route,
    required this.primary,
    required this.expand,
  });

  final String label;
  final String route;
  final bool primary;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final button = primary
        ? FilledButton(
            onPressed: () => context.go(route),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              backgroundColor: const Color(0xFF8B5CF6),
              shadowColor: const Color(0x4D6D28D9),
              elevation: 8,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(label),
          )
        : FilledButton(
            onPressed: () => context.go(route),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              backgroundColor: const Color(0xFF1A243D),
              foregroundColor: Colors.white,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    _HomeFeature(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Learn by doing',
      description: 'Solve real business problems and build practical experience as you learn.',
    ),
    _HomeFeature(
      icon: Icons.business_outlined,
      title: 'Connect with companies',
      description: 'Work with organizations seeking innovative solutions to real challenges.',
    ),
    _HomeFeature(
      icon: Icons.workspace_premium_outlined,
      title: 'Showcase your skills',
      description:
          'Build proof of your abilities through work that makes a difference.',
    ),
    _HomeFeature(
      icon: Icons.trending_up_rounded,
      title: 'Grow your career',
      description: 'Earn recognition and fast-track your journey from education to employment.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Why EduBridge',
                style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bridging Education and Employment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.sizeOf(context).width >= 700 ? 42 : 30,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Text(
                  'We connect ambitious students, graduates, freelancers, job seekers and professionals with organizations seeking innovative solutions, creating value for both education and business.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9AA7BA),
                    fontSize: AppTypography.title,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 42),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 620
                      ? 2
                      : 1;
                  const spacing = 20.0;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _features
                        .map(
                          (feature) => SizedBox(
                            width: itemWidth,
                            child: _FeatureCard(feature: feature),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFeature {
  const _HomeFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _HomeFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        border: Border.all(color: const Color(0xFF25334D)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 22),
          Text(
            feature.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feature.description,
            style: const TextStyle(color: Color(0xFF9AA7BA), height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _LatestChallengesSection extends ConsumerWidget {
  const _LatestChallengesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(openChallengesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: isWide
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1F8B5CF6),
                                border: Border.all(
                                  color: const Color(0x338B5CF6),
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: Color(0xFFA879FF),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Latest Opportunities',
                                    style: TextStyle(
                                      color: Color(0xFFA879FF),
                                      fontSize: AppTypography.body,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Challenges interns can solve now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWide ? 38 : 30,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Explore fresh real-world briefs from partner companies and start building proof of your skills.',
                              style: TextStyle(
                                color: Color(0xFF9AA7BA),
                                fontSize: AppTypography.title,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 20),
                      SizedBox(
                        width: 180,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/challenges'),
                          icon: const Text('Browse all'),
                          label: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF8B5CF6),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              challengesAsync.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
                error: (error, stackTrace) => _ChallengeLoadError(
                  onRetry: () => ref.invalidate(openChallengesProvider),
                ),
                data: (challenges) {
                  final latest = challenges
                      .where((challenge) => !challenge.isPastDeadline)
                      .take(3)
                      .toList(growable: false);
                  if (latest.isEmpty) {
                    return const _NoLatestChallenges();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1000
                          ? 3
                          : constraints.maxWidth >= 650
                          ? 2
                          : 1;
                      const spacing = 20.0;
                      final itemWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: latest
                            .map(
                              (challenge) => SizedBox(
                                width: itemWidth,
                                child: _LatestChallengeCard(
                                  challenge: challenge,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestChallengeCard extends StatelessWidget {
  const _LatestChallengeCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final tags = [
      challenge.category,
      ...challenge.requiredSkills,
    ].where((tag) => tag.trim().isNotEmpty).take(3);

    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111A2C), Color(0xFF171B38)],
        ),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF26334A),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Color(0xFFA879FF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        challenge.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTypography.title,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map((tag) => _ChallengeTag(label: tag))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x12FFFFFF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.cashPrize.isEmpty
                        ? 'No cash prize'
                        : 'Cash prize: ${challenge.cashPrize}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (challenge.estimatedDuration.isNotEmpty) ...[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Color(0xFF9AA7BA),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      challenge.estimatedDuration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9AA7BA),
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/challenges/${challenge.id}'),
              icon: const Text('View Challenge'),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA879FF),
                backgroundColor: const Color(0x1F8B5CF6),
                side: const BorderSide(color: Color(0x1A8B5CF6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeTag extends StatelessWidget {
  const _ChallengeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0x0DFFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFAAB4C3),
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoLatestChallenges extends StatelessWidget {
  const _NoLatestChallenges();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        border: Border.all(color: const Color(0xFF25334D)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'New opportunities are on the way. Check back soon or browse all challenges.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF9AA7BA), height: 1.6),
      ),
    );
  }
}

class _ChallengeLoadError extends StatelessWidget {
  const _ChallengeLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        border: Border.all(color: const Color(0xFF25334D)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Latest opportunities could not be loaded.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA7BA)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Divider(color: Color(0xFF25334D)),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 12,
                children: [
                  Text(
                    '© $year EduBridge Africa',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: AppTypography.body,
                    ),
                  ),
                  const Text(
                    'Built by Ineza Kevin',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: AppTypography.body),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF6D28D9).withValues(alpha: opacity),
                const Color(0xFF6D28D9).withValues(alpha: opacity * 0.35),
                Colors.transparent,
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
