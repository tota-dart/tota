import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:front_matter/front_matter.dart' as fm;
import 'package:markdown/markdown.dart';
import 'package:mustache/mustache.dart';
import 'tota_exception.dart';
import 'utils.dart';

const _defaultHtmlTemplate = 'base.mustache';

/// Scaffolds a source file from a starting template.
///
/// Creates a new [file] in the source directory with optional [metadata]
/// (front matter) and body [content].
Future<Uri> createSourceFile(Uri fileUri,
    {Map<String, dynamic> metadata,
    String content = '',
    bool force = false}) async {
  File file = File.fromUri(fileUri);
  if (await file.exists()) {
    if (force) {
      // Overwrite file.
      await file.delete();
    } else {
      throw fileAlreadyExistsException(file.path);
    }
  }
  // Prefix content with front matter.
  if (metadata?.isNotEmpty ?? false) {
    content = '${createFrontMatter(metadata)}\n\n$content';
  }
  await file.writeAsString(content);
  return fileUri;
}

/// Lists all files in a directory.
///
/// Returns a list of all Markdown files in a [directory] (recursively).
/// Optionally filters out files that don't match a file [extension].
Future<List<Uri>> listDirectory(Uri uri, {String extension}) async {
  var entities = await Directory.fromUri(uri).list(recursive: true).toList();
  var files = entities.whereType<File>().toList();
  if (extension != null) {
    files.removeWhere((file) => p.extension(file.path) != extension);
  }
  return files.map((file) => Uri.file(file.path)).toList();
}

/// Generates HTML files for all [files] in a list.
///
/// Parses file contents to separate front matter and body.
/// Converts Markdown body to HTML, then renders an HTML file
/// in the public directory using the desired HTML template.
Future<List<Uri>> generateHtmlFiles(
    {List<Uri> files, Uri sourceDir, publicDir}) async {
  List<Uri> generated = [];
  for (var srcFile in files) {
    // Read the file and parse front matter & content.
    fm.FrontMatterDocument parsed;
    try {
      parsed = await fm.parseFile(srcFile.path);
    } catch (e) {
      throw TotaException('${e.message} `${srcFile.path}`');
    }

    // Ignore files that aren't public (or just have no front matter).
    if ((parsed.data?.containsKey('public') ?? false) &&
        parsed.data['public']) {
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
      var templateFile =
          File(p.join(p.current, getenv('TEMPLATES_DIR'), templateFileName));
      if (!await templateFile.exists()) {
        throw TotaException('HTML template not found: `$templateFileName`');
      }
      var template = Template(await templateFile.readAsString(),
          partialResolver: getTemplatePartial);

      // Create a file URI relative to source directory, in order to
      // generate the same directory structure in the public directory.
      var fileName = p.relative(p.setExtension(srcFile.path, '.html'),
          from: sourceDir.path);
      Uri fileUri = Uri.file(p.join(publicDir.path, fileName));

      // Create nested directories in public directory before writing the file.
      await Directory(p.join(publicDir.path, p.dirname(fileUri.path)))
          .create(recursive: true);

      // Write to destination file.
      File file = File.fromUri(fileUri);
      await file.writeAsString(template.renderString({
        'content': fileContent,
        'data': parsed.data,
      }));
      generated.add(fileUri);
    }
  }
  return generated;
}

/// Resolves the template for a partial.
///
/// Recursively searches the `_partials` directory for a file
/// that matches the partial [name].
Template getTemplatePartial(String name) {
  var directory =
      Directory(p.join(p.current, getenv('TEMPLATES_DIR'), '_partials'));
  var partial = '';
  for (var file in directory.listSync(recursive: true)) {
    if (file is File && p.basenameWithoutExtension(file.path) == name) {
      partial = file.readAsStringSync();
    }
  }
  return Template(partial);
}
