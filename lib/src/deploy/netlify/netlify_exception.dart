import '../deploy_exception.dart';
import '../deploy_handler.dart';

class NetlifyException extends DeployException implements Exception {
  final String message;

  NetlifyException(this.message) : super(DeployHost.netlify, message);
}

/// An exception indicating an error with an API request.
class NetlifyApiException extends NetlifyException {
  final String message;
  final String reason;

  NetlifyApiException(this.message, this.reason) : super(message);

  @override
  String toString() =>
      reason == null ? super.toString() : '${super.toString()}: ${reason}';
}
