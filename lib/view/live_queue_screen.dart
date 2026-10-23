
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/token_model.dart';
import '../controller/token_controller.dart';

const Color pageColor = Color(0xFFBDE7EA);
const Color blue = Color(0xFF246D91);
const Color darkBlue = Color(0xFF285B7B);
const Color cardColor = Color(0xFFF1F8FF);

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
      context.read<TokenController>().fetchMyTokens();
    });
  }

  Future<void> _refreshQueue() async {
    await context.read<TokenController>().fetchMyTokens(refresh: true);
  }

  Future<void> _cancelToken(TokenModel token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Cancel Token',
          style: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel token ${token.tokenNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Token'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Token'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<TokenController>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await viewModel.cancelToken(token.id);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Token cancelled successfully.'),
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

  String _displayText(
    dynamic value, {
    String fallback = 'Not available',
  }) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') return fallback;

    return result;
  }

  String _status(String status) {
    final value = status.trim().toLowerCase();

    switch (value) {
      case 'pending':
      case 'waiting':
        return 'Waiting';
      case 'in-progress':
      case 'in progress':
        return 'In Progress';
      case 'completed':
      case 'served':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        if (value.isEmpty) return 'Waiting';
        return value[0].toUpperCase() + value.substring(1);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'served':
        return const Color(0xFF23845B);
      case 'cancelled':
      case 'canceled':
        return Colors.red.shade700;
      case 'in progress':
      case 'in-progress':
        return const Color(0xFFB96C16);
      default:
        return blue;
    }
  }

  bool _canCancel(String status) {
    final value = status.toLowerCase().trim();

    return value != 'cancelled' &&
        value != 'canceled' &&
        value != 'completed' &&
        value != 'served' &&
        value != 'in-progress' &&
        value != 'in progress';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TokenController>();

    final waitingCount = viewModel.tokens.where((token) {
      final status = token.status.toLowerCase().trim();
      return status == 'pending' || status == 'waiting';
    }).length;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: pageColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkBlue,
            size: 21,
          ),
        ),
        title: const Text(
          'Live Queue',
          style: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh queue',
            onPressed: viewModel.isLoading ? null : _refreshQueue,
            icon: const Icon(Icons.refresh_rounded, color: blue),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: blue,
        onRefresh: _refreshQueue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 22),
            const Text(
              'Queue Overview',
              style: TextStyle(
                color: darkBlue,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _OverviewCard(
                    icon: Icons.confirmation_number_outlined,
                    title: 'My Tokens',
                    value: '${viewModel.tokens.length}',
                    iconColor: blue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: _OverviewCard(
                    icon: Icons.people_alt_outlined,
                    title: 'Waiting',
                    value: '$waitingCount',
                    iconColor: const Color(0xFF23845B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Appointments',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: viewModel.isLoading ? null : _refreshQueue,
                  icon: const Icon(Icons.sync_rounded, size: 17),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(foregroundColor: blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (viewModel.isLoading && viewModel.tokens.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: blue),
                ),
              )
            else if (viewModel.error != null &&
                viewModel.tokens.isEmpty)
              _QueueMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load queue',
                subtitle: viewModel.error.toString(),
                buttonText: 'Try Again',
                onPressed: _refreshQueue,
              )
            else if (viewModel.tokens.isEmpty)
              _QueueMessage(
                icon: Icons.calendar_month_outlined,
                title: 'No appointments yet',
                subtitle:
                    'Book a token to see your queue position and waiting time here.',
                buttonText: 'Refresh Queue',
                onPressed: _refreshQueue,
              )
            else
              ...viewModel.tokens.map(
                (token) => _TokenCard(
                  token: token,
                  status: _status(token.status),
                  statusColor: _statusColor(_status(token.status)),
                  canCancel: _canCancel(token.status),
                  displayText: _displayText,
                  onCancel: () => _cancelToken(token),
                ),
              ),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: darkBlue,
                  size: 16,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Pull down to update your queue status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B779B), Color(0xFF205E82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR APPOINTMENT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Track Queue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your token, your turn, your time.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(
              Icons.local_hospital_outlined,
              color: Colors.white,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA9D9E0)),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFD9F1F3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: darkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF63859A),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  final TokenModel token;
  final String status;
  final Color statusColor;
  final bool canCancel;
  final String Function(dynamic, {String fallback}) displayText;
  final VoidCallback onCancel;

  const _TokenCard({
    required this.token,
    required this.status,
    required this.statusColor,
    required this.canCancel,
    required this.displayText,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFAADBE0)),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.08),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F0F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: blue,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token Number',
                      style: TextStyle(
                        color: Color(0xFF7897A9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayText(token.tokenNumber),
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 17),
            child: Divider(height: 1, color: Color(0xFFD8E9EE)),
          ),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Doctor',
            value: displayText(token.doctorName),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.local_hospital_outlined,
            label: 'Department',
            value: displayText(token.departmentName),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QueueStat(
                  icon: Icons.people_alt_outlined,
                  label: 'Patients ahead',
                  value: displayText(token.patientsAhead, fallback: '0'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QueueStat(
                  icon: Icons.access_time_rounded,
                  label: 'Est. waiting',
                  value:
                      '${displayText(token.estimatedWaitMinutes, fallback: '0')} min',
                ),
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 19),
                label: const Text(
                  'Cancel Token',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB74747),
                  side: const BorderSide(color: Color(0xFFE7B9B9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: blue, size: 21),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFF7897A9),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F4F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blue, size: 22),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF63859A),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _QueueMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFAADBE0)),
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFD8F0F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 36, color: blue),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF63859A),
              fontSize: 13,
            ),
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(buttonText!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
