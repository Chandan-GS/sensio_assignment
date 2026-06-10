import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:lottie/lottie.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';
import 'package:sensio_assignment/features/ble_scanner/repository/ble_repository.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/device_details_cubit.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/device_details_page/widgets/pulse_dot.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/device_details_page/widgets/vitals_visualizer.dart';

class DeviceDetailsPage extends StatelessWidget {
  final BleDeviceModel device;

  const DeviceDetailsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceDetailsCubit(
        bleRepository: RepositoryProvider.of<BleRepository>(context),
        deviceId: device.id,
      ),
      child: DeviceDetailsView(device: device),
    );
  }
}

class DeviceDetailsView extends StatefulWidget {
  final BleDeviceModel device;

  const DeviceDetailsView({super.key, required this.device});

  @override
  State<DeviceDetailsView> createState() => _DeviceDetailsViewState();
}

class _DeviceDetailsViewState extends State<DeviceDetailsView> {
  final Map<Uuid, List<int>> _chartHistory = {};

  String _getGattName(String uuid) {
    final cleanUuid = uuid.toLowerCase().replaceAll('-', '');
    if (cleanUuid.contains('2a37')) return 'Heart Rate Measurement';
    if (cleanUuid.contains('2a19')) return 'Battery Level';
    if (cleanUuid.contains('2a2b')) return 'Current Time';
    if (cleanUuid.contains('2a00')) return 'Device Name';
    if (cleanUuid.contains('2a29')) return 'Manufacturer Name';
    if (cleanUuid.contains('2a6e')) return 'Temperature';
    if (cleanUuid.contains('180d')) return 'Heart Rate Service';
    if (cleanUuid.contains('2A5F')) return 'SpO2 Service';
    if (cleanUuid.contains('1805')) return 'Current Time Service';
    if (cleanUuid.contains('180a')) return 'Device Information Service';
    if (cleanUuid.contains('181a')) return 'Temperature Service';
    return 'GATT Characteristic';
  }

  IconData _getServiceIcon(String uuid) {
    final cleanUuid = uuid.toLowerCase().replaceAll('-', '');
    if (cleanUuid.contains('180d')) return Icons.favorite_rounded;
    if (cleanUuid.contains('180f')) return Icons.battery_charging_full_rounded;
    if (cleanUuid.contains('1805')) return Icons.watch_later_rounded;
    if (cleanUuid.contains('180a')) return Icons.info_rounded;
    if (cleanUuid.contains('181a')) return Icons.thermostat_rounded;
    return Icons.settings_input_antenna_rounded;
  }

  int _parseNumericValue(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    if (bytes.length == 1) return bytes.first;
    if (bytes.length >= 2) return bytes[1];
    return bytes.first;
  }

  void _updateChartHistory(Map<Uuid, List<int>> values) {
    values.forEach((uuid, valueBytes) {
      final val = _parseNumericValue(valueBytes);
      final list = _chartHistory[uuid] ?? [];
      if (list.isEmpty || list.last != val) {
        list.add(val);
        if (list.length > 25) {
          list.removeAt(0);
        }
        _chartHistory[uuid] = List.from(list);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          widget.device.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<DeviceDetailsCubit, DeviceDetailsState>(
        listener: (context, state) {
          if (state is DeviceDetailsConnected) {
            setState(() {
              _updateChartHistory(state.characteristicValues);
            });
          }
        },
        builder: (context, state) {
          if (state is DeviceDetailsConnecting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieBuilder.asset(
                    'assets/animations/bluetooth_animation.json',
                    animate: true,
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(const [
                          '**',
                        ], value: Theme.of(context).colorScheme.secondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connecting to device...',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is DeviceDetailsDisconnected) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Disconnected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The connection was lost or terminated.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<DeviceDetailsCubit>().connect(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Text('Reconnect'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DeviceDetailsFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connection Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<DeviceDetailsCubit>().connect(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DeviceDetailsConnected) {
            final activeNotifyIds = state.activeNotifications;

            return ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                const PulseDot(color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Connected',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'MAC: ${widget.device.id}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                context.read<DeviceDetailsCubit>().disconnect(),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Disconnect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (activeNotifyIds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 16,
                      bottom: 8,
                    ),
                    child: Text(
                      'Live Vitals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...activeNotifyIds.map((uuid) {
                    final history = _chartHistory[uuid] ?? [];
                    if (history.isEmpty) return const SizedBox.shrink();
                    return VitalsVisualizer(
                      key: ValueKey('chart_$uuid'),
                      values: history,
                      title: _getGattName(uuid.toString()),
                    );
                  }),
                ],

                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'Services & Characteristics',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.services.length,
                  itemBuilder: (context, serviceIndex) {
                    final service = state.services[serviceIndex];
                    final serviceUuid = service.id.toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      color: theme.cardColor,
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            _getServiceIcon(serviceUuid),
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _getGattName(serviceUuid),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          serviceUuid,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        children: service.characteristics.map((characteristic) {
                          final charUuid = characteristic.id.toString();
                          final charName = _getGattName(charUuid);
                          final qualChar = QualifiedCharacteristic(
                            characteristicId: characteristic.id,
                            serviceId: service.id,
                            deviceId: widget.device.id,
                          );

                          final lastVal =
                              state.characteristicValues[characteristic.id];
                          final isSubscribed = state.activeNotifications
                              .contains(characteristic.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildPropertyBadge(
                                      'READ',
                                      characteristic.isReadable,
                                      theme,
                                    ),
                                    _buildPropertyBadge(
                                      'WRITE',
                                      characteristic.isWritableWithResponse ||
                                          characteristic
                                              .isWritableWithoutResponse,
                                      theme,
                                    ),
                                    _buildPropertyBadge(
                                      'NOTIFY',
                                      characteristic.isNotifiable,
                                      theme,
                                    ),
                                    _buildPropertyBadge(
                                      'INDICATE',
                                      characteristic.isIndicatable,
                                      theme,
                                    ),
                                  ],
                                ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'VALUE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Hex: ${lastVal.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Text: ${utf8.decode(lastVal, allowMalformed: true)}',
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
                                        onPressed: () => context
                                            .read<DeviceDetailsCubit>()
                                            .readCharacteristicValue(qualChar),
                                        icon: const Icon(
                                          Icons.arrow_downward,
                                          size: 16,
                                        ),
                                        label: const Text('Read'),
                                      ),
                                    if (characteristic.isWritableWithResponse ||
                                        characteristic
                                            .isWritableWithoutResponse)
                                      ElevatedButton.icon(
                                        onPressed:
                                            () {}, // Write func kept static as requested
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Write'),
                                      ),
                                    if (characteristic.isNotifiable ||
                                        characteristic.isIndicatable)
                                      ElevatedButton.icon(
                                        onPressed: () => context
                                            .read<DeviceDetailsCubit>()
                                            .toggleNotifications(qualChar),
                                        icon: Icon(
                                          isSubscribed
                                              ? Icons.notifications_active
                                              : Icons.notifications_none,
                                          size: 16,
                                        ),
                                        label: Text(
                                          isSubscribed
                                              ? 'Subscribed'
                                              : 'Subscribe',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPropertyBadge(String label, bool isEnabled, ThemeData theme) {
    if (!isEnabled) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
