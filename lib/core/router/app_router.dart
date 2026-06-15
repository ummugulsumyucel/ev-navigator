import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_completion_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/battery/presentation/screens/battery_health_screen.dart';
import '../../features/community/presentation/screens/community_feed_screen.dart';
import '../../features/cost/presentation/screens/cost_calculator_screen.dart';
import '../../features/home/presentation/screens/home_dashboard_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/map/presentation/screens/station_detail_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/service/presentation/screens/service_map_screen.dart';
import '../../features/trip_planner/presentation/screens/trip_planner_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_screen.dart';
import '../widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateStreamProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final path = state.matchedLocation;

      final isAuthRoute = path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/splash';

      if (path == '/splash') return null;

      if (!isLoggedIn && !isAuthRoute) return '/login';

      if (isLoggedIn) {
        if (user.needsEmailVerification && path != '/verify-email') {
          return '/verify-email';
        }
        if (!user.needsEmailVerification &&
            user.needsProfileCompletion &&
            path != '/complete-profile') {
          return '/complete-profile';
        }
        if (isAuthRoute ||
            path == '/verify-email' ||
            path == '/complete-profile') {
          if (!user.needsEmailVerification && !user.needsProfileCompletion) {
            return '/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (_, __) => const ProfileCompletionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeDashboardScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
          GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          GoRoute(
            path: '/planner',
            builder: (_, __) => const TripPlannerScreen(),
          ),
          GoRoute(
            path: '/community',
            builder: (_, __) => const CommunityFeedScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/map/station/:id',
        builder: (_, state) => StationDetailScreen(
          stationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/battery',
        builder: (_, __) => const BatteryHealthScreen(),
      ),
      GoRoute(
        path: '/cost',
        builder: (_, __) => const CostCalculatorScreen(),
      ),
      GoRoute(
        path: '/service',
        builder: (_, __) => const ServiceMapScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (_, __) => const VehiclesScreen(),
      ),
      GoRoute(
        path: '/vehicles/add',
        builder: (_, __) => const AddVehicleScreen(),
      ),
    ],
  );
});

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateStreamProvider);

    auth.whenData((user) {
      Future.microtask(() {
        if (!context.mounted) return;
        if (user == null) {
          context.go('/login');
        } else if (user.needsEmailVerification) {
          context.go('/verify-email');
        } else if (user.needsProfileCompletion) {
          context.go('/complete-profile');
        } else {
          context.go('/home');
        }
      });
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.electric_car, size: 64, color: Color(0xFF00D26A)),
            SizedBox(height: 16),
            Text(
              'EV Navigator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
