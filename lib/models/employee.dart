import 'dart:convert';

List<Employee> employeeFromJson(String str) =>
    List<Employee>.from(json.decode(str).map((x) => Employee.fromJson(x)));

class Employee {
  int? rownumber;
  int? totalrow;
  String? code;
  String? refCode;
  String? title;
  String? empName;
  int? branch;
  int? dept;
  int? desg;
  int? shift;
  String? empStatus;
  String? empType;
  String? empRm;
  String? empRm2;
  DateTime? doj;
  String? mobile;
  dynamic doe;
  String? attnId;
  String? deptName;
  String? desgName;
  String? imgAttn;
  dynamic img;
  dynamic rmName;
  dynamic rm2Name;

  Employee({
    this.rownumber,
    this.totalrow,
    this.code,
    this.refCode,
    this.title,
    this.empName,
    this.branch,
    this.dept,
    this.desg,
    this.shift,
    this.empStatus,
    this.empType,
    this.empRm,
    this.empRm2,
    this.doj,
    this.mobile,
    this.doe,
    this.attnId,
    this.deptName,
    this.desgName,
    this.imgAttn,
    this.img,
    this.rmName,
    this.rm2Name,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        rownumber: json["ROWNUMBER"],
        totalrow: json["TOTALROW"],
        code: json["CODE"],
        refCode: json["REF_CODE"],
        title: json["TITLE"],
        empName: json["EMP_NAME"],
        branch: json["BRANCH"],
        dept: json["DEPT"],
        desg: json["DESG"],
        shift: json["SHIFT"],
        empStatus: json["EMP_STATUS"],
        empType: json["EMP_TYPE"],
        empRm: json["EMP_RM"],
        empRm2: json["EMP_RM2"],
        doj: json["DOJ"] == null ? null : DateTime.parse(json["DOJ"]),
        mobile: json["MOBILE"],
        doe: json["DOE"],
        attnId: json["ATTN_ID"],
        deptName: json["DEPT_NAME"],
        desgName: json["DESG_NAME"],
        imgAttn: json["IMG_ATTN"],
        img: json["IMG"],
        rmName: json["RM_NAME"],
        rm2Name: json["RM2_NAME"],
      );
}
