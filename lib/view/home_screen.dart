
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/token_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/token_viewmodel.dart';

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
  static const Color _primary = Color(0xFF236D96);
  static const Color _background = Color(0xFFC2E9EC);
  static const Color _textColor = Color(0xFF285C7D);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TokenViewModel>().fetchMyTokens(refresh: true);
    });
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
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

    await context.read<AuthViewModel>().logout();

    if (!context.mounted) return;

    context.read<TokenViewModel>().clearTokens();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> _refreshBackend(BuildContext context) async {
    await context.read<TokenViewModel>().fetchMyTokens(refresh: true);
  }

  Future<void> _navigate(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (!mounted) return;

    await context.read<TokenViewModel>().fetchMyTokens(refresh: true);
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

    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }

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

    if (activeTokens.isNotEmpty) {
      return activeTokens.first;
    }

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
    required TokenViewModel tokenViewModel,
    required bool isDark,
    required ColorScheme colors,
  }) {
    final token = _getUpcomingAppointment(
      tokenViewModel.tokens,
      tokenViewModel.selectedToken,
    );

    final isLoading = tokenViewModel.isLoading;
    final hasError = tokenViewModel.error != null;

    final appointmentTime = token?.appointmentTime;
    final doctorName = token?.doctorName?.trim();
    final departmentName = token?.departmentName?.trim();
    final tokenNumber = token?.tokenNumber.trim();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : const Color(0xFFF3FAFF),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF285C7D).withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFD5F1F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Color(0xFF438DA7),
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Appointment',
                  style: TextStyle(
                    color: isDark
                        ? colors.onSurfaceVariant
                        : const Color(0xFF7EA6BC),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),

                if (isLoading &&
                    tokenViewModel.tokens.isEmpty &&
                    tokenViewModel.selectedToken == null) ...[
                  const Row(
                    children: [
                      SizedBox(
                        height: 17,
                        width: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      ),
                      SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          'Loading your appointment...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ] else if (token != null) ...[
                  if (appointmentTime != null)
                    Text(
                      '${_formatAppointmentDate(appointmentTime)} at '
                      '${_formatAppointmentTime(appointmentTime)}',
                      style: TextStyle(
                        color: isDark ? colors.onSurface : _textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      'Appointment time unavailable',
                      style: TextStyle(
                        color: isDark ? colors.onSurface : _textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 7),

                  Text(
                    doctorName != null && doctorName.isNotEmpty
                        ? (doctorName.toLowerCase().startsWith('dr.')
                            ? doctorName
                            : 'Dr. $doctorName')
                        : 'Doctor details unavailable',
                    style: TextStyle(
                      color: isDark
                          ? colors.onSurface
                          : const Color(0xFF53768B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    departmentName != null && departmentName.isNotEmpty
                        ? departmentName
                        : 'Department details unavailable',
                    style: const TextStyle(
                      color: Color(0xFF82A5B8),
                      fontSize: 12,
                    ),
                  ),

                  if (tokenNumber != null && tokenNumber.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Token: $tokenNumber',
                      style: const TextStyle(
                        color: Color(0xFF438DA7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: () => _navigate(
                      context,
                      const MyTokensScreen(),
                    ),
                    child: const Text(
                      'View My Tokens  >',
                      style: TextStyle(
                        color: Color(0xFF6F9BB4),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    isLoading
                        ? 'Loading your appointment...'
                        : hasError
                            ? 'Unable to load appointments'
                            : 'No upcoming appointment',
                    style: TextStyle(
                      color: isDark ? colors.onSurface : _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    hasError
                        ? 'Pull down to refresh and try again.'
                        : 'Book an appointment to see your doctor and visit time here.',
                    style: const TextStyle(
                      color: Color(0xFF82A5B8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  InkWell(
                    onTap: () => _navigate(
                      context,
                      const DepartmentScreen(),
                    ),
                    child: const Text(
                      'Book an Appointment  >',
                      style: TextStyle(
                        color: Color(0xFF6F9BB4),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authViewModel = context.watch<AuthViewModel>();
    final tokenViewModel = context.watch<TokenViewModel>();

    final rawName = authViewModel.user?.name;
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 370,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [colors.surface, colors.surface]
                        : const [
                            Color(0xFFB9E7EA),
                            Color(0xFFD7F4F3),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              color: _primary,
              onRefresh: () => _refreshBackend(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Home',
                              style: TextStyle(
                                color: isDark ? colors.onSurface : _textColor,
                                fontSize: 29,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 23),
                            Text(
                              _greeting(),
                              style: TextStyle(
                                color: isDark
                                    ? colors.onSurfaceVariant
                                    : const Color(0xFF78A8BB),
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? colors.onSurface : _textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 62,
                        width: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Color(0xFF6499AD),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _buildAppointmentCard(
                    context,
                    tokenViewModel: tokenViewModel,
                    isDark: isDark,
                    colors: colors,
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(
                        child: _MainActionButton(
                          title: 'Book Token',
                          icon: Icons.add_rounded,
                          onTap: () => _navigate(
                            context,
                            const DepartmentScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MainActionButton(
                          title: 'Track Queue',
                          icon: Icons.access_time_rounded,
                          onTap: () => _navigate(
                            context,
                            const LiveQueueScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 27),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Departments',
                          style: TextStyle(
                            color: isDark ? colors.onSurface : _textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
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
                            color: _textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                    children: [
                      _DepartmentTile(
                        title: 'General\nMedicine',
                        icon: Icons.medication_rounded,
                        color: const Color(0xFF55BFA4),
                        background: const Color(0xFFE1F8EE),
                        onTap: () => _openDepartment(
                          context,
                          'General Medicine',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Cardiology',
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFF57B8C6),
                        background: const Color(0xFFE0F8FC),
                        onTap: () => _openDepartment(
                          context,
                          'Cardiology',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Pediatrics',
                        icon: Icons.child_care_rounded,
                        color: const Color(0xFFC98796),
                        background: const Color(0xFFFFE9EF),
                        onTap: () => _openDepartment(
                          context,
                          'Pediatrics',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Orthopedics',
                        icon: Icons.accessibility_new_rounded,
                        color: const Color(0xFFB69C38),
                        background: const Color(0xFFFFF4C9),
                        onTap: () => _openDepartment(
                          context,
                          'Orthopedics',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Gynecology',
                        icon: Icons.female_rounded,
                        color: const Color(0xFFA28BD8),
                        background: const Color(0xFFEFE5FF),
                        onTap: () => _openDepartment(
                          context,
                          'Gynecology',
                        ),
                      ),
                      _DepartmentTile(
                        title: 'Dermatology',
                        icon: Icons.face_rounded,
                        color: const Color(0xFFD18D9D),
                        background: const Color(0xFFFFE6ED),
                        onTap: () => _openDepartment(
                          context,
                          'Dermatology',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: true,
                  onTap: () {},
                ),
                _BottomNavItem(
                  icon: Icons.history_rounded,
                  label: 'My Tokens',
                  onTap: () => _navigate(
                    context,
                    const MyTokensScreen(),
                  ),
                ),
                _BottomNavItem(
                  icon: Icons.airport_shuttle_rounded,
                  label: 'Ambulance',
                  onTap: () => _navigate(
                    context,
                    const AmbulanceScreen(),
                  ),
                ),
                _BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () => _navigate(
                    context,
                    const ProfileScreen(),
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: () => _logout(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
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
  final IconData icon;
  final VoidCallback onTap;

  const _MainActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF236D96),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF236D96).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
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

class _DepartmentTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _DepartmentTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 13, 5, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 43, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF53768B),
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
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 25, color: Colors.white),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
