import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/scanner_cubit.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/widgets/scanner_failure_view.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/widgets/scanner_initial_view.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/widgets/scanner_running_view.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Permissions Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Bluetooth and Location permissions are permanently denied. Please enable them in your device settings to start scanning.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "BlueNode",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
        ),
      ),
      body: BlocListener<ScannerCubit, ScannerState>(
        listener: (context, state) async {
          if (state is ScannerFailure && state.isPermissionError) {
            final isLocationPermanentlyDenied =
                await Permission.location.isPermanentlyDenied;
            final isScanPermanentlyDenied =
                await Permission.bluetoothScan.isPermanentlyDenied;
            final isConnectPermanentlyDenied =
                await Permission.bluetoothConnect.isPermanentlyDenied;

            if (isLocationPermanentlyDenied ||
                isScanPermanentlyDenied ||
                isConnectPermanentlyDenied) {
              if (context.mounted) {
                _showPermissionDialog(context);
              }
            }
          }
        },
        child: BlocBuilder<ScannerCubit, ScannerState>(
          builder: (context, state) {
            if (state is ScannerInitial) {
              return const ScannerInitialView();
            }
            if (state is ScannerRunning) {
              return const ScannerRunningView();
            }
            if (state is ScannerSuccess) {
              return ListView.builder(
                itemCount: state.devices.length,
                itemBuilder: (context, index) {
                  final device = state.devices[index];
                  return ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.id),
                  );
                },
              );
            }
            if (state is ScannerFailure) {
              return ScannerFailureView(
                errorMessage: state.errorMessage,
                isPermissionError: state.isPermissionError,
                onRetry: () => context.read<ScannerCubit>().startScan(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: BlocBuilder<ScannerCubit, ScannerState>(
        builder: (context, state) {
          final isScanning = state is ScannerRunning;
          return FloatingActionButton.large(
            onPressed: () {
              if (isScanning) {
                context.read<ScannerCubit>().stopScan();
              } else {
                context.read<ScannerCubit>().startScan();
              }
            },
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Icon(isScanning ? Icons.stop : Icons.bluetooth_searching),
          );
        },
      ),
    );
  }
}
