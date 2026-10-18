
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/queue_viewmodel.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QueueViewModel>().checkBackendStatus();
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await context.read<AuthViewModel>().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final queue = context.watch<QueueViewModel>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Hospital Queue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: queue.checkBackendStatus,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Hello, ${user?.name.isNotEmpty == true ? user!.name : 'Patient'}!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your hospital visit with ease.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              _BackendStatusCard(
                isChecking: queue.isChecking,
                isOnline: queue.isBackendOnline,
                errorMessage: queue.errorMessage,
                onRetry: queue.checkBackendStatus,
              ),

              const SizedBox(height: 24),
              Text(
                'Hospital Services',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _ActionCard(
                    title: 'Book Token',
                    subtitle: 'Get your queue token',
                    icon: Icons.confirmation_number_outlined,
                    color: const Color(0xFF1479A4),
                    onTap: () => _showMessage(
                      'Token booking will be connected after the booking API is available.',
                    ),
                  ),
                  _ActionCard(
                    title: 'Live Queue',
                    subtitle: 'Check patients ahead',
                    icon: Icons.people_alt_outlined,
                    color: const Color(0xFF16866A),
                    onTap: () => _showMessage(
                      'Live queue requires the backend queue API.',
                    ),
                  ),
                  _ActionCard(
                    title: 'Departments',
                    subtitle: 'Explore hospital services',
                    icon: Icons.local_hospital_outlined,
                    color: const Color(0xFF8055B7),
                    onTap: () => _showMessage(
                      'Department information will be connected next.',
                    ),
                  ),
                  _ActionCard(
                    title: 'Ambulance ETA',
                    subtitle: 'View arrival predictions',
                    icon: Icons.emergency_outlined,
                    color: const Color(0xFFD97732),
                    onTap: () => _showMessage(
                      'Ambulance arrival prediction requires its API or ML integration.',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                'Queue Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 0,
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 38,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No active token',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Book a token to view your queue details here.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _BackendStatusCard extends StatelessWidget {
  final bool isChecking;
  final bool? isOnline;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _BackendStatusCard({
    required this.isChecking,
    required this.isOnline,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final statusColor = isChecking
        ? colors.primary
        : isOnline == true
            ? Colors.green
            : isOnline == false
                ? colors.error
                : colors.onSurfaceVariant;

    final statusText = isChecking
        ? 'Checking backend connection...'
        : isOnline == true
            ? 'Backend Connected'
            : isOnline == false
                ? 'Backend Unavailable'
                : 'Connection not checked';

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (isChecking)
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: statusColor,
                ),
              )
            else
              Icon(
                isOnline == true
                    ? Icons.cloud_done_outlined
                    : isOnline == false
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_outlined,
                size: 30,
                color: statusColor,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline == true
                        ? 'Your app can reach the server.'
                        : errorMessage ??
                            'Checking the hospital server status.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Retry connection',
              onPressed: isChecking ? null : onRetry,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
