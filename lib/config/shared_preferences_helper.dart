import 'package:shared_preferences/shared_preferences.dart';

class MySharedPref {
  // prevent making instance
  MySharedPref();

  // get storage
  static SharedPreferences? sharedPreferences;

  // STORING KEYS
  static const String _ipServer = 'ipServer';
  static const String _cmsKey = 'cmsKey';
  static const String _displayName = 'displayName';
  static const String _urlDevice = 'urlDevice';

  /// init get storage services
  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static setStorage(SharedPreferences sharedPreferences) {
    sharedPreferences = sharedPreferences;
  }

  /// ipServer
  static Future<void> setIpServer(String ipServer) =>
      sharedPreferences!.setString(_ipServer, ipServer);
  static String? getIpServer() => sharedPreferences!.getString(_ipServer);

  /// cmsKey
  static Future<void> setCmsKey(String cmsKey) => sharedPreferences!.setString(_cmsKey, cmsKey);
  static String? getCmsKey() => sharedPreferences!.getString(_cmsKey);

  /// displayName
  static Future<void> setDisplayName(String displayName) =>
      sharedPreferences!.setString(_displayName, displayName);
  static String? getDisplayName() => sharedPreferences!.getString(_displayName);

  /// urlDevice
  static Future<void> setUrlDevice(String urlDevice) =>
      sharedPreferences!.setString(_urlDevice, urlDevice);
  static String? getUrlDevice() => sharedPreferences!.getString(_urlDevice);

  /// clear all data from shared pref
  static Future<void> clear() async => await sharedPreferences!.clear();
}
