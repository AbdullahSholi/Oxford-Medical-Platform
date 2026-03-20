import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/extensions/context_extensions.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/categories');
            case 2: context.go('/cart');
            case 3: context.go('/orders');
            case 4: context.go('/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category_outlined),
            activeIcon: const Icon(Icons.category_rounded),
            label: context.l10n.homeCategories,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_outlined),
            activeIcon: const Icon(Icons.shopping_cart_rounded),
            label: context.l10n.cartTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long_rounded),
            label: context.l10n.ordersTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: const Icon(Icons.person_rounded),
            label: context.l10n.profileTitle,
          ),
        ],
      ),
    );
  }
}
