import 'package:slugify/slugify.dart';
import 'package:path/path.dart' as p;
import 'generator.dart';
import 'config.dart';
import 'utils.dart';

const _markdownFileExtension = '.md';

class Pages {
  /// The URI for the pages directory.
  Uri sourceDir = config.pagesDir;

  /// The URI for the public directory.
  Uri publicDir = config.publicDir;

  /// Scaffolds a new page file with desired [title].
  Future<Uri> create(String title, {bool force}) async {
    // Slugify title to create a file name.
    var fileName = p.setExtension(Slugify(title), '.md');
    var fileUri = sourceDir.resolve(fileName);
    var metadata = <String, dynamic>{
      'title': title,
      'date': formatDate(DateTime.now()),
      'template': 'base',
      'public': false,
    };

    return createSourceFile(fileUri,
        metadata: metadata, content: 'Hello, world!', force: force);
  }

  /// Lists all Markdown files in the pages directory.
  Future<List<Uri>> list() =>
      listDirectory(sourceDir, extension: _markdownFileExtension);

  /// Builds the files in the pages directory.
  Future<List<Uri>> build() async => generateHtmlFiles(
      files: await list(), sourceDir: sourceDir, publicDir: publicDir);
}
