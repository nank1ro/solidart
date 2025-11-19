// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:source_span/source_span.dart';

/// An abstraction around doing static type checking at compile/build time.
abstract class TypeChecker {
  const TypeChecker._();

  /// Creates a new [TypeChecker] that delegates to other [checkers].
  ///
  /// This implementation will return `true` for type checks if _any_ of the
  /// provided type checkers return true, which is useful for deprecating an
  /// API:
  /// ```dart
  /// const $Foo = const TypeChecker.fromRuntime(Foo);
  /// const $Bar = const TypeChecker.fromRuntime(Bar);
  ///
  /// // Used until $Foo is deleted.
  /// const $FooOrBar = const TypeChecker.forAny(const [$Foo, $Bar]);
  /// ```
  const factory TypeChecker.any(Iterable<TypeChecker> checkers) = _AnyChecker;

  /// Create a new [TypeChecker] for types matching the name of [type].
  ///
  /// Optionally, also pass [inPackage] to restrict to a specific package by
  /// name. Set [inSdk] if it's a `dart` package.
  const factory TypeChecker.typeNamed(
    Type type, {
    String? inPackage,
    bool? inSdk,
  }) = _NameTypeChecker;

  /// Create a new [TypeChecker] for types with name exactly [name].
  ///
  /// Optionally, also pass [inPackage] to restrict to a specific package by
  /// name. Set [inSdk] if it's a `dart` package.
  const factory TypeChecker.typeNamedLiterally(
    String name, {
    String? inPackage,
    bool? inSdk,
  }) = _LiteralNameTypeChecker;

  /// Create a new [TypeChecker] backed by a static [type].
  const factory TypeChecker.fromStatic(DartType type) = _LibraryTypeChecker;

  /// Create a new [TypeChecker] backed by a library [url].
  ///
  /// Example of referring to a `LinkedHashMap` from `dart:collection`:
  /// ```dart
  /// const linkedHashMap = const TypeChecker.fromUrl(
  ///   'dart:collection#LinkedHashMap',
  /// );
  /// ```
  ///
  /// **NOTE**: This is considered a more _brittle_ way of determining the type
  /// because it relies on knowing the _absolute_ path (i.e. after resolved
  /// `export` directives). You should ideally only use `fromUrl` when you know
  /// the full path (likely you own/control the package) or it is in a stable
  /// package like in the `dart:` SDK.
  const factory TypeChecker.fromUrl(dynamic url) = _UriTypeChecker;

  /// Returns the first constant annotating [element] assignable to this type.
  ///
  /// Otherwise returns `null`.
  ///
  /// Throws on unresolved annotations unless [throwOnUnresolved] is `false`.
  DartObject? firstAnnotationOf(
    Object element, {
    bool throwOnUnresolved = true,
  }) {
    final results = annotationsOf(
      element,
      throwOnUnresolved: throwOnUnresolved,
    );
    return results.isEmpty ? null : results.first;
  }

  /// Returns if a constant annotating [element] is assignable to this type.
  ///
  /// Throws on unresolved annotations unless [throwOnUnresolved] is `false`.
  bool hasAnnotationOf(Element element, {bool throwOnUnresolved = true}) =>
      firstAnnotationOf(element, throwOnUnresolved: throwOnUnresolved) != null;

  /// Returns the first constant annotating [element] that is exactly this type.
  ///
  /// Throws [UnresolvedAnnotationException] on unresolved annotations unless
  /// [throwOnUnresolved] is explicitly set to `false` (default is `true`).
  DartObject? firstAnnotationOfExact(
    Element element, {
    bool throwOnUnresolved = true,
  }) {
    if (element.metadata.annotations.isEmpty) {
      return null;
    }
    final results = annotationsOfExact(
      element,
      throwOnUnresolved: throwOnUnresolved,
    );
    return results.isEmpty ? null : results.first;
  }

