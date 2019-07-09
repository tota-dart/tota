/// Configuration settings required to connect with the Netlify API.
class NetlifyConfig {
  /// Base URI for Netlify API.
  final Uri baseUri = Uri.parse('https://api.netlify.com/api/v1/');

  /// Netlify account credentials.
  final String siteName, accessToken;

  NetlifyConfig(this.siteName, this.accessToken);

  /// Returns the full site name with Netlify domain suffix.
  String get siteId => '$siteName.netlify.com';
}
