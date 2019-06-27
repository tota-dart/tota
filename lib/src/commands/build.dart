import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import '../../tota.dart' as tota;
import '../config.dart';

class BuildCommand extends Command {
  final name = 'build';
  final description = 'Generate static files.';

  BuildCommand() {
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
  }

  void run() async {
    dotenv.load();

    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      Config config = tota.createConfig();
      await tota.compile(config);

      logger.stdout('All ${logger.ansi.emphasized('done')}.');
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
