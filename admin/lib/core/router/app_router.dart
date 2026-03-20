import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/orders/pages/orders_page.dart';
import '../../features/orders/pages/order_detail_page.dart';
import '../../features/products/pages/products_page.dart';
import '../../features/products/pages/product_form_page.dart';
import '../../features/doctors/pages/doctors_page.dart';
import '../../features/discounts/pages/discounts_page.dart';
import '../../features/discounts/pages/discount_form_page.dart';
import '../../features/banners/pages/banners_page.dart';
import '../layout/admin_shell.dart';

/// Bridges Bloc stream → ChangeNotifier so GoRouter re-evaluates redirects.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthNotifier(AuthCubit cubit) {
    _sub = cubit.stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

abstract class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    final notifier = _AuthNotifier(authCubit);
    return GoRouter(
      initialLocation: '/',
      refreshListenable: notifier,
      redirect: (context, state) {
        final auth = authCubit.state;
        final isLogin = state.uri.path == '/login';

        if (auth is Unauthenticated || auth is AuthInitial) {
          return isLogin ? null : '/login';
        }
        if (auth is Authenticated && isLogin) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        ShellRoute(
          builder: (_, __, child) => AdminShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
            GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
            GoRoute(path: '/orders/:id', builder: (_, state) => OrderDetailPage(id: state.pathParameters['id']!)),
            GoRoute(path: '/products', builder: (_, __) => const ProductsPage()),
            GoRoute(path: '/products/new', builder: (_, __) => const ProductFormPage()),
            GoRoute(path: '/products/:id/edit', builder: (_, state) => ProductFormPage(id: state.pathParameters['id'])),
            GoRoute(path: '/doctors', builder: (_, __) => const DoctorsPage()),
            GoRoute(path: '/discounts', builder: (_, __) => const DiscountsPage()),
            GoRoute(path: '/discounts/new', builder: (_, __) => const DiscountFormPage()),
            GoRoute(path: '/discounts/:id/edit', builder: (_, state) => DiscountFormPage(id: state.pathParameters['id'])),
            GoRoute(path: '/banners', builder: (_, __) => const BannersPage()),
          ],
        ),
      ],
    );
  }
}
