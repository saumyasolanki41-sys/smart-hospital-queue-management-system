
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import 'ambulance_screen.dart';
import 'my_tokens_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _primary = Color(0xFF174A5B);
  static const Color _skyBlue = Color(0xFF7ED3E8);
  static const Color _background = Color(0xFFEAF8FB);
  static const Color _textColor = Color(0xFF174A5B);
  static const Color _muted = Color(0xFF648994);
  // static const Color _secondary = Color(0xFF24758B);
  static const Color _lightBlue = Color(0xFFDDF4F8);
  // static const Color _border = Color(0xFFD2EAF0);

  bool _isLoggingOut = false;

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .where(
          (word) => !{
            'dr',
            'dr.',
            'doctor',
            'prof',
            'prof.',
            'professor',
          }.contains(word.toLowerCase()),
        )
        .toList();

    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : _primary,
        ),
      );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 35,
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: _textColor),
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

    if (confirm != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      await context.read<AuthController>().logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (_) {
      _showMessage(
        'Unable to logout. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  void _openAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTokensScreen(),
      ),
    );
  }

  void _openAmbulance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AmbulanceScreen(),
      ),
    );
  }

  BoxDecoration _cardDecoration(
    bool isDark,
    ColorScheme colors,
  ) {
    return BoxDecoration(
      color: isDark ? colors.surfaceContainer : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: _skyBlue.withValues(alpha: 0.45),
      ),
      boxShadow: [
        BoxShadow(
          color: _primary.withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final fullName = user?.name.trim().isNotEmpty == true
        ? user!.name
        : 'User';

    final email = user?.email ?? 'No email available';

    return Scaffold(
      backgroundColor: isDark ? colors.surface : _background,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFFEAF8FB),
                    Color(0xFFDDF4F8),
                    Colors.white,
                    Color(0xFFEAF8FB),
                  ],
                  stops: [0.0, 0.25, 0.65, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeaderButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.maybePop(context),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? colors.onSurface
                                  : _textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Manage your personal details',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? colors.onSurfaceVariant
                                  : _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Profile header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF174A5B),
                        Color(0xFF24758B),
                        Color(0xFF7ED3E8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 102,
                        height: 102,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: _lightBlue,
                          child: Text(
                            _getInitials(fullName),
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFEAF8FB),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const _SectionHeading(
                  title: 'Personal Information',
                  subtitle: 'Your registered details',
                  icon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 14),

                // Registered name and email
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(isDark, colors),
                  child: Column(
                    children: [
                      _InformationRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Full Name',
                        value: fullName,
                        isDark: isDark,
                        colors: colors,
                      ),
                      const _SoftDivider(),
                      _InformationRow(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: email,
                        isDark: isDark,
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const _SectionHeading(
                  title: 'Smart Hospital',
                  subtitle: 'Your healthcare shortcuts',
                  icon: Icons.local_hospital_outlined,
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: _cardDecoration(isDark, colors),
                  child: Column(
                    children: [
                      _ProfileMenuRow(
                        icon: Icons.local_hospital_outlined,
                        title: 'Ambulance Services',
                        subtitle: 'Access ambulance information',
                        onTap: _openAmbulance,
                        isDark: isDark,
                        colors: colors,
                      ),
                      const _SoftDivider(),
                      _ProfileMenuRow(
                        icon: Icons.calendar_month_outlined,
                        title: 'Appointments',
                        subtitle: 'Manage your appointments',
                        onTap: _openAppointments,
                        isDark: isDark,
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_isLoggingOut || auth.isLoading)
                        ? null
                        : _logout,
                    icon: _isLoggingOut || auth.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primary,
                            ),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text(
                      _isLoggingOut || auth.isLoading
                          ? 'Please wait...'
                          : 'Logout',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.red.shade100,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Center(
                  child: Text(
                    'Your health, our priority',
                    style: TextStyle(
                      color: isDark
                          ? colors.onSurfaceVariant
                          : _muted,
                      fontSize: 12,
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
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD2EAF0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF174A5B).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isDark ? colors.onSurface : const Color(0xFF174A5B),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF4F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Color(0xFF174A5B),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF174A5B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF648994),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;
  final ColorScheme colors;

  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF4F8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF24758B),
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? colors.onSurfaceVariant
                        : const Color(0xFF648994),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? colors.onSurface
                        : const Color(0xFF174A5B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 19,
      thickness: 1,
      color: Color(0xFFD2EAF0),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme colors;

  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFDDF4F8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF24758B),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark
              ? colors.onSurface
              : const Color(0xFF174A5B),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? colors.onSurfaceVariant
                : const Color(0xFF648994),
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark
            ? colors.onSurfaceVariant
            : const Color(0xFF648994),
      ),
      onTap: onTap,
    );
  }
}