  /// Returns if a constant annotating [element] is exactly this type.
  ///
  /// Throws [UnresolvedAnnotationException] on unresolved annotations unless
  /// [throwOnUnresolved] is explicitly set to `false` (default is `true`).
  bool hasAnnotationOfExact(Element element, {bool throwOnUnresolved = true}) =>
      firstAnnotationOfExact(element, throwOnUnresolved: throwOnUnresolved) !=
      null;

  DartObject? _computeConstantValue(
    Object element,
    ElementAnnotation annotation,
    int annotationIndex, {
    bool throwOnUnresolved = true,
  }) {
    final result = annotation.computeConstantValue();
    if (result == null && throwOnUnresolved && element is Element) {
      throw UnresolvedAnnotationException._from(element, annotationIndex);
    }
    return result;
  }

  /// Returns annotating constants on [element] assignable to this type.
  ///
  /// Throws [UnresolvedAnnotationException] on unresolved annotations unless
  /// [throwOnUnresolved] is explicitly set to `false` (default is `true`).
  Iterable<DartObject> annotationsOf(
    Object element, {
    bool throwOnUnresolved = true,
  }) => _annotationsWhere(
    element,
    isAssignableFromType,
    throwOnUnresolved: throwOnUnresolved,
  );

  Iterable<DartObject> _annotationsWhere(
    Object element,
    bool Function(DartType) predicate, {
    bool throwOnUnresolved = true,
  }) sync* {
    if (element
        case Element(:final metadata) || ElementDirective(:final metadata)) {
      final annotations = metadata.annotations;
      for (var i = 0; i < annotations.length; i++) {
        final value = _computeConstantValue(
          element,
          annotations[i],
          i,
          throwOnUnresolved: throwOnUnresolved,
        );
        if (value?.type != null && predicate(value!.type!)) {
          yield value;
        }
      }
    }
  }

  /// Returns annotating constants on [element] of exactly this type.
  ///
  /// Throws [UnresolvedAnnotationException] on unresolved annotations unless
  /// [throwOnUnresolved] is explicitly set to `false` (default is `true`).
  Iterable<DartObject> annotationsOfExact(
    Element element, {
    bool throwOnUnresolved = true,
  }) => _annotationsWhere(
    element,
    isExactlyType,
    throwOnUnresolved: throwOnUnresolved,
  );

  /// Returns `true` if the type of [element] can be assigned to this type.
  bool isAssignableFrom(Element element) =>
      isExactly(element) ||
      (element is InterfaceElement && element.allSupertypes.any(isExactlyType));

  /// Returns `true` if [staticType] can be assigned to this type.
  bool isAssignableFromType(DartType staticType) {
    final element = staticType.element;
    return element != null && isAssignableFrom(element);
  }

  /// Returns `true` if representing the exact same class as [element].
  bool isExactly(Element element);

  /// Returns `true` if representing the exact same type as [staticType].
  ///
  /// This will always return false for types without a backing class such as
  /// `void` or function types.
  bool isExactlyType(DartType staticType) {
    final element = staticType.element;
    if (element != null) {
      return isExactly(element);
    } else {
      return false;
    }
  }

  /// Returns `true` if representing a super class of [element].
  ///
  /// This check only takes into account the *extends* hierarchy. If you wish
  /// to check mixins and interfaces, use [isAssignableFrom].
  bool isSuperOf(Element element) {
    if (element is InterfaceElement) {
      var theSuper = element.supertype;

      do {
        if (isExactlyType(theSuper!)) {
          return true;
        }

        theSuper = theSuper.superclass;
      } while (theSuper != null);
    }

    return false;
  }

  /// Returns `true` if representing a super type of [staticType].
  ///
  /// This only takes into account the *extends* hierarchy. If you wish
  /// to check mixins and interfaces, use [isAssignableFromType].
  bool isSuperTypeOf(DartType staticType) => isSuperOf(staticType.element!);
}

// Checks a static type against another static type;
class _LibraryTypeChecker extends TypeChecker {
  final DartType _type;

