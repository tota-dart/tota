library tota;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'utils.dart';
import 'pages.dart';
import 'posts.dart';

/// Page type assigned to posts.
const postsPageType = 'posts';

/// Runs the generator, creating static files.
Future<List<File>> build({bool deploy = false}) async {
  final Config config = Config(File(p.join(p.current, 'config.yaml')));

  Pages pages = Pages(config);
  Pages posts = Posts(config);

  List<File> result = [
    ...await pages.build(),
    ...await posts.build(),
  ];

  if (deploy) {
    // TODO
    print('TODO deploy');
  }

  return result;
}

Future<File> create(String title, {String type}) async {
  final Config config = Config(File(p.join(p.current, 'config.yaml')));

  Pages resource;
  switch (type) {
    case postsPageType:
      resource = Posts(config);
      break;
    default:
      resource = Pages(config);
  }

  return resource.create(title);
}
