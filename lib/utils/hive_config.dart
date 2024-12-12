import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

const String user = 'user';

Future<void> loadHive() async {
  final path = await getApplicationDocumentsDirectory();
  Hive.init(path.path);
  await Hive.openBox(user);
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

  static deleteFace(String name) {
    final faces = getFaces();
    faces?.removeWhere((face) => face['name'] == name);
    setFaces(faces);
  }

  static clearUserBox() {
    return userBox().clear();
  }
}
