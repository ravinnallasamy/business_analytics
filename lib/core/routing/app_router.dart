import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/auth/state/auth_notifier.dart';
import 'package:business_analytics_chat/features/auth/presentation/screens/login_screen.dart';
import 'package:business_analytics_chat/features/chat/presentation/screens/conversation_screen.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/scaffold_with_sidebar.dart';
import 'package:business_analytics_chat/features/home_widget/home_widget_placeholder.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/chat',
    refreshListenable: _GoRouterRefreshStream(authNotifier.stream), // Or simple ValueNotifier if exposed
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
      final isLoggedIn = ref.read(authProvider).isAuthenticated;
      final isLoggingIn = state.uri.path == '/login';
      final isLoading = ref.read(authProvider).isLoading;

      if (isLoading) {
         // Maybe return null or a splash route?
         // For now, if loading, we might show splash. 
         // But authState starts loading = true.
         // Let's just stay put or go to login?
         return null; 
      }

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/chat';
      }
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
            builder: (context, state) => const ConversationScreen(conversationId: null),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return ConversationScreen(conversationId: id);
                },
              ),
            ],
          ),
        ],
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
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

