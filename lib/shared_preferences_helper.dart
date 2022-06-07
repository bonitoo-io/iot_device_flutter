import 'package:shared_preferences/shared_preferences.dart';

final iotCenterUrlStore = SharedPreferencesStringStore("iot-center-v2-url");
final clientIdStore = SharedPreferencesStringStore("client-id");

class SharedPreferencesStringStore {
  String key;

  Future<String> save(String str) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString(key, str);
    return str;
  }

  Future<String?> load() async {
    var prefs = await SharedPreferences.getInstance();
    try {
      return prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  SharedPreferencesStringStore(this.key);
}
