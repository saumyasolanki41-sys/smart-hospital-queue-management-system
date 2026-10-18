
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ApiService _apiService = ApiService();

  String _message = 'Checking API connection...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApi();
  }

  Future<void> _checkApi() async {
    setState(() {
      _isLoading = true;
      _message = 'Checking API connection...';
    });

    try {
      final result = await _apiService.checkHealth();

      if (!mounted) return;

      final data = result['data'];

      setState(() {
        _message = 'API connected successfully!\n\n'
            'Response: ${data ?? result}';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = 'Connection failed.\n\n$error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
        backgroundColor: const Color(0xFF087BA5),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLoading
                    ? Icons.cloud_sync
                    : _message.startsWith('API connected')
                        ? Icons.check_circle
                        : Icons.error,
                size: 65,
                color: _isLoading
                    ? Colors.blue
                    : _message.startsWith('API connected')
                        ? Colors.green
                        : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkApi,
                child: const Text('Test Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
