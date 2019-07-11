import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tota/src/deploy/netlify/netlify_client.dart';
import 'package:tota/src/deploy/netlify/netlify_deploy.dart';
import 'package:tota/src/deploy/netlify/netlify_exception.dart';
import 'package:tota/src/deploy/netlify/netlify_file.dart';
import 'package:tota/src/deploy/netlify/netlify_site.dart';

import 'utils.dart';

void main() {
  group('NelifySite', () {
    test('retrieves existing site', () async {
      var url =
          'https://api.netlify.com/api/v1/sites/foo.netlify.com/?access_token=t0k3n';
      var mockHttpClient = MockClient((req) {
        expect(req.method, equals('GET'));
        expect(req.url.toString(), equals(url));
        return Future.value(Response('{"id":"foo"}', 200));
      });

      var site = NetlifySite(NetlifyClient('foo', 't0k3n', mockHttpClient));
      expect(site.id, isNull);
      await site.retrieve();
      expect(site.id, equals('foo'));
      mockHttpClient.close();
    });

    test('creates a site', () async {
      var url = 'https://api.netlify.com/api/v1/sites/?access_token=t0k3n';
      var mockHttpClient = MockClient((req) {
        expect(req.method, equals('POST'));
        expect(req.url.toString(), equals(url));
        return Future.value(Response('{"id":"foo"}', 201));
      });

      var site = NetlifySite(NetlifyClient('foo', 't0k3n', mockHttpClient));
      expect(site.id, isNull);
      await site.create();
      expect(site.id, equals('foo'));
      mockHttpClient.close();
    });

    test('throws exception if API returns error', () async {
      var mockHttpClient = MockClient(
          (req) => Future.value(Response('{"message":"reason"}', 500)));

      var site = NetlifySite(NetlifyClient('foo', 't0k3n', mockHttpClient));

      expect(() async => await site.create(),
          throwsA(TypeMatcher<NetlifyApiException>()));
      mockHttpClient.close();
    });
  });

  group('NetlifyFile', () {
    BaseClient mockHttpClient = MockClient(null);
    NetlifyClient mockClient = NetlifyClient('foo', 't0k3n', mockHttpClient);

    tearDown(() {
      mockClient.close();
    });

    test('creates file digest', () {
      withFixtures((config) async {
        var file = NetlifyFile(
            client: mockClient,
            directory: Uri.directory(config.rootPath),
            path: p.join(config.publicPath, 'index.html'));
        expect(file.digest, isNull);
        await file.createDigest();
        expect(file.digest, isNotNull);
        expect(file.digest.runtimeType, equals(Digest));
      });
    });

    test('uploads file', () {
      withFixtures((config) async {
        var url =
            'https://api.netlify.com/api/v1/deploys/123/files/public/index.html?access_token=t0k3n';
        var mockHttpClient = MockClient((req) {
          expect(req.method, equals('PUT'));
          expect(req.url.toString(), equals(url));
          expect(req.body, equals('<h1>Hello, world!</h1>\n'));
          return Future.value(Response('{"id":"123"}', 200));
        });

        var file = NetlifyFile(
            client: NetlifyClient('foo', 't0k3n', mockHttpClient),
            directory: Uri.directory(config.rootPath),
            path: p.join(config.publicPath, 'index.html'));

        await file.upload('123');
        file.client.close();
      });
    });
  });

  group('NetlifyDeploy', () {
    BaseClient mockHttpClient = MockClient((req) {
      expect(
          req.url.toString(),
          equals(
              'https://api.netlify.com/api/v1/sites/foo.netlify.com/deploys?access_token=t0k3n'));
      return Future.value(Response('{"id":"123","required":["123"]}', 200));
    });
    NetlifyClient mockClient = NetlifyClient('foo', 't0k3n', mockHttpClient);
    List<NetlifyFile> files = [
      NetlifyFile(
          client: mockClient, directory: Uri.directory('foo'), path: 'bar')
    ];

    tearDown(() {
      mockClient.close();
    });

    test('creates deployment', () async {
      var deploy = NetlifyDeploy(
          client: mockClient, files: files, functions: <NetlifyFile>[]);
      expect(deploy.hasId, isFalse);
      await deploy.create();
      expect(deploy.hasId, isTrue);
      expect(deploy.hasFunctions, isFalse);
      expect(deploy.requiredFiles, hasLength(1));
      mockClient.close();
    });

    test('creates JSON body for deploy', () {
      var deploy = NetlifyDeploy(
          client: mockClient, files: files, functions: <NetlifyFile>[]);
      var body = deploy.toJson();
      expect(body['title'], equals('Deploy via Tota CLI'));
      expect(body['files'], hasLength(1));
    });
  });
}
