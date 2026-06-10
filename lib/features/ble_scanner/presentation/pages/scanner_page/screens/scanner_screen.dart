import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensio_assignment/core/theme/cubit/theme_cubit.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/scanner_cubit.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/device_details_cubit.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/device_details_page/screens/device_details_screen.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/scanner_page/widgets/scanner_failure_view.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/scanner_page/widgets/scanner_initial_view.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/scanner_page/widgets/scanner_running_view.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/scanner_page/widgets/scanner_success_view.dart';

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
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "BlueNode",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        actions: [
          BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
            builder: (context, detailsState) {
              if (detailsState is DeviceDetailsConnected &&
                  detailsState.device != null) {
                return IconButton(
                  icon: const Icon(
                    Icons.bluetooth_connected,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            DeviceDetailsPage(device: detailsState.device!),
                      ),
                    );
                  },
                );
              } else if (detailsState is DeviceDetailsConnecting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme();
                },
                icon: Icon(
                  state == ThemeMode.light ? Icons.mode_night : Icons.sunny,
                ),
              );
            },
          ),

          const SizedBox(width: 16),
        ],
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
              return ScannerSuccessView(
                devices: state.devices,
                onDeviceTap: (device) {
                  context.read<DeviceDetailsCubit>().connect(device);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DeviceDetailsPage(device: device),
                    ),
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
          final IconData icon;
          final VoidCallback onPressed;

          if (state is ScannerRunning) {
            icon = Icons.stop_rounded;
            onPressed = () => context.read<ScannerCubit>().stopScan();
          } else if (state is ScannerSuccess) {
            icon = Icons.refresh;
            onPressed = () => context.read<ScannerCubit>().startScan();
          } else {
            icon = Icons.bluetooth_searching;
            onPressed = () => context.read<ScannerCubit>().startScan();
          }

          return FloatingActionButton.large(
            onPressed: onPressed,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Icon(icon),
          );
        },
      ),
    );
  }
}
