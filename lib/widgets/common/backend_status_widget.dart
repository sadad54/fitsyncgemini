import 'package:flutter/material.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BackendStatusWidget extends StatefulWidget {
  const BackendStatusWidget({super.key});

  @override
  State<BackendStatusWidget> createState() => _BackendStatusWidgetState();
}

class _BackendStatusWidgetState extends State<BackendStatusWidget> {
  bool _isChecking = false;
  bool? _isConnected;
  String? _errorMessage;
  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _isChecking = true;
      _isConnected = null;
      _errorMessage = null;
    });

    try {
      final health = await MLAPIService.healthCheck();
      setState(() {
        _isConnected = true;
        _healthData = health;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.server,
                  color:
                      _isChecking
                          ? Colors.grey
                          : _isConnected == true
                          ? Colors.green
                          : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backend Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_isChecking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    onPressed: _checkBackendHealth,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isChecking)
              const Text('Checking backend connection...')
            else if (_isConnected == true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Connected',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_healthData != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Environment: ${_healthData!['environment'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Version: ${_healthData!['version'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.xCircle, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Disconnected',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage ?? 'Unknown error',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure the backend server is running on localhost:8000',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
