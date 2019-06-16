import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../../tota.dart' as tota;

class BuildCommand extends Command {
  final name = 'build';
  final description = 'Generates static files.';

  BuildCommand() {
    // Add option to deploy after generation.
    argParser.addFlag('deploy', abbr: 'd');
  }

  /// Prints a message acknowledging the generated [file].
  void logFile(File file) {
    var path = file.path.replaceAll(p.join('${p.current}/'), '');
    print('[INFO] Generated: ${path}');
  }

  void run() async {
    try {
      Map<String, dynamic> result =
          await tota.build(deploy: argResults['deploy']);
      result['pages']?.forEach(this.logFile);
      result['posts']?.forEach(this.logFile);
    } catch (e) {
      print(e);
    }
  }
}
