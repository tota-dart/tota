import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:front_matter/front_matter.dart' as fm;
import 'package:markdown/markdown.dart';
import 'package:mustache/mustache.dart';
import 'tota_exception.dart';
import 'utils.dart';

const _defaultHtmlTemplate = 'base.mustache';
const _defaultLanguage = 'en';

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

/// Lists all files in a [directory].
///
/// Returns a list of all Markdown files in a [directory] (recursively).
/// Optionally filters out files that don't match a file [extension].
Future<List<Uri>> listDirectory(Uri directory, {String extension}) async {
  var dir = Directory.fromUri(directory);
  if (!await dir.exists()) {
    throw TotaException('Directory not found: ${directory.toFilePath()}');
  }
  var entities = await dir.list(recursive: true).toList();
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
    {List<Uri> files, Uri sourceDir, publicDir, templatesDir}) async {
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
      var bodyContent = markdownToHtml(parsed.content, inlineSyntaxes: [
        InlineHtmlSyntax(),
      ], blockSyntaxes: [
        HeaderWithIdSyntax(),
        TableSyntax(),
      ]);

      // Get HTML template, fallback to default template.
      var templateFileName = parsed.data.containsKey('template')
          ? parsed.data['template']
          : _defaultHtmlTemplate;
      // Add template file extension if absent.
      if (p.extension(templateFileName).isEmpty) {
        templateFileName = p.setExtension(templateFileName, '.mustache');
      }
      var templateFile = File.fromUri(templatesDir.resolve(templateFileName));
      if (!await templateFile.exists()) {
        throw TotaException('HTML template not found: `$templateFileName`');
      }
      var template = Template(await templateFile.readAsString(),
          partialResolver: partialResolver(templatesDir.resolve('_partials')));

      // Create a file URI relative to source directory, in order to
      // generate the same nested directory structure in the public directory.
      var fileName = p.relative(p.setExtension(srcFile.path, '.html'),
          from: sourceDir.path);
      Uri fileUri = publicDir.resolve(fileName);

      // Create nested directories in public directory before writing the file.
      await Directory(p.dirname(fileUri.toFilePath())).create(recursive: true);

      // Compile HTML templates.
      String fileContent;
      try {
        fileContent = template.renderString({
          'content': bodyContent,
          'title': parsed.data['title'] ?? getenv('TITLE'),
          'description': parsed.data['description'] ?? getenv('DESCRIPTION'),
          'date': parsed.data['date'] ?? formatDate(DateTime.now()),
          'language': getenv('LANGUAGE', fallback: _defaultLanguage),
          'data': parsed.data,
        });
      } catch (e) {
        throw TotaException('Failed to compile templates. ${e.message}');
      }

      // Write to destination file.
      await File.fromUri(fileUri).writeAsString(fileContent);
      generated.add(fileUri);
    }
  }
  return generated;
}

/// Returns a function that resolves the partial template.
///
/// Recursively searches the `_partials` directory for a file
/// that matches the partial [name].
Function(String name) partialResolver(Uri partialsDir) {
  return (String name) {
    var directory = Directory.fromUri(partialsDir);
    if (!directory.existsSync()) {
      throw TotaException("template partials directory not found");
    }
    var partial = '';
    for (var file in directory.listSync(recursive: true)) {
      if (file is File && p.basenameWithoutExtension(file.path) == name) {
        partial = file.readAsStringSync();
      }
    }
    return Template(partial);
  };
}

/// Copies a directory from a [source] to a [destination] URI.
Future<void> copyDirectory(Uri source, destination) async {
  var sourceDir = Directory.fromUri(source);
  await for (FileSystemEntity entity in sourceDir.list(recursive: true)) {
    if (await FileSystemEntity.isFile(entity.path)) {
      // Relative file path from origin directory.
      var filePath = p.relative(entity.path, from: source.toFilePath());
      // Relative path joined to destination.
      var destPath = p.join(destination.toFilePath(), filePath);
      // Create any nested sub-directories.
      await Directory(p.dirname(destPath)).create(recursive: true);
      // Copy file to new path.
      await File(entity.path).copy(destPath);
    }
  }
}

/// Deletes a [directory].
Future<bool> removeDir(Uri directory, {bool recursive = false}) async {
  Directory dir = Directory.fromUri(directory);
  if (await dir.exists()) {
    await dir.delete(recursive: recursive);
  }
  return await dir.exists();
}
