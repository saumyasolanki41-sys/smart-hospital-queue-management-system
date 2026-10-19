import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/queue_viewmodel.dart';
import 'book_token_screen.dart';
import 'live_queue_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Design tokens taken from the UI reference
  static const Color primary = Color(0xFF1B8FB0);
  static const Color primaryDark = Color(0xFF0E5D80);
  static const Color tint = Color(0xFFE4F5FA);
  static const Color ink = Color(0xFF0B2A3F);
  static const Color muted = Color(0xFF7391A1);
  static const Color line = Color(0xFFD8ECF3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<QueueViewModel>().checkBackendStatus();
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openBookToken() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookTokenScreen()),
      );

  void _openLiveQueue() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveQueueScreen()),
      );

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available after API integration.')),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final queue = context.watch<QueueViewModel>();
    final userName = auth.user?.name ?? 'Patient';
    final initials = userName.trim().isEmpty
        ? 'P'
        : userName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD9F2F9), Color(0xFFF1FBFD)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: queue.checkBackendStatus,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const Text(
                  'Home',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
                ),
                const SizedBox(height: 14),

                // Greeting + avatar (tap avatar to logout)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(),
                              style: const TextStyle(fontSize: 13, color: muted)),
                          Text(userName,
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
                        ],
                      ),
                    ),
                    _ServerDot(queue: queue),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Logout',
                      child: GestureDetector(
                        onTap: _logout,
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBFE8F2), Color(0xFF2AA7C7)],
                            ),
                            boxShadow: _shadow,
                          ),
                          child: Text(initials,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Next appointment
                // TODO: replace placeholder values with data from your view model.
                _NextAppointmentCard(
                  doctor: 'Dr. Priya Sharma',
                  department: 'General Medicine',
                  dateTime: '12 Apr 2025 · 10:30 AM',
                  onDetails: () => _showComingSoon('Appointment details'),
                ),
                const SizedBox(height: 16),

                
                Row(
                  children: [
                    Expanded(
                      child: _GradientButton(
                        label: 'Book Token',
                        icon: Icons.confirmation_num_outlined,
                        onTap: _openBookToken,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GradientButton(
                        label: 'Track Queue',
                        icon: Icons.people_alt_outlined,
                        onTap: _openLiveQueue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Departments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Departments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
                    GestureDetector(
                      onTap: () => _showComingSoon('Departments'),
                      child: const Text('View All',
                          style: TextStyle(
                              fontSize: 13, color: primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DeptTile(
                        label: 'General\nMedicine',
                        icon: Icons.add_box_outlined,
                        onTap: () => _showComingSoon('General Medicine'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DeptTile(
                        label: 'Cardiology',
                        icon: Icons.favorite,
                        onTap: () => _showComingSoon('Cardiology'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DeptTile(
                        label: 'Orthopedics',
                        icon: Icons.accessibility_new,
                        onTap: () => _showComingSoon('Orthopedics'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: line)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.white,
            indicatorColor: tint,
            selectedIndex: 0,
            onDestinationSelected: (i) {
              if (i == 1) _showComingSoon('History');
              if (i == 2) _showComingSoon('Notifications');
              if (i == 3) _showComingSoon('Profile');
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: primary),
                label: 'Home',
              ),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
              NavigationDestination(
                  icon: Icon(Icons.notifications_none), label: 'Notifications'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

const List<BoxShadow> _shadow = [
  BoxShadow(color: Color(0x241B8FB0), blurRadius: 18, offset: Offset(0, 6)),
];

class _ServerDot extends StatelessWidget {
  final QueueViewModel queue;
  const _ServerDot({required this.queue});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String tip;
    if (queue.isChecking) {
      color = Colors.blueGrey;
      tip = 'Checking server connection...';
    } else if (queue.isBackendOnline == true) {
      color = Colors.green;
      tip = 'Server connected';
    } else {
      color = Colors.red;
      tip = queue.errorMessage ?? 'Server unavailable. Tap to retry.';
    }

    return Tooltip(
      message: tip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: queue.isChecking ? null : queue.checkBackendStatus,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final String doctor;
  final String department;
  final String dateTime;
  final VoidCallback onDetails;

  const _NextAppointmentCard({
    required this.doctor,
    required this.department,
    required this.dateTime,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomeScreenState.line),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Next Appointment',
              style: TextStyle(fontSize: 11, color: _HomeScreenState.muted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _HomeScreenState.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: _HomeScreenState.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _HomeScreenState.ink)),
                    Text(department,
                        style: const TextStyle(
                            fontSize: 12, color: _HomeScreenState.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _HomeScreenState.muted),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _HomeScreenState.line),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: _HomeScreenState.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(dateTime,
                    style: const TextStyle(
                        fontSize: 12, color: _HomeScreenState.muted)),
              ),
              GestureDetector(
                onTap: onDetails,
                child: const Text('View Details',
                    style: TextStyle(
                        fontSize: 12,
                        color: _HomeScreenState.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF2AA7C7), _HomeScreenState.primaryDark],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x4D1B8FB0), blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeptTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DeptTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _HomeScreenState.line),
            boxShadow: _shadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: _HomeScreenState.tint, shape: BoxShape.circle),
                child: Icon(icon, color: _HomeScreenState.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: _HomeScreenState.ink)),
            ],
          ),
        ),
      ),
    );
  }
}