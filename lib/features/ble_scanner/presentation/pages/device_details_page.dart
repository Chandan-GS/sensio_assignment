import 'package:flutter/material.dart';

class DeviceDetailsPage extends StatelessWidget {
  const DeviceDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Details'),
      ),
      body: const Center(
        child: Text('Device Details Page'),
      ),
    );
  }
}
