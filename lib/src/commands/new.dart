import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import '../../tota.dart' as tota;
import '../config.dart';
import '../tota_exception.dart';

class NewCommand extends Command {
  final name = 'new';
  final description = 'Create a new page.';

  NewCommand() {
    argParser.addOption('type',
        allowed: ['page', 'post'],
        defaultsTo: 'pages',
        abbr: 't',
        help: 'Type of page to create.');
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enable verbose logging.');
    argParser.addFlag('force',
        abbr: 'f',
        negatable: false,
        help: 'Force creation of file.',
        defaultsTo: false);
  }

  /// Converts a page type [name] into a Tota resource type.
  tota.ResourceType getResourceType(String name) {
    switch (name) {
      case 'post':
        return tota.ResourceType.post;
      default:
        return tota.ResourceType.page;
    }
  }

  void run() async {
    dotenv.load();

    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      Config config = tota.loadConfig();

      String title = argResults.rest.isEmpty ? '' : argResults.rest[0];
      if (title.isEmpty) {
        throw TotaException('Title is required');
      }

      await tota.createPage(getResourceType(argResults['type']), title,
          config: config, force: argResults['force'], logger: logger);

      logger.stdout('File ${logger.ansi.emphasized('created')}.');
    } catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    }
  }
}
