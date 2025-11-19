import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

extension ImportFix on DartFileEditBuilder {
  String _buildImport(Uri uri, String name) {
    final import = importLibraryElement(uri);

    final prefix = import.prefix;
    if (prefix != null) return '$prefix.$name';

    return name;
  }

  @useResult
  String _importWithPrefix(String name, List<Uri> uris) {
    for (var i = 0; i < uris.length - 1; i++) {
      final uri = uris[i];
      if (importsLibrary(uri)) return _buildImport(uri, name);
    }

    final lastUri = uris.last;
    return _buildImport(lastUri, name);
  }

  @useResult
  String _importDisco(String name) {
    return _importWithPrefix(name, [
      Uri(scheme: 'package', path: 'disco/disco.dart'),
    ]);
  }

  @useResult
  String importProviderScope() => _importDisco('ProviderScope');
}
