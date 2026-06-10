import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sensio_assignment/features/ble_scanner/repository/ble_repository.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensio_assignment/core/services/foreground_task_handler.dart';

part 'device_details_state.dart';

class DeviceDetailsCubit extends Cubit<DeviceDetailsState> {
  final BleRepository _bleRepository;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  final Map<Uuid, StreamSubscription<List<int>>> _notificationSubscriptions =
      {};

  DeviceDetailsCubit({required BleRepository bleRepository})
    : _bleRepository = bleRepository,
      super(const DeviceDetailsInitial()) {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map<String, dynamic> && data['action'] == 'disconnect') {
      disconnect();
    }
  }

  void connect(BleDeviceModel device) async {
    if (state.device != null && state.device!.id != device.id) {
      await disconnect();
    }

    if (state is DeviceDetailsConnected && state.device?.id == device.id) {
      return;
    }

    emit(DeviceDetailsConnecting(device: device));
    _connectionSubscription?.cancel();
    _connectionSubscription = _bleRepository
        .connectToDevice(device.id)
        .listen(
          (update) async {
            switch (update.connectionState) {
              case DeviceConnectionState.connecting:
                emit(DeviceDetailsConnecting(device: device));
                break;
              case DeviceConnectionState.connected:
                try {
                  // Give the BLE stack a moment to stabilize the connection
                  await Future.delayed(const Duration(milliseconds: 1000));

                  final services = await _bleRepository.discoverServices(
                    device.id,
                  );
                  emit(
                    DeviceDetailsConnected(device: device, services: services),
                  );
                  ForegroundServiceManager.startService(device.name);
                } catch (e) {
                  emit(
                    DeviceDetailsFailure(
                      'Failed to discover services: $e',
                      device: device,
                    ),
                  );
                }
                break;
              case DeviceConnectionState.disconnecting:
                emit(DeviceDetailsDisconnecting(device: device));
                break;
              case DeviceConnectionState.disconnected:
                _cancelAllSubscriptions();
                emit(DeviceDetailsDisconnected(device: device));
                break;
            }
          },
          onError: (error) {
            emit(
              DeviceDetailsFailure('Connection error: $error', device: device),
            );
          },
        );
  }

  Future<void> disconnect() async {
    final currentDevice = state.device;
    emit(DeviceDetailsDisconnecting(device: currentDevice));
    ForegroundServiceManager.stopService();
    _cancelAllSubscriptions();
    await _connectionSubscription?.cancel();
    emit(DeviceDetailsDisconnected(device: currentDevice));
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
        await readCharacteristicValue(characteristic);
      } catch (e) {
        /**ignored*/
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
            .listen((value) {
              final latestState = state;
              if (latestState is DeviceDetailsConnected) {
                final updatedValues = Map<Uuid, List<int>>.from(
                  latestState.characteristicValues,
                );
                updatedValues[characteristicId] = value;
                emit(latestState.copyWith(characteristicValues: updatedValues));
              }
            }, onError: (error) {});

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
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    ForegroundServiceManager.stopService();
    _cancelAllSubscriptions();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
