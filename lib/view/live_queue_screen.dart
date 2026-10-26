
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/token_model.dart';
import '../controller/token_controller.dart';

const Color pageColor = Color(0xFFE6EFFF);
const Color blue = Color(0xFF8DB8F5);
const Color darkBlue = Color.fromARGB(255, 14, 18, 33);
const Color cardColor = Colors.white;
const Color mutedColor = Color(0xFF60758A);
const Color lightBlue = Color(0xFFE8F0FF);
const Color borderColor = Color(0xFFE2E8F0);

class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({super.key});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  bool _isRefreshingStatus = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadQueueWithStatus();
    });
  }

  Future<void> _loadQueueWithStatus({
    bool refresh = false,
  }) async {
    if (_isRefreshingStatus) return;

    _isRefreshingStatus = true;

    final controller = context.read<TokenController>();

    try {
      await controller.fetchMyTokens(refresh: refresh);

      if (!mounted) return;

      final activeTokens = controller.tokens.where((token) {
        final status = token.status.toLowerCase().trim();

        return status == 'waiting' ||
            status == 'pending' ||
            status == 'in-progress' ||
            status == 'in progress';
      }).toList();

      for (final token in activeTokens) {
        if (!mounted) return;

        try {
          await controller.fetchTokenStatus(token.id);
        } catch (_) {
          // Keep the screen usable if live status is unavailable.
        }
      }
    } catch (_) {
      // Display only a general message in the UI.
    } finally {
      _isRefreshingStatus = false;
    }
  }

  Future<void> _refreshQueue() async {
    await _loadQueueWithStatus(refresh: true);
  }

  Future<void> _cancelToken(TokenModel token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Cancel Token',
          style: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel token ${token.tokenNumber}?',
          style: const TextStyle(
            color: mutedColor,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Keep Token',
              style: TextStyle(color: mutedColor),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC94F58),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

      await _loadQueueWithStatus(refresh: true);
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to cancel token. Please try again.',
          ),
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

    if (result.isEmpty || result == 'null') {
      return fallback;
    }

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
        return const Color(0xFFC94F58);
      case 'in progress':
      case 'in-progress':
        return const Color(0xFFB7791F);
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
            onPressed: viewModel.isLoading || _isRefreshingStatus
                ? null
                : _refreshQueue,
            icon: const Icon(
              Icons.refresh_rounded,
              color: darkBlue,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE6EFFF),
              Color(0xFFF5F8FF),
              Colors.white,
              Color(0xFFE8F0FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          color: darkBlue,
          onRefresh: _refreshQueue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              _buildWelcomeCard(),

              const SizedBox(height: 25),

              const Text(
                'Queue Overview',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _OverviewCard(
                      icon: Icons.confirmation_number_outlined,
                      title: 'My Tokens',
                      value: '${viewModel.tokens.length}',
                      iconColor: darkBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _OverviewCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Waiting',
                      value: '$waitingCount',
                      iconColor: const Color(0xFF329875),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

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
                    onPressed:
                        viewModel.isLoading || _isRefreshingStatus
                            ? null
                            : _refreshQueue,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: darkBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (viewModel.isLoading && viewModel.tokens.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: darkBlue,
                    ),
                  ),
                )
              else if (viewModel.error != null &&
                  viewModel.tokens.isEmpty)
                _QueueMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load queue',
                  subtitle:
                      'Unable to load your appointments. Please try again.',
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
                    color: mutedColor,
                    size: 17,
                  ),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Pull down to update your queue status',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 14, 18, 33),
            Color(0xFF8DB8F5),
            Color(0xFFB7D2F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                const SizedBox(height: 12),
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
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: darkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: mutedColor,
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
    final waitMinutes = token.estimatedWaitMinutes;
    final patientsAhead = token.patientsAhead;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: darkBlue,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token Number',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayText(token.tokenNumber),
                      style: const TextStyle(
                        color: darkBlue,
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
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
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
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: borderColor),
          ),

          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Doctor',
            value: displayText(token.doctorName),
          ),

          const SizedBox(height: 15),

          _DetailRow(
            icon: Icons.local_hospital_outlined,
            label: 'Department',
            value: displayText(token.departmentName),
          ),

          const SizedBox(height: 19),

          Row(
            children: [
              Expanded(
                child: _QueueStat(
                  icon: Icons.people_alt_outlined,
                  label: 'Patients ahead',
                  value: displayText(patientsAhead),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QueueStat(
                  icon: Icons.access_time_rounded,
                  label: 'Est. waiting',
                  value: waitMinutes == null
                      ? 'Not available'
                      : '$waitMinutes min',
                ),
              ),
            ],
          ),

          if (canCancel) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 19),
                label: const Text(
                  'Cancel Token',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC94F58),
                  side: const BorderSide(
                    color: Color(0xFFE8BFC3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: darkBlue, size: 19),
        ),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            color: mutedColor,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: darkBlue, size: 22),
          const SizedBox(height: 10),
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
              color: mutedColor,
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
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: darkBlue),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: darkBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
