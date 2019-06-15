import 'dart:io';
import 'package:test/test.dart';
import 'package:tota/tota.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Config', () {
    test('throws error if file not found', () {
      var file = File('/path/to/nowhere.yaml');
      expect(() => Config(file), throwsA(const TypeMatcher<TotaException>()));
    });

    test('throws error if config file is invalid', () async {
      var invalidFile =
          File(p.join(p.current, 'test', 'fixtures', 'config.invalid.yaml'));

      var invalidFileError = predicate(
          (e) => e.message?.contains('configuration file is invalid.'));

      expect(() => Config(invalidFile), throwsA(invalidFileError));
    });

    test('parses config file correctly', () async {
      var file = File(p.join(p.current, 'test', 'fixtures', 'config.yaml'));
      var expected = loadYaml(await file.readAsString());

      var config = Config(file);

      expect(config.site['title'], equals(expected['site']['title']));
      expect(
          config.directory['public'], equals(expected['directory']['public']));
    });
  });
}
