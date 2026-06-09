part of 'scanner_cubit.dart';

@immutable
sealed class ScannerState {}

final class ScannerInitial extends ScannerState {}

final class ScannerRunning extends ScannerState {}

final class ScannerSuccess extends ScannerState {
  final List<BleDeviceModel> devices;
  ScannerSuccess({required this.devices});
}

final class ScannerFailure extends ScannerState {
  final String errorMessage;
  ScannerFailure({required this.errorMessage});
}
