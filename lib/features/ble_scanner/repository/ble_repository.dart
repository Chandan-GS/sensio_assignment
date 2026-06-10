import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleRepository {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  Stream<DiscoveredDevice> scanDevices({List<Uuid> withServices = const []}) {
    return _ble.scanForDevices(
      withServices: withServices,
      scanMode: ScanMode.lowLatency,
    );
  }

  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    return _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    );
  }

  Future<List<Service>> discoverServices(String deviceId) async {
    await _ble.discoverAllServices(deviceId);
    return await _ble.getDiscoveredServices(deviceId);
  }

  Future<void> requestConnectionPriority(
    String deviceId,
    ConnectionPriority priority,
  ) async {
    await _ble.requestConnectionPriority(
      deviceId: deviceId,
      priority: priority,
    );
  }

  Future<int> requestMtu(String deviceId, int mtu) async {
    return await _ble.requestMtu(deviceId: deviceId, mtu: mtu);
  }

  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  ) {
    return _ble.subscribeToCharacteristic(characteristic);
  }

  Future<List<int>> readCharacteristic(
    QualifiedCharacteristic characteristic,
  ) async {
    return await _ble.readCharacteristic(characteristic);
  }

  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic,
    List<int> value,
  ) async {
    await _ble.writeCharacteristicWithResponse(characteristic, value: value);
  }

  Future<void> writeCharacteristicWithoutResponse(
    QualifiedCharacteristic characteristic,
    List<int> value,
  ) async {
    await _ble.writeCharacteristicWithoutResponse(characteristic, value: value);
  }

  static const _kVitalsServiceUuids = {'0000180d00001000800000805f9b34fb'};

  String cleanUuid(String uuid) => uuid.toLowerCase().replaceAll('-', '');

  bool isVitalsService(String uuid) =>
      _kVitalsServiceUuids.contains(cleanUuid(uuid));

  String getGattName(String uuid) {
    final u = cleanUuid(uuid);
    if (u.contains('2a37')) return 'Heart Rate Measurement';
    if (u.contains('2a5f')) return 'SpO2 Measurement';
    if (u.contains('2a6e')) return 'Temperature';
    if (u.contains('180d')) return 'Heart Rate Service';
    if (u.contains('1822')) return 'Pulse Oximeter Service';
    if (u.contains('2a00')) return 'Device Name';
    if (u.contains('2a29')) return 'Manufacturer Name';
    if (u.contains('180a')) return 'Device Information Service';
    return 'GATT Characteristic';
  }

  IconData getServiceIcon(String uuid) {
    final u = cleanUuid(uuid);
    if (u.contains('180d')) return Icons.favorite_rounded;
    if (u.contains('1822')) return Icons.water_drop_rounded;
    if (u.contains('181a')) return Icons.thermostat_rounded;
    if (u.contains('180f')) return Icons.battery_charging_full_rounded;
    if (u.contains('1805')) return Icons.watch_later_rounded;
    if (u.contains('180a')) return Icons.info_rounded;
    return Icons.settings_input_antenna_rounded;
  }

  int parseNumericValue(String uuid, List<int> bytes) {
    if (bytes.isEmpty) return 0;
    final u = cleanUuid(uuid);

    if (u.contains('2a37')) {
      return bytes.length >= 2 ? bytes[1] : bytes[0];
    }
    if (u.contains('2a5f')) {
      return bytes[0];
    }
    if (u.contains('2a6e')) {
      if (bytes.length >= 2) {
        final raw = bytes[0] | (bytes[1] << 8);
        return raw ~/ 10;
      }
      return bytes[0];
    }
    return bytes.length >= 2 ? bytes[1] : bytes[0];
  }

  String getFormattedValue(String uuid, List<int> bytes) {
    if (bytes.isEmpty) return 'No Data';
    final u = cleanUuid(uuid);

    if (u.contains('2a37')) {
      return bytes.length >= 2 ? '${bytes[1]} BPM' : '${bytes[0]} BPM';
    }
    if (u.contains('2a5f')) {
      return '${bytes[0]}%';
    }
    if (u.contains('2a6e')) {
      if (bytes.length >= 2) {
        final raw = bytes[0] | (bytes[1] << 8);
        return '${(raw / 10.0).toStringAsFixed(1)}°C';
      }
      return '${bytes[0]}°C';
    }
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return 'Unknown data';
    }
  }
}
