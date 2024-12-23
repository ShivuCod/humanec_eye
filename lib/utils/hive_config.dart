import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

const String user = 'user';
const String offlineAttendance = 'offlineAttendance';

Future<void> loadHive() async {
  final path = await getApplicationDocumentsDirectory();
  Hive.init(path.path);
  await Hive.openBox(user);
  await Hive.openBox(offlineAttendance);
}

class HiveUser {
  static Box<dynamic> userBox() => Hive.box(user);

  static bool isFirstTime() => userBox().get('intro') ?? true;
  static doneFirstTime(bool? intro) => userBox().put('intro', intro);

  static String getAccessToken() => userBox().get('access_token') ?? '';
  static setAccessToken(String? accesstoken) =>
      userBox().put('access_token', accesstoken);

  static bool isSuperAdmin() => userBox().get('isSuperAdmin') ?? false;
  static setIsSuperAdmin(bool? admin) => userBox().put('isSuperAdmin', admin);

  static int getOrgId() => userBox().get('orgId') ?? 0;
  static setOrgId(int? orgId) => userBox().put('orgId', orgId);

  static String getName() => userBox().get('name') ?? '';
  static setName(String? name) => userBox().put('name', name);

  static String getUserName() => userBox().get('userName') ?? '';
  static setUserName(String? userName) => userBox().put('userName', userName);

  static setemPCODE(String empCode) => userBox().put('emP_CODE', empCode);

  static String? get emPCODE => userBox().get('emP_CODE');

  static setAdmin(bool value) => userBox().put("isAdmin", value);
  static bool get isAdmin => userBox().get('isAdmin') ?? false;

  static setHrHead(bool value) => userBox().put("isHr", value);
  static bool get isHr => userBox().get('isHr') ?? false;

  static String? get phoneNumber => userBox().get('phoneNumber');
  static setPhoneNumber(String phone) => userBox().put('phoneNumber', phone);

  static List<Map<String, dynamic>>? getFaces() {
    final faces = userBox().get('faces');
    if (faces == null) return null;
    List<Map<String, dynamic>> faceList = [];
    for (var face in faces) {
      faceList.add({
        'name': face['name'],
        'code': face['code'],
        'embedding': face['embedding'],
      });
    }

    return faceList;
  }

  static setFaces(List<Map<String, dynamic>>? faces) =>
      userBox().put('faces', faces);

  static clearFaces() => userBox().delete('faces');

  static addFace(Map<String, dynamic> face) {
    final faces = getFaces();
    if (faces == null) {
      setFaces([face]);
    } else {
      faces.add(face);
      setFaces(faces);
    }
  }

  static deleteFace(String empCode) {
    final faces = getFaces();
    faces?.removeWhere((face) => face['code'] == empCode);
    setFaces(faces);
  }

  static clearUserBox() {
    return userBox().clear();
  }

  static clearCache() {
    return userBox().delete('faces');
  }
}

class HiveAttendance {
  static Box<dynamic> attendanceBox() => Hive.box(offlineAttendance);

  // Save offline attendance
  static Future<void> saveAttendance(String empCode, String datetime) async {
    final attendance = {
      'empCode': empCode,
      'datetime': datetime,
      'isSynced': false,
    };
    await attendanceBox().add(attendance);
  }

  // Get all unsynced attendance
  static List<Map<String, dynamic>> getUnsyncedAttendance() {
    final box = attendanceBox();
    List<Map<String, dynamic>> unsynced = [];

    for (var i = 0; i < box.length; i++) {
      final attendance = box.getAt(i);
      if (attendance != null && attendance['isSynced'] == false) {
        unsynced.add({
          ...Map<String, dynamic>.from(attendance),
          'key': i, // Store the key for updating later
        });
      }
    }
    return unsynced;
  }

  // Mark attendance as synced
  static Future<void> markAsSynced(int key) async {
    final attendance = attendanceBox().getAt(key);
    if (attendance != null) {
      attendance['isSynced'] = true;
      await attendanceBox().putAt(key, attendance);
    }
  }

  // Clear synced attendance (optional cleanup)
  static Future<void> clearSyncedAttendance() async {
    final box = attendanceBox();
    final keys = box.keys.where((key) {
      final attendance = box.get(key);
      return attendance != null && attendance['isSynced'] == true;
    }).toList();

    for (var key in keys) {
      await box.delete(key);
    }
  }

  // Check if there's any unsynced attendance
  static bool hasUnsyncedAttendance() {
    return getUnsyncedAttendance().isNotEmpty;
  }
}
