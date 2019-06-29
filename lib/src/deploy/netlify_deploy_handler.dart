import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:tota/src/tota_exception.dart';

import 'deploy_handler.dart';

// A file to be uploaded to Netlify.
class _FileDigest {
  String path;
  Digest digest;
  _FileDigest(this.path, this.digest);

  Map<String, String> toJson() {
    return {
      'path': path,
      'digest': digest.toString(),
    };
  }
}

/// Deploys a site to Netlify.
class NetlifyDeployHandler implements DeployHandler {
  final Uri uri = Uri.parse('https://api.netlify.com/api/v1/');
  final String siteId, accessToken;

  NetlifyDeployHandler(this.siteId, this.accessToken);

  /// Returns the Netlify site from API.
  Future<dynamic> _getSite(String siteId) async {
    var response = await get(
        uri.resolve('sites/$siteId.netlify.com?access_token=$accessToken'));
    if (response.statusCode != 200) {
      throw TotaException('netlify site not found: `$siteId`');
    }
    return json.decode(response.body);
  }

  /// Creates digests for all files in a [directory].
  Future<List<_FileDigest>> _createDigest(Uri directory) async {
    var digests = <_FileDigest>[];
    Directory dir = Directory.fromUri(directory);
    await for (var entity in dir.list(recursive: true)) {
      if (entity is File) {
        var bytes = await File(entity.path).readAsBytes();
        var digest = sha1.convert(bytes);
        var path = p.relative(entity.path, from: directory.toFilePath());
        digests.add(_FileDigest('/$path', digest));
      }
    }
    return digests;
  }

  /// Deploys the site to Netlify.
  ///
  /// Sends a digest of all files to Netlify to be uploaded,
  /// then uploads whatever Netlify doesn't have on its server.
  @override
  Future<void> deploy(Uri directory) async {
    // var site = await _getSite(siteId);
    var digest = await _createDigest(directory);
    print(json.encode(digest));
  }
}
