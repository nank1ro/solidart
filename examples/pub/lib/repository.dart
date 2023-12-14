import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pub/common/in_memory_cache.dart';
import 'package:pub/domain/package.dart';
import 'package:pub/domain/package_score.dart';
import 'package:pub/domain/search_packages.dart';
import 'dart:async';

const _host = 'pub.dartlang.org';

const _defaultCacheDuration = Duration(hours: 1);

class PubRepository {
  final _searchPackagesCache =
      InMemoryCache<SearchPackages>(_defaultCacheDuration);

  Future<SearchPackages> searchPackages({
    required int page,
    required String search,
  }) {
    return _searchPackagesCache.fetch(() async {
      final uri = Uri.https(
        _host,
        'api/search',
        {'page': '$page', 'q': search},
      );
      final responseString = await http.read(_proxyWebUri(uri));
      final json = Map<String, dynamic>.from(jsonDecode(responseString));
      json['page'] = page;
      return SearchPackages.fromJson(json);
    }, key: '$page-$search');
  }

  final _getPackageScoreCache =
      InMemoryCache<PackageScore>(_defaultCacheDuration);

  Future<PackageScore> getPackageScore({
    required String package,
  }) async {
    return _getPackageScoreCache.fetch(() async {
      final uri = Uri.https(_host, 'api/packages/$package/score');
      final responseString = await http.read(_proxyWebUri(uri));
      final json = Map<String, dynamic>.from(jsonDecode(responseString));
      return PackageScore.fromJson(json);
    }, key: package);
  }

  final _getPackageCache = InMemoryCache<Package>(_defaultCacheDuration);

  Future<Package> getPackage({
    required String package,
  }) {
    return _getPackageCache.fetch(() async {
      final uri = Uri.https(_host, '/api/packages/$package');
      final responseString = await http.read(_proxyWebUri(uri));
      final json = Map<String, dynamic>.from(jsonDecode(responseString));
      return Package.fromJson(json);
    }, key: package);
  }

  Uri _proxyWebUri(Uri uri) {
    if (kIsWeb) {
      return Uri.https(
          'api.codetabs.com', '/v1/proxy', {'quest': uri.toString()});
    }
    return uri;
  }
}
