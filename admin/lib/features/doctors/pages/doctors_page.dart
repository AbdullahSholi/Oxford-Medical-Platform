import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});
  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  List<dynamic> _doctors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/admin/doctors');
      setState(() { _doctors = (res['data'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    try {
      await context.read<AuthCubit>().apiClient.patch('/admin/doctors/$id/approve');
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor approved'), backgroundColor: Color(0xFF10B981)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _suspend(String id) async {
    try {
      await context.read<AuthCubit>().apiClient.patch('/admin/doctors/$id/suspend');
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor suspended'), backgroundColor: Color(0xFFF59E0B)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _reject(String id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Doctor'),
          content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 3),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Reject')),
          ],
        );
      },
    );
    if (reason == null || reason.trim().length < 5) return;
    try {
      await context.read<AuthCubit>().apiClient.patch('/admin/doctors/$id/reject', data: {'reason': reason.trim()});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Doctors', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                    ? const Center(child: Text('No doctors found'))
                    : Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Specialty')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _doctors.map((d) {
                              final doc = d as Map<String, dynamic>;
                              final status = doc['status'] ?? doc['verificationStatus'] ?? 'pending';
                              return DataRow(cells: [
                                DataCell(Text(doc['fullName'] ?? '')),
                                DataCell(Text(doc['email'] ?? '')),
                                DataCell(Text(doc['specialty'] ?? 'N/A')),
                                DataCell(_buildStatus(status as String)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status != 'approved')
                                      TextButton(onPressed: () => _approve(doc['id'] as String), child: const Text('Approve')),
                                    if (status == 'approved')
                                      TextButton(onPressed: () => _suspend(doc['id'] as String),
                                          child: Text('Suspend', style: TextStyle(color: cs.error))),
                                    if (status == 'pending')
                                      TextButton(onPressed: () => _reject(doc['id'] as String),
                                          child: Text('Reject', style: TextStyle(color: cs.error))),
                                  ],
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(String status) {
    final (color, label) = switch (status) {
      'approved' || 'active' => (const Color(0xFF10B981), 'Approved'),
      'pending' => (const Color(0xFFF59E0B), 'Pending'),
      'rejected' => (const Color(0xFFEF4444), 'Rejected'),
      'suspended' => (const Color(0xFFEF4444), 'Suspended'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
