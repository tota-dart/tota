import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:tota/src/config.dart';
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
      config.allowEmpty = true;
    });

    test('loads file in directory', () {
      withTempDir((path) {
        config.rootDir = Uri.directory(path);

        // Create test files.
        var partialsPath = p.join(path, 'templates', '_partials');
        Directory(partialsPath)..createSync(recursive: true);

        File(p.join(partialsPath, 'foo.mustache'))
          ..writeAsStringSync('<h1>{{ foo }}</h1>');

        var partial = getTemplatePartial('foo');
        expect(partial.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });

    test('loads nested file in directory', () {
      withTempDir((path) {
        config.rootDir = Uri.directory(path);

        // Create test files.
        var partialsPath = p.join(path, 'templates', '_partials', 'nested');
        Directory(partialsPath)..createSync(recursive: true);

        File(p.join(partialsPath, 'foo.mustache'))
          ..writeAsStringSync('<h1>{{ foo }}</h1>');

        var partial = getTemplatePartial('foo');
        expect(partial.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });
  });

  group('generateHtmlFiles', () {
    var testIds = <String>['foo', 'bar', 'baz', 'qux'];

    setUp(() {
      config.allowEmpty = true;
    });

    test('generates HTML files', () {
      return withTempDir((path) async {
        config.rootDir = Uri.directory(path);

        var t = createTestFiles(path, testIds);
        var result = await generateHtmlFiles(
            files: t['files'],
            sourceDir: t['pagesDir'],
            publicDir: t['publicDir']);

        expect(result.length, testIds.length);

        result.asMap().forEach((i, fileUri) async {
          var file = File.fromUri(fileUri);
          // File exists.
          expect(file.exists(), completion(equals(true)));
          // File name is expected.
          expect(p.basename(fileUri.path), equals('test-${testIds[i]}.html'));
        });
      });
    });
  });
}
