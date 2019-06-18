import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:tota/src/utils.dart' show dirs;
import 'package:tota/tota.dart';
import 'package:tota/src/generator.dart';
import 'utils.dart';

void main() {
  group('createSourceFile', () {
    test('creates a new file', () {
      withTempDir((path) async {
        var file = File(p.join(path, 'foo.md'));

        await createSourceFile(Uri.file(file.path),
            metadata: <String, String>{'foo': 'bar'}, content: 'foo');

        expect(file.exists(), completion(equals(true)));
        expect(file.readAsString(),
            completion(equals('---\nfoo: bar\n---\n\nfoo')));
      });
    });

    test('throws error if file exists at file path', () {
      withTempDir((path) async {
        var file = File(p.join(path, 'foo.md'));
        await file.writeAsString('foo');

        expect(createSourceFile(Uri.file(file.path)),
            throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('overwrites file with force option', () {
      withTempDir((path) async {
        var file = File(p.join(path, 'foo.md'));
        await file.writeAsString('foo');
        await createSourceFile(Uri.file(file.path),
            content: 'bar', force: true);

        expect(await file.readAsString(), equals('bar'));
      });
    });
  });

  group('listDirectory', () {
    test('lists all files in a directory', () {
      withTempDir((path) async {
        var nums = List<int>.generate(5, (i) => i);

        // Create test files in temp dir.
        for (var num in nums) {
          await File(p.join(path, 'test-$num.md'))
            ..writeAsString('foo');
        }

        var result = await listDirectory(Uri.directory(path));
        expect(result.length, equals(nums.length));
      });
    });

    test("omits files that don't match a file extension", () {
      withTempDir((path) async {
        var filenames = ['foo.md', 'bar.md', 'virus.exe'];

        // Create test files in temp dir.
        for (var name in filenames) {
          await File(p.join(path, name))
            ..writeAsString('foo');
        }

        var result = await listDirectory(Uri.directory(path), extension: '.md');
        expect(result.length, equals(filenames.length - 1));
      });
    });
  });

  group('getTemplatePartial', () {
    setUp(() {
      dirs.allowEmpty = true;
    });

    tearDown(() {
      dirs.reset();
    });

    test('loads file in directory', () {
      withTempDir((path) {
        dirs.root = path;

        // Create test files
        var partialsPath = p.join(path, '_partials');
        Directory(partialsPath)..createSync();

        File(p.join(partialsPath, 'foo.mustache'))
          ..writeAsStringSync('<h1>{{ foo }}</h1>');

        var partial = getTemplatePartial('foo');
        expect(partial.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });

    test('loads nested file in directory', () {
      withTempDir((path) async {
        dirs.root = path;

        // Create test files
        var partialsPath = p.join(path, '_partials', 'nested');
        Directory(partialsPath)..createSync(recursive: true);

        File(p.join(partialsPath, 'foo.mustache'))
          ..writeAsStringSync('<h1>{{ foo }}</h1>');

        var partial = getTemplatePartial('foo');
        expect(partial.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });
  });
}
