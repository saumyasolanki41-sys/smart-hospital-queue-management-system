import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/doctor_model.dart';
import '../controller/doctor_controller.dart';
import 'doctor_details_screen.dart';

class DoctorListScreen extends StatefulWidget {
  final String? departmentId;
  final String? departmentName;

  const DoctorListScreen({
    super.key,
    this.departmentId,
    this.departmentName,
  });

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  static const Color _background = Color(0xFFEAF8FB);
  static const Color _primary = Color(0xFF174A5B);
  static const Color _heading = Color(0xFF174A5B);
  static const Color _lightBlue = Color(0xFFDDF4F8);
  static const Color _muted = Color(0xFF648994);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.departmentId != null) {
        context.read<DoctorController>().fetchDoctors(
              departmentId: widget.departmentId,
              refresh: true,
            );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshDoctors() async {
    await context.read<DoctorController>().fetchDoctors(
          departmentId: widget.departmentId,
          refresh: true,
        );
  }

  String _safeText(String? value, [String fallback = '']) {
    if (value == null || value.trim().isEmpty || value == 'null') {
      return fallback;
    }
    return value.trim();
  }

  void _openDoctorDetails(DoctorModel doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetailsScreen(
          doctor: doctor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorController>();
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final doctors = controller.doctors.where((doctor) {
      final query = _searchQuery.toLowerCase();

      return doctor.name.toLowerCase().contains(query) ||
          _safeText(doctor.specialization)
              .toLowerCase()
              .contains(query) ||
          _safeText(doctor.qualification)
              .toLowerCase()
              .contains(query);
    }).toList();

    final departmentName = widget.departmentName?.trim();
    final hasDepartmentName =
        departmentName != null && departmentName.isNotEmpty;

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF8FB),
              Color(0xFFF4FCFD),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: _primary,
            onRefresh: _refreshDoctors,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: _heading.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _heading,
                          size: 25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Doctor List',
                        style: TextStyle(
                          color: _heading,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: IconButton(
                        tooltip: 'Refresh doctors',
                        onPressed:
                            controller.isLoading ? null : _refreshDoctors,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF174A5B),
                        Color(0xFF267F96),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasDepartmentName
                                  ? departmentName
                                  : 'Find Your Doctor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              hasDepartmentName
                                  ? 'Doctors in this department. Choose a doctor to view their details.'
                                  : 'Explore available doctors and choose the right specialist for you.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF7ED3E8),
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Search Doctors',
                  style: TextStyle(
                    color: _heading,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7ED3E8)
                          .withValues(alpha: 0.55),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _heading.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                    style: TextStyle(
                      color: isDark ? colors.onSurface : _heading,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Name, specialization or qualification',
                      hintStyle: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _primary,
                        size: 23,
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _muted,
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Available Doctors',
                        style: TextStyle(
                          color: _heading,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!controller.isLoading && doctors.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _lightBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${doctors.length} found',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 15),

                if (controller.isLoading && controller.doctors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primary,
                      ),
                    ),
                  )

                else if (controller.error != null &&
                    controller.doctors.isEmpty)
                  _DoctorMessage(
                    icon: Icons.cloud_off_rounded,
                    message:
                        'Unable to load doctors. Please try again.',
                    actionLabel: 'Try Again',
                    onAction: _refreshDoctors,
                  )

                else if (doctors.isEmpty)
                  _DoctorMessage(
                    icon: Icons.person_search_rounded,
                    message: _searchQuery.isEmpty
                        ? 'No doctors are available.'
                        : 'No doctors match your search.',
                    actionLabel:
                        _searchQuery.isNotEmpty ? 'Clear Search' : null,
                    onAction: _searchQuery.isNotEmpty
                        ? () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          }
                        : null,
                  )

                else
                  ...doctors.map(
                    (doctor) => _DoctorListCard(
                      doctor: doctor,
                      safeText: _safeText,
                      onTap: () => _openDoctorDetails(doctor),
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

class _DoctorListCard extends StatelessWidget {
  final DoctorModel doctor;
  final String Function(String?, [String]) safeText;
  final VoidCallback onTap;

  const _DoctorListCard({
    required this.doctor,
    required this.safeText,
    required this.onTap,
  });

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .where(
          (word) =>
              !{'dr', 'dr.', 'doctor', 'prof', 'prof.', 'professor'}
                  .contains(word.toLowerCase()),
        )
        .toList();

    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final specialization = safeText(doctor.specialization);
    final qualification = safeText(doctor.qualification);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7ED3E8).withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF174A5B).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7ED3E8),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFEAF8FB),
                    child: Text(
                      _getInitials(doctor.name),
                      style: const TextStyle(
                        color: Color(0xFF174A5B),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? colors.onSurface
                              : const Color(0xFF174A5B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (specialization.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          specialization,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF648994),
                            fontSize: 13,
                          ),
                        ),
                      ],

                      if (qualification.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          qualification,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF648994),
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: doctor.isAvailable
                              ? const Color(0xFFE5F7F0)
                              : const Color(0xFFFFE9E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              doctor.isAvailable
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 13,
                              color: doctor.isAvailable
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                doctor.isAvailable
                                    ? 'Available'
                                    : 'Currently unavailable',
                                style: TextStyle(
                                  color: doctor.isAvailable
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8FB),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF174A5B),
                    size: 24,
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

class _DoctorMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DoctorMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  static const Color _primary = Color(0xFF174A5B);
  static const Color _heading = Color(0xFF174A5B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7ED3E8).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: 34,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _heading,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}