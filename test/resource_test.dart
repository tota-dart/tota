import 'dart:io';
import 'package:test/test.dart';
import 'package:tota/src/config.dart';
import 'package:tota/tota.dart';
import 'package:tota/src/resource.dart';
import 'utils.dart';

void main() {
  group('createResource', () {
    test('creates a new file from title', () {
      withTempDir((path) async {
        var config = createTestConfig(path);
        var t = createTestFiles(config, ['foo']);

        await createResource(ResourceType.page, 'Test Bar', config: config);

        var file = File.fromUri(config.pagesDirUri.resolve('test-bar.md'));
        expect(file.exists(), completion(equals(true)));
      });
    });

    test('throws error if file exists already exists', () {
      withTempDir((path) async {
        var config = createTestConfig(path);
        var t = createTestFiles(config, ['foo']);

        expect(createResource(ResourceType.page, 'Test Foo', config: config),
            throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('overwrites file with force option', () {
      withTempDir((path) async {
        var config = createTestConfig(path);
        var t = createTestFiles(config, ['foo']);

        await createResource(ResourceType.page, 'Test Foo',
            config: config, force: true);

        var file = File.fromUri(config.pagesDirUri.resolve('test-foo.md'));
        expect(file.exists(), completion(equals(true)));
      });
    });
  });

  group('compileResources', () {
    test('compiles files in pages directory', () {
      withTempDir((path) async {
        var config = createTestConfig(path);
        createTestFiles(config, ['foo', 'bar']);

        var result = await compileResources(ResourceType.page, config: config);

        expect(result.length, equals(2));
      });
    });

    test('public directory structure resembles source directory', () {
      withTempDir((path) async {
        var config = createTestConfig(path);
        createTestFiles(config, ['foo', 'bar']);

        // Create nested file in source directory.
        File.fromUri(config.pagesDirUri.resolve('path/to/nested/page.md'))
          ..createSync(recursive: true)
          ..writeAsStringSync('---\npublic: true\n---\nfoo');

        var result = await compileResources(ResourceType.page, config: config);

        var expectedFile = File.fromUri(
            config.publicDirUri.resolve('path/to/nested/page.html'));

        expect(result.length, equals(3));
        expect(expectedFile.exists(), completion(equals(true)));
      });
    });
  });

  group('createPostsArchive', () {
    test('throws an error if archive template is not found', () {
      withTempDir((path) async {
        var config = createTestConfig(path);
        var t = createTestFiles(config, ['foo', 'bar']);
        var posts = <Resource>[
          Resource(
              type: ResourceType.post,
              path: 'foo',
              title: 'foo',
              date: DateTime.now())
        ];

        var result = createPostsArchive(posts,
            config: config,
            templatesDir: config.templatesDirUri,
            publicDir: config.publicDirUri);

        expect(result, throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('creates an archive page', () {
      withTempDir((path) async {
        var config = createTestConfig(path);
        var t = createTestFiles(config, ['foo', 'bar']);
        var today = DateTime.now();
        var posts = <Resource>[
          Resource(
              type: ResourceType.post, path: 'foo', title: 'foo', date: today),
          Resource(
              type: ResourceType.post,
              path: 'bar',
              title: 'bar',
              date: today.add(Duration(days: 1)))
        ];

        // Create archive template.
        File.fromUri(t['templatesDir'].resolve('archive.mustache'))
          ..writeAsStringSync('{{#posts}}'
              '<p>{{title}}</p>'
              '{{/posts}}');

        await createPostsArchive(posts,
            config: config,
            templatesDir: config.templatesDirUri,
            publicDir: config.publicDirUri);

        var file =
            File.fromUri(config.publicDirUri.resolve('posts/index.html'));
        expect(file.existsSync(), equals(true));
        expect(file.readAsStringSync(), equals('<p>bar</p><p>foo</p>'));
      });
    });
  });
}
