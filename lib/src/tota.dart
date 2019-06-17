library tota;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'utils.dart';
import 'pages.dart';
import 'posts.dart';

/// Page type assigned to posts.
const postsPageType = 'posts';

/// Runs the generator, creating static files.
Future<List<Uri>> build() async {
  Pages pages = Pages();
  Posts posts = Posts();

  List<Uri> result = [
    ...await pages.build(),
    ...await posts.build(),
  ];

  return result;
}

/*
Future<Uri> create(String title, {String type}) async {
  Pages resource;
  switch (type) {
    case postsPageType:
      resource = Posts();
      break;
    default:
      resource = Pages();
  }

  return resource.create(title);
}
*/
