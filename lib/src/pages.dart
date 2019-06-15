import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:front_matter/front_matter.dart' as fm;
import 'package:markdown/markdown.dart';
import 'config.dart';
import 'exceptions.dart';
import 'utils.dart';

const _markdownFileExtension = '.md';

class Pages {
  final Config config;
  Directory sourceDir, publicDir;

  Pages(this.config) {
    this.sourceDir =
        Directory(p.join(p.current, this.config.directory['pages']));
    this.publicDir =
        Directory(p.join(p.current, this.config.directory['public']));
  }

  /// Creates an initial page file from a starting template.
  ///
  /// Creates a new [file] in the pages directory with optional [metadata]
  /// (front matter) and body [content].
  Future<File> createSourceFile(File file,
      {Map<String, dynamic> metadata, String content = ''}) async {
    if (await file.exists()) {
      throw fileAlreadyExistsException(file.path);
    }
    // Prefix content with front matter.
    if (metadata?.isNotEmpty ?? false) {
      content = "${createFrontMatter(metadata)}\n\n$content";
    }
    return file.writeAsString(content);
  }

  /// Creates a new page file with desired [title].
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

    return this
        .createSourceFile(file, metadata: metadata, content: 'Hello, world!');
  }

  /// Generates HTML files for all the Markdown files in a directory.
  ///
  /// Reads all Markdown files in a [directory]. Parses file contents to
  /// separate front matter and body content. Converts body from Markdown
  /// to HTML, and saves the resulting file in the public directory.
  Future<List<File>> buildDirectory(Directory directory) async {
    List<File> files = List();
    await for (var entity in directory.list(recursive: true)) {
      // Limit the process to Markdown files only.
      if (entity is File &&
          p.extension(entity.path) == _markdownFileExtension) {
        // Read the file and parse front matter & content.
        var parsed = await fm.parseFile(entity.path);
        // Ignore files that aren't public.
        if (parsed.data.containsKey('public') && parsed.data['public']) {
          // Calculate a relative file path with source directory as root.
          var filePath = entity.path.replaceAll('${this.sourceDir.path}/', '');
          // Convert body content from markdown to HTML.
          var fileContent = markdownToHtml(parsed.content, inlineSyntaxes: [
            InlineHtmlSyntax(),
          ], blockSyntaxes: [
            HeaderWithIdSyntax(),
            TableSyntax(),
          ]);
          // TODO use mustache HTML template.
          var file = File(
              p.join(this.publicDir.path, p.setExtension(filePath, '.html')));
          // Create sub-directories before writing the file.
          await Directory(p.join(this.publicDir.path, p.dirname(filePath)))
              .create(recursive: true);
          await file.writeAsString(fileContent);

          files.add(file);
        }
      }
    }
    return files;
  }

  /// Builds the files in the pages directory.
  Future<List<File>> build() => this.buildDirectory(this.sourceDir);
}
