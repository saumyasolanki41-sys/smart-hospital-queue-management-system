
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/token_model.dart';
import '../controller/auth_controller.dart';
import '../controller/token_controller.dart';
import 'ambulance_screen.dart';
import 'department_screen.dart';
import 'live_queue_screen.dart';
import 'my_tokens_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _skyBlue = Color(0xFF8DB8F5);
  static const Color _background = Color(0xFFE6EFFF);
  static const Color _darkText = Color.fromARGB(255, 5, 26, 37);
  static const Color _muted = Color(0xFF60758A);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TokenController>().fetchMyTokens(refresh: true);
    });
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: _darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await context.read<AuthController>().logout();

    if (!context.mounted) return;

    context.read<TokenController>().clearTokens();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> _refreshBackend(BuildContext context) async {
    await context.read<TokenController>().fetchMyTokens(refresh: true);
  }

  Future<void> _navigate(BuildContext context, Widget screen) async {
    final tokenController = context.read<TokenController>();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (!mounted) return;

    await tokenController.fetchMyTokens(refresh: true);
  }

  void _openDepartment(
    BuildContext context,
    String departmentName,
  ) {
    _navigate(
      context,
      DepartmentScreen(selectedDepartmentName: departmentName),
    );
  }

  bool _isActiveToken(TokenModel token) {
    final status = token.status.trim().toLowerCase();

    return !{
      'cancelled',
      'canceled',
      'completed',
      'complete',
      'served',
      'done',
      'rejected',
      'expired',
    }.contains(status);
  }

  TokenModel? _getUpcomingAppointment(
    List<TokenModel> tokens,
    TokenModel? selectedToken,
  ) {
    final now = DateTime.now();

    final upcoming = tokens.where((token) {
      final time = token.appointmentTime;

      return _isActiveToken(token) &&
          time != null &&
          !time.toLocal().isBefore(now);
    }).toList();

    upcoming.sort((a, b) {
      return a.appointmentTime!
          .toLocal()
          .compareTo(b.appointmentTime!.toLocal());
    });

    if (upcoming.isNotEmpty) return upcoming.first;

    if (selectedToken != null && _isActiveToken(selectedToken)) {
      return selectedToken;
    }

    final activeTokens = tokens.where(_isActiveToken).toList();

    activeTokens.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    if (activeTokens.isNotEmpty) return activeTokens.first;

    return null;
  }

  String _formatAppointmentDate(DateTime dateTime) {
    final date = dateTime.toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) return 'Today';

    if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatAppointmentTime(DateTime dateTime) {
    final date = dateTime.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Widget _buildAppointmentCard(
    BuildContext context, {
    required TokenController tokenController,
    required bool isDark,
    required ColorScheme colors,
  }) {
    final token = _getUpcomingAppointment(
      tokenController.tokens,
      tokenController.selectedToken,
    );

    final isLoading = tokenController.isLoading;
    final hasError = tokenController.error != null;
    final appointmentTime = token?.appointmentTime;

    final rawDoctorName = token?.doctorName?.trim();

    final doctorName =
        rawDoctorName == null || rawDoctorName.isEmpty
            ? null
            : rawDoctorName
                .replaceFirst(
                  RegExp(r'^(dr\.?\s*)+', caseSensitive: false),
                  '',
                )
                .trim();

    final rawDepartmentName = token?.departmentName?.trim();

    final departmentName =
        rawDepartmentName == null ||
                rawDepartmentName.isEmpty ||
                rawDepartmentName.toLowerCase() ==
                    'department not available' ||
                rawDepartmentName.toLowerCase() == 'null'
            ? null
            : rawDepartmentName;

    final tokenNumber = token?.tokenNumber.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _skyBlue.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Next Appointment',
                  style: TextStyle(
                    color: isDark ? colors.onSurface : _darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'APPOINTMENT',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (isLoading &&
              tokenController.tokens.isEmpty &&
              tokenController.selectedToken == null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: _primary),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Loading your appointment...',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          ] else if (token != null) ...[
            if (appointmentTime != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: _primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAppointmentDate(appointmentTime),
                            style: const TextStyle(
                              color: _darkText,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatAppointmentTime(appointmentTime),
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Appointment time unavailable',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 15),

            _appointmentDetail(
              icon: Icons.person_rounded,
              label: doctorName != null && doctorName.isNotEmpty
                  ? 'Dr. $doctorName'
                  : 'Doctor details unavailable',
              isDark: isDark,
              colors: colors,
            ),

            if (departmentName != null) ...[
              const SizedBox(height: 10),
              _appointmentDetail(
                icon: Icons.local_hospital_rounded,
                label: departmentName,
                isDark: isDark,
                colors: colors,
              ),
            ],

            if (tokenNumber != null && tokenNumber.isNotEmpty) ...[
              const SizedBox(height: 10),
              _appointmentDetail(
                icon: Icons.confirmation_number_rounded,
                label: 'Token: $tokenNumber',
                isDark: isDark,
                colors: colors,
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigate(
                  context,
                  const MyTokensScreen(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _skyBlue),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'View My Tokens',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: _background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 34,
                  color: _primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                isLoading
                    ? 'Loading your appointment...'
                    : hasError
                        ? 'Unable to load appointments'
                        : 'No upcoming appointment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? colors.onSurface : _darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasError
                  ? 'Pull down to refresh and try again.'
                  : 'Book an appointment to see your doctor and visit time here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigate(
                  context,
                  const DepartmentScreen(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Book an Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _appointmentDetail({
    required IconData icon,
    required String label,
    required bool isDark,
    required ColorScheme colors,
  }) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? colors.onSurface : _darkText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authController = context.watch<AuthController>();
    final tokenController = context.watch<TokenController>();

    final rawName = authController.user?.name;
    final name = rawName == null || rawName.trim().isEmpty
        ? 'Patient'
        : rawName.trim();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colors.surface : _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFF8DB8F5),
                            Color(0xFFB7D2F8),
                            Color(0xFFE6EFFF),
                            Colors.white,
                            Color(0xFFE8F0FF),
                            Color(0xFF9DBDF2),
                          ],
                          stops: [0.0, 0.16, 0.32, 0.55, 0.78, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                ),
              ),
            ),

            RefreshIndicator(
              color: _primary,
              onRefresh: () => _refreshBackend(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  // Header with profile icon at the top-right.
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Home',
                              style: TextStyle(
                                color: isDark ? colors.onSurface : _darkText,
                                fontSize: 29,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 17),
                            Text(
                              _greeting(),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? colors.onSurface : _darkText,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tapping the profile icon opens ProfileScreen.
                      InkWell(
                        onTap: () => _navigate(
                          context,
                          const ProfileScreen(),
                        ),
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          height: 66,
                          width: 66,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _skyBlue.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF315B91)
                                    .withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 39,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Next appointment
                  _buildAppointmentCard(
                    context,
                    tokenController: tokenController,
                    isDark: isDark,
                    colors: colors,
                  ),

                  const SizedBox(height: 27),

                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: isDark ? colors.onSurface : _darkText,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _MainActionButton(
                          title: 'Book Token',
                          subtitle: 'Book a doctor visit',
                          icon: Icons.add_circle_outline_rounded,
                          onTap: () => _navigate(
                            context,
                            const DepartmentScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MainActionButton(
                          title: 'Track Queue',
                          subtitle: 'Check your queue',
                          icon: Icons.access_time_rounded,
                          onTap: () => _navigate(
                            context,
                            const LiveQueueScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 29),

                  // Departments
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Departments',
                          style: TextStyle(
                            color: isDark ? colors.onSurface : _darkText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _navigate(
                          context,
                          const DepartmentScreen(),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.79,
                    children: [
                      _DepartmentTile(
                        title: 'General\nMedicine',
                        icon: Icons.medication_rounded,
                        onTap: () => _openDepartment(
                          context,
                          'General Medicine',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Cardiology',
                        icon: Icons.favorite_rounded,
                        onTap: () => _openDepartment(
                          context,
                          'Cardiology',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Pediatrics',
                        icon: Icons.child_care_rounded,
                        onTap: () => _openDepartment(
                          context,
                          'Pediatrics',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Orthopedics',
                        icon: Icons.accessibility_new_rounded,
                        onTap: () => _openDepartment(
                          context,
                          'Orthopedics',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Gynecology',
                        icon: Icons.female_rounded,
                        onTap: () => _openDepartment(
                          context,
                          'Gynecology',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Dermatology',
                        icon: Icons.face_rounded,
                        onTap: () => _openDepartment(
                          context,
                          'Dermatology',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Ambulance shortcut
                  Material(
                    color: isDark ? colors.surfaceContainer : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _navigate(
                        context,
                        const AmbulanceScreen(),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _background,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.emergency_rounded,
                                color: _primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ambulance Services',
                                    style: TextStyle(
                                      color: isDark
                                          ? colors.onSurface
                                          : _darkText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Access ambulance assistance',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: _muted,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation: Profile has been removed.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceContainer : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: true,
                  isDark: isDark,
                  onTap: () {},
                ),
                _BottomNavItem(
                  icon: Icons.confirmation_number_outlined,
                  label: 'My Tokens',
                  isDark: isDark,
                  onTap: () => _navigate(
                    context,
                    const MyTokensScreen(),
                  ),
                ),
                _BottomNavItem(
                  icon: Icons.airport_shuttle_rounded,
                  label: 'Ambulance',
                  isDark: isDark,
                  onTap: () => _navigate(
                    context,
                    const AmbulanceScreen(),
                  ),
                ),
                InkWell(
                  onTap: () => _logout(context),
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 23,
                          color: isDark ? colors.onSurface : _muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? colors.onSurface : _muted,
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
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _MainActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MainActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  static const Color primaryBlue = Color.fromARGB(255, 14, 18, 33);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 105),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF315B91).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primaryBlue, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color.fromARGB(255, 5, 26, 37),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF60758A),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DepartmentTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  static const Color primaryBlue = Color.fromARGB(255, 14, 18, 33);
  static const Color darkText = Color.fromARGB(255, 5, 26, 37);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 13, 5, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF315B91).withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 57,
                width: 57,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.selected = false,
  });

  static const Color primaryBlue = Color.fromARGB(255, 14, 18, 33);
  static const Color darkText = Color.fromARGB(255, 5, 26, 37);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final itemColor = selected
        ? primaryBlue
        : isDark
            ? colors.onSurfaceVariant
            : const Color(0xFF60758A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F0FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: itemColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? darkText
                    : isDark
                        ? colors.onSurface
                        : itemColor,
                fontSize: 9,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
