import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/token_model.dart';
import '../models/doctor_model.dart';
import '../controller/auth_controller.dart';
import '../controller/token_controller.dart';
import '../controller/doctor_controller.dart';
import 'ambulance_screen.dart';
import 'department_screen.dart';
import 'doctor_details_screen.dart';
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

  bool _openingDoctorProfile = false;

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

  Future<void> _openDoctorProfile(TokenModel token) async {
    if (_openingDoctorProfile) return;

    setState(() {
      _openingDoctorProfile = true;
    });

    try {
      final doctorController = context.read<DoctorController>();

      await doctorController.fetchDoctors(
        departmentId: token.departmentId,
        refresh: true,
      );

      if (!mounted) return;

      DoctorModel? matchedDoctor;

      for (final doctor in doctorController.doctors) {
        if (doctor.id.trim() == token.doctorId.trim()) {
          matchedDoctor = doctor;
          break;
        }
      }

      if (matchedDoctor == null) {
        final error = doctorController.error;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error != null
                  ? 'Unable to load doctor details. $error'
                  : 'Doctor details could not be found. Please try again.',
            ),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorDetailsScreen(
            doctor: matchedDoctor!,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open doctor profile. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingDoctorProfile = false;
        });
      }
    }
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

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'P';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _skyBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                style: TextStyle(color: _darkText, fontSize: 13),
              ),
            ),
          ] else if (token != null) ...[
            if (appointmentTime != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: _primary,
                        size: 25,
                      ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatAppointmentTime(appointmentTime),
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.access_time_rounded,
                      color: _primary,
                      size: 24,
                    ),
                  ],
                ),
              )
            else
              // const Text(
              //   'Appointment time unavailable',
              //   style: TextStyle(
              //     color: _darkText,
              //     fontSize: 15,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),

            const SizedBox(height: 15),

            Row(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: _primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName != null && doctorName.isNotEmpty
                            ? 'Dr. $doctorName'
                            : 'Doctor details unavailable',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (departmentName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          departmentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _darkText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (tokenNumber != null && tokenNumber.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: _primary,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Token: $tokenNumber',
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _openingDoctorProfile || token.doctorId.trim().isEmpty
                        ? null
                        : () => _openDoctorProfile(token),
                icon: _openingDoctorProfile
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_search_rounded),
                label: Text(
                  _openingDoctorProfile
                      ? 'Loading Doctor Profile...'
                      : 'View Doctor Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _muted,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 9),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigate(
                  context,
                  const MyTokensScreen(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
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
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 124, 124, 146).withValues(alpha: 0.8),
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
                style: const TextStyle(
                  color: _darkText,
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
                color: _darkText,
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
                  foregroundColor: const Color.fromARGB(255, 128, 135, 150),
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
                            Color(0xFF9DBDF2),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: [
             
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => _navigate(
                            context,
                            const ProfileScreen(),
                          ),
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            height: 48,
                            width: 48,
                            child: Center(
                              child: Text(
                                _getInitials(name),
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}!',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 6, 16, 26),
                                fontSize: 25,
                                   fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _darkText,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => _navigate(
                            context,
                            const MyTokensScreen(),
                          ),
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: _primary,
                          ),
                          tooltip: 'My appointments',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'How are you feeling\ntoday?',
                    style: TextStyle(
                      color: _darkText,
                      fontSize: 29,
                      height: 1.15,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

       
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _navigate(
                        context,
                        const DepartmentScreen(),
                      ),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: _muted,
                              size: 23,
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Text(
                                'Search doctors, departments...',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.medical_services_outlined,
                              color: _primary.withValues(alpha: 0.8),
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

             
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Upcoming Appointments',
                          style: TextStyle(
                            color: _darkText,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _navigate(
                          context,
                          const MyTokensScreen(),
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

                  const SizedBox(height: 10),

                  _buildAppointmentCard(
                    context,
                    tokenController: tokenController,
                    isDark: isDark,
                    colors: colors,
                  ),

                  const SizedBox(height: 28),

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
