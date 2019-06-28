library tota;

import 'dart:io';
import 'package:cli_util/cli_logging.dart';
import 'config.dart';
import 'starter.dart';
import 'resource.dart';
import 'file_system.dart' as fs;
import 'tota_exception.dart';
import 'utils.dart';

/// Initializes a new project in [directory].
Future<void> createProject(Uri directory) async {
  var dir = Directory.fromUri(directory);

  // Stop if directory isn't empty.
  if (await dir.exists()) {
    var dirents = await dir.list().toList();
    if (dirents.isNotEmpty) {
      throw TotaException(
          'target directory is not empty: `${directory.toFilePath()}`');
    }
  }

  return await clone(directory);
}

/// Creates a new page file.
///
/// The default [type] of resource to create is "page". Will throw an
/// exception if file already exists, but [force] will override this.
Future<void> createPage(Config config, String title,
    {ResourceType resourceType = ResourceType.page,
    bool force,
    Logger logger}) async {
  logger ??= Logger.standard();

  Progress progress = logger.progress('Generating file');
  Uri file;
  switch (resourceType) {
    case ResourceType.post:
      file = await createResource(resolveDir(config.dir.posts), title,
          force: force);
      break;
    default:
      file = await createResource(resolveDir(config.dir.pages), title,
          force: force);
  }
  logger.trace(file.toFilePath());
  progress.finish(showTiming: true);
}

/// Compiles source files and generates static files in the public directory.
Future<void> compile(Config config, {Logger logger}) async {
  logger ??= Logger.standard();

  // Empty the public directory.
  Uri publicDir = resolveDir(config.dir.public);
  logger.stdout('Deleting public directory');
  logger.trace(publicDir.toFilePath());
  await fs.removeDirectory(publicDir, recursive: true);

  Progress progress = logger.progress('Generating static files');
  Uri pagesDir = resolveDir(config.dir.pages);
  Uri templatesDir = resolveDir(config.dir.templates);
  await compileResources(
      sourceDir: pagesDir,
      publicDir: publicDir,
      templatesDir: templatesDir,
      config: config,
      resourceType: ResourceType.page);

  // Posts are nested one-level deep inside the public directory.
  // This will be reflected in the URL path for the blog.
  Uri postsDir = resolveDir(config.dir.posts);
  var posts = await compileResources(
      sourceDir: postsDir,
      publicDir: publicDir,
      templatesDir: templatesDir,
      config: config,
      resourceType: ResourceType.post);
  progress.finish(showTiming: true);

  // Create posts archive page.
  await createPostsArchive(posts,
      config: config, templatesDir: templatesDir, publicDir: publicDir);

  // Copy assets directory to public directory.
  Uri publicAssetsDir = publicDir.resolve(config.dir.assets);
  logger.stdout('Copying assets folder');
  logger.trace(publicAssetsDir.toFilePath());
  fs.copyDirectory(resolveDir(config.dir.assets), publicAssetsDir);
}
