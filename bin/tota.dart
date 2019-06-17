#!/usr/bin/env dart
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:tota/cli.dart';

void main(List<String> args) {
  dotenv.load();
  var runner = CommandRunner('tota', 'Static site generator.')
    ..addCommand(BuildCommand())
    ..addCommand(NewCommand())
    ..run(args);
}
