import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensio_assignment/features/ble_scanner/repository/ble_repository.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/pages/scanner_page/screens/scanner_screen.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/scanner_cubit.dart';
import 'package:sensio_assignment/features/ble_scanner/presentation/cubit/device_details_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cubit/theme_cubit.dart';

void main() {
  runApp(const SensioAssignmentApp());
}

class SensioAssignmentApp extends StatelessWidget {
  const SensioAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => BleRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(
            create: (context) => DeviceDetailsCubit(
              bleRepository: RepositoryProvider.of<BleRepository>(context),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Sensio Assignment',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: BlocProvider(
                create: (context) => ScannerCubit(
                  bleRepository: RepositoryProvider.of<BleRepository>(context),
                ),
                child: const ScannerPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}
