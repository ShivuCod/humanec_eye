import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:humanec_eye/widgets/custom_message.dart';
import 'package:intl/intl.dart';
import '../core/main_endpoint.dart';
import '../main.dart';
import '../models/attendance.dart';
import '../models/business.dart';
import '../models/employee.dart';
import '../models/user.dart';
import '../pages/login.dart';
import '../utils/hive_config.dart';

enum ConnectionStatus { disconnected, slow, good }

class Services {
  static Future<ConnectionStatus> checkInternetSpeed() async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(Uri.parse('https://google.com'))
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (response.statusCode == 200) {
        debugPrint(stopwatch.elapsedMilliseconds.toString());
        return stopwatch.elapsedMilliseconds <= 1500
            ? ConnectionStatus.good
            : ConnectionStatus.slow;
      } else {
        return ConnectionStatus.disconnected;
      }
    } on TimeoutException catch (_) {
      return ConnectionStatus.slow;
    } catch (e) {
      return ConnectionStatus.disconnected;
    }
  }

  static Future<User?> getLogin(
      {required String username, required String password}) async {
    try {
      // ConnectionStatus status = await checkInternetSpeed();
      // if (status == ConnectionStatus.disconnected) {
      //   showMessage(
      //     "Please connect with internet",
      //     navigatorKey.currentContext!,
      //   );
      // }

      debugPrint('username $username password $password');
      var params = {
        'username': username,
        'password': password,
      };
      const headers = {"Content-Type": "application/json"};
      http.Response resp = await http.post(Uri.parse(MainEndpoint.loginWithOtp),
          body: json.encode(params), headers: headers);
      debugPrint('resp is ${resp.body}');
      if (resp.statusCode >= 200 && resp.statusCode <= 299) {
        HiveUser.clearFaces();
        User user = userFromJson(resp.body);
        HiveUser.setAccessToken(user.accessToken);
        HiveUser.setIsSuperAdmin(user.isSuperAdmin);
        HiveUser.setOrgId(user.orgId);
        HiveUser.setName(user.name);
        HiveUser.setPhoneNumber(user.phoneNumber ?? '');
        // HiveUser.setUserName(user.userName);
        return user;
      }
    } catch (e) {
      debugPrint('error in login $e');
      throw Exception(e);
    }

    return null;
  }

  static Future<List<Employee>> getEmployees(String query, int page) async {
    try {
      String token = HiveUser.getAccessToken();
      var headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      };
      var params = {
        'pageNo': page,
        'pageSize': 10,
        'searchText': query,
        'orderBy': ''
      };
      http.Response resp = await http.post(
          Uri.parse("${MainEndpoint.employees}/Records"),
          headers: headers,
          body: json.encode(params));

      if (resp.statusCode >= 200 && resp.statusCode <= 299) {
        debugPrint('employees ${resp.body}');
        return employeeFromJson(resp.body);
      } else if (resp.statusCode == 401) {
        HiveUser.clearUserBox();
        Navigator.pushReplacementNamed(
            navigatorKey.currentContext!, LoginPage.routerName);
      }
    } catch (e) {
      debugPrint('error in employees $e');
      throw Exception(e);
    }
    return [];
  }

  static Future<bool> sendWithOTP(String phoneNumber) async {
    const headers = {"Content-Type": "application/json"};

    ConnectionStatus status = await checkInternetSpeed();
    if (status == ConnectionStatus.slow) {
      debugPrint('slow internet');
      showMessage(
          'Please wait connection is weak', navigatorKey.currentContext!);
    }
    http.Response resp = await http.post(
      Uri.parse(MainEndpoint.sendLoginOTP),
      body: json.encode({
        'username': phoneNumber,
      }),
      headers: headers,
    );

    debugPrint('sendWithOTP data ${resp.statusCode} ${resp.body}');

    if (resp.statusCode == 200) {
      final decodeData = json.decode(resp.body);
      debugPrint('decodeData $decodeData');
      if (decodeData[0]["IS_ACTIVE"] != 0) {
        return true;
      }
      return false;
    }

    return false;
  }

  static Future<List<Employee>> getRegisteredEmployees(String search, int page,
      {int? pageSize}) async {
    try {
      var params = {
        'pageNo': page,
        'pageSize': pageSize ?? 10,
        'searchText': search,
        'orderBy': ''
      };
      String token = HiveUser.getAccessToken();
      var headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };
      http.Response resp = await http.post(
          Uri.parse(MainEndpoint.registeredEmployees),
          body: json.encode(params),
          headers: headers);
      if (resp.statusCode >= 200 && resp.statusCode <= 299) {
        debugPrint('registered employees ${resp.body}');
        return employeeFromJson(resp.body);
      } else if (resp.statusCode == 401) {
        HiveUser.clearUserBox();
        Navigator.pushReplacementNamed(
            navigatorKey.currentContext!, LoginPage.routerName);
      }
    } catch (e) {
      debugPrint('employees $e');
      throw Exception(e);
    }
    return [];
  }

  // static Future<Map<String, dynamic>> addEmployees(
  //     {required String empCode,
  //     required String empName,
  //     required File image}) async {
  //   try {
  //     debugPrint('register params ${HiveUser.getOrgId()} emp');
  //     final url = Uri.parse(MicroServiceEndpoint.addEmployee);
  //     final request = http.MultipartRequest('POST', url);
  //     request.fields['emp_id'] = empCode;
  //     request.fields['name'] = empName;
  //     request.fields['org_id'] = '${HiveUser.getOrgId()}';
  //     String? fileName = image.path.split('/').last;
  //     var multipartFile = await http.MultipartFile.fromPath('image', image.path,
  //         filename: fileName);
  //     request.files.add(multipartFile);
  //     var resp = await request.send();
  //     debugPrint(
  //         'add params $empCode org ${HiveUser.getOrgId()} image $image emp resp ${resp.statusCode}');
  //     if (resp.statusCode >= 200 && resp.statusCode <= 299) {
  //       var response = await http.Response.fromStream(resp);
  //       final json = jsonDecode(response.body);
  //       debugPrint('addEmployees data $json');
  //       return json;
  //     }
  //   } catch (e) {
  //     debugPrint('error employees add $e');
  //     throw Exception(e);
  //   }
  //   return {};
  // }

  static Future<bool> registerEmployees({
    required String empCode,
    required String embeding,
    required String img,
  }) async {
    try {
      // ConnectionStatus status = await checkInternetSpeed();
      // if (status == ConnectionStatus.disconnected) {
      //   CustomSnackBar.customErrorSnackBar(
      //       navigatorKey.currentContext!, "Please connect with internet");
      //   return false;
      // }
      // if (status == ConnectionStatus.slow) {
      //   debugPrint('slow internet');
      //   CustomSnackBar.customErrorSnackBar(
      //       navigatorKey.currentContext!, 'Please wait connection is weak');
      // }
      String token = HiveUser.getAccessToken();
      final url = Uri.parse(MainEndpoint.employees);
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = "Bearer $token";
      request.fields['CODE'] = empCode;
      request.fields['ATTN_FLAG'] = 'true';
      request.fields['IMG_Base64'] = json.encode(embeding);
      request.files.add(await http.MultipartFile.fromPath('IMG_ATTN', img));
      debugPrint(request.fields.toString());
      var resp = await request.send();

      debugPrint(
          'register params $empCode image $embeding emp resp ${resp.statusCode}');
      if (resp.statusCode >= 200 && resp.statusCode <= 299) {
        return true;
      }
    } catch (e) {
      debugPrint('error employees register $e');
      throw Exception(e);
    }
    return false;
  }

  static Future<bool> removeEmployees({required String empCode}) async {
    try {
      String token = HiveUser.getAccessToken();
      final url = Uri.parse(MainEndpoint.employees);
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = "Bearer $token";
      request.fields['CODE'] = empCode;
      request.fields['ATTN_FLAG'] = 'false';
      var resp = await request.send();
      debugPrint('remove params $empCode emp resp ${resp.statusCode}');
      if (resp.statusCode >= 200 && resp.statusCode <= 299) {
        return true;
      }
    } catch (e) {
      debugPrint('error in remove employees $e');
      throw Exception(e);
    }
    return false;
  }

  // static Future<bool> deleteEmployee({required String empCode}) async {
  //   try {
  //     debugPrint('delete params ${HiveUser.getOrgId()} emp');
  //     http.Response resp = await http.delete(Uri.parse(
  //         '${MicroServiceEndpoint.deleteEmployee}/${HiveUser.getOrgId()}/$empCode'));
  //     debugPrint('delete params $empCode emp resp ${resp.statusCode}');
  //     if (resp.statusCode >= 200 && resp.statusCode <= 299) {
  //       return true;
  //     }
  //   } catch (e) {
  //     debugPrint('error in delete employee $e');
  //     throw Exception(e);
  //   }
  //   return false;
  // }

  static Future<bool> addAttendance(
      {required String empCode, required String datetime}) async {
    try {
      // ConnectionStatus status = await checkInternetSpeed();
      // debugPrint('status $status');
      // if (status == ConnectionStatus.slow) {
      //   debugPrint('slow internet');
      //   CustomSnackBar.customErrorSnackBar(
      //       navigatorKey.currentContext!, 'Please wait connection is weak');
      // }
      debugPrint('add attendance params $empCode $datetime');
      var params = [
        {
          'code': empCode,
          'loG_DATETIME': datetime,
        }
      ];
      String token = HiveUser.getAccessToken();
      var headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };
      http.Response resp = await http.post(Uri.parse(MainEndpoint.attendance),
          body: json.encode(params), headers: headers);

      debugPrint('=>>> ${resp.body} status ${resp.statusCode}');
      if (resp.statusCode >= 200 && resp.statusCode <= 299) {
        debugPrint(
            '=>>> add attendance ${resp.body} status ${resp.statusCode}');
        return true;
      } else if (resp.statusCode == 401) {
        HiveUser.clearUserBox();
        Navigator.pushReplacementNamed(
            navigatorKey.currentContext!, LoginPage.routerName);
      }
    } catch (e) {
      debugPrint('error in add attendance $e');
      throw Exception(e);
    }
    return false;
  }

  static Future<List<Attendance>> getAttendance() async {
    try {
      var params = {
        "emP_TYPE": "",
        "depT_ID": 0,
        "desG_ID": 0,
        "gradE_ID": 0,
        "brancH_ID": 0,
        "emP_CODE": "",
        "searchText": ""
      };
      String date = DateFormat('yyyyMMdd').format(DateTime.now());
      String token = HiveUser.getAccessToken();
      var headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };
      http.Response resp = await http.post(
          Uri.parse('${MainEndpoint.attendance}/$date'),
          body: json.encode(params),
          headers: headers);
      debugPrint(
          'url ${MainEndpoint.attendance}/$date get attendance ${resp.body}');
      if (resp.statusCode >= 200 && resp.statusCode <= 299) {
        return attendanceFromJson(resp.body);
      } else if (resp.statusCode == 401) {
        HiveUser.clearUserBox();
        Navigator.pushReplacementNamed(
            navigatorKey.currentContext!, LoginPage.routerName);
      }
    } catch (e) {
      debugPrint('error in show attendance $e');
      throw Exception(e);
    }
    return [];
  }

  static Future<List<Business>> allBusiness() async {
    try {
      final String token = HiveUser.getAccessToken();

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };

      final http.Response resp = await http.get(
        Uri.parse(MainEndpoint.business),
        headers: headers,
      );

      if (resp.statusCode == 200) {
        final decodeData = json.decode(resp.body);
        return List<Business>.from(
          decodeData.map(
            (x) => Business.fromJson(x),
          ),
        );
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  static Future<User?> switchBusiness(String id) async {
    try {
      final String token = HiveUser.getAccessToken();

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };

      final http.Response resp = await http.post(
        Uri.parse(
          MainEndpoint.switchBusiness,
        ),
        headers: headers,
        body: json.encode({
          'id': id,
        }),
      );

      debugPrint(
          'switching business resp.body  ${resp.body} ${resp.statusCode}');

      if (resp.statusCode == 200) {
        HiveUser.clearFaces();
        User user = userFromJson(resp.body);
        HiveUser.setAccessToken(user.accessToken);
        HiveUser.setIsSuperAdmin(user.isSuperAdmin);
        HiveUser.setOrgId(user.orgId);
        HiveUser.setName(user.name);
        HiveUser.setUserName(user.userName);

        return user;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> setPin(String pin) async {
    try {
      final String token = HiveUser.getAccessToken();

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };

      final http.Response resp = await http.post(
        Uri.parse(MainEndpoint.setPin),
        headers: headers,
        body: json.encode({
          'pin': pin,
        }),
      );

      debugPrint(
          'switching business resp.body${MainEndpoint.setPin} ${resp.body} ${resp.statusCode}');

      if (resp.statusCode == 201) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
