import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleDeviceModel {
  final String id;
  final String name;
  final int rssi;

  const BleDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
  });

  factory BleDeviceModel.fromDiscoveredDevice(DiscoveredDevice device) {
    return BleDeviceModel(
      id: device.id,
      name: device.name.isEmpty ? 'Unknown Device' : device.name,
      rssi: device.rssi,
    );
  }

  BleDeviceModel copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isConnectable,
  }) {
    return BleDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
