import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

class User {
  String? accessToken;
  DateTime? tokenExpiration;
  dynamic refreshToken;
  dynamic refreshExpiration;
  int? orgId;
  String? name;
  String? userName;
  String? phoneNumber;
  dynamic emPCode;
  dynamic email;
  bool? isSuperAdmin;
  bool? isAdmin;
  bool? isHrHead;
  int? statusCode;
  String? message;

  User({
    this.accessToken,
    this.tokenExpiration,
    this.refreshToken,
    this.refreshExpiration,
    this.orgId,
    this.name,
    this.userName,
    this.phoneNumber,
    this.emPCode,
    this.email,
    this.isSuperAdmin,
    this.statusCode,
    this.message,
    this.isAdmin,
    this.isHrHead,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        accessToken: json["access_token"],
        tokenExpiration: json["token_expiration"] == null ? null : DateTime.parse(json["token_expiration"]),
        refreshToken: json["refresh_token"],
        refreshExpiration: json["refresh_expiration"],
        orgId: json["orgID"],
        name: json["name"],
        userName: json["userName"],
        phoneNumber: json["phoneNumber"],
        emPCode: json["emP_CODE"],
        email: json["email"],
        isSuperAdmin: json["isSuperAdmin"],
        statusCode: json["statusCode"],
        message: json["message"],
        isAdmin: json["isAdmin"],
        isHrHead: json["isHrHead"],
      );
}
