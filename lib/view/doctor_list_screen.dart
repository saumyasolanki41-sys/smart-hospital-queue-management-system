import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/doctor_model.dart';
import '../viewmodels/doctor_viewmodel.dart';
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
  static const Color _background = Color(0xFFC2E7EB);
  static const Color _primary = Color(0xFF286C91);
  static const Color _secondaryText = Color(0xFF80A5B8);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.departmentId != null) {
        context.read<DoctorViewModel>().fetchDoctors(
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
    await context.read<DoctorViewModel>().fetchDoctors(
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
    final viewModel = context.watch<DoctorViewModel>();
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final doctors = viewModel.doctors.where((doctor) {
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
      backgroundColor: isDark ? colors.surface : _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _refreshDoctors,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Doctor List',
                      style: TextStyle(
                        color: isDark ? colors.onSurface : _primary,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh doctors',
                    onPressed:
                        viewModel.isLoading ? null : _refreshDoctors,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: _primary,
                    ),
                  ),
                ],
              ),

              // Selected department heading
              if (hasDepartmentName) ...[
                const SizedBox(height: 8),
                Text(
                  'Doctors in $departmentName Department',
                  style: TextStyle(
                    color: isDark ? colors.onSurface : _primary,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a doctor to view their details.',
                  style: TextStyle(
                    color: isDark
                        ? colors.onSurfaceVariant
                        : _secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Search doctors
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceContainer
                      : const Color(0xFFF1F9FF),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.15),
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
                    hintText: 'Search Doctors',
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (viewModel.isLoading && viewModel.doctors.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _primary,
                    ),
                  ),
                )
              else if (viewModel.error != null &&
                  viewModel.doctors.isEmpty)
                _DoctorMessage(
                  icon: Icons.cloud_off_rounded,
                  message: viewModel.error!,
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

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final specialization = safeText(doctor.specialization);
    final qualification = safeText(doctor.qualification);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainer : const Color(0xFFF1F9FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF285C7D).withValues(alpha: 0.18),
            blurRadius: 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFD8F3FA),
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF3988A4),
                    size: 43,
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
                        style: const TextStyle(
                          color: Color(0xFF285C7D),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (specialization.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          specialization,
                          style: const TextStyle(
                            color: Color(0xFF80A5B8),
                            fontSize: 14,
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
                            color: Color(0xFF80A5B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        doctor.isAvailable
                            ? 'Available'
                            : 'Currently unavailable',
                        style: TextStyle(
                          color: doctor.isAvailable
                              ? Colors.green.shade700
                              : colors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
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
