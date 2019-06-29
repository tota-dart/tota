import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:tota/src/deploy/deploy_handler.dart';

import '../../tota.dart' as tota;
import '../config.dart';

class DeployCommand extends Command {
  final name = 'deploy';
  final description = 'Deploy site to host provider';

  DeployCommand() {
    argParser.addOption('provider',
        abbr: 'p',
        allowed: ['netlify'],
        help: 'Host provider',
        defaultsTo: 'netlify');
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
  }

  HostProvider getHostProvider(String name) {
    switch (name) {
      case 'netlify':
        return HostProvider.netlify;
      default:
        throw tota.TotaException('host not supported: `$name`');
    }
  }

  void run() async {
    dotenv.load();
    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      Config config = tota.loadConfig();

      // Progress progress = logger.progress('Deploying site');
      await tota.deploy(getHostProvider(argResults['provider']),
          config: config, logger: logger);
      // progress.finish(showTiming: true);

      //logger.stdout('Project ${logger.ansi.emphasized('deployed')}.');
    } catch (e) {
      switch (e.runtimeType) {
        case tota.TotaException:
          logger.stderr(logger.ansi.error(e.message));
          break;
        default:
          rethrow;
      }
    }
  }
}