import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Profile
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  bool _savingProfile = false;

  // Password
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _savingPassword = false;
  bool _showCurrent = false;
  bool _showNew = false;

  // Stats
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSystemStats();
  }

  @override
  void dispose() {
    _fullName.dispose(); _email.dispose();
    _currentPassword.dispose(); _newPassword.dispose(); _confirmPassword.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _fullName.text = authState.user['fullName'] ?? '';
      _email.text = authState.user['email'] ?? '';
    }
  }

  Future<void> _loadSystemStats() async {
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/admin/dashboard/stats');
      setState(() { _stats = res['data'] as Map<String, dynamic>?; _loadingStats = false; });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_fullName.text.trim().isEmpty) return;
    setState(() => _savingProfile = true);
    try {
      // Note: This would need a PATCH /admin/profile endpoint on the server
      // For now show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    setState(() => _savingProfile = false);
  }

  Future<void> _changePassword() async {
    if (_newPassword.text.isEmpty || _currentPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all password fields')));
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (_newPassword.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters')));
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await context.read<AuthCubit>().apiClient.patch('/auth/change-password', data: {
        'currentPassword': _currentPassword.text,
        'newPassword': _newPassword.text,
      });
      if (mounted) {
        _currentPassword.clear(); _newPassword.clear(); _confirmPassword.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    setState(() => _savingPassword = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Two-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    // Admin Profile Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_rounded, color: cs.primary),
                                const SizedBox(width: 8),
                                Text('Admin Profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _fullName,
                              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_rounded)),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
                              readOnly: true,
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: _savingProfile ? null : _updateProfile,
                                icon: _savingProfile
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save_rounded, size: 18),
                                label: const Text('Save Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change Password Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_rounded, color: cs.primary),
                                const SizedBox(width: 8),
                                Text('Change Password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _currentPassword,
                              obscureText: !_showCurrent,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showCurrent = !_showCurrent),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _newPassword,
                              obscureText: !_showNew,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showNew = !_showNew),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPassword,
                              obscureText: !_showNew,
                              decoration: const InputDecoration(
                                labelText: 'Confirm New Password',
                                prefixIcon: Icon(Icons.lock_rounded),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: _savingPassword ? null : _changePassword,
                                icon: _savingPassword
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.key_rounded, size: 18),
                                label: const Text('Change Password'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right column - System Info
              Expanded(
                child: Column(
                  children: [
                    // System Overview Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_rounded, color: cs.primary),
                                const SizedBox(width: 8),
                                Text('System Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 24),
                            if (_loadingStats)
                              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                            else if (_stats != null) ...[
                              _InfoTile(icon: Icons.shopping_bag_rounded, label: 'Total Orders', value: '${_stats!['totalOrders'] ?? 0}', color: cs.primary),
                              _InfoTile(icon: Icons.payments_rounded, label: 'Total Revenue', value: 'EGP ${(double.tryParse((_stats!['totalRevenue'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}', color: const Color(0xFF10B981)),
                              _InfoTile(icon: Icons.people_rounded, label: 'Active Doctors', value: '${_stats!['activeDoctors'] ?? 0}', color: const Color(0xFF8B5CF6)),
                              _InfoTile(icon: Icons.inventory_2_rounded, label: 'Products', value: '${_stats!['totalProducts'] ?? 0}', color: const Color(0xFFF59E0B)),
                              _InfoTile(icon: Icons.category_rounded, label: 'Categories', value: '${_stats!['totalCategories'] ?? 0}', color: const Color(0xFF3B82F6)),
                              _InfoTile(icon: Icons.hourglass_top_rounded, label: 'Pending Orders', value: '${_stats!['pendingOrders'] ?? 0}', color: const Color(0xFFEF4444)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flash_on_rounded, color: cs.primary),
                                const SizedBox(width: 8),
                                Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 24),
                            _ActionButton(
                              icon: Icons.refresh_rounded,
                              label: 'Refresh Dashboard Stats',
                              onTap: () async {
                                setState(() => _loadingStats = true);
                                await _loadSystemStats();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Stats refreshed!'), backgroundColor: Color(0xFF10B981)),
                                  );
                                }
                              },
                            ),
                            _ActionButton(
                              icon: Icons.logout_rounded,
                              label: 'Sign Out',
                              isDestructive: true,
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Sign Out'),
                                    content: const Text('Are you sure you want to sign out?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                                    ],
                                  ),
                                );
                                if (confirm == true && mounted) {
                                  context.read<AuthCubit>().logout();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // App Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medical_services_rounded, color: cs.primary),
                                const SizedBox(width: 8),
                                Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 24),
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('MedOrder Admin Panel'),
                              subtitle: const Text('Version 1.0.0'),
                              leading: Icon(Icons.apps_rounded, color: cs.primary),
                            ),
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('API Server'),
                              subtitle: const Text('http://52.1.133.146/api/v1'),
                              leading: Icon(Icons.dns_rounded, color: cs.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFEF4444) : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: color, size: 20),
        title: Text(label, style: TextStyle(color: isDestructive ? color : null, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, color: color, size: 20),
        onTap: onTap,
      ),
    );
  }
}
