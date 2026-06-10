import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ScannerInitialView extends StatelessWidget {
  const ScannerInitialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 3),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            'No BLE devices connected.\nTap the button to start scanning.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Spacer(flex: 1),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 100.0, bottom: 20.0),
            child: SvgPicture.asset(
              'assets/images/wavy_arrow.svg',
              width: 80,
              height: 200,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
