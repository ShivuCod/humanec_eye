class MainEndpoint {
  static const String serverUrl = 'https://humanec.ai/xiraeye';

  static const String mainEndPoint = '$serverUrl/api';
  static const sendLoginOTP =
      '$mainEndPoint/Authorization/api/Authorization/SendLoginOTP';
  static const loginWithOtp =
      '$mainEndPoint/Authorization/api/Authorization/LoginWithOTP';
  static const employees = '$mainEndPoint/Employee';
  static const registeredEmployees = '$mainEndPoint/Attendance/EmpRecords';
  static const attendance = '$mainEndPoint/Attendance';
  static const business = '$mainEndPoint/Business';
  static const switchBusiness = '$mainEndPoint/Business/SwitchBusiness';
  static const setPin = '$mainEndPoint/Authorization/api/Authorization/SetPin';
}
