
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
  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _skyBlue = Color(0xFF8DB8F5);
  static const Color _background = Color(0xFFE6EFFF);
  static const Color _heading = Color.fromARGB(255, 5, 26, 37);
  static const Color _muted = Color(0xFF60758A);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String? _openingDepartmentId;

  final List<Color> _cardColors = const [
    Color(0xFFE8F0FF),
    Color(0xFFFFEEEE),
    Color(0xFFF0EAFF),
    Color(0xFFFFF0F4),
    Color(0xFFE8F7EF),
    Color(0xFFFFF4E5),
  ];

  final List<IconData> _departmentIcons = const [
    Icons.medical_services_rounded,
    Icons.favorite_rounded,
    Icons.psychology_rounded,
    Icons.health_and_safety_rounded,
    Icons.child_care_rounded,
    Icons.medication_rounded,
    Icons.hearing_rounded,
    Icons.accessibility_new_rounded,
    Icons.local_hospital_rounded,
    Icons.biotech_rounded,
    Icons.science_rounded,
  Icons.medical_services_rounded,
    Icons.bloodtype_rounded,
    Icons.monitor_heart_rounded,
    Icons.healing_rounded,
    Icons.remove_red_eye_rounded,
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
        if (_normalizeDepartmentName(department.name) == selectedName) {
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [colors.surface, colors.surface]
                : const [
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
                // Header
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.06),
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
                          color: _primary,
                          size: 25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Text(
                        'Departments',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
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

                const SizedBox(height: 24),

                // Search bar, similar to the reference image
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _skyBlue.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.04),
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
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search departments...',
                      hintStyle: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _muted,
                        size: 22,
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
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 23),

                // Grid heading and department count
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'All Departments',
                        style: TextStyle(
                          color: isDark ? colors.onSurface : _heading,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!departmentController.isLoading &&
                        departments.isNotEmpty)
                      Text(
                        '${departments.length} found',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 15),

                // Loading state
                if (departmentController.isLoading &&
                    departmentController.departments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 65),
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
                    onAction: _refreshData,
                  )

                // Empty state
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

                // Three-column department grid
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth >= 600 ? 4 : 3;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: departments.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, index) {
                          final department = departments[index];

                          return _DepartmentCard(
                            department: department,
                            backgroundColor: _cardColors[
                                index % _cardColors.length],
                            icon: _departmentIcons[
                                index % _departmentIcons.length],
                            isLoading:
                                _openingDepartmentId == department.id,
                            onTap: () =>
                                _selectDepartment(department),
                          );
                        },
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

class _DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final Color backgroundColor;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _muted = Color(0xFF60758A);

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

    return Material(
      color: isDark ? colors.surface : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 13, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF8DB8F5)
                  .withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medical icon
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: _primary,
                  size: 27,
                ),
              ),

              const Spacer(),

              // Department name
              Text(
                department.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? colors.onSurface
                      : const Color.fromARGB(255, 5, 26, 37),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 7),

              // Open department indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'View doctors',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      height: 13,
                      width: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: _primary,
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: _primary,
                      size: 14,
                    ),
                ],
              ),
            ],
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

  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _heading = Color.fromARGB(255, 5, 26, 37);

  const _StatusMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8DB8F5)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFFF),
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
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
