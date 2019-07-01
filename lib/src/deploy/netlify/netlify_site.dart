import 'dart:convert';

import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart';
import 'package:tota/src/deploy/netlify/netlify_deploy_handler.dart';
import 'package:tota/src/tota_exception.dart';

/// A site resource in Netlify.
class NetlifySite {
  final String id, name;

  NetlifySite({this.id, this.name});

  /// Returns the full site ID with Netlify domain suffix.
  String get siteId => '$name.netlify.com';

  /// Creates a new site [name] on Netlify.
  static Future<NetlifySite> _create(String name, accessToken) async {
    var response = await post(
        baseUri.resolve('sites/?access_token=$accessToken'),
        headers: defaultHeaders,
        body: json.encode({'name': name}));
    if (response.statusCode != 201) {
      throw TotaException('[netlify] could not create site `$name`');
    }
    var body = json.decode(response.body);
    return NetlifySite(id: body['id'], name: body['name']);
  }

  /// Returns a Netlify site [name] from API.
  static Future<NetlifySite> _get(String name, accessToken) async {
    var response = await get(
        baseUri.resolve('sites/$name.netlify.com/?access_token=$accessToken'));
    if (response.statusCode != 200) {
      throw TotaException('[netlify] site not found: `$name`');
    }
    var body = json.decode(response.body);
    return NetlifySite(id: body['id'], name: body['name']);
  }

  /// Find or creates a Netlify site.
  static Future<NetlifySite> findOrCreate(String name, accessToken,
      {Logger logger}) async {
    logger ??= Logger.standard();
    try {
      NetlifySite site = await _get(name, accessToken);
      logger.trace('Site found: $name.netlify.com');
      return site;
    } catch (e) {
      if (e.message.toString().contains('site not found')) {
        logger.trace('Site not found: $name.netlify.com');
        logger.trace('Creating new site.');
        return await _create(name, accessToken);
      } else {
        rethrow;
      }
    }
  }
}
