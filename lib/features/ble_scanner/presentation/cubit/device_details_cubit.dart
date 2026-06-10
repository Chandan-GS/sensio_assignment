import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sensio_assignment/features/ble_scanner/repository/ble_repository.dart';

part 'device_details_state.dart';

class DeviceDetailsCubit extends Cubit<DeviceDetailsState> {
  final BleRepository _bleRepository;
  final String deviceId;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  final Map<Uuid, StreamSubscription<List<int>>> _notificationSubscriptions =
      {};

  DeviceDetailsCubit({
    required BleRepository bleRepository,
    required this.deviceId,
  }) : _bleRepository = bleRepository,
       super(DeviceDetailsInitial()) {
    connect();
  }

  void connect() {
    emit(DeviceDetailsConnecting());
    _connectionSubscription?.cancel();
    _connectionSubscription = _bleRepository
        .connectToDevice(deviceId)
        .listen(
          (update) async {
            switch (update.connectionState) {
              case DeviceConnectionState.connecting:
                emit(DeviceDetailsConnecting());
                break;
              case DeviceConnectionState.connected:
                try {
                  // Request High Priority to prevent the peripheral from rejecting Android's default connection parameters
                  await _bleRepository.requestConnectionPriority(
                    deviceId,
                    ConnectionPriority.balanced,
                  );

                  // Request a higher MTU to ensure large payloads don't drop the connection
                  try {
                    await _bleRepository.requestMtu(deviceId, 512);
                  } catch (_) {
                    // Ignore MTU request failures, some devices don't support it
                  }

                  final services = await _bleRepository.discoverServices(
                    deviceId,
                  );
                  emit(DeviceDetailsConnected(services: services));
                } catch (e) {
                  emit(DeviceDetailsFailure('Failed to discover services: $e'));
                }
                break;
              case DeviceConnectionState.disconnecting:
                emit(DeviceDetailsDisconnecting());
                break;
              case DeviceConnectionState.disconnected:
                _cancelAllSubscriptions();
                emit(DeviceDetailsDisconnected());
                break;
            }
          },
          onError: (error) {
            emit(DeviceDetailsFailure('Connection error: $error'));
          },
        );
  }

  Future<void> disconnect() async {
    emit(DeviceDetailsDisconnecting());
    _cancelAllSubscriptions();
    await _connectionSubscription?.cancel();
    emit(DeviceDetailsDisconnected());
  }

  Future<void> readCharacteristicValue(
    QualifiedCharacteristic characteristic,
  ) async {
    final currentState = state;
    if (currentState is DeviceDetailsConnected) {
      try {
        final value = await _bleRepository.readCharacteristic(characteristic);

        final updatedValues = Map<Uuid, List<int>>.from(
          currentState.characteristicValues,
        );
        updatedValues[characteristic.characteristicId] = value;

        emit(currentState.copyWith(characteristicValues: updatedValues));
      } catch (e) {
        // Ignored, state preserved
      }
    }
  }

  Future<void> writeCharacteristicValue(
    QualifiedCharacteristic characteristic,
    List<int> value,
  ) async {
    final currentState = state;
    if (currentState is DeviceDetailsConnected) {
      try {
        await _bleRepository.writeCharacteristicWithResponse(
          characteristic,
          value,
        );
        // Automatically fetch latest value post-write
        await readCharacteristicValue(characteristic);
      } catch (e) {
        // Ignored, state preserved
      }
    }
  }

  void toggleNotifications(QualifiedCharacteristic characteristic) {
    final currentState = state;
    if (currentState is DeviceDetailsConnected) {
      final characteristicId = characteristic.characteristicId;
      final updatedNotifications = Set<Uuid>.from(
        currentState.activeNotifications,
      );

      if (_notificationSubscriptions.containsKey(characteristicId)) {
        _notificationSubscriptions[characteristicId]?.cancel();
        _notificationSubscriptions.remove(characteristicId);
        updatedNotifications.remove(characteristicId);
        emit(currentState.copyWith(activeNotifications: updatedNotifications));
      } else {
        final subscription = _bleRepository
            .subscribeToCharacteristic(characteristic)
            .listen(
              (value) {
                final latestState = state;
                if (latestState is DeviceDetailsConnected) {
                  final updatedValues = Map<Uuid, List<int>>.from(
                    latestState.characteristicValues,
                  );
                  updatedValues[characteristicId] = value;
                  emit(
                    latestState.copyWith(characteristicValues: updatedValues),
                  );
                }
              },
              onError: (error) {
                // Ignored, keep connection active
              },
            );

        _notificationSubscriptions[characteristicId] = subscription;
        updatedNotifications.add(characteristicId);
        emit(currentState.copyWith(activeNotifications: updatedNotifications));
      }
    }
  }

  void _cancelAllSubscriptions() {
    for (final subscription in _notificationSubscriptions.values) {
      subscription.cancel();
    }
    _notificationSubscriptions.clear();
  }

  @override
  Future<void> close() {
    _cancelAllSubscriptions();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
