import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pub/domain/search_packages.dart';

const _host = 'pub.dartlang.org';

class PubRepository {
  Future<SearchPackages> searchPackages({
    required int page,
    required String search,
  }) async {
    final uri = Uri.https(
      _host,
      'api/search',
      {'page': '$page', 'q': search},
    );
    final responseString = await http.read(uri);
    final json = Map<String, dynamic>.from(jsonDecode(responseString));
    return SearchPackages.fromJson(json);
  }
}
