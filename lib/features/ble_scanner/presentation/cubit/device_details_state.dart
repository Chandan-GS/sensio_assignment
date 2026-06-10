part of 'device_details_cubit.dart';

@immutable
abstract class DeviceDetailsState {}

class DeviceDetailsInitial extends DeviceDetailsState {}

class DeviceDetailsConnecting extends DeviceDetailsState {}

class DeviceDetailsConnected extends DeviceDetailsState {
  final List<Service> services;
  final Map<Uuid, List<int>> characteristicValues;
  final Set<Uuid> activeNotifications;

  DeviceDetailsConnected({
    required this.services,
    this.characteristicValues = const {},
    this.activeNotifications = const {},
  });

  DeviceDetailsConnected copyWith({
    List<Service>? services,
    Map<Uuid, List<int>>? characteristicValues,
    Set<Uuid>? activeNotifications,
  }) {
    return DeviceDetailsConnected(
      services: services ?? this.services,
      characteristicValues: characteristicValues ?? this.characteristicValues,
      activeNotifications: activeNotifications ?? this.activeNotifications,
    );
  }
}

class DeviceDetailsDisconnecting extends DeviceDetailsState {}

class DeviceDetailsDisconnected extends DeviceDetailsState {}

class DeviceDetailsFailure extends DeviceDetailsState {
  final String errorMessage;

  DeviceDetailsFailure(this.errorMessage);
}
