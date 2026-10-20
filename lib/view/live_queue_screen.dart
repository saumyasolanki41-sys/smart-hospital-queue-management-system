
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/token_model.dart';
import '../viewmodels/token_viewmodel.dart';

class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({super.key});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TokenViewModel>().fetchMyTokens();
    });
  }

  Future<void> _refreshQueue() async {
    await context.read<TokenViewModel>().fetchMyTokens(refresh: true);
  }

  Future<void> _cancelToken(TokenModel token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Token'),
        content: Text(
          'Are you sure you want to cancel token ${token.tokenNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Token'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Token'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<TokenViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await viewModel.cancelToken(token.id);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Token cancellation completed.'),
        ),
      );

      await viewModel.fetchMyTokens(refresh: true);
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Unable to cancel token: $error'),
        ),
      );
    }
  }

  bool _canCancel(String status) {
    final normalized = status.toLowerCase();

    return normalized != 'cancelled' &&
        normalized != 'canceled' &&
        normalized != 'completed' &&
        normalized != 'served' &&
        normalized != 'in-progress' &&
        normalized != 'in progress';
  }

  Color _statusColor(String status, BuildContext context) {
    final normalized = status.toLowerCase();

    if (normalized == 'completed' || normalized == 'served') {
      return Colors.green;
    }

    if (normalized == 'cancelled' || normalized == 'canceled') {
      return Theme.of(context).colorScheme.error;
    }

    if (normalized == 'in-progress' || normalized == 'in progress') {
      return Colors.orange;
    }

    return Theme.of(context).colorScheme.primary;
  }

  String _displayText(dynamic value, {String fallback = 'Not available'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TokenViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Status'),
        actions: [
          IconButton(
            tooltip: 'Refresh queue',
            onPressed: viewModel.isLoading ? null : _refreshQueue,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshQueue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 36,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your Queue',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track your token and estimated waiting time.',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (viewModel.isLoading && viewModel.tokens.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (viewModel.error != null && viewModel.tokens.isEmpty)
              _QueueMessage(
                icon: Icons.error_outline,
                message: viewModel.error.toString(),
                buttonText: 'Try Again',
                onPressed: _refreshQueue,
              )
            else if (viewModel.tokens.isEmpty)
              const _QueueMessage(
                icon: Icons.confirmation_number_outlined,
                message: 'You have no booked tokens yet.',
                subtitle:
                    'Book a token to see your position in the hospital queue.',
              )
            else ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Bookings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${viewModel.tokens.length} token(s)',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...viewModel.tokens.map(
                (token) => _TokenCard(
                  token: token,
                  statusColor: _statusColor(
                    _displayText(token.status, fallback: 'pending'),
                    context,
                  ),
                  canCancel: _canCancel(
                    _displayText(token.status, fallback: 'pending'),
                  ),
                  displayText: _displayText,
                  onCancel: () => _cancelToken(token),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Text(
              'Pull down to refresh your queue status.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  final TokenModel token;
  final Color statusColor;
  final bool canCancel;
  final String Function(dynamic, {String fallback}) displayText;
  final VoidCallback onCancel;

  const _TokenCard({
    required this.token,
    required this.statusColor,
    required this.canCancel,
    required this.displayText,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    size: 28,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Token Number'),
                      Text(
                        displayText(token.tokenNumber),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayText(token.status, fallback: 'pending'),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _TokenDetail(
              icon: Icons.person_outline,
              label: 'Doctor',
              value: displayText(token.doctorName),
            ),
            const SizedBox(height: 12),
            _TokenDetail(
              icon: Icons.local_hospital_outlined,
              label: 'Department',
              value: displayText(token.departmentName),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QueueStat(
                    icon: Icons.people_outline,
                    label: 'Patients ahead',
                    value: displayText(token.patientsAhead, fallback: '0'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QueueStat(
                    icon: Icons.schedule,
                    label: 'Est. waiting',
                    value:
                        '${displayText(token.estimatedWaitMinutes, fallback: '0')} min',
                  ),
                ),
              ],
            ),
            if (canCancel) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Token'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TokenDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TokenDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Text('$label: '),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _QueueStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QueueStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _QueueMessage({
    required this.icon,
    required this.message,
    this.subtitle,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 52, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}
