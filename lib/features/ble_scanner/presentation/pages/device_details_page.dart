import 'package:flutter/material.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';

class DeviceDetailsPage extends StatelessWidget {
  final BleDeviceModel device;

  const DeviceDetailsPage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: Center(
        child: Text('Device ID: ${device.id}'),
      ),
    );
  }
}
