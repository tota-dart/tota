import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import '../../tota.dart' as tota;
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

  void run() async {
    dotenv.load();

    Logger logger =
        argResults['verbose'] ? Logger.verbose() : Logger.standard();

    try {
      String title = argResults.rest.isEmpty ? '' : argResults.rest[0];
      if (title.isEmpty) {
        throw TotaException('Title is required');
      }

      Progress progress = logger.progress('Generating file');
      tota.Resource resource;
      switch (argResults['type']) {
        case 'post':
          resource = tota.Resource.post;
          break;
        default:
          resource = tota.Resource.page;
      }
      Uri file =
          await tota.createPage(resource, title, force: argResults['force']);
      logger.trace(file.path);
      progress.finish(showTiming: true);

      logger.stdout('File ${logger.ansi.emphasized('created')}.');
    } catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    }
  }
}
