import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:tota/tota.dart';
import 'package:tota/src/fs.dart';
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

        var result = await listDirectory(Uri.directory(path)).toList();
        expect(result.length, equals(nums.length));
      });
    });

    test("throws an error if directory doesn't exist", () {
      withTempDir((path) async {
        expect(
            () async => await listDirectory(Uri.directory('/path/not/found')),
            throwsA(TypeMatcher<TotaException>()));
      });
    });
  });

  group('parseSourceFile', () {
    test('parses Markdown file', () {
      withTempDir((path) async {
        var fileUri = Uri.file(p.join(path, 'foo.md'));
        await File.fromUri(fileUri)
          ..writeAsString('---\nfoo: bar\n---\nbaz');

        Map<String, dynamic> parsed = await parseSourceFile(fileUri);

        expect(parsed['foo'], equals('bar'));
        expect(parsed['content'], equals('\nbaz'));
      });
    });
  });

  group('loadTemplate', () {
    test('reads template file', () {
      withTempDir((path) async {
        var templatesDir = Uri.directory(p.join(path, 'templates/'));
        await Directory.fromUri(templatesDir).create();
        await File.fromUri(templatesDir.resolve('foo.mustache'))
            .writeAsString('<h1>{{ foo }}</h1>');

        var template = await loadTemplate('foo.mustache', templatesDir);

        expect(template.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });

    test('reads template file without file extension', () {
      withTempDir((path) async {
        var templatesDir = Uri.directory(p.join(path, 'templates/'));
        await Directory.fromUri(templatesDir).create();
        await File.fromUri(templatesDir.resolve('foo.mustache'))
            .writeAsString('<h1>{{ foo }}</h1>');

        var template = await loadTemplate('foo', templatesDir);

        expect(template.renderString({'foo': 'bar'}), equals('<h1>bar</h1>'));
      });
    });
  });

  group('createHtmlFile', () {
    test('creates HTML file in public directory', () {
      return withTempDir((path) async {
        var publicDir = Uri.directory(p.join(path, 'public/'));
        await Directory.fromUri(publicDir).create();

        await createHtmlFile(Uri.file('foo.md'), publicDir, content: 'bar');

        var file = File.fromUri(publicDir.resolve('foo.html'));
        expect(file.exists(), completion(equals(true)));
        expect(file.readAsString(), completion(equals('bar')));
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

  group('copyDirectory', () {
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

  group('removeDirectory', () {
    test('deletes a directory', () {
      withTempDir((path) async {
        // Create test directory
        var dir = Uri.directory(p.join(path, 'delete-me/'));
        await Directory.fromUri(dir).create();
        await File.fromUri(dir.resolve('nested/foo.md'))
            .create(recursive: true);

        await removeDirectory(dir, recursive: true);

        expect(Directory.fromUri(dir).exists(), completion(equals(false)));
      });
    });
  });
}
