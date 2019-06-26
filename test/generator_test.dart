import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:tota/src/config.dart';
import 'package:tota/tota.dart';
import 'package:tota/src/generator.dart';
import 'utils.dart';

void main() {
  setUp(() {
    dotenv.load('test/fixtures/.env');
  });

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

  group('partialResolver', () {
    test('loads partial file in directory', () {
      return withTempDir((path) async {
        var templatesDir = Uri.directory(p.join(path, 'templates/'));
        var partialsPath = templatesDir.resolve('_partials/');

        // Create test files.
        await Directory.fromUri(partialsPath).create(recursive: true);
        await File.fromUri(partialsPath.resolve('foo.mustache'))
            .writeAsString('<h1>{{ foo }}</h1>');

        var resolver = partialResolver(templatesDir.resolve('_partials/'));
        var partial = resolver('foo');
        expect(partial.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });

    test('loads nested file in directory', () {
      return withTempDir((path) async {
        var templatesDir = Uri.directory(p.join(path, 'templates/'));
        var partialsPath = templatesDir.resolve('_partials/nested/');

        // Create test files.
        await Directory.fromUri(partialsPath).create(recursive: true);
        await File.fromUri(partialsPath.resolve('foo.mustache'))
            .writeAsString('<h1>{{ foo }}</h1>');

        var resolver = partialResolver(templatesDir.resolve('_partials/'));
        var partial = resolver('foo');
        expect(partial.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });
  });

  group('generateHtmlFiles', () {
    var testIds = <String>['foo', 'bar', 'baz', 'qux'];

    test('generates HTML files', () {
      return withTempDir((path) async {
        var t = createTestFiles(path, testIds);
        var result = await generateHtmlFiles(
            files: t['files'],
            sourceDir: t['pagesDir'],
            publicDir: t['publicDir'],
            templatesDir: t['templatesDir']);

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

    test('public directory structure resembles source directory', () {
      return withTempDir((path) async {
        var t = createTestFiles(path, testIds);

        // Create nested directory in source directory.
        var fileDir =
            Directory.fromUri(t['pagesDir'].resolve('path/to/nested'));
        await fileDir.create(recursive: true);

        // Write test file in nested directory.
        var fileUri = Uri.file(p.join(fileDir.path, 'page.md'));
        await File.fromUri(fileUri)
            .writeAsString('---\npublic: true\n---\nfoo');

        var result = await generateHtmlFiles(
            files: <Uri>[fileUri],
            sourceDir: t['pagesDir'],
            publicDir: t['publicDir'],
            templatesDir: t['templatesDir']);

        var expectedFile = File(
            p.join(t['publicDir'].toFilePath(), 'path/to/nested/page.html'));

        expect(result.length, equals(1));
        expect(expectedFile.exists(), completion(equals(true)));
      });
    });
  });

  group('copyDirectory()', () {
    test('copies assets directory to public directory', () {
      return withTempDir((path) async {
        var t = createTestFiles(path, <String>['foo']);
        var targetUri = t['publicDir'].resolve('assets/');
        await copyDirectory(t['assetsDir'], targetUri);

        // Destination directory exists.
        expect(Directory.fromUri(targetUri).exists(), completion(equals(true)));

        var file = File.fromUri(targetUri.resolve('index.js'));
        expect(file.exists(), completion(equals(true)));
        expect(file.readAsString(), completion(equals('console.log("foo")')));
      });
    });
  });
}
