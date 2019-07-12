import 'deploy/deploy.dart';

/// Base exception class for Tota exceptions.
class TotaException implements Exception {
  final String message;

  TotaException([this.message]);

  @override
  String toString() => message ?? super.toString();
}

/// Exception raised when file system operation failures occur.
class TotaIOException extends TotaException {
  final String path;
  final String message;

  TotaIOException(this.path, this.message);

  @override
  String toString() => 'TotaIOException(path: $path): ${super.toString()}';
}

/// Exception raised when deployment fails.
class DeployException extends TotaException {
  final DeployHost host;

  DeployException(this.host, String message) : super(message);

  @override
  String toString() =>
      'DeployException(host: ${_parseHost(host)}): ${super.toString()}';
}

String _parseHost(DeployHost host) {
  switch (host) {
    case DeployHost.netlify:
      return 'netlify';
    default:
      throw ArgumentError('Invalid host');
  }
}