  const _LibraryTypeChecker(this._type) : super._();

  @override
  bool isExactly(Element element) =>
      element is InterfaceElement && element == _type.element;

  @override
  String toString() => urlOfElement(_type.element!);
}

// Checks a runtime type name and optional package against a static type.
class _NameTypeChecker extends TypeChecker {
  final Type _type;

  final String? _inPackage;
  final bool _inSdk;

  const _NameTypeChecker(this._type, {String? inPackage, bool? inSdk})
    : _inPackage = inPackage,
      _inSdk = inSdk ?? false,
      super._();

  String get _typeName {
    final result = _type.toString();
    return result.contains('<')
        ? result.substring(0, result.indexOf('<'))
        : result;
  }

  @override
  bool isExactly(Element element) {
    final library = element.library;
    if (library == null) return false;
    final uri = library.uri;
    return element.name == _typeName &&
        (_inPackage == null ||
            (((uri.scheme == 'dart') == _inSdk) &&
                uri.pathSegments.first == _inPackage));
  }

  @override
  String toString() => _inPackage == null ? '$_type' : '$_inPackage#$_type';
}

// [_NameTypeChecker] that ignores the `Type` and uses a `String` name.
class _LiteralNameTypeChecker extends _NameTypeChecker {
  @override
  final String _typeName;

  const _LiteralNameTypeChecker(
    this._typeName, {
    String? inPackage,
    bool? inSdk,
  }) : super(Object, inPackage: inPackage, inSdk: inSdk);

  @override
  String toString() => _inPackage == null ? '$_type' : '$_inPackage#$_typeName';
}

// Checks a runtime type against an Uri and Symbol.
class _UriTypeChecker extends TypeChecker {
  final String _url;

  // Precomputed cache of String --> Uri.
  static final _cache = Expando<Uri>();

  const _UriTypeChecker(dynamic url) : _url = '$url', super._();

  @override
  bool operator ==(Object o) => o is _UriTypeChecker && o._url == _url;

  @override
  int get hashCode => _url.hashCode;

  /// Url as a [Uri] object, lazily constructed.
  Uri get uri => _cache[this] ??= normalizeUrl(Uri.parse(_url));

  /// Returns whether this type represents the same as [url].
  bool hasSameUrl(dynamic url) =>
      uri.toString() ==
      (url is String ? url : normalizeUrl(url as Uri).toString());

  @override
  bool isExactly(Element element) => hasSameUrl(urlOfElement(element));

  @override
  String toString() => '$uri';
}

class _AnyChecker extends TypeChecker {
  final Iterable<TypeChecker> _checkers;

  const _AnyChecker(this._checkers) : super._();

  @override
  bool isExactly(Element element) => _checkers.any((c) => c.isExactly(element));
}

/// Exception thrown when [TypeChecker] fails to resolve a metadata annotation.
///
/// Methods such as [TypeChecker.firstAnnotationOf] may throw this exception
/// when one or more annotations are not resolvable. This is usually a sign that
/// something was misspelled, an import is missing, or a dependency was not
/// defined (for build systems such as Bazel).
class UnresolvedAnnotationException implements Exception {
  /// Element that was annotated with something we could not resolve.
  final Element annotatedElement;

  /// Source span of the annotation that was not resolved.
  ///
  /// May be `null` if the import library was not found.
  final SourceSpan? annotationSource;

