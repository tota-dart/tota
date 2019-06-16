import 'dart:io';
import 'package:path/path.dart' as p;
import 'generator.dart';
import 'config.dart';
import 'utils.dart';

const _markdownFileExtension = '.md';

class Pages extends Generator {
  Pages(Config config) : super(config);

  /// Scaffolds a new page file with desired [title].
  Future<File> create(String title) async {
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
  Future<List<File>> list() => Generator.listDirectory(this.sourceDir,
      extension: _markdownFileExtension);

  /// Builds the files in the pages directory.
  Future<List<File>> build() async =>
      super.generateHtmlFiles(await this.list());
}
