import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:lottie/lottie.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';
import 'package:sensio_assignment/features/ble_scanner/repository/ble_repository.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/device_details_cubit.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/device_details_page/widgets/pulse_dot.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/device_details_page/widgets/vitals_visualizer.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/device_details_page/widgets/characteristic_tile.dart';

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

  void _updateChartHistory(Map<Uuid, List<int>> values) {
    final repository = context.read<BleRepository>();
    values.forEach((uuid, valueBytes) {
      final val = repository.parseNumericValue(uuid.toString(), valueBytes);
      final list = List<int>.from(_chartHistory[uuid] ?? []);
      if (list.isEmpty || list.last != val) {
        list.add(val);
        if (list.length > 25) list.removeAt(0);
        _chartHistory[uuid] = list;
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
            setState(() => _updateChartHistory(state.characteristicValues));
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
                        ], value: theme.colorScheme.secondary),
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

            final repository = context.read<BleRepository>();

            // Split services into vitals vs other
            final vitalsServices = state.services
                .where((s) => repository.isVitalsService(s.id.toString()))
                .toList();
            final otherServices = state.services
                .where((s) => !repository.isVitalsService(s.id.toString()))
                .toList();

            // Flatten all characteristics from all vitals services
            final vitalsCharWidgets = <Widget>[
              for (final service in vitalsServices)
                for (final characteristic in service.characteristics)
                  CharacteristicTile(
                    characteristic: characteristic,
                    service: service,
                    deviceId: widget.device.id,
                    lastVal: state.characteristicValues[characteristic.id],
                    isSubscribed: state.activeNotifications.contains(
                      characteristic.id,
                    ),
                  ),
            ];

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

                // ── Live Vitals charts ────────────────────────────────────
                if (activeNotifyIds.isNotEmpty) ...[
                  _sectionHeader('Live Vitals', theme),
                  ...activeNotifyIds.map((uuid) {
                    final history = _chartHistory[uuid] ?? [];
                    if (history.isEmpty) return const SizedBox.shrink();
                    final charUuid = repository.cleanUuid(uuid.toString());
                    VitalType type = VitalType.unknown;
                    if (charUuid.contains('2a37')) type = VitalType.heartRate;
                    if (charUuid.contains('2a5f')) type = VitalType.spo2;
                    if (charUuid.contains('2a6e')) type = VitalType.temperature;

                    return VitalsVisualizer(
                      key: ValueKey('chart_$uuid'),
                      values: history,
                      title: repository.getGattName(uuid.toString()),
                      type: type,
                    );
                  }),
                ],

                _sectionHeader('Services & Characteristics', theme),

                if (vitalsCharWidgets.isNotEmpty)
                  Card(
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
                      key: const PageStorageKey('vitals_expansion'),
                      shape: const Border(),
                      initiallyExpanded: true,
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.monitor_heart_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Vitals Services',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Heart Rate · SpO2 · Temperature',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(16),
                      children: vitalsCharWidgets,
                    ),
                  ),

                ...otherServices.map((service) {
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
                      key: PageStorageKey(serviceUuid),
                      shape: const Border(),
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          repository.getServiceIcon(serviceUuid),
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        repository.getGattName(serviceUuid),
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
                      children: service.characteristics
                          .map(
                            (c) => CharacteristicTile(
                              characteristic: c,
                              service: service,
                              deviceId: widget.device.id,
                              lastVal: state.characteristicValues[c.id],
                              isSubscribed: state.activeNotifications.contains(
                                c.id,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                }),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
