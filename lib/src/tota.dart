library tota;

import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:tota/src/deploy/deploy_handler.dart';

import 'config.dart';
import 'file_system.dart' as fs;
import 'resource.dart';
import 'starter.dart';
import 'tota_exception.dart';

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
Future<void> createPage(ResourceType type, String title,
    {@required Config config, bool force = false, Logger logger}) async {
  logger ??= Logger.standard();

  Progress progress = logger.progress('Generating file');
  Resource page =
      await createResource(type, title, config: config, force: force);
  logger.trace(page.path);
  progress.finish(showTiming: true);
}

/// Compiles source files and generates static files in the public directory.
Future<void> compile(Config config, {Logger logger}) async {
  logger ??= Logger.standard();

  // Empty the public directory.
  logger.stdout('Deleting public directory');
  logger.trace(config.publicDirUri.toFilePath());
  await fs.removeDirectory(config.publicDirUri, recursive: true);

  Progress progress = logger.progress('Generating static files');
  await compileResources(ResourceType.page, config: config, logger: logger);
  List<Resource> posts =
      await compileResources(ResourceType.post, config: config, logger: logger);
  progress.finish(showTiming: true);

  // Create posts archive page.
  logger.stdout('Creating archive pages');
  await createPostArchive(
    posts,
    config: config,
    logger: logger,
  );
  await createTagArchives(posts, config: config, logger: logger);

  // Copy assets directory to public directory.
  Uri publicAssetsDir = config.publicDirUri.resolve(config.assetsDir);
  logger.stdout('Copying assets folder');
  logger.trace(publicAssetsDir.toFilePath());
  fs.copyDirectory(config.assetsDirUri, publicAssetsDir);
}

Future<void> deploy(DeployHost host,
    {@required Config config, Logger logger}) async {
  DeployHandler handler = getDeployHandler(host, config);
  await handler.deploy(config.publicDirUri, logger: logger);
}
