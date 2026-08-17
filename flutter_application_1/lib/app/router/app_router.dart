import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/navigation/presentation/screens/navigation_screen.dart';
import '../../features/parcel/domain/parcel_models.dart';

/// Route names for navigation
abstract final class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String parcelSearch = '/parcel-search';
  static const String parcelDetails = '/parcel-details/:id';
  static const String mapNavigation = '/map-navigation/:parcelId';
  static const String validation = '/validation/:parcelId';
  static const String photoCapture = '/photo-capture';
  static const String syncQueue = '/sync-queue';
  static const String settings = '/settings';
}

/// App router configuration
final appRouterProvider = GoRouter(
  initialLocation: RouteNames.splash,
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.uri}')),
    );
  },
  routes: [
    // Splash screen
    GoRoute(
      path: RouteNames.splash,
      name: 'splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    // Login screen
    GoRoute(
      path: RouteNames.login,
      name: 'login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    // Home screen
    GoRoute(
      path: RouteNames.home,
      name: 'home',
      builder: (context, state) {
        return const HomeScreen();
      },
    ),

    // Parcel search screen
    GoRoute(
      path: RouteNames.parcelSearch,
      name: 'parcel-search',
      builder: (context, state) {
        // Will be replaced with actual ParcelSearchScreen widget
        return const Scaffold(
          body: Center(child: Text('Parcel Search Screen')),
        );
      },
    ),

    // Parcel details screen
    GoRoute(
      path: RouteNames.parcelDetails,
      name: 'parcel-details',
      builder: (context, state) {
        final parcelId = state.pathParameters['id'] ?? '';
        return Scaffold(body: Center(child: Text('Parcel Details: $parcelId')));
      },
    ),

    // Map navigation screen — routes the validator from their current GPS
    // location to a selected parcel. The parcel is passed via `extra`
    // since it carries geometry/data not worth re-fetching by id alone.
    GoRoute(
      path: RouteNames.mapNavigation,
      name: 'map-navigation',
      builder: (context, state) {
        final parcel = state.extra as LandParcel?;
        if (parcel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Navigate')),
            body: const Center(child: Text('No parcel selected.')),
          );
        }
        return NavigationScreen(parcel: parcel);
      },
    ),

    // Validation screen
    GoRoute(
      path: RouteNames.validation,
      name: 'validation',
      builder: (context, state) {
        final parcelId = state.pathParameters['parcelId'] ?? '';
        return Scaffold(body: Center(child: Text('Validation: $parcelId')));
      },
    ),

    // Photo capture screen
    GoRoute(
      path: RouteNames.photoCapture,
      name: 'photo-capture',
      builder: (context, state) {
        // Will be replaced with actual PhotoCaptureScreen widget
        return const Scaffold(
          body: Center(child: Text('Photo Capture Screen')),
        );
      },
    ),

    // Sync queue screen
    GoRoute(
      path: RouteNames.syncQueue,
      name: 'sync-queue',
      builder: (context, state) {
        // Will be replaced with actual SyncQueueScreen widget
        return const Scaffold(body: Center(child: Text('Sync Queue Screen')));
      },
    ),

    // Settings screen
    GoRoute(
      path: RouteNames.settings,
      name: 'settings',
      builder: (context, state) {
        // Will be replaced with actual SettingsScreen widget
        return const Scaffold(body: Center(child: Text('Settings Screen')));
      },
    ),
  ],
);
