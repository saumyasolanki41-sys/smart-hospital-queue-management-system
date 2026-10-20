
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'ambulance_screen.dart';
import 'my_tokens_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primary = Color(0xFF236D96);
  static const Color _background = Color(0xFFC2E9EC);
  static const Color _textColor = Color(0xFF285C7D);

  String _displayValue(dynamic value, String fallback) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
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
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await context.read<AuthViewModel>().logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void _openTokens(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTokensScreen(),
      ),
    );
  }

  void _openAmbulance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AmbulanceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.user;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = _displayValue(user?.name, 'Patient');
    final email = _displayValue(user?.email, 'Not provided');

    return Scaffold(
      backgroundColor: isDark ? colors.surface : _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Aqua background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [colors.surface, colors.surface]
                        : const [
                            Color(0xFFBCE7EA),
                            Color(0xFFD4F2F1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Decorative background shapes
            if (!isDark) ...[
              Positioned(
                left: -55,
                bottom: 115,
                child: Container(
                  height: 190,
                  width: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FDDE0)
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Positioned(
                right: -75,
                bottom: 160,
                child: Container(
                  height: 180,
                  width: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9BCFFF)
                        .withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],

            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                // Page heading
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: _textColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: isDark ? colors.onSurface : _textColor,
                        fontSize: 27,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 65),

                // Profile card
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.surfaceContainer
                        : const Color(0xFFF1F9FF),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _textColor.withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // User information
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          15,
                          14,
                          12,
                          17,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 112,
                              width: 112,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD1EFF7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF568CA5),
                                size: 75,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? colors.onSurface
                                          : _textColor,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    email,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF80A8BC),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(
                        height: 1,
                        thickness: 1,
                        color: const Color(0xFFB9E4E8)
                            .withValues(alpha: 0.8),
                      ),

                      // Profile menu
                      _ProfileMenuRow(
                        icon: Icons.badge_outlined,
                        title: 'Personal Information',
                        onTap: () {
                          _showInformationDialog(
                            context,
                            'Personal Information',
                            'Name: $name\n\nEmail: $email',
                          );
                        },
                      ),
                      _ProfileMenuRow(
                        icon: Icons.description_outlined,
                        title: 'Medical History',
                        onTap: () {
                          _showInformationDialog(
                            context,
                            'Medical History',
                            'Medical history is not available yet.',
                          );
                        },
                      ),
                      _ProfileMenuRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () {
                          _showInformationDialog(
                            context,
                            'Notifications',
                            'Notifications are not available yet.',
                          );
                        },
                      ),
                      _ProfileMenuRow(
                        icon: Icons.history_rounded,
                        title: 'Appointments',
                        onTap: () => _openTokens(context),
                      ),
                      _ProfileMenuRow(
                        icon: Icons.support_agent_rounded,
                        title: 'Help & Support',
                        showDivider: false,
                        onTap: () {
                          _showInformationDialog(
                            context,
                            'Help & Support',
                            'For emergency assistance, use the Ambulance option.',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Logout button
                SizedBox(
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 24,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? colors.surfaceContainer
                          : const Color(0xFFF1F9FF),
                      foregroundColor: const Color(0xFFB9788B),
                      elevation: 4,
                      shadowColor: _textColor.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: Text(
                    'CareQueue • Better care, less waiting',
                    style: TextStyle(
                      color: isDark
                          ? colors.onSurfaceVariant
                          : _textColor.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
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
                _ProfileBottomItem(
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
                _ProfileBottomItem(
                  icon: Icons.history_rounded,
                  label: 'My Tokens',
                  onTap: () => _openTokens(context),
                ),
                _ProfileBottomItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Ambulance',
                  onTap: () => _openAmbulance(context),
                ),
                const _ProfileBottomItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  selected: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInformationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF32789A),
                    size: 30,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDark ? colors.onSurface : const Color(0xFF356A86),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF32789A),
                    size: 27,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: const Color(0xFFB9E4E8).withValues(alpha: 0.8),
          ),
      ],
    );
  }
}

class _ProfileBottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const _ProfileBottomItem({
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
