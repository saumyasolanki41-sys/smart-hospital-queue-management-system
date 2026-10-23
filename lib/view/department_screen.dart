
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
  static const Color _background = Color(0xFFC2E7EB);
  static const Color _primary = Color(0xFF286C91);
  static const Color _secondaryText = Color(0xFF80A5B8);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String? _openingDepartmentId;

  final List<Color> _cardColors = const [
    Color(0xFFDDF9EC),
    Color(0xFFDDF7FC),
    Color(0xFFFFE5E8),
    Color(0xFFFFF4C4),
    Color(0xFFEBDFFF),
    Color(0xFFFFDFEB),
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

      final selectedName = _normalizeDepartmentName(
        widget.selectedDepartmentName!,
      );

      DepartmentModel? selectedDepartment;

      for (final department in departmentController.departments) {
        if (_normalizeDepartmentName(department.name) ==
            selectedName) {
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
    return name
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
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
      backgroundColor: isDark ? colors.surface : _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _refreshData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
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
                      color: _primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Department Selection',
                      style: TextStyle(
                        color: isDark ? colors.onSurface : _primary,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh departments',
                    onPressed: departmentController.isLoading
                        ? null
                        : _refreshData,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceContainer
                      : const Color(0xFFF1F9FF),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.13),
                      blurRadius: 6,
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
                  decoration: InputDecoration(
                    hintText: 'Search Departments',
                    hintStyle: const TextStyle(
                      color: Color(0xFF89979F),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _secondaryText,
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
                              color: _secondaryText,
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

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
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final Color backgroundColor;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

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
      margin: const EdgeInsets.only(bottom: 17),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF367B91).withValues(alpha: 0.13),
            blurRadius: 9,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 19,
            ),
            child: Row(
              children: [
                Container(
                  height: 45,
                  width: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3998B8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Text(
                    department.name,
                    style: TextStyle(
                      color: isDark
                          ? colors.onSurface
                          : const Color(0xFF285C7D),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _DepartmentScreenState._primary,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF3988A4),
                    size: 30,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 12,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF3998B8),
            size: 45,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF285C7D),
              fontSize: 14,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
