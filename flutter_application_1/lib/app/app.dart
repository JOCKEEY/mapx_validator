import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Main app widget
class MapXFieldValidatorApp extends ConsumerWidget {
  const MapXFieldValidatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activates automatic retry of locally-saved validations once the
    // device is back online.
    ref.watch(validationSyncCoordinatorProvider);

    return MaterialApp.router(
      title: 'MapX Validator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouterProvider,
    );
  }
}
