import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sensio_assignment/features/ble_scanner/data/models/ble_device_model.dart';

part 'scanner_state.dart';

class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit() : super(ScannerInitial());

  void startScan() {
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
