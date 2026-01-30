import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Compliance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Privacy-first design', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('- No screen capture, no keystroke logging.'),
          Text('- Only aggregated, privacy-safe signals used for AI idle detection.'),
          Text('- Full audit logs and data retention controls managed on server.'),
        ]),
      ),
    );
  }
}