  static SourceSpan? _findSpan(Element annotatedElement, int annotationIndex) {
    try {
      final parsedLibrary =
          annotatedElement.session!.getParsedLibraryByElement(
                annotatedElement.library!,
              )
              as ParsedLibraryResult;
      final declaration = parsedLibrary.getFragmentDeclaration(
        annotatedElement.firstFragment,
      );
      if (declaration == null) {
        return null;
      }
      final node = declaration.node;
      final List<Annotation> metadata;
      if (node is AnnotatedNode) {
        metadata = node.metadata;
      } else if (node is FormalParameter) {
        metadata = node.metadata;
      } else {
        throw StateError(
          'Unhandled Annotated AST node type: ${node.runtimeType}',
        );
      }
      final annotation = metadata[annotationIndex];
      final start = annotation.offset;
      final end = start + annotation.length;
      final parsedUnit = declaration.parsedUnit!;
      return SourceSpan(
        SourceLocation(start, sourceUrl: parsedUnit.uri),
        SourceLocation(end, sourceUrl: parsedUnit.uri),
        parsedUnit.content.substring(start, end),
      );
    } catch (e, stack) {
      // Trying to get more information on https://github.com/dart-lang/sdk/issues/45127
      log.warning(
        '''
An unexpected error was thrown trying to get location information on `$annotatedElement` (${annotatedElement.runtimeType}).

Please file an issue at https://github.com/dart-lang/source_gen/issues/new
Include the contents of this warning and the stack trace along with
the version of `package:source_gen`, `package:analyzer` from `pubspec.lock`.
''',
        e,
        stack,
      );
      return null;
    }
  }

  /// Creates an exception from an annotation ([annotationIndex]) that was not
  /// resolvable while traversing `metadata2` on [annotatedElement].
  factory UnresolvedAnnotationException._from(
    Element annotatedElement,
    int annotationIndex,
  ) {
    final sourceSpan = _findSpan(annotatedElement, annotationIndex);
    return UnresolvedAnnotationException._(annotatedElement, sourceSpan);
  }

  const UnresolvedAnnotationException._(
    this.annotatedElement,
    this.annotationSource,
  );

  @override
  String toString() {
    final message = 'Could not resolve annotation for `$annotatedElement`.';
    if (annotationSource != null) {
      return annotationSource!.message(message);
    }
    return message;
  }
}

/// Returns a non-null name for the provided [type].
///
/// In newer versions of the Dart analyzer, a `typedef` does not keep the
/// existing `name`, because it is used an alias:
/// ```
/// // Used to return `VoidFunc` for name, is now `null`.
/// typedef VoidFunc = void Function();
/// ```
///
/// This function will return `'VoidFunc'`, unlike [DartType.element]`.name`.
String typeNameOf(DartType type) {
  final aliasElement = type.alias?.element;
  if (aliasElement != null) {
    return aliasElement.name!;
  }
  if (type is DynamicType) {
    return 'dynamic';
  }
  if (type is InterfaceType) {
    return type.element.name!;
  }
  if (type is TypeParameterType) {
    return type.element.name!;
  }
  throw UnimplementedError('(${type.runtimeType}) $type');
}

bool hasExpectedPartDirective(CompilationUnit unit, String part) => unit
    .directives
    .whereType<PartDirective>()
    .any((e) => e.uri.stringValue == part);

/// Returns a uri suitable for `part of "..."` when pointing to [element].
String uriOfPartial(LibraryElement element, AssetId source, AssetId output) {
  assert(source.package == output.package);
  return p.url.relative(source.path, from: p.url.dirname(output.path));
}

/// Returns what 'part "..."' URL is needed to import [output] from [input].
///
/// For example, will return `test_lib.g.dart` for `test_lib.dart`.
String computePartUrl(AssetId input, AssetId output) => p.url.joinAll(
  p.url.split(p.url.relative(output.path, from: input.path)).skip(1),
);

/// Returns a URL representing [element].
String urlOfElement(Element element) => element.kind == ElementKind.DYNAMIC
    ? 'dart:core#dynamic'
    // using librarySource.uri – in case the element is in a part
    : normalizeUrl(
        element.library!.uri,
      ).replace(fragment: element.name).toString();

Uri normalizeUrl(Uri url) => switch (url.scheme) {
  'dart' => normalizeDartUrl(url),
  'package' => _packageToAssetUrl(url),
  'file' => _fileToAssetUrl(url),
  _ => url,
};

