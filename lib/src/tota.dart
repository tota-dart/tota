library tota;

import 'dart:io';
import 'config.dart';
import 'pages.dart';
import 'posts.dart';

/// Page type assigned to posts.
const postPageType = 'post';

/// Initializes a new project.
Future<void> init() async {}

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
