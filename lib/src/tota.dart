library tota;

import 'dart:io';
import 'config.dart';
import 'starter.dart';
import 'resource.dart';
import 'generator.dart' show removeDir, copyDirectory;
import 'tota_exception.dart';
import 'utils.dart';

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
Future<List<Uri>> buildFiles() async {
  List<Uri> pages = await build(config.pagesDir, config.publicDir);
  // Posts are nested one-level deep inside the public directory.
  // This will be reflected in the URL path for the blog.
  var postsDirname = getenv('POSTS_DIR', fallback: 'posts', isDirectory: true);
  List<Uri> posts =
      await build(config.postsDir, config.publicDir.resolve(postsDirname));

  return <Uri>[...pages, ...posts];
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
Future<Uri> createPage(Resource resource, String title, {bool force}) async {
  switch (resource) {
    case Resource.post:
      return create(config.postsDir, title, force: force);
    default:
      return create(config.pagesDir, title, force: force);
  }
}
