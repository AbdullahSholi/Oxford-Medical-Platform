import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection_container.dart' as di;
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/order/presentation/bloc/order_detail_bloc.dart';
import '../features/product/presentation/bloc/product_detail_bloc.dart';
import '../features/product/presentation/bloc/product_list_bloc.dart';
import '../features/product/presentation/bloc/search_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/pending_approval_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/notification/presentation/pages/notifications_page.dart';
import '../features/order/presentation/pages/checkout_page.dart';
import '../features/order/presentation/pages/order_detail_page.dart';
import '../features/order/presentation/pages/order_confirmation_page.dart';
import '../features/order/presentation/pages/order_tracking_page.dart';
import '../features/order/presentation/pages/orders_list_page.dart';
import '../features/product/presentation/pages/product_detail_page.dart';
import '../features/product/presentation/pages/product_list_page.dart';
import '../features/product/presentation/pages/search_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/addresses_page.dart';
import '../features/wishlist/presentation/pages/wishlist_page.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnAuthPage = state.matchedLocation.startsWith('/auth');

      if (authState is AuthUnauthenticated && !isOnAuthPage) {
        return '/auth/login';
      }
      if (authState is AuthPendingApproval) {
        return '/auth/pending';
      }
      if (authState is AuthAuthenticated && isOnAuthPage) {
        return '/home';
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      // Auth routes
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpPage(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return ResetPasswordPage(
            email: extra['email'] ?? '',
            otp: extra['otp'] ?? '',
          );
        },
      ),
      GoRoute(path: '/auth/pending', builder: (_, __) => const PendingApprovalPage()),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(
            path: '/categories',
            builder: (_, __) => BlocProvider(
              create: (_) => di.sl<ProductListBloc>(),
              child: const ProductListPage(title: 'Categories'),
            ),
          ),
          GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersListPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),

      // Standalone routes
      GoRoute(
        path: '/products',
        builder: (_, state) => BlocProvider(
          create: (_) => di.sl<ProductListBloc>(),
          child: ProductListPage(
            categoryId: state.uri.queryParameters['categoryId'],
          ),
        ),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) => BlocProvider(
          create: (_) => di.sl<ProductDetailBloc>()
            ..add(ProductDetailFetched(state.pathParameters['id']!)),
          child: ProductDetailPage(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => BlocProvider(
          create: (_) => di.sl<SearchBloc>(),
          child: const SearchPage(),
        ),
      ),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) => BlocProvider(
          create: (_) => di.sl<OrderDetailBloc>()
            ..add(OrderDetailFetched(state.pathParameters['id']!)),
          child: OrderDetailPage(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id/tracking',
        builder: (_, state) => BlocProvider(
          create: (_) => di.sl<OrderDetailBloc>(),
          child: OrderTrackingPage(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id/confirmation',
        builder: (_, state) => OrderConfirmationPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfilePage()),
      GoRoute(path: '/profile/addresses', builder: (_, __) => const AddressesPage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/wishlist', builder: (_, __) => const WishlistPage()),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
