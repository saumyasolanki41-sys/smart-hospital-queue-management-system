
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/department_model.dart';
import '../controller/department_controller.dart';
import '../controller/doctor_controller.dart';
import 'doctor_list_screen.dart';

class DepartmentScreen extends StatefulWidget {
  final String? selectedDepartmentName;

  const DepartmentScreen({
    super.key,
    this.selectedDepartmentName,
  });

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  static const Color _primary = Color(0xFF246F96);
  static const Color _background = Color(0xFFE6EFFF);
  static const Color _heading = Color(0xFF173B5E);
  static const Color _lightBlue = Color(0xFFB7D2F8);
  static const Color _muted = Color(0xFF7892B0);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String? _openingDepartmentId;

  final List<Color> _cardColors = const [
    Color(0xFFE8F0FF),
    Color(0xFFF0F6FF),
    Color(0xFFEAF5FF),
    Color(0xFFF3F7FF),
    Color(0xFFE8F0FF),
    Color(0xFFF0F6FF),
  ];

  final List<IconData> _departmentIcons = const [
    Icons.medical_services_rounded,
    Icons.favorite_rounded,
    Icons.child_care_rounded,
    Icons.accessibility_new_rounded,
    Icons.health_and_safety_rounded,
    Icons.face_rounded,
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final departmentController =
          context.read<DepartmentController>();

      await departmentController.fetchDepartments();

      if (!mounted || widget.selectedDepartmentName == null) {
        return;
      }

      final selectedName =
          _normalizeDepartmentName(widget.selectedDepartmentName!);

      DepartmentModel? selectedDepartment;

      for (final department in departmentController.departments) {
        final departmentName =
            _normalizeDepartmentName(department.name);

        if (departmentName == selectedName) {
          selectedDepartment = department;
          break;
        }
      }

      if (!mounted) return;

      if (selectedDepartment != null) {
        await _selectDepartment(selectedDepartment);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Department "${widget.selectedDepartmentName}" was not found.',
            ),
          ),
        );
      }
    });
  }

  String _normalizeDepartmentName(String name) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    const aliases = {
      'gynaceology': 'gynecology',
      'gynaecology': 'gynecology',
      'gynecology': 'gynecology',
      'obstetricsandgynecology': 'gynecology',
      'obstetricsgynecology': 'gynecology',
      'obstetricsandgynaecology': 'gynecology',
      'obstetricsgynaecology': 'gynecology',
      'obgyn': 'gynecology',
      'obgynae': 'gynecology',
    };

    return aliases[normalized] ?? normalized;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDepartment(
    DepartmentModel department,
  ) async {
    if (_openingDepartmentId != null) return;

    setState(() {
      _openingDepartmentId = department.id;
    });

    try {
      final doctorController = context.read<DoctorController>();

      await doctorController.fetchDoctors(
        departmentId: department.id,
        refresh: true,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorListScreen(
            departmentId: department.id,
            departmentName: department.name,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load doctors: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingDepartmentId = null;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await context.read<DepartmentController>().refreshDepartments();
  }

  @override
  Widget build(BuildContext context) {
    final departmentController =
        context.watch<DepartmentController>();

    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final departments = departmentController.departments
        .where(
          (department) => department.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6EFFF),
              Color(0xFFF5F8FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: _primary,
            onRefresh: _refreshData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                // Top navigation row
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: _heading.withValues(alpha: 0.05),
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
                        'Departments',
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
                        tooltip: 'Refresh departments',
                        onPressed: departmentController.isLoading
                            ? null
                            : _refreshData,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Gradient header banner
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF246F96),
                        Color(0xFF8DB8F5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Your Department',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 9),
                            Text(
                              'Choose a medical department to explore available doctors.',
                              style: TextStyle(
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
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Search heading
                const Text(
                  'Search Departments',
                  style: TextStyle(
                    color: _heading,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _lightBlue.withValues(alpha: 0.7),
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
                      hintText: 'Search by department name',
                      hintStyle: const TextStyle(
                        color: _muted,
                        fontSize: 14,
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

                const SizedBox(height: 26),

                // Department list heading
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Available Departments',
                        style: TextStyle(
                          color: _heading,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!departmentController.isLoading &&
                        departments.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${departments.length} found',
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

                // Loading state
                if (departmentController.isLoading &&
                    departmentController.departments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(35),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primary,
                      ),
                    ),
                  )

                // Error state
                else if (departmentController.error != null &&
                    departmentController.departments.isEmpty)
                  _StatusMessage(
                    icon: Icons.cloud_off_rounded,
                    message: departmentController.error!,
                    actionLabel: 'Try Again',
                    onAction: () {
                      departmentController.refreshDepartments();
                    },
                  )

                // Empty search or empty department list
                else if (departments.isEmpty)
                  _StatusMessage(
                    icon: Icons.search_off_rounded,
                    message: _searchQuery.isEmpty
                        ? 'No departments are available.'
                        : 'No departments match your search.',
                    actionLabel:
                        _searchQuery.isNotEmpty ? 'Clear Search' : null,
                    onAction: _searchQuery.isNotEmpty
                        ? () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          }
                        : null,
                  )

                // Department cards
                else
                  ...departments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final department = entry.value;
                    final isOpening =
                        _openingDepartmentId == department.id;

                    return _DepartmentCard(
                      department: department,
                      backgroundColor:
                          _cardColors[index % _cardColors.length],
                      icon: _departmentIcons[
                          index % _departmentIcons.length],
                      isLoading: isOpening,
                      onTap: () => _selectDepartment(department),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final Color backgroundColor;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF246F96);
  static const Color _heading = Color(0xFF173B5E);

  const _DepartmentCard({
    required this.department,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB7D2F8).withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: _heading.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            child: Row(
              children: [
                Container(
                  height: 53,
                  width: 53,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: _primary,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    department.name,
                    style: TextStyle(
                      color: isDark ? colors.onSurface : _heading,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                if (isLoading)
                  const SizedBox(
                    height: 23,
                    width: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: _primary,
                    ),
                  )
                else
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: _primary,
                      size: 25,
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

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  static const Color _primary = Color(0xFF246F96);
  static const Color _heading = Color(0xFF173B5E);
  // static const Color _muted = Color(0xFF7892B0);

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
          color: const Color(0xFFB7D2F8).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
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
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
