import 'package:a2abrokerapp/pages/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/brokermanagement/broker_setup_page.dart';
import '../pages/login/login_page.dart';

// ADMIN
import '../pages/dashboard/admin_shell.dart';
import '../pages/dashboard/admindashboard.dart';
import '../pages/listings/listings_screen.dart';
import '../pages/requirements/requirements_screen.dart';
import '../pages/directory/broker_directory_screen.dart';
import '../pages/profile/profile_screen.dart';
import '../pages/a2aforms/a2aforms_screen.dart';
import '../pages/import/import_from_bayut_screen.dart';
import '../pages/import/import_from_propertyfinder_screen.dart';
import '../pages/brokermanagement/broker_management_screen.dart';
import '../pages/tagmanagement/tag_management_screen.dart';
import '../pages/propertytypes/property_types_screen.dart';
import '../pages/locations/locations_screen.dart';

// BROKER
import '../pages/dashboard/broker_shell.dart';
import '../pages/dashboard/brokerdashboard.dart';
import '../pages/dashboard/UnApprovedBrokerDashboard.dart';
import '../services/session_service.dart';

/// ------------------------------------------------------------
/// GLOBAL ROUTER
/// ------------------------------------------------------------

GoRouter createRouter() {
  return GoRouter(
   initialLocation: '/login',
    debugLogDiagnostics: true,

    errorPageBuilder: (context, state) => const MaterialPage(
      child: Scaffold(
        body: Center(
          child: Text('Route not found!'),
        ),
      ),
    ),
    // 🔐 GLOBAL REDIRECT (FIXES REFRESH)
    redirect: (context, state) async {
      final user = await SessionService.loadUser();
      final location = state.uri.path;

      // 1️⃣ Not logged in → only allow /login
      if (user == null) {
        return location == '/login' ? null : '/login';
      }

      // 2️⃣ Logged in → block going back to login ONLY
      if (location == '/login') {
        return user['role'] == 'ADMIN'
            ? '/admin/dashboard'
            : '/broker/dashboard';
      }

      // 3️⃣ 🔑 CRITICAL: allow refresh on current route
      return null;
    },

    routes: [
      // ================= LOGIN =================
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),

      // ================= ADMIN SHELL =================
      ShellRoute(
        builder: (context, state, child) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: SessionService.loadUser(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              return AdminShell(
                userData: snapshot.data!,
                child: child,
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) {
              final user = SessionService.cachedUser!;
              return AdminDashboardContent(userData: user);
            },
          ),


          GoRoute(
            path: '/admin/listings',
            builder: (_, __) =>
                ListingsScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/admin/requirements',
            builder: (_, __) =>
                RequirementsScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/admin/brokers',
            builder: (_, __) =>
                BrokerDirectoryScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (_, __) {
              final user = SessionService.cachedUser!;
              return ProfileScreen(
                brokerId: user['broker']['id'],
                userData: user,
              );
            },
          ),
          GoRoute(
            path: '/admin/forms',
            builder: (_, __) =>
                A2AFormsScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/admin/mytransactions',
            builder: (_, __) =>
                MyTransactionsScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/admin/import/bayut',
            builder: (_, __) =>
                ImportFromBayutScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/admin/import/propertyfinder',
            builder: (_, __) =>
                ImportFromPropertyFinderScreen(
                    userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/admin/broker-management',
            builder: (_, __) => BrokerManagementScreen(),
          ),
          GoRoute(
            path: '/admin/tags',
            builder: (_, __) => TagManagementScreen(),
          ),
          GoRoute(
            path: '/admin/property-types',
            builder: (_, __) => PropertyTypesScreen(),
          ),
          GoRoute(
            path: '/admin/locations',
            builder: (_, __) => LocationManagementScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/broker/setup',
        builder: (context, state) {
          final user = SessionService.cachedUser!;
          return BrokerSetupPage(userData: user);
        },
      ),

      // ================= BROKER SHELL =================
      ShellRoute(
        builder: (context, state, child) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: SessionService.loadUser(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              return BrokerShell(
                userData: snapshot.data!,
                child: child,
              );
            },
          );
        },
        routes: [

          GoRoute(
            path: '/broker/unapproved',
            builder: (context, state) {
              SessionService.loadUser();
              final user = SessionService.cachedUser!;

              print(' user value ->> $user');
              return UnverifiedBrokerDashboard(
                userData: user,

              );
            },
          ),

          GoRoute(
            path: '/broker/dashboard',
            builder: (context, state) {
              final user = SessionService.cachedUser!;

              print(' user value ->> $user');
              final approved =
                  user['broker']['approvalStatus'] == 'APPROVED';

              return approved
                  ? BrokerDashboardContent(userData: user,)
                  : UnverifiedBrokerDashboard(
                userData: user,
              );
            },
          ),
          GoRoute(
            path: '/broker/listings',
            builder: (_, __) =>
                ListingsScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/broker/requirements',
            builder: (_, __) =>
                RequirementsScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/broker/brokers',
            builder: (_, __) =>
                BrokerDirectoryScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/broker/profile',
            builder: (_, __) {
              final user = SessionService.cachedUser!;
              return ProfileScreen(
                brokerId: user['broker']['id'],
                userData: user,
              );
            },
          ),
          GoRoute(
            path: '/broker/forms',
            builder: (_, __) =>
                A2AFormsScreen(userData: SessionService.cachedUser!),
          ),
          GoRoute(
            path: '/broker/mytransactions',
            builder: (_, __) =>
                MyTransactionsScreen(userData: SessionService.cachedUser!),
          ),
        ],

      ),
    ],
  );
}

