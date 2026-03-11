class AppConfig {
  // Android emulator uses 10.0.2.2 to reach host machine localhost.
  static const apiBaseUrlAndroidEmulator = 'http://10.0.2.2:3001';
  static const apiBaseUrlLocalhost = 'http://localhost:3001';

  static String apiBaseUrlForPlatform({required bool isAndroidEmulator}) {
    return isAndroidEmulator ? apiBaseUrlAndroidEmulator : apiBaseUrlLocalhost;
  }
}

