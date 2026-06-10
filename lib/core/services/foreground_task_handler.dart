import 'dart:isolate';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyForegroundTaskHandler());
}

class MyForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Foreground task started: ${starter.name}');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Keep alive
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('Foreground task destroyed (timeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {
    print('Foreground task received data: $data');
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('Notification button pressed: $id');
    if (id == 'btn_disconnect') {
      FlutterForegroundTask.sendDataToMain({'action': 'disconnect'});
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

class ForegroundServiceManager {
  static Future<void> requestPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  static void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'Keeps BLE connection alive in the background.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<ServiceRequestResult> startService(String deviceName) async {
    await requestPermissions();
    initService();

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.updateService(
        notificationTitle: 'Connected to $deviceName',
        notificationText: 'Running in the background',
      );
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Connected to $deviceName',
        notificationText: 'Running in the background',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: 'btn_disconnect', text: 'Disconnect'),
        ],
        callback: startCallback,
      );
    }
  }

  static Future<ServiceRequestResult> stopService() async {
    return FlutterForegroundTask.stopService();
  }
}
