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
    return _ble.connectToDevice(id: deviceId);
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
}
