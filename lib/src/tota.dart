library tota;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'utils.dart';
import 'pages.dart';
import 'posts.dart';

/// Page type assigned to posts.
const postsPageType = 'posts';

/// Loads the config file.
Config loadConfig({String fileName = 'config.yaml'}) =>
    Config(File(p.join(p.current, fileName)));

/// Runs the generator, creating static files.
Future<List<File>> build(Config config) async {
  Pages pages = Pages(config);
  Posts posts = Posts(config);

  List<File> result = [
    ...await pages.build(),
    ...await posts.build(),
  ];

  return result;
}

Future<File> create(Config config, String title, {String type}) async {
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
