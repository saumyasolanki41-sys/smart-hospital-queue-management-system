
import 'package:flutter/material.dart';

class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({super.key});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  static const Color primaryColor = Color(0xFF176B87);

  // Sample data until the real queue API is connected.
  final int currentToken = 24;
  final int patientsAhead = 4;
  final int estimatedWaitMinutes = 20;

  final List<Map<String, String>> upcomingTokens = [
    {'token': '25', 'status': 'Waiting'},
    {'token': '26', 'status': 'Waiting'},
    {'token': '27', 'status': 'Waiting'},
    {'token': '28', 'status': 'Waiting'},
  ];

  Future<void> _refreshQueue() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sample queue displayed. Live updates require API integration.',
        ),
      ),
    );
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
          IconButton(
            onPressed: _refreshQueue,
            tooltip: 'Refresh queue',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshQueue,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your Queue Status',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track your position while you wait.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.confirmation_num_outlined,
                    size: 42,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'YOUR TOKEN NUMBER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currentToken',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Waiting for your turn',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.people_alt_outlined,
                    title: '$patientsAhead',
                    subtitle: 'Patients Ahead',
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.access_time,
                    title: '~$estimatedWaitMinutes min',
                    subtitle: 'Estimated Wait',
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            const Text(
              'Upcoming Tokens',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < upcomingTokens.length; i++) ...[
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE5F2F6),
                        child: Text(
                          upcomingTokens[i]['token']!,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'Token ${upcomingTokens[i]['token']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 9,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 6),
                          Text('Waiting'),
                        ],
                      ),
                    ),
                    if (i < upcomingTokens.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Note: Queue numbers and waiting times are sample values. '
              'They will reflect actual hospital data after API integration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 20,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
