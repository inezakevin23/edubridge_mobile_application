import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/preferences/domain/entities/app_preferences.dart';
import 'features/preferences/presentation/providers/preferences_providers.dart';

class EduBridgeApp extends ConsumerWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preferences = ref.watch(preferencesControllerProvider).asData?.value;
    return MaterialApp.router(
      title: 'EduBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: toMaterialThemeMode(
        preferences?.themeMode ?? AppThemeMode.dark,
      ),
      routerConfig: router,
    );
  }
}
