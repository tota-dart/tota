import 'package:args/command_runner.dart';
import 'package:tota/cli.dart';

void main(List<String> args) {
  var runner = new CommandRunner("tota", "Static site generator.")
    ..addCommand(BuildCommand())
    ..run(args);
}
