import 'package:flutter/material.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';
import 'signal_strength_indicator.dart';

class BleDeviceListTile extends StatelessWidget {
  final BleDeviceModel device;
  final VoidCallback onTap;

  const BleDeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(
        //   color: isDark
        //       ? Colors.white.withValues(alpha: 0.05)
        //       : Colors.black.withValues(alpha: 0.04),
        //   width: 1,
        // ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bluetooth_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            device.id,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${device.rssi} dBm',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            SignalStrengthIndicator(rssi: device.rssi),
          ],
        ),
      ),
    );
  }
}
