import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';
import 'package:sensio_assignment/features/ble_scanner/repository/ble_repository.dart';

part 'scanner_state.dart';

class ScannerCubit extends Cubit<ScannerState> {
  final BleRepository _bleRepository;
  StreamSubscription? _scanSubscription;
  final List<BleDeviceModel> _devices = [];

  ScannerCubit({required BleRepository bleRepository})
    : _bleRepository = bleRepository,
      super(ScannerInitial());

  void startScan() {
    _startScan();
  }

  void stopScan() {
    _scanSubscription?.cancel();
    emit(ScannerInitial());
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }

  Future<void> _startScan() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      final locationGranted = statuses[Permission.location]?.isGranted ?? false;
      final scanGranted =
          statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted =
          statuses[Permission.bluetoothConnect]?.isGranted ?? false;

      if (!locationGranted || !scanGranted || !connectGranted) {
        emit(
          ScannerFailure(
            errorMessage:
                'Location and Bluetooth permissions are required to scan.',
            isPermissionError: true,
          ),
        );
        return;
      }
    }

    emit(ScannerRunning());
    _devices.clear();
    await _scanSubscription?.cancel();

    _scanSubscription = _bleRepository.scanDevices().listen(
      (device) {
        final model = BleDeviceModel.fromDiscoveredDevice(device);
        if (!_devices.contains(model)) {
          _devices.add(model);
          _devices.sort((a, b) => b.rssi.compareTo(a.rssi));
          emit(ScannerSuccess(devices: List.from(_devices)));
        }
      },
      onError: (error) {
        emit(ScannerFailure(errorMessage: error.toString()));
      },
    );
  }
}
