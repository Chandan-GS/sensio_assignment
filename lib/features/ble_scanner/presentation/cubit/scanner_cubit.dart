import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';

part 'scanner_state.dart';

class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit() : super(ScannerInitial());

  Future<void> startScan() async {
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
  }

  void stopScan() {
    emit(ScannerInitial());
  }

  void addDevice(BleDeviceModel device) {
    emit(ScannerSuccess(devices: [device]));
  }

  void setError(String errorMessage) {
    emit(ScannerFailure(errorMessage: errorMessage));
  }
}
