
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/token_model.dart';
import '../viewmodels/token_viewmodel.dart';
import 'token_details_screen.dart';
import 'ambulance_screen.dart';
import 'profile_screen.dart';

class MyTokensScreen extends StatefulWidget {
  const MyTokensScreen({super.key});

  @override
  State<MyTokensScreen> createState() => _MyTokensScreenState();
}

class _MyTokensScreenState extends State<MyTokensScreen> {
  static const Color _primary = Color(0xFF236D96);
  static const Color _background = Color(0xFFC2E9EC);
  static const Color _textColor = Color(0xFF285C7D);

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TokenViewModel>().fetchMyTokens(refresh: true);
    });
  }

  Future<void> _refreshTokens() async {
    await context.read<TokenViewModel>().fetchMyTokens(refresh: true);
  }

  String _safeText(dynamic value, [String fallback = 'Not available']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
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
    final viewModel = context.watch<TokenViewModel>();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTokens = viewModel.tokens.where((token) {
      return _selectedTab == 0 ? !_isPast(token) : _isPast(token);
    }).toList();

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
              height: 400,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [colors.surface, colors.surface]
                        : const [
                            Color(0xFFB9E5E9),
                            Color(0xFFD2F0F0),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            RefreshIndicator(
              color: _primary,
              onRefresh: _refreshTokens,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 115),
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/home');
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _textColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'My Tokens',
                          style: TextStyle(
                            color: isDark ? colors.onSurface : _textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh appointments',
                        onPressed:
                            viewModel.isLoading ? null : _refreshTokens,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  
                  Container(
                    height: 58,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceContainer
                          : const Color(0xFFF1F9FF),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: _textColor.withValues(alpha: 0.16),
                          blurRadius: 7,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _HistoryTab(
                            title: 'Upcoming',
                            selected: _selectedTab == 0,
                            onTap: () {
                              setState(() => _selectedTab = 0);
                            },
                          ),
                        ),
                        Expanded(
                          child: _HistoryTab(
                            title: 'Past',
                            selected: _selectedTab == 1,
                            onTap: () {
                              setState(() => _selectedTab = 1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (viewModel.isLoading && viewModel.tokens.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _primary,
                        ),
                      ),
                    )
                  else if (viewModel.error != null &&
                      viewModel.tokens.isEmpty)
                    _HistoryMessage(
                      icon: Icons.error_outline_rounded,
                      message: viewModel.error.toString(),
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
                      buttonText: _selectedTab == 0
                          ? 'Refresh'
                          : null,
                      onPressed: _selectedTab == 0
                          ? _refreshTokens
                          : null,
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(
                        '${filteredTokens.length} ${_selectedTab == 0 ? 'upcoming' : 'past'} '
                        '${filteredTokens.length == 1 ? 'appointment' : 'appointments'}',
                        style: TextStyle(
                          color: isDark
                              ? colors.onSurfaceVariant
                              : const Color(0xFF729DB2),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ...filteredTokens.map(
                      (token) => _AppointmentCard(
                        token: token,
                        safeText: _safeText,
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
          ],
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 9,
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
                  label: 'History',
                  selected: true,
                ),
                _BottomNavItem(
                  icon: Icons.notifications_none_rounded,
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

class _HistoryTab extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF236D96) : Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color(0xFF356D8D),
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
  final Color statusColor;
  final bool isPast;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.token,
    required this.safeText,
    required this.statusColor,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final doctor = safeText(token.doctorName, 'Doctor not available');
    final department =
        safeText(token.departmentName, 'Department not available');
    final status = safeText(token.status, 'Pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : const Color(0xFFF1F9FF),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF285C7D).withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 104,
                  width: 104,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4F1F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Color(0xFF4F91AB),
                    size: 48,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              isPast ? 'Previous Appointment' : 'Appointment',
                              style: const TextStyle(
                                color: Color(0xFF80A5B9),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF80A5B9),
                            size: 25,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        doctor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? colors.onSurface
                              : const Color(0xFF285C7D),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        department,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF80A5B9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Token: ${safeText(token.tokenNumber)}',
                        style: const TextStyle(
                          color: Color(0xFF80A5B9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'View Details  >',
                        style: TextStyle(
                          color: Color(0xFF80A5B9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 15),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4F91AB),
            size: 55,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF285C7D),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF729DB2),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF236D96),
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText!),
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
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.17)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 27,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
