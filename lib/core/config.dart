class AppConfig {
  // Emulator: http://10.0.2.2:8080 ;
  //Real device: http://<PC_IP>:8080
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
