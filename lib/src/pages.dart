import 'dart:io';
import 'package:path/path.dart' as p;
import 'generator.dart';
import 'utils.dart';

const _markdownFileExtension = '.md';

class Pages {
  /// Gets the pages directory URI.
  Uri get sourceDir =>
      Uri.directory(p.join(p.current, getenv('PAGES_DIR', fallback: 'pages')));

  /// Gets the public directory URI.
  Uri get publicDir =>
      Uri.directory(p.join(p.current, getenv('PUBLIC_DIR', fallback: 'pages')));

  /// Scaffolds a new page file with desired [title].
  Future<Uri> create(String title) async {
    // Slugify title to create a file name.
    var fileName = p.setExtension(slugify(title), '.md');
    var file = File(p.join(this.sourceDir.path, fileName));
    var metadata = <String, dynamic>{
      'title': title,
      'date': formatDate(DateTime.now()),
      'template': 'base',
      'public': false,
    };

    return Generator.createSourceFile(file,
        metadata: metadata, content: 'Hello, world!');
  }

  /// Lists all Markdown files in the pages directory.
  Future<List<Uri>> list() =>
      Generator.listDirectory(Directory.fromUri(this.sourceDir),
          extension: _markdownFileExtension);

  /// Builds the files in the pages directory.
  Future<List<Uri>> build() async => Generator.generateHtmlFiles(
      files: await this.list(),
      sourceDir: this.sourceDir,
      publicDir: this.publicDir);
}
