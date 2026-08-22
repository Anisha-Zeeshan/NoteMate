import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_ai_service.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() =>
      _ConnectivityBannerState();
}

class _ConnectivityBannerState
    extends State<ConnectivityBanner> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity()
        .onConnectivityChanged
        .listen((result) {
      if (mounted) {
        setState(() {
          _isOnline = !result
              .contains(ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result =
    await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = !result
            .contains(ConnectivityResult.none);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();

    final aiReady = OfflineAIService().isReady;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: aiReady
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: aiReady
              ? Colors.green.withOpacity(0.4)
              : Colors.orange.withOpacity(0.4),
        ),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
            aiReady ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          aiReady
              ? '📱 Offline mode · AI ready'
              : '⏳ Offline mode · AI loading...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: aiReady
                ? Colors.green[700]
                : Colors.orange[700],
          ),
        ),
        const Spacer(),
        Icon(
          _isOnline ? Icons.wifi : Icons.wifi_off,
          size: 14,
          color: aiReady
              ? Colors.green[700]
              : Colors.orange[700],
        ),
      ]),
    );
  }
}