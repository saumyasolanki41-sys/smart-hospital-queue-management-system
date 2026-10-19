import 'package:flutter/material.dart';
import '../models/queue_status.dart';
import '../services/queue_service.dart';
import '../viewmodels/live_queue_viewmodel.dart';

class LiveQueueScreen extends StatefulWidget {
 
  final String? tokenId;
 
  final QueueService? queueService;

  const LiveQueueScreen({
    super.key,
    this.tokenId,
    this.queueService,
  });

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen>
    with WidgetsBindingObserver {
  static const Color primaryColor = Color(0xFF176B87);
  late final LiveQueueViewModel _vm;
  late final QueueService _queueService;
  late final bool _ownsService;

  bool get _hasToken =>
      widget.tokenId != null && widget.tokenId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.queueService == null;
    // NOTE: pass tokenProvider so the Bearer token is sent, e.g.
    // QueueService(tokenProvider: () async => await TokenService().getToken())
    _queueService = widget.queueService ?? QueueService();
    _vm = LiveQueueViewModel(
      service: _queueService,
      tokenId: widget.tokenId ?? '',
      onNearTurn: (s) {
        // NOTE: call your notification_service here, e.g.
        // 'Almost your turn: ${s.patientsAhead} patients ahead'
      },
      onUnauthorized: () {
        // NOTE: clear session and navigate to login
      },
    );
    if (_hasToken) _vm.start();
    WidgetsBinding.instance.addObserver(this);
  }

  // Pause polling when the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasToken) return;
    if (state == AppLifecycleState.resumed) {
      _vm.start();
    } else if (state == AppLifecycleState.paused) {
      _vm.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.dispose();
    if (_ownsService) _queueService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Live Queue'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_hasToken)
            IconButton(
              onPressed: _vm.refresh,
              tooltip: 'Refresh queue',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (!_hasToken) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You have no active token. Book a token first.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (_vm.isLoading && _vm.status == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_vm.status == null) {
            return _ErrorView(message: _vm.error, onRetry: _vm.refresh);
          }
          return RefreshIndicator(
            onRefresh: _vm.refresh,
            child: _buildContent(_vm.status!, _vm.error),
          );
        },
      ),
    );
  }

  Widget _buildContent(QueueStatus s, String? error) {
    final isMyTurn = s.status == 'called' || s.status == 'in_consultation';
    final label = switch (s.status) {
      'called' => 'Your turn - please proceed',
      'in_consultation' => 'In consultation',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => 'Waiting for your turn',
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$error Showing last known status.',
                style: const TextStyle(fontSize: 12)),
          ),
        const Text('Your Queue Status',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Updates automatically every few seconds.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isMyTurn ? Colors.green.shade700 : primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.confirmation_num_outlined,
                  size: 42, color: Colors.white),
              const SizedBox(height: 12),
              const Text('YOUR TOKEN NUMBER',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 14, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(s.myToken,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.campaign_outlined,
                title: s.currentlyServing ?? '-',
                subtitle: 'Now Serving',
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.people_alt_outlined,
                title: '${s.patientsAhead}',
                subtitle: 'Patients Ahead',
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.access_time,
                title: s.estimatedWaitMinutes == null
                    ? '--'
                    : '~${s.estimatedWaitMinutes} min',
                subtitle: 'Estimated Wait',
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text('Upcoming Tokens',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (s.upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No upcoming tokens.'),
          )
        else
          Card(
            color: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                for (int i = 0; i < s.upcoming.length; i++) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE5F2F6),
                      child: Text(s.upcoming[i].token,
                          style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    title: Text('Token ${s.upcoming[i].token}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(s.upcoming[i].status),
                  ),
                  if (i < s.upcoming.length - 1)
                    const Divider(height: 1, indent: 72),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Waiting time is an estimate and may change.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message ?? 'Something went wrong.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}