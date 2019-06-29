import 'dart:io';

import 'package:test/test.dart';
import 'package:tota/src/resource.dart';
import 'package:tota/tota.dart';

import 'utils.dart';

void main() {
  group('createResource', () {
    test('creates a new file from title', () {
      withFixtures((config) async {
        var result =
            await createResource(ResourceType.page, 'New File', config: config);
        expect(result.title, equals('New File'));

        var file = File.fromUri(config.pagesDirUri.resolve('new-file.md'));
        expect(file.exists(), completion(isTrue));
      });
    });

    test('throws error if file exists already exists', () {
      withFixtures((config) async {
        expect(createResource(ResourceType.page, 'Foo Bar', config: config),
            throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('overwrites file with force option', () {
      withFixtures((config) async {
        var result = await createResource(ResourceType.page, 'Foo Bar',
            config: config, force: true);
        expect(result, isA<Resource>());
      });
    });
  });

  group('compileResources', () {
    test('compiles files in pages directory', () {
      withFixtures((config) async {
        var result = await compileResources(ResourceType.page, config: config);
        expect(result.length, equals(3));
      });
    });

    test('public directory structure resembles source directory', () {
      withFixtures((config) async {
        await compileResources(ResourceType.page, config: config);

        var file =
            File.fromUri(config.publicDirUri.resolve('nested/page.html'));
        expect(file.existsSync(), isTrue);
      });
    });

    test('formats date according to config', () {
      withFixtures((config) async {
        config = createTestConfig(config.rootDir, dateFormat: 'yMMMMd');
        await compileResources(ResourceType.post, config: config);

        var file =
            File.fromUri(config.publicDirUri.resolve('posts/foo-bar.html'));
        expect(file.readAsStringSync(), contains('July 20, 1969'));
      });
    });
  });

  group('createPostsArchive', () {
    test('throws an error if archive template is not found', () {
      withFixtures((config) async {
        await File.fromUri(config.templatesDirUri.resolve('archive.mustache'))
            .delete();

        var posts = <Resource>[
          Resource(
              title: 'foo',
              path: 'foo',
              date: DateTime.now(),
              type: ResourceType.post)
        ];

        expect(() async => await createPostArchive(posts, config: config),
            throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('creates an archive page', () {
      withFixtures((config) async {
        var posts = <Resource>[
          Resource(
              title: 'foo',
              path: 'foo',
              date: DateTime.now(),
              type: ResourceType.post)
        ];
        await createPostArchive(posts, config: config);

        var file =
            File.fromUri(config.publicDirUri.resolve('posts/index.html'));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('<a>foo</a>\n'));
      });
    });
  });
}
