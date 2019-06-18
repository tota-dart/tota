import 'dart:io';
import 'package:path/path.dart' as p;
import 'generator.dart';
import 'utils.dart';

const _markdownFileExtension = '.md';

class Pages {
  /// Gets the pages directory URI.
  Uri get sourceDir => dirs.pages;

  /// Gets the public directory URI.
  Uri get publicDir => dirs.public;

  /// Scaffolds a new page file with desired [title].
  Future<Uri> create(String title, {bool force}) async {
    // Slugify title to create a file name.
    var fileName = p.setExtension(slugify(title), '.md');
    var fileUri = Uri.file(p.join(this.sourceDir.path, fileName));
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
      listDirectory(this.sourceDir, extension: _markdownFileExtension);

  /// Builds the files in the pages directory.
  Future<List<Uri>> build() async => generateHtmlFiles(
      files: await this.list(),
      sourceDir: this.sourceDir,
      publicDir: this.publicDir);
}
