import 'dart:convert';

import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart';
import 'package:tota/src/tota_exception.dart';

import 'netlify_config.dart';
import 'netlify_deploy_handler.dart';

/// A site resource in Netlify.
class NetlifySite {
  final NetlifyConfig config;

  // Account ID obtained after retrieval or creation.
  String id;

  NetlifySite(this.config);

  /// Creates a new site on Netlify.
  Future<NetlifySite> _create() async {
    var response = await post(
        config.baseUri.resolve('sites/?access_token=${config.accessToken}'),
        headers: defaultHeaders,
        body: json.encode({'name': config.siteName}));
    if (response.statusCode != 201) {
      throw TotaException('[netlify] could not create site `${config.siteId}`');
    }
    var body = json.decode(response.body);
    this.id = body['id'];
    return this;
  }

  /// Retrieves a site from Netlify API.
  Future<NetlifySite> _get() async {
    var response = await get(config.baseUri
        .resolve('sites/${config.siteId}/?access_token=${config.accessToken}'));
    if (response.statusCode != 200) {
      throw TotaException('[netlify] site not found: `${config.siteId}`');
    }
    var body = json.decode(response.body);
    this.id = body['id'];
    return this;
  }

  /// Find or creates a Netlify site.
  Future<NetlifySite> findOrCreate({Logger logger}) async {
    logger ??= Logger.standard();
    try {
      NetlifySite site = await _get();
      logger.trace('Site found: ${config.siteId}');
      return site;
    } catch (e) {
      if (e.message.toString().contains('site not found')) {
        logger.trace('Site not found, creating new site: ${config.siteId}');
        return await _create();
      } else {
        rethrow;
      }
    }
  }
}
