const bool live = true;

class MicroServiceEndpoint {
  static const String microserviceUrl =
      live ? 'https://api.eye.humanec.ai' : 'http://192.168.0.181:8000';
  static const String microserviceWebSocketUrl =
      live ? 'wss://api.eye.humanec.ai' : 'ws://192.168.0.181:8000';
  static const addEmployee = '$microserviceUrl/employee/add';
  static const deleteEmployee = '$microserviceUrl/employee/delete';
  static const scanFace = '$microserviceWebSocketUrl/face';
}
