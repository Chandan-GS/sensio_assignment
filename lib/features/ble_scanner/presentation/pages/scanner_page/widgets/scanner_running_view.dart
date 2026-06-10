import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ScannerRunningView extends StatelessWidget {
  const ScannerRunningView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LottieBuilder.asset(
            'assets/animations/bluetooth_animation.json',
            animate: true,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(const [
                  '**',
                ], value: Theme.of(context).colorScheme.secondary),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
