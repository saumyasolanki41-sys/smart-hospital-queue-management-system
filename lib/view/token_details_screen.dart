
import 'package:flutter/material.dart';

import '../models/token_model.dart';

class TokenDetailsScreen extends StatelessWidget {
  final TokenModel token;

  const TokenDetailsScreen({
    super.key,
    required this.token,
  });

  String _displayValue(dynamic value, [String fallback = 'Not available']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'served':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Theme.of(context).colorScheme.error;
      case 'in-progress':
      case 'in progress':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = _displayValue(token.status, 'Pending');
    final statusColor = _statusColor(context, status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your Token Number',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _displayValue(token.tokenNumber),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Appointment Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.person_outline,
            title: 'Doctor',
            value: _displayValue(token.doctorName),
          ),
          _InfoCard(
            icon: Icons.local_hospital_outlined,
            title: 'Department',
            value: _displayValue(token.departmentName),
          ),
          _InfoCard(
            icon: Icons.people_outline,
            title: 'Patients Ahead',
            value: _displayValue(token.patientsAhead, '0'),
          ),
          _InfoCard(
            icon: Icons.schedule,
            title: 'Estimated Waiting Time',
            value: '${_displayValue(token.estimatedWaitMinutes, '0')} minutes',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: colors.primary, size: 28),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