/*GoRouter createRouter(Map<String, dynamic>? userData) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,

    routes: [

      /// ---------------- LOGIN ----------------
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      /// ================= ADMIN SHELL =================
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(
            userData: state.extra as Map<String, dynamic>,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) =>
                AdminDashboardContent(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/admin/listings',
            builder: (context, state) =>
                ListingsScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/admin/requirements',
            builder: (context, state) =>
                RequirementsScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/admin/brokers',
            builder: (context, state) =>
                BrokerDirectoryScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return ProfileScreen(
                brokerId: data['broker']['id'],
                userData: data,
              );
            },
          ),
          GoRoute(
            path: '/admin/forms',
            builder: (context, state) =>
                A2AFormsScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/admin/import/bayut',
            builder: (context, state) =>
                ImportFromBayutScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/admin/import/propertyfinder',
            builder: (context, state) =>
                ImportFromPropertyFinderScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/admin/broker-management',
            builder: (context, state) => BrokerManagementScreen(),
          ),
          GoRoute(
            path: '/admin/tags',
            builder: (context, state) => TagManagementScreen(),
          ),
          GoRoute(
            path: '/admin/property-types',
            builder: (context, state) => PropertyTypesScreen(),
          ),
          GoRoute(
            path: '/admin/locations',
            builder: (context, state) => LocationManagementScreen(),
          ),
        ],
      ),

      /// ================= BROKER SHELL =================
      ShellRoute(
        builder: (context, state, child) {
          return BrokerShell(
            userData: state.extra as Map<String, dynamic>,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/broker/dashboard',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              final approved =
                  data['broker']['approvalStatus'] == 'APPROVED';

              return approved
                  ? BrokerDashboardContent(userData: data)
                  : UnverifiedBrokerDashboard(
                userData: data,
                onNavigateToBrokers: () {
                  context.go('/broker/brokers', extra: data);
                },
                onNavigateToProfile: () {
                  context.go('/broker/profile', extra: data);
                },
              );
            },
          ),

          GoRoute(
            path: '/broker/listings',
            builder: (context, state) =>
                ListingsScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/broker/requirements',
            builder: (context, state) =>
                RequirementsScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/broker/brokers',
            builder: (context, state) =>
                BrokerDirectoryScreen(userData: state.extra as Map<String, dynamic>),
          ),
          GoRoute(
            path: '/broker/profile',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return ProfileScreen(
                brokerId: data['broker']['id'],
                userData: data,
              );
            },
          ),
          GoRoute(
            path: '/broker/forms',
            builder: (context, state) =>
                A2AFormsScreen(userData: state.extra as Map<String, dynamic>),
          ),
        ],
      ),
    ],
  );
}*/
