import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as p;

import '../deploy.dart';
import 'netlify_client.dart';
import 'netlify_deploy.dart';
import 'netlify_file.dart';
import 'netlify_site.dart';

/// Handles a site deployment to Netlify via the API.
class NetlifyDeployHandler implements DeployHandler {
  NetlifyClient _client;

  NetlifyDeployHandler(this._client);

  /// Builds a list of files in a [directory] with digests.
  Future<List<NetlifyFile>> _createDigest(Uri directory,
      {Logger logger}) async {
    logger ??= Logger.standard();
    var files = <NetlifyFile>[];
    await for (FileSystemEntity entity
        in Directory.fromUri(directory).list(recursive: true)) {
      if (entity is File) {
        NetlifyFile file = NetlifyFile(
            client: _client,
            directory: directory,
            path: p.relative(entity.path, from: directory.toFilePath()));
        await file.createDigest();
        files.add(file);
        logger.trace(directory.resolve(file.path).toFilePath());
      }
    }
    return files;
  }

  /// Deploys the site to Netlify.
  ///
  /// Sends a digest of all files to Netlify to be uploaded,
  /// then uploads whatever Netlify doesn't have on its server.
  @override
  Future<void> deploy(Uri filesDir, {Uri functionsDir, Logger logger}) async {
    logger ??= Logger.standard();

    // Find or create the site.
    Progress siteProgress = logger.progress('Retrieving site from Netlify');
    NetlifySite site = NetlifySite(_client);
    await site.findOrCreate(logger: logger);
    siteProgress.finish(showTiming: true);

    // Create a digest of files to be uploaded.
    Progress digestProgress = logger.progress('Gathering file information');
    List<NetlifyFile> files = await _createDigest(filesDir, logger: logger);
    List<NetlifyFile> functions = [];
    if (functionsDir != null) {
      functions.addAll(await _createDigest(functionsDir));
    }
    digestProgress.finish(showTiming: true);

    // Create a deploy from file digests.
    Progress deployProgress = logger.progress('Creating deployment');
    NetlifyDeploy deploy =
        NetlifyDeploy(client: _client, files: files, functions: functions);
    await deploy.create(logger: logger);
    deployProgress.finish(showTiming: true);

    // Skip files that are already on Netlify's servers.
    files.retainWhere(
        (file) => deploy.requiredFiles.contains(file.digest.toString()));
    if (deploy.hasFunctions) {
      functions.retainWhere(
          (file) => deploy.requiredFunctions.contains(file.digest.toString()));
    }

    Progress uploadProgress = logger.progress('Uploading files');
    var filesUploaded = await deploy.uploadAll(files, logger: logger);

    _client.close();

    logger.trace(filesUploaded.isEmpty
        ? 'No new files to upload.'
        : 'Uploaded ${filesUploaded.length} file(s).');
    uploadProgress.finish(showTiming: true);
  }
}
