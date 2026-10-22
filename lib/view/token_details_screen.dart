import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/token_model.dart';
import '../viewmodels/token_viewmodel.dart';

class TokenDetailsScreen extends StatefulWidget {
  final TokenModel token;

  const TokenDetailsScreen({
    super.key,
    required this.token,
  });

  @override
  State<TokenDetailsScreen> createState() => _TokenDetailsScreenState();
}

class _TokenDetailsScreenState extends State<TokenDetailsScreen> {
  bool _isCancelling = false;

  String _displayValue(
    dynamic value, [
    String fallback = 'Not available',
  ]) {
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

  bool _canCancel(String status) {
    final normalized = status.trim().toLowerCase();

    return normalized == 'pending' ||
        normalized == 'waiting' ||
        normalized == 'booked' ||
        normalized == 'confirmed' ||
        normalized == 'scheduled';
  }

  Future<void> _confirmCancellation() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Token?'),
        content: const Text(
          'Are you sure you want to cancel this appointment? '
          'This action may not be reversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Token'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Token'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) return;

    await _cancelToken();
  }

  Future<void> _cancelToken() async {
    if (_isCancelling) return;

    setState(() => _isCancelling = true);

    final viewModel = context.read<TokenViewModel>();

    final success = await viewModel.cancelToken(widget.token.id);

    if (!mounted) return;

    setState(() => _isCancelling = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token cancelled successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.error ?? 'Unable to cancel your token. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final viewModel = context.watch<TokenViewModel>();
    final status = _displayValue(widget.token.status, 'Pending');
    final statusColor = _statusColor(context, status);
    final canCancel = _canCancel(status);

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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _displayValue(widget.token.tokenNumber),
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.person_outline,
            title: 'Doctor',
            value: _displayValue(widget.token.doctorName),
          ),
          _InfoCard(
            icon: Icons.local_hospital_outlined,
            title: 'Department',
            value: _displayValue(widget.token.departmentName),
          ),
          _InfoCard(
            icon: Icons.people_outline,
            title: 'Patients Ahead',
            value: _displayValue(widget.token.patientsAhead, '0'),
          ),
          _InfoCard(
            icon: Icons.schedule,
            title: 'Estimated Waiting Time',
            value:
                '${_displayValue(widget.token.estimatedWaitMinutes, '0')} minutes',
          ),
          const SizedBox(height: 20),

          if (canCancel) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_isCancelling || viewModel.isCancelling)
                    ? null
                    : _confirmCancellation,
                icon: (_isCancelling || viewModel.isCancelling)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(
                  (_isCancelling || viewModel.isCancelling)
                      ? 'Cancelling...'
                      : 'Cancel Token',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCancelling
                  ? null
                  : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
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
        leading: Icon(
          icon,
          color: colors.primary,
          size: 28,
        ),
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