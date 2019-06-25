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
      // Delete existing public directory.
      logger.stdout('Deleting public directory');
      logger.trace(config.publicDir.toFilePath());
      await tota.deletePublicDir();

      // Build pages, posts, etc.
      Progress progress = logger.progress('Generating static files');
      List<Uri> files = await tota.buildFiles();
      files.forEach((file) => logger.trace(file.path));
      progress.finish(showTiming: true);

      // Copy assets folder to public directory.
      logger.stdout('Copying assets directory to public directory');
      logger.trace(config.publicDir.toFilePath());
      await tota.copyAssets();

      logger.stdout('All ${logger.ansi.emphasized('done')}.');
    } catch (e) {
      logger.stderr(logger.ansi.error(e.message));
    }
  }
}
