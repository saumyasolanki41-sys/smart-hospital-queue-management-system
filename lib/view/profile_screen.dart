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
  static const Color _primary = Color(0xFF236D96);
  static const Color _background = Color(0xFFC2E9EC);
  static const Color _textColor = Color(0xFF285C7D);

  String? _age;
  String? _gender;

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
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    final fullName = user?.name.trim().isNotEmpty == true
        ? user!.name
        : 'User';

    final email = user?.email ?? 'No email available';
    final age = _age ?? user?.age?.toString() ?? 'Not added';
    final gender = _gender ?? user?.gender ?? 'Not added';

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAFBFC),
              Color(0xFFC2E9EC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: _primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _editProfile,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: _primary,
                      ),
                      tooltip: 'Edit profile',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF3F5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 56,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _InformationRow(
                        icon: Icons.person_outline,
                        title: 'Full Name',
                        value: fullName,
                      ),
                      const Divider(height: 24),
                      _InformationRow(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: email,
                      ),
                      const Divider(height: 24),
                      _InformationRow(
                        icon: Icons.cake_outlined,
                        title: 'Age',
                        value: age,
                      ),
                      const Divider(height: 24),
                      _InformationRow(
                        icon: Icons.people_outline,
                        title: 'Gender',
                        value: gender,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                const Text(
                  'Smart Hospital',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _ProfileMenuRow(
                        icon: Icons.confirmation_number_outlined,
                        title: 'My Tokens',
                        subtitle: 'View your booked appointments',
                        onTap: _openTokens,
                      ),
                      const Divider(height: 1),
                      _ProfileMenuRow(
                        icon: Icons.local_hospital_outlined,
                        title: 'Ambulance Services',
                        subtitle: 'Access ambulance information',
                        onTap: _openAmbulance,
                      ),
                      const Divider(height: 1),
                      _ProfileMenuRow(
                        icon: Icons.medical_information_outlined,
                        title: 'Medical History',
                        subtitle: 'Your health information',
                        onTap: () => _showInformationDialog(
                          title: 'Medical History',
                          message:
                              'Your medical history feature can be connected '
                              'to your hospital records when available.',
                        ),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Appointment and queue updates',
                        onTap: () => _showInformationDialog(
                          title: 'Notifications',
                          message:
                              'Appointment and queue notifications will appear '
                              'here when notifications are configured.',
                        ),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuRow(
                        icon: Icons.calendar_month_outlined,
                        title: 'Appointments',
                        subtitle: 'Manage your appointments',
                        onTap: _openTokens,
                      ),
                      const Divider(height: 1),
                      _ProfileMenuRow(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get help using CareQueue',
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

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(auth.isLoading ? 'Please wait...' : 'Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: Colors.red.shade100,
                        ),
                      ),
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
  static const Color _primary = Color(0xFF236D96);
  static const Color _textColor = Color(0xFF285C7D);

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

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _ageController = TextEditingController(text: widget.age);
    _gender = _genders.contains(widget.gender) ? widget.gender : null;
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
        const SnackBar(content: Text('Please select your gender')),
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
      backgroundColor: const Color(0xFFEAFBFC),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFEAFBFC),
        foregroundColor: _textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFFDDF3F5),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 42,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Update your details',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
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
                      return 'Enter a valid age between 1 and 120';
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
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: const Color(0xFFF5FBFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7E9ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7E9ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF236D96)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF285C7D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7F8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xFF236D96)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF285C7D),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blueGrey.shade500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF236D96),
      ),
      onTap: onTap,
    );
  }
}
