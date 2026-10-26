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
  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _skyBlue = Color(0xFF8DB8F5);
  static const Color _background = Color(0xFFE6EFFF);
  static const Color _textColor = Color.fromARGB(255, 5, 26, 37);
  static const Color _muted = Color(0xFF60758A);

  String? _age;
  String? _gender;

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .where(
          (word) =>
              !{
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

  Future<void> _editProfile() async {
    final auth = context.read<AuthController>();
    final user = auth.user;

    if (user == null) return;

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          fullName: user.name,
          age: _age ?? user.age?.toString() ?? '',
          gender: _gender ?? user.gender ?? '',
        ),
      ),
    );

    if (!mounted || result == null) return;

    final success = auth.updateProfile(
      fullName: result['fullName'] ?? '',
      age: result['age'] ?? '',
      gender: result['gender'] ?? '',
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _age = result['age'];
        _gender = result['gender'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: _primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Unable to update profile'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _logout() async {
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

    await context.read<AuthController>().logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void _openTokens() {
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

  void _showInformationDialog({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: _primary),
            ),
          ),
        ],
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
        color: _skyBlue.withValues(alpha: 0.35),
      ),
      boxShadow: [
        BoxShadow(
          color: _primary.withValues(alpha: 0.08),
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
    final age = _age ?? user?.age?.toString() ?? 'Not added';
    final gender = _gender ?? user?.gender ?? 'Not added';

    return Scaffold(
      backgroundColor: isDark ? colors.surface : _background,
      body: Container(
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
                  ],
                  stops: [0.0, 0.20, 0.42, 0.70, 1.0],
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
                          const Text(
                            'Manage your personal details',
                            style: TextStyle(
                              fontSize: 12,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 14, 18, 33),
                        Color(0xFF315B91),
                        Color(0xFF8DB8F5),
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
                            color: Colors.white.withValues(alpha: 0.65),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F0FF),
                          child: Text(
                            _getInitials(fullName),
                            style: const TextStyle(
                              color: Color(0xFF246F96),
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
                          color: Color(0xFFE6EFFF),
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white70,
                          ),
                          backgroundColor: Colors.white.withValues(
                            alpha: 0.10,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 21,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                      const _SoftDivider(),
                      _InformationRow(
                        icon: Icons.cake_outlined,
                        title: 'Age',
                        value: age,
                        isDark: isDark,
                        colors: colors,
                      ),
                      const _SoftDivider(),
                      _InformationRow(
                        icon: Icons.people_outline_rounded,
                        title: 'Gender',
                        value: gender,
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
                        icon: Icons.confirmation_number_outlined,
                        title: 'My Tokens',
                        subtitle: 'View your booked appointments',
                        onTap: _openTokens,
                        isDark: isDark,
                        colors: colors,
                      ),
                      const _SoftDivider(),
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
                        icon: Icons.medical_information_outlined,
                        title: 'Medical History',
                        subtitle: 'Your health information',
                        isDark: isDark,
                        colors: colors,
                        onTap: () => _showInformationDialog(
                          title: 'Medical History',
                          message:
                              'Your medical history feature can be connected '
                              'to your hospital records when available.',
                        ),
                      ),
                      const _SoftDivider(),
                      _ProfileMenuRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Appointment and queue updates',
                        isDark: isDark,
                        colors: colors,
                        onTap: () => _showInformationDialog(
                          title: 'Notifications',
                          message:
                              'Appointment and queue notifications will appear '
                              'here when notifications are configured.',
                        ),
                      ),
                      const _SoftDivider(),
                      _ProfileMenuRow(
                        icon: Icons.calendar_month_outlined,
                        title: 'Appointments',
                        subtitle: 'Manage your appointments',
                        onTap: _openTokens,
                        isDark: isDark,
                        colors: colors,
                      ),
                      const _SoftDivider(),
                      _ProfileMenuRow(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get help using CareQueue',
                        isDark: isDark,
                        colors: colors,
                        onTap: () => _showInformationDialog(
                          title: 'Help & Support',
                          message:
                              'For help with your appointment or token, '
                              'please contact the hospital.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _logout,
                    icon: auth.isLoading
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
                      auth.isLoading ? 'Please wait...' : 'Logout',
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

                const Center(
                  child: Text(
                    'Your health, our priority',
                    style: TextStyle(
                      color: _muted,
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
          color: const Color(0xFF8DB8F5).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315B91).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: const Color.fromARGB(255, 14, 18, 33),
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
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 14, 18, 33),
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
                  color: Color.fromARGB(255, 5, 26, 37),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF60758A),
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
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 14, 18, 33),
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
                        : const Color(0xFF60758A),
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
                        : const Color.fromARGB(255, 5, 26, 37),
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
      color: Color(0xFFE2E8F0),
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
          color: const Color(0xFFE8F0FF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: const Color.fromARGB(255, 14, 18, 33),
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
              : const Color.fromARGB(255, 5, 26, 37),
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
                : const Color(0xFF60758A),
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark
            ? colors.onSurfaceVariant
            : const Color(0xFF60758A),
      ),
      onTap: onTap,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String fullName;
  final String age;
  final String gender;

  const EditProfileScreen({
    super.key,
    required this.fullName,
    required this.age,
    required this.gender,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _skyBlue = Color(0xFF8DB8F5);
  static const Color _textColor = Color.fromARGB(255, 5, 26, 37);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _ageController;
  late String? _gender;

  final List<String> _genders = const [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .where(
          (word) =>
              !{
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

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(
      text: widget.fullName,
    );

    _ageController = TextEditingController(
      text: widget.age,
    );

    _gender = _genders.contains(widget.gender)
        ? widget.gender
        : null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
        ),
      );
      return;
    }

    Navigator.pop<Map<String, String>>(
      context,
      {
        'fullName': _fullNameController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _gender!,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EFFF),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE6EFFF),
        foregroundColor: _textColor,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB7D2F8),
              Color(0xFFE6EFFF),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFFE8F0FF),
                      child: Text(
                        _getInitials(_fullNameController.text),
                        style: const TextStyle(
                          color: Color(0xFF246F96),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Update your details',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Keep your profile information up to date.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF60758A),
                    ),
                  ),
                  const SizedBox(height: 23),

                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Please enter a valid name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      label: 'Age',
                      icon: Icons.cake_outlined,
                    ),
                    validator: (value) {
                      final age = int.tryParse(value?.trim() ?? '');

                      if (age == null || age < 1 || age > 120) {
                        return 'Enter an age between 1 and 120';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: _inputDecoration(
                      label: 'Gender',
                      icon: Icons.people_outline,
                    ),
                    items: _genders.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _gender = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 27),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF60758A),
      ),
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: const Color(0xFFF5F8FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _skyBlue,
          width: 1.5,
        ),
      ),
    );
  }
}
