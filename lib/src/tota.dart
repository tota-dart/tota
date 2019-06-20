library tota;

import 'dart:io';
import 'config.dart';
import 'starter.dart';
import 'pages.dart';
import 'posts.dart';
import 'tota_exception.dart';

/// Page type assigned to posts.
const postPageType = 'post';

/// Initializes a new project in [directory].
Future<void> init(Uri directory) async {
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

/// Runs the generator, creating static files.
Future<List<Uri>> build() async {
  // Delete existing public directory to start from scratch.
  var publicDir = Directory.fromUri(config.publicDir);
  if (await publicDir.exists()) {
    await publicDir.delete(recursive: true);
  }

  Pages pages = Pages();
  Posts posts = Posts();

  List<Uri> result = [
    ...await pages.build(),
    ...await posts.build(),
  ];

  return result;
}

/// Creates a new source file.
///
/// The default [type] of resource to create is "page". Will throw an
/// exception if file already exists, but [force] will override this.
Future<Uri> create(String title, {String type, bool force}) async {
  Pages resource;
  switch (type) {
    case postPageType:
      resource = Posts();
      break;
    default:
      resource = Pages();
  }

  return resource.create(title, force: force);
}
