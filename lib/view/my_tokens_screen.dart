import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/token_model.dart';
import '../models/doctor_model.dart';
import '../controller/token_controller.dart';
import '../controller/doctor_controller.dart';
import 'token_details_screen.dart';
import 'ambulance_screen.dart';
import 'profile_screen.dart';

class MyTokensScreen extends StatefulWidget {
  const MyTokensScreen({super.key});

  @override
  State<MyTokensScreen> createState() => _MyTokensScreenState();
}

class _MyTokensScreenState extends State<MyTokensScreen> {
  static const Color _primary = Color.fromARGB(255, 21, 28, 54);
  static const Color _background = Color(0xFFE8F0FF);
  static const Color _textColor = Color.fromARGB(255, 5, 26, 37);

  int _selectedTab = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshTokens();
    });
  }

  Future<void> _refreshTokens() async {
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await context.read<TokenController>().fetchMyTokens(
        refresh: true,
      );
    } catch (error, stackTrace) {
      debugPrint('Refresh tokens error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load appointments. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _safeText(dynamic value, [String fallback = 'Not available']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String _getDepartmentName(
    TokenModel token,
    List<DoctorModel> doctors,
  ) {
    final tokenDepartment = token.departmentName?.trim();

    if (tokenDepartment != null &&
        tokenDepartment.isNotEmpty &&
        tokenDepartment.toLowerCase() != 'null') {
      return tokenDepartment;
    }

    for (final doctor in doctors) {
      if (doctor.id.trim() == token.doctorId.trim()) {
        final departmentName = doctor.departmentName?.trim();

        if (departmentName != null &&
            departmentName.isNotEmpty &&
            departmentName.toLowerCase() != 'null') {
          return departmentName;
        }
      }
    }

    return 'Department not available';
  }

  bool _isPast(TokenModel token) {
    final status = _safeText(token.status, 'pending').toLowerCase();

    return status == 'completed' ||
        status == 'served' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'served':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.redAccent;
      case 'in-progress':
      case 'in progress':
        return Colors.orange;
      default:
        return _primary;
    }
  }

  void _openTokenDetails(TokenModel token) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TokenDetailsScreen(token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenController = context.watch<TokenController>();
    final doctorController = context.watch<DoctorController>();
    final doctors = doctorController.doctors;

    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTokens = tokenController.tokens.where((token) {
      return _selectedTab == 0 ? !_isPast(token) : _isPast(token);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? colors.surface : _background,
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [colors.surface, colors.surface]
                  : const [
                      Color(0xFFE6EFFF),
                      Color(0xFFF6F9FF),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: RefreshIndicator(
            color: _primary,
            onRefresh: _refreshTokens,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
             
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.surfaceContainer
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _textColor.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/home');
                          }
                        },
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? colors.onSurface : _textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Tokens',
                            style: TextStyle(
                              color: isDark ? colors.onSurface : _textColor,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Manage your appointments',
                            style: TextStyle(
                              color: Color(0xFF60758A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.surfaceContainer
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

             
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 14, 18, 33),
                        Color(0xFF315B91),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.22),
                        blurRadius: 15,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Healthcare Journey',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTab == 0
                                  ? 'Keep track of your upcoming visits.'
                                  : 'Review your previous appointments.',
                              style: const TextStyle(
                                color: Color(0xFFE6EFFF),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.17),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filteredTokens.length} '
                                '${filteredTokens.length == 1 ? 'appointment' : 'appointments'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          size: 39,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

             
                Container(
                  height: 57,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surfaceContainer : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _textColor.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HistoryTab(
                          title: 'Upcoming',
                          icon: Icons.event_available_rounded,
                          selected: _selectedTab == 0,
                          onTap: () {
                            setState(() => _selectedTab = 0);
                          },
                        ),
                      ),
                      Expanded(
                        child: _HistoryTab(
                          title: 'Past',
                          icon: Icons.history_rounded,
                          selected: _selectedTab == 1,
                          onTap: () {
                            setState(() => _selectedTab = 1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        _selectedTab == 0
                            ? Icons.calendar_month_rounded
                            : Icons.history_rounded,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedTab == 0
                            ? 'Upcoming Appointments'
                            : 'Appointment History',
                        style: TextStyle(
                          color: isDark ? colors.onSurface : _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (tokenController.isLoading &&
                    tokenController.tokens.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 70, bottom: 70),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primary,
                      ),
                    ),
                  )
                else if (tokenController.error != null &&
                    tokenController.tokens.isEmpty)
                  _HistoryMessage(
                    icon: Icons.cloud_off_rounded,
                    message: 'Unable to load appointments',
                    subtitle: 'Please check your connection and try again.',
                    buttonText: 'Try Again',
                    onPressed: _refreshTokens,
                  )
                else if (filteredTokens.isEmpty)
                  _HistoryMessage(
                    icon: _selectedTab == 0
                        ? Icons.event_available_rounded
                        : Icons.history_rounded,
                    message: _selectedTab == 0
                        ? 'No upcoming appointments'
                        : 'No past appointments',
                    subtitle: _selectedTab == 0
                        ? 'Your booked tokens will appear here.'
                        : 'Completed or cancelled tokens will appear here.',
                    buttonText: _selectedTab == 0 ? 'Refresh' : null,
                    onPressed: _selectedTab == 0 ? _refreshTokens : null,
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: Text(
                      '${filteredTokens.length} '
                      '${_selectedTab == 0 ? 'upcoming' : 'past'} '
                      '${filteredTokens.length == 1 ? 'appointment' : 'appointments'}',
                      style: const TextStyle(
                        color: Color(0xFF60758A),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ...filteredTokens.map(
                    (token) => _AppointmentCard(
                      token: token,
                      safeText: _safeText,
                      departmentName: _getDepartmentName(token, doctors),
                      statusColor: _statusColor(
                        _safeText(token.status, 'pending'),
                      ),
                      isPast: _isPast(token),
                      onTap: () => _openTokenDetails(token),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

    
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 24, 33, 66),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(23),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushNamed(context, '/home');
                    }
                  },
                ),
                const _BottomNavItem(
                  icon: Icons.history_rounded,
                  label: 'My Tokens',
                  selected: true,
                ),
                _BottomNavItem(
                  icon: Icons.local_hospital_outlined,
                  label: 'Ambulance',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AmbulanceScreen(),
                      ),
                    );
                  },
                ),
                _BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final TokenModel token;
  final String Function(dynamic, [String]) safeText;
  final String departmentName;
  final Color statusColor;
  final bool isPast;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.token,
    required this.safeText,
    required this.departmentName,
    required this.statusColor,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final doctor = safeText(
      token.doctorName,
      'Doctor not available',
    );

    final department = departmentName;
    final status = safeText(token.status, 'Pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: isDark
              ? colors.outlineVariant
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315B91).withValues(alpha: 0.12),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 57,
                      width: 57,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Color(0xFF315B91),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPast
                                ? 'Previous Appointment'
                                : 'Appointment',
                            style: const TextStyle(
                              color: Color(0xFF60758A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            doctor,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? colors.onSurface
                                  : const Color.fromARGB(255, 5, 26, 37),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            department,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF60758A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF60758A),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      color: Color(0xFF315B91),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Token number',
                      style: TextStyle(
                        color: Color(0xFF60758A),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        safeText(token.tokenNumber),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? colors.onSurface
                              : const Color.fromARGB(255, 5, 26, 37),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 10,
                      color: Color(0xFF60758A),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'Appointment status',
                      style: TextStyle(
                        color: Color(0xFF60758A),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: Color.fromARGB(255, 14, 18, 33),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'View Appointment Details',
                        style: TextStyle(
                          color: Color.fromARGB(255, 14, 18, 33),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryTab({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color.fromARGB(255, 14, 18, 33)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? Colors.white
                  : const Color(0xFF60758A),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFF60758A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _HistoryMessage({
    required this.icon,
    required this.message,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.fromLTRB(22, 35, 22, 32),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? colors.outlineVariant
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 85,
            width: 85,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF315B91),
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? colors.onSurface
                  : const Color.fromARGB(255, 5, 26, 37),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF60758A),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(buttonText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 14, 18, 33),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
