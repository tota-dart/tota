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

  /// Retrieves a site from Netlify API.
  Future<NetlifySite> retrieve() async {
    var response = await client.retrieveSite();
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        throw NetlifyException('Site already exists', 401);
      default:
        throw NetlifyException('Site not found');
    }
    var body = json.decode(response.body);
    this.id = body['id'];
    return this;
  }

  /// Creates a new site on Netlify.
  Future<NetlifySite> create() async {
    var response = await client.createSite();
    var body = json.decode(response.body);
    if (response.statusCode != 201) {
      throw NetlifyException('Failed to create site');
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
    } on NetlifyException catch (e) {
      if (e.statusCode == 401) {
        // Can't proceed; site already exists.
        rethrow;
      }
      logger.trace('Site not found');
      logger.trace('Creating new site: ${client.siteId}');
      return await create();
    } catch (e) {
      rethrow;
    }
  }
}
