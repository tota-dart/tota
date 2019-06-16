import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:front_matter/front_matter.dart' as fm;
import 'package:markdown/markdown.dart';
import 'package:mustache/mustache.dart';
import 'config.dart';
import 'exceptions.dart';
import 'utils.dart';

const _defaultHtmlTemplate = 'base.mustache';

class Generator {
  final Config config;
  Directory sourceDir, publicDir;

  Generator(this.config) {
    this.sourceDir =
        Directory(p.join(p.current, this.config.directory['pages']));
    this.publicDir =
        Directory(p.join(p.current, this.config.directory['public']));
  }

  /// Scaffolds a source file from a starting template.
  ///
  /// Creates a new [file] in the source directory with optional [metadata]
  /// (front matter) and body [content].
  static Future<File> createSourceFile(File file,
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

  /// Lists all files in a directory.
  ///
  /// Returns a list of all Markdown files in a [directory] (recursively).
  /// Optionally filters out files that don't match a file [extension].
  static Future<List<File>> listDirectory(Directory directory,
      {String extension}) async {
    var entities = await directory.list(recursive: true).toList();
    var files = entities.whereType<File>().toList();
    if (extension != null) {
      files.removeWhere((file) => p.extension(file.path) != extension);
    }
    return files;
  }

  /// Generates HTML files for all [files] in a list.
  ///
  /// Parses file contents to separate front matter and body.
  /// Converts Markdown body to HTML, then renders an HTML file
  /// in the public directory using the desired HTML template.
  Future<List<File>> generateHtmlFiles(List<File> files) async {
    List<File> generated = [];
    for (var srcFile in files) {
      // Read the file and parse front matter & content.
      var parsed = await fm.parseFile(srcFile.path);
      // Ignore files that aren't public (or just have no front matter).
      if ((parsed.data?.containsKey('public') ?? false) &&
          parsed.data['public']) {
        // Calculate a relative file path with source directory as root.
        var filePath = srcFile.path.replaceAll('${this.sourceDir.path}/', '');
        // Convert body content from markdown to HTML.
        var fileContent = markdownToHtml(parsed.content, inlineSyntaxes: [
          InlineHtmlSyntax(),
        ], blockSyntaxes: [
          HeaderWithIdSyntax(),
          TableSyntax(),
        ]);

        // Get HTML template, fallback to default template.
        var templateFileName = parsed.data.containsKey('template')
            ? parsed.data['template']
            : _defaultHtmlTemplate;
        var templateFile = File(p.join(
            p.current, this.config.directory['templates'], templateFileName));
        if (!await templateFile.exists()) {
          throw TotaException('HTML template not found: `$templateFileName`');
        }
        var template = Template(await templateFile.readAsString(),
            partialResolver: this.getTemplatePartial);

        // Create the destination file.
        var file = File(
            p.join(this.publicDir.path, p.setExtension(filePath, '.html')));

        // Create sub-directories before writing the file.
        await Directory(p.join(this.publicDir.path, p.dirname(filePath)))
            .create(recursive: true);
        await file.writeAsString(template.renderString({
          'content': fileContent,
          'data': parsed.data,
        }));
        generated.add(file);
      }
    }
    return generated;
  }

  /// Resolves the template partial.
  Template getTemplatePartial(String name) {
    var partialDir = Directory(
        p.join(p.current, this.config.directory['templates'], '_partials'));
    String partialText = '';
    for (var file in partialDir.listSync(recursive: true)) {
      if (file is File && p.basenameWithoutExtension(file.path) == name) {
        partialText = (file as File).readAsStringSync();
      }
    }
    if (partialText.isEmpty) {
      throw TotaException('HTML template partial not found: `$name`');
    }
    return Template(partialText);
  }
}