/// Make `dart:`-type URLs look like a user-knowable path.
///
/// Some internal dart: URLs are something like `dart:core/map.dart`.
///
/// This isn't a user-knowable path, so we strip out extra path segments
/// and only expose `dart:core`.
Uri normalizeDartUrl(Uri url) => url.pathSegments.isNotEmpty
    ? url.replace(pathSegments: url.pathSegments.take(1))
    : url;

Uri _fileToAssetUrl(Uri url) {
  if (!p.isWithin(p.url.current, url.path)) return url;
  return Uri(
    scheme: 'asset',
    path: p.join(rootPackageName, p.relative(url.path)),
  );
}

/// Returns a `package:` URL converted to a `asset:` URL.
///
/// This makes internal comparison logic much easier, but still allows users
/// to define assets in terms of `package:`, which is something that makes more
/// sense to most.
///
/// For example, this transforms `package:source_gen/source_gen.dart` into:
/// `asset:source_gen/lib/source_gen.dart`.
Uri _packageToAssetUrl(Uri url) => url.scheme == 'package'
    ? url.replace(
        scheme: 'asset',
        pathSegments: <String>[
          url.pathSegments.first,
          'lib',
          ...url.pathSegments.skip(1),
        ],
      )
    : url;

/// Returns a `asset:` URL converted to a `package:` URL.
///
/// For example, this transformers `asset:source_gen/lib/source_gen.dart' into:
/// `package:source_gen/source_gen.dart`. Asset URLs that aren't pointing to a
/// file in the 'lib' folder are not modified.
///
/// Asset URLs come from `package:build`, as they are able to describe URLs that
/// are not describable using `package:...`, such as files in the `bin`, `tool`,
/// `web`, or even root directory of a package - `asset:some_lib/web/main.dart`.
Uri assetToPackageUrl(Uri url) =>
    url.scheme == 'asset' &&
        url.pathSegments.isNotEmpty &&
        url.pathSegments[1] == 'lib'
    ? url.replace(
        scheme: 'package',
        pathSegments: [url.pathSegments.first, ...url.pathSegments.skip(2)],
      )
    : url;

final String rootPackageName = () {
  final name =
      (loadYaml(File('pubspec.yaml').readAsStringSync()) as Map)['name'];
  if (name is! String) {
    throw StateError(
      'Your pubspec.yaml file is missing a `name` field or it isn\'t '
      'a String.',
    );
  }
  return name;
}();

/// Returns a valid buildExtensions map created from [optionsMap] or
/// returns [defaultExtensions] if no 'build_extensions' key exists.
///
/// Modifies [optionsMap] by removing the `build_extensions` key from it, if
/// present.
Map<String, List<String>> validatedBuildExtensionsFrom(
  Map<String, dynamic>? optionsMap,
  Map<String, List<String>> defaultExtensions,
) {
  final extensionsOption = optionsMap?.remove('build_extensions');
  if (extensionsOption == null) {
    // defaultExtensions are provided by the builder author, not the end user.
    // It should be safe to skip validation.
    return defaultExtensions;
  }

  if (extensionsOption is! Map) {
    throw ArgumentError(
      'Configured build_extensions should be a map from inputs to outputs.',
    );
  }

  final result = <String, List<String>>{};

  for (final entry in extensionsOption.entries) {
    final input = entry.key;
    if (input is! String || !input.endsWith('.dart')) {
      throw ArgumentError(
        'Invalid key in build_extensions option: `$input` '
        'should be a string ending with `.dart`',
      );
    }

    final output = (entry.value is List) ? entry.value as List : [entry.value];

    for (var i = 0; i < output.length; i++) {
      final o = output[i];
      if (o is! String || (i == 0 && !o.endsWith('.dart'))) {
        throw ArgumentError(
          'Invalid output extension `${entry.value}`. It should be a string '
          'or a list of strings with the first ending with `.dart`',
        );
      }
    }

    result[input] = output.cast<String>().toList();
  }

  if (result.isEmpty) {
    throw ArgumentError('Configured build_extensions must not be empty.');
  }

  return result;
}
