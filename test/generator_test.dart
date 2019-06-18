import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:tota/tota.dart';
import 'package:tota/src/generator.dart';
import 'utils.dart';

void main() {
  group('createSourceFile()', () {
    test('creates a new source file', () {
      withTempDir((path) async {
        var file = File(p.join(path, 'foo.md'));

        await createSourceFile(Uri.file(file.path),
            metadata: <String, String>{'foo': 'bar'}, content: 'foo');

        expect(file.exists(), completion(equals(true)));
        expect(file.readAsString(),
            completion(equals('---\nfoo: bar\n---\n\nfoo')));
      });
    });

    test('throws error if file already exists', () {
      withTempDir((path) async {
        var file = File(p.join(path, 'foo.md'));
        await file.writeAsString('foo');

        expect(createSourceFile(Uri.file(file.path)),
            throwsA(TypeMatcher<TotaException>()));
      });
    });

    test('overwrites file with force option', () {
      withTempDir((path) async {
        var file = File(p.join(path, 'foo.md'));
        await file.writeAsString('foo');
        await createSourceFile(Uri.file(file.path),
            content: 'bar', force: true);

        expect(await file.readAsString(), equals('bar'));
      });
    });
  });

  group('listDirectory()', () {
    test('lists all files in a directory', () {
      withTempDir((path) async {
        var nums = List<int>.generate(5, (i) => i);

        // Create test files in temp dir.
        for (var num in nums) {
          var file = File(p.join(path, 'test-$num.md'));
          await file.writeAsString('foo');
        }

        var result = await listDirectory(Uri.directory(path));
        expect(result.length, equals(nums.length));
      });
    });

    test('only returns files that match a file extension', () {
      withTempDir((path) async {
        var filenames = ['foo.md', 'bar.md', 'virus.exe'];

        // Create test files in temp dir.
        for (var name in filenames) {
          var file = File(p.join(path, name));
          await file.writeAsString('foo');
        }

        var result = await listDirectory(Uri.directory(path), extension: '.md');
        expect(result.length, equals(filenames.length - 1));
      });
    });
  });
}
