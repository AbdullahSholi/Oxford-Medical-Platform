import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/cubit/auth_cubit.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/'),
    _NavItem(icon: Icons.shopping_bag_rounded, label: 'Orders', path: '/orders'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Products', path: '/products'),
    _NavItem(icon: Icons.category_rounded, label: 'Categories', path: '/categories'),
    _NavItem(icon: Icons.people_rounded, label: 'Doctors', path: '/doctors'),
    _NavItem(icon: Icons.discount_rounded, label: 'Discounts', path: '/discounts'),
    _NavItem(icon: Icons.campaign_rounded, label: 'Banners', path: '/banners'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: cs.surface,
            child: Column(
              children: [
                // Logo
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: cs.primary, size: 28),
                      const SizedBox(width: 10),
                      Text('MedOrder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Nav items
                ...List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final selected = currentPath == item.path;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: ListTile(
                      leading: Icon(item.icon, color: selected ? cs.primary : cs.onSurfaceVariant, size: 22),
                      title: Text(item.label, style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? cs.primary : cs.onSurface,
                        fontSize: 14,
                      )),
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: selected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
                      onTap: () => context.go(item.path),
                    ),
                  );
                }),
                const Spacer(),
                const Divider(height: 1),
                // User info + logout
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final name = state is Authenticated ? (state.user['fullName'] ?? 'Admin') : 'Admin';
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.primaryContainer,
                          child: Text(name.toString().substring(0, 1).toUpperCase(),
                              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(name.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        trailing: IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          tooltip: 'Logout',
                          onPressed: () => context.read<AuthCubit>().logout(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Vertical divider
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: Container(
              color: cs.surfaceContainerLowest,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
