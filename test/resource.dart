import 'dart:io';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:tota/src/config.dart';
import 'package:tota/tota.dart';
import 'package:tota/src/resource.dart';
import 'utils.dart';

void main() {
  setUp(() {
    dotenv.load('test/fixtures/.env');
  });

  group('createResource', () {
    test('creates a new file from title', () {
      withTempDir((path) async {
        var sourceDir = Uri.directory(path);
        await createResource(sourceDir, 'Foo Bar');

        var file = File.fromUri(sourceDir.resolve('foo-bar.md'));
        expect(file.exists(), completion(equals(true)));
      });
    });

    test('throws error if file exists already exists', () {
      withTempDir((path) async {
        var sourceDir = Uri.directory(path);
        await File.fromUri(sourceDir.resolve('foo-bar.md')).create();

        expect(createResource(sourceDir, 'Foo Bar'),
            throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('overwrites file with force option', () {
      withTempDir((path) async {
        var sourceDir = Uri.directory(path);
        await File.fromUri(sourceDir.resolve('foo-bar.md')).create();
        await createResource(sourceDir, 'Foo Bar', force: true);

        var file = File.fromUri(sourceDir.resolve('foo-bar.md'));
        expect(file.exists(), completion(equals(true)));
      });
    });
  });

  group('compileResources', () {
    test('compiles files in pages directory', () {
      withTempDir((path) async {
        var t = createTestFiles(path, ['foo', 'bar']);

        var result = await compileResources(
            sourceDir: t['pagesDir'],
            publicDir: t['publicDir'],
            templatesDir: t['templatesDir'],
            config: createConfig(),
            resourceType: ResourceType.page);

        expect(result.length, equals(2));
      });
    });

    test('public directory structure resembles source directory', () {
      withTempDir((path) async {
        var t = createTestFiles(path, ['foo', 'bar']);

        // Create nested file in source directory.
        File.fromUri(t['pagesDir'].resolve('path/to/nested/page.md'))
          ..createSync(recursive: true)
          ..writeAsStringSync('---\npublic: true\n---\nfoo');

        var result = await compileResources(
            sourceDir: t['pagesDir'],
            publicDir: t['publicDir'],
            templatesDir: t['templatesDir'],
            config: createConfig(),
            resourceType: ResourceType.page);

        var expectedFile =
            File.fromUri(t['publicDir'].resolve('path/to/nested/page.html'));

        expect(result.length, equals(3));
        expect(expectedFile.exists(), completion(equals(true)));
      });
    });
  });

  group('createPostsArchive', () {
    test('throws an error if archive template is not found', () {
      return withTempDir((path) async {
        var t = createTestFiles(path, ['foo', 'bar']);
        var posts = <Resource>[
          Resource(url: 'foo', title: 'foo', date: DateTime.now())
        ];

        var result = createPostsArchive(posts,
            config: createConfig(),
            templatesDir: t['templatesDir'],
            publicDir: t['publicDir']);

        expect(result, throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('creates an archive page', () {
      withTempDir((path) async {
        var t = createTestFiles(path, ['foo', 'bar']);
        var posts = <Resource>[
          Resource(url: 'foo', title: 'foo', date: DateTime.now())
        ];

        // Create archive template.
        File.fromUri(t['templatesDir'].resolve('archive.mustache'))
          ..writeAsStringSync('{{#posts}}'
              '<h1>{{title}}</h1>'
              '{{/posts}}');

        await createPostsArchive(posts,
            config: createConfig(),
            templatesDir: t['templatesDir'],
            publicDir: t['publicDir']);

        var file = File.fromUri(t['publicDir'].resolve('posts/index.html'));
        expect(file.existsSync(), equals(true));
        expect(file.readAsStringSync(), equals('<h1>foo</h1>'));
      });
    });
  });
}
