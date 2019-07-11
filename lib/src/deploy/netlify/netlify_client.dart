import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// An HTTP Client that connects to the Netlify API.
///
/// Drop-in replacement for [BaseClient] that contains several
/// helper methods to CRUD resources within the API.
class NetlifyClient extends http.BaseClient {
  /// The underlying HTTP client.
  http.Client _client;

  /// Base URI for Netlify API.
  final Uri _baseUri = Uri.parse('https://api.netlify.com/api/v1/');

  /// Netlify account access token.
  final String _accessToken;

  /// Base site name without ".netlify.com" suffix.
  final String _siteName;

  NetlifyClient(this._siteName, this._accessToken, [http.Client client])
      : _client = client ?? http.Client();

  /// Full site name with domain suffix.
  String get siteId => '$_siteName.netlify.com';

  /// Creates a Map of HTTP headers.
  Map<String, String> _createHeaders({String contentType}) {
    contentType ??= 'application/json';
    return <String, String>{HttpHeaders.contentTypeHeader: contentType};
  }

  /// Retrieves a site.
  Future<http.Response> retrieveSite() => _client
      .get(_baseUri.resolve('sites/${siteId}/?access_token=${_accessToken}'));

  /// Creates a new site.
  Future<http.Response> createSite() =>
      _client.post(_baseUri.resolve('sites/?access_token=${_accessToken}'),
          headers: _createHeaders(), body: json.encode({'name': _siteName}));

  /// Creates a new deploy.
  Future<http.Response> createDeploy(Map<String, dynamic> body) => _client.post(
      _baseUri.resolve('sites/${siteId}/deploys?access_token=${_accessToken}'),
      body: json.encode(body),
      headers: _createHeaders());

  /// Uploads a single file.
  Future<http.Response> createFile(String deployId, filePath, List<int> body) =>
      _client.put(
          _baseUri.resolve(
              'deploys/$deployId/files/${Uri.encodeComponent(filePath)}?access_token=${_accessToken}'),
          headers: _createHeaders(contentType: 'application/octet-stream'),
          body: body);

  /// Concrete implementation of parent abstract class.
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request);

  /// Closes this client and its underlying HTTP client.
  void close() {
    if (_client != null) _client.close();
    _client = null;
  }
}
