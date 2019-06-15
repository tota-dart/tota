import 'dart:io';
import 'dart:async';
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;
import 'package:front_matter/front_matter.dart' as fm;
import 'exceptions.dart';
import 'config.dart';

const _markdownFileExtension = '.md';

class Resource {
  Config config;
  Directory publicDir;

  Resource(this.config) {
    this.publicDir =
        Directory(p.join(p.current, this.config.directory['public']));
  }

  /// Creates a new source [file] with optional [frontMatter] and [content].
  Future<File> createSourceFile(File file,
      {Map<String, dynamic> frontMatter, String content = ''}) async {
    if (await file.exists()) {
      throw fileAlreadyExistsException(file.path);
    }
    if (frontMatter?.isNotEmpty ?? false) {
      // Naive YAML dump (unsupported by `yaml` package).
      var fm =
          frontMatter.entries.map((entry) => '${entry.key}: ${entry.value}');
      content = "---\n${fm.join('\n')}\n---\n\n$content";
    }
    return file.writeAsString(content);
  }

  /// Generates HTML files for all source files in a directory.
  ///
  /// Reads all Markdown files in a [sourceDir], parses the file contents,
  /// converts content to HTML and saves the resulting file to the [publicDir].
  Future<List<File>> generateFiles(Directory sourceDir) async {
    List<File> createdFiles = List();
    await for (var sourceFile in sourceDir.list()) {
      if (p.extension(sourceFile.path) == _markdownFileExtension) {
        var parsed = await fm.parseFile(sourceFile.path);
        if (parsed.data.containsKey('public') && parsed.data['public']) {
          var fileName = p.basenameWithoutExtension(sourceFile.path);
          var fileContent = markdownToHtml(parsed.content, inlineSyntaxes: [
            InlineHtmlSyntax(),
          ], blockSyntaxes: [
            HeaderWithIdSyntax(),
            TableSyntax(),
          ]);
          var file = File(
              p.join(this.publicDir.path, p.setExtension(fileName, '.html')));
          await file.writeAsString(fileContent);
          createdFiles.add(file);
        }
      }
    }
    return createdFiles;
  }

  void foo2(Directory directory) async {
    await for (var file in directory.list(recursive: true)) {
      print(file.runtimeType);
    }
  }
}
