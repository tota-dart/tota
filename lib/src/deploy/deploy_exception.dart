import 'deploy_handler.dart';

/// An exception class for exceptions during site deployment.
class DeployException implements Exception {
  final DeployHost host;
  final String message;

  DeployException(this.host, this.message);

  @override
  String toString() => 'DeployException(host: $host): $message';
}
