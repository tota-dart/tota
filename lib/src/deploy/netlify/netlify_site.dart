import 'dart:convert';

import 'package:cli_util/cli_logging.dart';
import 'package:tota/src/deploy/netlify/netlify_exception.dart';

import 'netlify_client.dart';

/// A site resource in Netlify.
class NetlifySite {
  final NetlifyClient client;

  // Account ID obtained after retrieval or creation.
  String id;

  NetlifySite(this.client);

  /// Creates a new site on Netlify.
  Future<NetlifySite> create() async {
    var response = await client.createSite();
    if (response.statusCode != 201) {
      throw NetlifyApiException(
          'failed to create site (${client.siteId})', null);
    }
    var body = json.decode(response.body);
    this.id = body['id'];
    return this;
  }

  /// Retrieves a site from Netlify API.
  Future<NetlifySite> retrieve() async {
    var response = await client.retrieveSite();
    var body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw NetlifyApiException(
          'site not found (${client.siteId})', body['message']);
    }
    this.id = body['id'];
    return this;
  }

  /// Find or creates a Netlify site.
  Future<NetlifySite> findOrCreate({Logger logger}) async {
    logger ??= Logger.standard();
    try {
      NetlifySite site = await retrieve();
      logger.trace('Site found: ${client.siteId}');
      return site;
    } catch (e) {
      if (e.message.toString().contains('site not found')) {
        logger.trace('Site not found');
        logger.trace('Creating new site: ${client.siteId}');
        return await create();
      } else {
        rethrow;
      }
    }
  }
}
