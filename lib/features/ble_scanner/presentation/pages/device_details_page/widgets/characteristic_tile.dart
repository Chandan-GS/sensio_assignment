import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sensio_assignment/features/ble_scanner/repository/ble_repository.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/device_details_cubit.dart';

class CharacteristicTile extends StatelessWidget {
  final Characteristic characteristic;
  final Service service;
  final String deviceId;
  final List<int>? lastVal;
  final bool isSubscribed;

  const CharacteristicTile({
    super.key,
    required this.characteristic,
    required this.service,
    required this.deviceId,
    required this.lastVal,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.read<BleRepository>();

    final charUuid = characteristic.id.toString();
    final charName = repository.getGattName(charUuid);
    final qualChar = QualifiedCharacteristic(
      characteristicId: characteristic.id,
      serviceId: service.id,
      deviceId: deviceId,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            charName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            charUuid,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),

          if (lastVal != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VALUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hex: ${lastVal!.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Parsed: ${repository.getFormattedValue(charUuid, lastVal!)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (characteristic.isReadable)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.cardColor,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () => context
                      .read<DeviceDetailsCubit>()
                      .readCharacteristicValue(qualChar),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Read'),
                ),
              if (characteristic.isWritableWithResponse ||
                  characteristic.isWritableWithoutResponse)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.cardColor,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Write'),
                ),
              if (characteristic.isNotifiable || characteristic.isIndicatable)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isSubscribed
                        ? theme.colorScheme.secondary
                        : theme.cardColor,
                    foregroundColor: isSubscribed
                        ? theme.colorScheme.onSecondary
                        : theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    context.read<DeviceDetailsCubit>().toggleNotifications(
                      qualChar,
                    );
                  },
                  icon: Icon(
                    color: isSubscribed
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,

                    isSubscribed
                        ? Icons.notifications_active
                        : Icons.notifications,
                    size: 16,
                  ),
                  label: Text(
                    isSubscribed ? 'Subscribed' : 'Subscribe',
                    style: TextStyle(
                      color: isSubscribed
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
