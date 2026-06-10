import 'package:flutter/material.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';
import 'ble_device_list_tile.dart';

class ScannerSuccessView extends StatelessWidget {
  final List<BleDeviceModel> devices;
  final Function(BleDeviceModel) onDeviceTap;

  const ScannerSuccessView({
    super.key,
    required this.devices,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const Center(
        child: Text(
          'No devices found yet.\nSearching...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return BleDeviceListTile(
          device: device,
          onTap: () => onDeviceTap(device),
        );
      },
    );
  }
}
