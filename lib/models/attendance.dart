import 'dart:convert';

List<Attendance> attendanceFromJson(String str) => List<Attendance>.from(json.decode(str).map((x) => Attendance.fromJson(x)));


class Attendance {
    int? id;
    String? empCode;
    String? empName;
    String? deptName;
    String? desgName;
    int? grade;
    DateTime? trnDate;
    String? attn1;
    String? attn2;
    DateTime? inTime;
    DateTime? outTime;
    String? refNo;
    num? lattitude;
    num? longitude;
    dynamic remarks;
    String? createdBy;
    DateTime? createdOn;
    String? modifiedBy;
    DateTime? modifiedOn;
    bool? readOnly;

    Attendance({
        this.id,
        this.empCode,
        this.empName,
        this.deptName,
        this.desgName,
        this.grade,
        this.trnDate,
        this.attn1,
        this.attn2,
        this.inTime,
        this.outTime,
        this.refNo,
        this.lattitude,
        this.longitude,
        this.remarks,
        this.createdBy,
        this.createdOn,
        this.modifiedBy,
        this.modifiedOn,
        this.readOnly,
    });

    factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json["ID"],
        empCode: json["EMP_CODE"],
        empName: json["EMP_NAME"],
        deptName: json["DEPT_NAME"],
        desgName: json["DESG_NAME"],
        grade: json["GRADE"],
        trnDate: json["TRN_DATE"] == null ? null : DateTime.parse(json["TRN_DATE"]),
        attn1: json["ATTN1"],
        attn2: json["ATTN2"],
        inTime: json["IN_TIME"] == null ? null : DateTime.parse(json["IN_TIME"]),
        outTime: json["OUT_TIME"] == null ? null : DateTime.parse(json["OUT_TIME"]),
        refNo: json["REF_NO"],
        lattitude: json["LATTITUDE"],
        longitude: json["LONGITUDE"],
        remarks: json["REMARKS"],
        createdBy: json["CREATED_BY"],
        createdOn: json["CREATED_ON"] == null ? null : DateTime.parse(json["CREATED_ON"]),
        modifiedBy: json["MODIFIED_BY"],
        modifiedOn: json["MODIFIED_ON"] == null ? null : DateTime.parse(json["MODIFIED_ON"]),
        readOnly: json["READ_ONLY"],
    );

}
