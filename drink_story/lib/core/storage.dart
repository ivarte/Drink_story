import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/models.dart';

class AppStorage {
  static Future<Directory> appDir() => getApplicationSupportDirectory();

  static Future<File> _file(String name) async =>
      File('${(await appDir()).path}/$name');

  static Future<void> saveLicense(License l) async {
    final f = await _file('license.json'); f.createSync(recursive: true);
    await f.writeAsString(jsonEncode(l.toJson()));
  }

  static Future<License?> loadLicense() async {
    final f = await _file('license.json');
    if (!f.existsSync()) return null;
    return License.fromJson(jsonDecode(await f.readAsString()));
  }

  static Future<void> saveManifest(Map<String, dynamic> j) async {
    final f = await _file('manifest.json'); f.createSync(recursive: true);
    await f.writeAsString(jsonEncode(j));
  }

  static Future<RouteManifest?> loadManifest() async {
    final f = await _file('manifest.json');
    if (!f.existsSync()) return null;
    return RouteManifest.fromJson(jsonDecode(await f.readAsString()));
  }

  static Future<File> sceneFile(String relativePath) async =>
      File('${(await appDir()).path}/$relativePath');
}
