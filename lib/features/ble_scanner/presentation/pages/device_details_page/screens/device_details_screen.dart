import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
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
    if (cleanUuid.contains('180f')) return 'Battery Service';
    if (cleanUuid.contains('1805')) return 'Current Time Service';
    if (cleanUuid.contains('180a')) return 'Device Information Service';
    if (cleanUuid.contains('1809')) return 'Health Thermometer Service';
    return 'GATT Characteristic';
  }

  IconData _getServiceIcon(String uuid) {
    final cleanUuid = uuid.toLowerCase().replaceAll('-', '');
    if (cleanUuid.contains('180d')) return Icons.favorite_rounded;
    if (cleanUuid.contains('180f')) return Icons.battery_charging_full_rounded;
    if (cleanUuid.contains('1805')) return Icons.watch_later_rounded;
    if (cleanUuid.contains('180a')) return Icons.info_rounded;
    if (cleanUuid.contains('1809')) return Icons.thermostat_rounded;
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

  void _showWriteDialog(
    BuildContext context,
    QualifiedCharacteristic characteristic,
  ) {
    final textController = TextEditingController();
    var isHex = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Write Command',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(bottomSheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    characteristic.characteristicId.toString(),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isHex ? 'e.g. 01 02 FF' : 'e.g. Hello',
                      labelText: isHex ? 'Hexadecimal Payload' : 'Text Payload',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code_rounded, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Format as HEX bytes',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: isHex,
                        activeTrackColor: theme.colorScheme.secondary,
                        onChanged: (val) {
                          setDialogState(() {
                            isHex = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        List<int> bytes;
                        if (isHex) {
                          final cleanHex = textController.text.replaceAll(
                            ' ',
                            '',
                          );
                          try {
                            bytes = [];
                            for (var i = 0; i < cleanHex.length; i += 2) {
                              bytes.add(
                                int.parse(
                                  cleanHex.substring(i, i + 2),
                                  radix: 16,
                                ),
                              );
                            }
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invalid Hex format'),
                              ),
                            );
                            return;
                          }
                        } else {
                          bytes = utf8.encode(textController.text);
                        }
                        context
                            .read<DeviceDetailsCubit>()
                            .writeCharacteristicValue(characteristic, bytes);
                        Navigator.pop(bottomSheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Send Write Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          'Device Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
                  const SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(strokeWidth: 3.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Establishing Secure Connection...',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exchanging GATT security keys',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bluetooth_disabled_rounded,
                        size: 54,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Connection Lost',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The Bluetooth session was terminated cleanly or the peripheral went out of range.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<DeviceDetailsCubit>().connect(),
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Reconnect Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 54,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Session Failure',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<DeviceDetailsCubit>().connect(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
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
                // 1. Premium Device Meta Header Card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.device.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      widget.device.id,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(text: widget.device.id),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('MAC Address copied'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Pulse badge showing active status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PulseDot(color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'CONNECTED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context
                                  .read<DeviceDetailsCubit>()
                                  .disconnect(),
                              icon: const Icon(
                                Icons.link_off_rounded,
                                size: 18,
                              ),
                              label: const Text('Disconnect Session'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 1.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Real-Time Vitals / Subscribed Streams Card
                if (activeNotifyIds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    key: const ValueKey('vitals_title'),
                    child: Row(
                      children: [
                        const PulseDot(color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE VITALS RADAR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
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

                // 3. Discovered GATT Services List
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text(
                    'DISCOVERED GATT SERVICES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey[500],
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

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          shape: const Border(),
                          iconColor: theme.colorScheme.secondary,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getServiceIcon(serviceUuid),
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _getGattName(serviceUuid),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            serviceUuid,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontFamily: 'monospace',
                            ),
                          ),
                          childrenPadding: const EdgeInsets.all(12),
                          children: service.characteristics.map((
                            characteristic,
                          ) {
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
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              charName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              charUuid,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildPropertyBadge(
                                        'READ',
                                        characteristic.isReadable,
                                      ),
                                      _buildPropertyBadge(
                                        'WRITE',
                                        characteristic.isWritableWithResponse ||
                                            characteristic
                                                .isWritableWithoutResponse,
                                      ),
                                      _buildPropertyBadge(
                                        'NOTIFY',
                                        characteristic.isNotifiable,
                                      ),
                                      _buildPropertyBadge(
                                        'INDICATE',
                                        characteristic.isIndicatable,
                                      ),
                                    ],
                                  ),
                                  if (lastVal != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'VALUE READOUT',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  final readableString = utf8
                                                      .decode(
                                                        lastVal,
                                                        allowMalformed: true,
                                                      );
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text: readableString,
                                                    ),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Value copied',
                                                      ),
                                                      duration: Duration(
                                                        seconds: 1,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.copy_rounded,
                                                  size: 12,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Hex: ${lastVal.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Text: ${utf8.decode(lastVal, allowMalformed: true)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // Button interaction pill row
                                  Row(
                                    children: [
                                      if (characteristic.isReadable) ...[
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () => context
                                                .read<DeviceDetailsCubit>()
                                                .readCharacteristicValue(
                                                  qualChar,
                                                ),
                                            icon: const Icon(
                                              Icons.arrow_downward_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Read',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.secondary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.08),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (characteristic
                                              .isWritableWithResponse ||
                                          characteristic
                                              .isWritableWithoutResponse) ...[
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () => _showWriteDialog(
                                              context,
                                              qualChar,
                                            ),
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Write',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.secondary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.08),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (characteristic.isNotifiable ||
                                          characteristic.isIndicatable) ...[
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () => context
                                                .read<DeviceDetailsCubit>()
                                                .toggleNotifications(qualChar),
                                            icon: Icon(
                                              isSubscribed
                                                  ? Icons
                                                        .notifications_active_rounded
                                                  : Icons
                                                        .notifications_none_rounded,
                                              size: 16,
                                            ),
                                            label: Text(
                                              isSubscribed
                                                  ? 'Subscribed'
                                                  : 'Subscribe',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: isSubscribed
                                                  ? Colors.white
                                                  : theme.colorScheme.secondary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              backgroundColor: isSubscribed
                                                  ? theme.colorScheme.secondary
                                                  : theme.colorScheme.secondary
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
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

  Widget _buildPropertyBadge(String label, bool isEnabled) {
    if (!isEnabled) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.blue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
