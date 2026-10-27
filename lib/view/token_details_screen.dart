import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/token_model.dart';
import '../controller/token_controller.dart';

class TokenDetailsScreen extends StatefulWidget {
  final TokenModel token;

  const TokenDetailsScreen({
    super.key,
    required this.token,
  });

  @override
  State<TokenDetailsScreen> createState() =>
      _TokenDetailsScreenState();
}

class _TokenDetailsScreenState extends State<TokenDetailsScreen> {
  bool _isCancelling = false;

  static const Color primaryBlue =
      Color.fromARGB(255, 14, 18, 33);

  static const Color darkBlue =
      Color.fromARGB(255, 5, 26, 37);

  static const Color backgroundColor = Color(0xFFE8F0FF);

  static const Color accentBlue = Color(0xFF315B91);

  String _displayValue(
    dynamic value, [
    String fallback = 'Not available',
  ]) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'served':
        return Colors.green.shade700;

      case 'cancelled':
      case 'canceled':
        return Colors.red.shade700;

      case 'in-progress':
      case 'in progress':
      case 'in_progress':
        return Colors.orange.shade800;

      default:
        return accentBlue;
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

  TokenModel _getCurrentToken(
    TokenController controller,
  ) {
    for (final token in controller.tokens) {
      if (token.id.trim() == widget.token.id.trim()) {
        return token;
      }
    }

    final selectedToken = controller.selectedToken;

    if (selectedToken != null &&
        selectedToken.id.trim() == widget.token.id.trim()) {
      return selectedToken;
    }

    return widget.token;
  }

  Future<void> _confirmCancellation() async {
    if (_isCancelling) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 42,
        ),
        title: const Text(
          'Cancel Token?',
          style: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this appointment? '
          'This action may not be reversible.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text(
              'Keep Token',
              style: TextStyle(color: primaryBlue),
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
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

    setState(() {
      _isCancelling = true;
    });

    try {
      final tokenController =
          context.read<TokenController>();

      final success = await tokenController.cancelToken(
        widget.token.id,
      );

      if (!mounted) return;

      if (success) {
        _showMessage('Token cancelled successfully.');

        Navigator.pop(context, true);
      } else {
        _showMessage(
          'Unable to cancel your token. Please try again.',
          isError: true,
        );
      }
    } catch (_) {
      // Never expose backend or exception details to the user.
      _showMessage(
        'Unable to cancel your token. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenController =
        context.watch<TokenController>();

    final currentToken = _getCurrentToken(tokenController);

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final colors = Theme.of(context).colorScheme;

    final status = _displayValue(
      currentToken.status,
      'Pending',
    );

    final statusColor = _statusColor(status);

    final canCancel = _canCancel(status);

    final isCancelling =
        _isCancelling || tokenController.isCancelling;

    final patientsAheadText = _displayValue(
      currentToken.patientsAhead,
    );

    final waitingTimeText =
        currentToken.estimatedWaitMinutes == null
            ? 'Not available'
            : '${currentToken.estimatedWaitMinutes!.toStringAsFixed(0)} minutes';

    return Scaffold(
      backgroundColor:
          isDark ? colors.surface : backgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDark ? colors.surface : backgroundColor,
        foregroundColor:
            isDark ? colors.onSurface : darkBlue,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Token Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? colors.onSurface : darkBlue,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFF8DB8F5),
                    Color(0xFFB7D2F8),
                    Color(0xFFE6EFFF),
                    Colors.white,
                    Color(0xFFE8F0FF),
                    Color(0xFF9DBDF2),
                  ],
                  stops: [
                    0.0,
                    0.16,
                    0.32,
                    0.55,
                    0.78,
                    1.0,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 14, 18, 33),
                    Color(0xFF315B91),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: accentBlue.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'YOUR TOKEN NUMBER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayValue(
                      currentToken.tokenNumber,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: accentBlue,
                  size: 24,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Appointment Information',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              icon: Icons.person_outline,
              title: 'Doctor',
              value: _displayValue(
                currentToken.doctorName,
              ),
            ),
            _InfoCard(
              icon: Icons.local_hospital_outlined,
              title: 'Department',
              value: _displayValue(
                currentToken.departmentName,
              ),
            ),
            _InfoCard(
              icon: Icons.people_outline,
              title: 'Patients Ahead',
              value: patientsAheadText,
            ),
            _InfoCard(
              icon: Icons.schedule_outlined,
              title: 'Estimated Waiting Time',
              value: waitingTimeText,
            ),
            const SizedBox(height: 18),
            if (canCancel) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: isCancelling
                      ? null
                      : _confirmCancellation,
                  icon: isCancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.cancel_outlined,
                        ),
                  label: Text(
                    isCancelling
                        ? 'Cancelling...'
                        : 'Cancel Token',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.red.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isCancelling
                    ? null
                    : () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(
                    color: primaryBlue,
                    width: 1.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  static const Color darkBlue =
      Color.fromARGB(255, 5, 26, 37);

  static const Color accentBlue =
      Color(0xFF315B91);

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainer
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? colors.outlineVariant
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: accentBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: accentBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF60758A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark
                        ? colors.onSurface
                        : darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
