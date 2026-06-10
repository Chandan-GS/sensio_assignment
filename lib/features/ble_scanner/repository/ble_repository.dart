import 'dart:async';
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

  Stream<List<int>> subscribeToCharacteristic(QualifiedCharacteristic characteristic) {
    return _ble.subscribeToCharacteristic(characteristic);
  }

  Future<List<int>> readCharacteristic(QualifiedCharacteristic characteristic) async {
    return await _ble.readCharacteristic(characteristic);
  }
}
