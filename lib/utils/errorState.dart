import 'package:flutter/material.dart';
import '../utils/colors.dart'; // your custom color

enum ErrorType { server, network, empty, unauthorized, unknown }

class ErrorStatePage extends StatelessWidget {
  final ErrorType type;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorStatePage({
    super.key,
    required this.type,
    this.message,
    this.onRetry,
  });

  String get _title {
    switch (type) {
      case ErrorType.server:
        return "Server Error";
      case ErrorType.network:
        return "Network Error";
      case ErrorType.empty:
        return "No Data Available";
      case ErrorType.unauthorized:
        return "Unauthorized Access";
      default:
        return "Something went wrong";
    }
  }

  IconData get _icon {
    switch (type) {
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.empty:
        return Icons.inbox;
      case ErrorType.unauthorized:
        return Icons.lock_outline;
      default:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 80, color: kPrimaryColor),
            const SizedBox(height: 16),
            Text(
              _title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Retry"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
