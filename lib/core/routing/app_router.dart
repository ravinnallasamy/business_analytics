import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/auth/state/auth_notifier.dart';
import 'package:business_analytics_chat/features/auth/presentation/screens/login_screen.dart';
import 'package:business_analytics_chat/features/auth/presentation/screens/splash_screen.dart';
import 'package:business_analytics_chat/features/chat/presentation/screens/conversation_screen.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/scaffold_with_sidebar.dart';
import 'package:business_analytics_chat/features/home_widget/home_widget_placeholder.dart';
import 'package:business_analytics_chat/modules/scheduler/screens/scheduler_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login', // Start at login, redirect will send authenticated users to /chat
    refreshListenable: routerNotifier,
    // But Notifier stream is available
    // Actually, simpler: Since we watch authState inside the provider, 
    // simply rebuilding the router on state change is NOT ideal (loses nav stack).
    // Correct way: use refreshListenable or redirect logic. 
    // With Riverpod, we often create a listenable wrapper.
    // For simplicity with basic Notifier, we can just use the redirect directly and let GoRouter re-evaluate when `ref.watch` triggers a rebuild of THIS provider?
    // No, GoRouter instance shouldn't be rebuilt constantly.
    
    // BETTER APPROACH:
    // Make `appRouterProvider` a `Provider` but pass a listenable.
    // However, `authProvider` is a `NotifierProvider`.
    // Let's implement a simple redirect logic based on `ref.read` inside redirect, 
    // and use `refreshListenable` pointing to a custom notifier or just accept the rebuild if we key it? No.
    
    // Standard Riverpod+GoRouter pattern:
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final currentPath = state.uri.path;

      // Show splash screen while checking authentication
      if (isLoading) {
        if (currentPath != '/splash') {
          return '/splash';
        }
        return null;
      }

      // Auth check complete - redirect based on auth status
      if (!isLoggedIn) {
        // Not authenticated - show login unless already there
        if (currentPath != '/login') {
          debugPrint('🚧 Router: Redirecting to /login because user is not authenticated.');
          return '/login';
        }
      } else {
        // Authenticated - redirect to chat if on login or splash
        if (currentPath == '/login' || currentPath == '/splash') {
          debugPrint('🚧 Router: Redirecting to /chat because user is authenticated.');
          return '/chat';
        }
      }
      
      // Deep Link Fallback (Android Native passing full URI)
      final fullUriStr = state.uri.toString();
      if (fullUriStr.contains('chat/new') || fullUriStr.contains('chat/last')) {
         debugPrint('🚧 Router: Intercepting Deep Link $fullUriStr -> /chat');
         return '/chat'; // Force a new chat session instead of last
      }
      
      debugPrint('🚧 Router: No redirect needed for path: $currentPath');
      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithSidebar(child: child);
        },
        routes: [
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ConversationScreen(key: ValueKey('new'), conversationId: null),
            routes: [
              GoRoute(
                path: 'last',
                builder: (context, state) => const ConversationScreen(key: ValueKey('last'), conversationId: 'last'),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  if (id == 'last') {
                      return const ConversationScreen(key: ValueKey('last'), conversationId: 'last');
                  }
                  return ConversationScreen(key: ValueKey(id), conversationId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/scheduler',
            builder: (context, state) => const SchedulerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home_widget',
        builder: (context, state) => const HomeWidgetPlaceholder(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
    debugLogDiagnostics: true, // Enable Router logging
  );
});


class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}


