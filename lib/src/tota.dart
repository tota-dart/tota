library tota;

import 'dart:io';
import 'config.dart';
import 'starter.dart';
import 'pages.dart';
import 'posts.dart';
import 'generator.dart' show removeDir, copyDirectory;
import 'tota_exception.dart';
import 'utils.dart';

/// Page type assigned to posts.
const _postPageType = 'post';

/// Initializes a new project in [directory].
Future<void> createProject(Uri directory) async {
  var dir = Directory.fromUri(directory);

  // Stop if directory isn't empty.
  if (await dir.exists()) {
    var dirents = await dir.list().toList();
    if (dirents.isNotEmpty) {
      throw TotaException(
          'target directory is not empty: `${directory.toFilePath()}`');
    }
  }

  return await clone(directory);
}

/// Deletes the existing public directory.
Future<void> deletePublicDir() => removeDir(config.publicDir, recursive: true);

/// Creates static files from sources files (pages, posts, etc.)
Future<List<Uri>> buildPages() async {
  Pages pages = Pages();
  Posts posts = Posts();
  return <Uri>[
    ...await pages.build(),
    ...await posts.build(),
  ];
}

/// Copies assets directory to public directory.
Future<void> copyAssets() async {
  var dirname = getenv('ASSETS_DIR', fallback: 'assets', isDirectory: true);
  return copyDirectory(config.assetsDir, config.publicDir.resolve(dirname));
}

/// Creates a new source file.
///
/// The default [type] of resource to create is "page". Will throw an
/// exception if file already exists, but [force] will override this.
Future<Uri> createPage(String title, {String type, bool force}) async {
  Pages resource;
  switch (type) {
    case _postPageType:
      resource = Posts();
      break;
    default:
      resource = Pages();
  }

  return resource.create(title, force: force);
}
