import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../../tota_exception.dart';
import 'netlify_config.dart';

/// A file to be uploaded to Netlify.
///
/// Contains a digest of file path and SHA1 of file contents.
class NetlifyFile {
  final NetlifyConfig config;

  /// URI of containing [directory].
  final Uri directory;

  /// File [path] relative to [directory].
  final String path;

  /// SHA1 [digest] of file contents;
  Digest digest;

  NetlifyFile(
      {@required this.config, @required this.directory, @required this.path});

  /// Reads the file as bytes.
  Future<List<int>> _readAsBytes() async {
    return await File.fromUri(directory.resolve(path)).readAsBytes();
  }

  /// Creates SHA1 digest of file contents.
  Future<void> createDigest() async {
    List<int> bytes = await _readAsBytes();
    this.digest = sha1.convert(bytes);
  }

  /// Uploads the file to Netlify.
  Future<NetlifyFile> upload(String deployId, {Logger logger}) async {
    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/octet-stream'
    };
    logger ??= Logger.standard();
    var response = await put(
        config.baseUri.resolve(
            'deploys/$deployId/files/$path?access_token=${config.accessToken}'),
        headers: headers,
        body: await _readAsBytes());

    var body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw TotaException("Failed to upload file `$path`: ${body['message']}");
    }
    logger.trace(directory.resolve(path).toFilePath());
    return this;
  }
}
