part of 'device_details_cubit.dart';

@immutable
abstract class DeviceDetailsState {
  final BleDeviceModel? device;
  const DeviceDetailsState({this.device});
}

class DeviceDetailsInitial extends DeviceDetailsState {
  const DeviceDetailsInitial({super.device});
}

class DeviceDetailsConnecting extends DeviceDetailsState {
  const DeviceDetailsConnecting({super.device});
}

class DeviceDetailsConnected extends DeviceDetailsState {
  final List<Service> services;
  final Map<Uuid, List<int>> characteristicValues;
  final Set<Uuid> activeNotifications;

  const DeviceDetailsConnected({
    super.device,
    required this.services,
    this.characteristicValues = const {},
    this.activeNotifications = const {},
  });

  DeviceDetailsConnected copyWith({
    BleDeviceModel? device,
    List<Service>? services,
    Map<Uuid, List<int>>? characteristicValues,
    Set<Uuid>? activeNotifications,
  }) {
    return DeviceDetailsConnected(
      device: device ?? this.device,
      services: services ?? this.services,
      characteristicValues: characteristicValues ?? this.characteristicValues,
      activeNotifications: activeNotifications ?? this.activeNotifications,
    );
  }
}

class DeviceDetailsDisconnecting extends DeviceDetailsState {
  const DeviceDetailsDisconnecting({super.device});
}

class DeviceDetailsDisconnected extends DeviceDetailsState {
  const DeviceDetailsDisconnected({super.device});
}

class DeviceDetailsFailure extends DeviceDetailsState {
  final String errorMessage;

  const DeviceDetailsFailure(this.errorMessage, {super.device});
}
