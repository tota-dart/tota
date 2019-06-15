import 'dart:io';
import 'package:path/path.dart' as p;
import '../lib/tota.dart' as tota;

Future<void> main() async {
  try {
    await tota.build();
  } catch (e) {
    print(e);
  }
}
