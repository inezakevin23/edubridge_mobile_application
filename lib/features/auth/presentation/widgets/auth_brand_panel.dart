import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({
    super.key,
    required this.title,
    required this.description,
    this.accentColor = AppTheme.primary,
    this.isRegistration = false,
    this.fillHeight = false,
  });

  final String title;
  final String description;
  final Color accentColor;
  final bool isRegistration;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: isRegistration ? 30 : 44,
      fontWeight: FontWeight.w800,
      height: isRegistration ? 1.18 : 1.22,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE6182236),
        gradient: isRegistration
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF20194E),
                  Color(0xFF162338),
                  Color(0xFF0F172A),
                ],
              )
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -230,
            left: -250,
            child: _Glow(color: accentColor, size: 640, opacity: 0.18),
          ),
          Positioned(
            bottom: -240,
            right: -210,
            child: _Glow(
              color: const Color(0xFF4338CA),
              size: 560,
              opacity: 0.12,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: fillHeight ? 52 : 28,
              vertical: fillHeight ? 52 : 32,
            ),
            child: Column(
              mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/edubridge-logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'EduBridge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (fillHeight && isRegistration) const Spacer(),
                SizedBox(
                  height: isRegistration
                      ? (fillHeight ? 0 : 32)
                      : (fillHeight ? 80 : 32),
                ),
                Text(title, style: titleStyle),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFA6B1C4),
                      fontSize: AppTypography.title,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.opacity});

  final Color color;
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
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.25),
                Colors.transparent,
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
      ),
    );
  }
}
