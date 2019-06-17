import 'dart:io';
import 'package:yaml/yaml.dart';
import 'exceptions.dart';

class Config {
  File _file;
  Map<String, dynamic> site = {};
  Map<String, dynamic> directory = {};

  /// Reads and parses the config file if it exists.
  Config(this._file) {
    if (!this._file.existsSync()) {
      throw fileNotFoundException(this._file.path);
    }

    try {
      var content = loadYaml(this._file.readAsStringSync());
      this.site = Map<String, dynamic>.from(content['site']);
      this.directory = Map<String, dynamic>.from(content['directory']);
    } catch (e) {
      throw TotaException('configuration file is invalid.');
    }
  }

  /// Returns the config file path.
  String get path => this._file.path;
}
