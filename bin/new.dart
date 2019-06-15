import 'dart:io';
import 'package:path/path.dart' as p;
import '../lib/tota.dart' as tota;

Future<void> main(List<String> args) async {
  try {
    File file = await tota.create(args[1], type: args[0]);
    print('Created: ./${p.relative(file.path)}');
  } catch (e) {
    print(e);
  }
}
