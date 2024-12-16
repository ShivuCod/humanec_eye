import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/hive_config.dart';
import 'services.dart';

class SyncService {
  static Future<void> syncAttendance() async {
    final unsyncedAttendance = HiveAttendance.getUnsyncedAttendance();

    for (var attendance in unsyncedAttendance) {
      try {
        final success = await Services.addAttendance(
          empCode: attendance['empCode'],
          datetime: attendance['datetime'],
        );

        if (success) {
          await HiveAttendance.markAsSynced(attendance['key']);
          debugPrint('Attendance synced successfully');
        }
      } catch (e) {
        debugPrint('Error syncing attendance: $e');
      }
    }
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await SyncService.syncAttendance();
    return Future.value(true);
  });
}
