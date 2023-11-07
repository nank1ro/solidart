import 'package:awesome_flutter_extensions/awesome_flutter_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:intl/intl.dart';
import 'package:pub/bloc/pub_search/bloc.dart';
import 'package:pub/common/assets.dart';
import 'package:pub/common/ui/basic_badge.dart';
import 'package:pub/common/ui/score_view.dart';
import 'package:pub/common/ui/tag_badge.dart';
import 'package:pub/domain/package.dart';
import 'package:pub/domain/package_score.dart';
import 'package:timeago/timeago.dart' as timeago;

class SearchPackagesList extends StatelessWidget {
  const SearchPackagesList({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the PubSearchBloc from the context
    final bloc = context.get<PubSearchBloc>();
    return RefreshIndicator(
      // refresh the resource when the user pulls down
      onRefresh: () => bloc.searchPackages.refresh(),
      // Using a ResourceBuilder to track each change in the searchPackages resource
      child: ResourceBuilder(
        resource: bloc.searchPackages,
        builder: (context, searchPackagesState) {
          // Handle the different states of the resource
          return searchPackagesState.on(
            ready: (searchPackages) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchPackages.packages.length,
                      itemBuilder: (BuildContext context, int index) {
                        return PackageView(
                          package: searchPackages.packages[index].package,
                        );
                      },
                    ),
                  ),
                  // TODO: add page selector
                  // const SizedBox(height: 8),
                  // PageSelector(
                  //   page: searchPackages.page,
                  //   hasNextPage: searchPackages.next != null,
                  // ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
          );
        },
      ),
    );
  }
}

class PackageView extends StatefulWidget {
  const PackageView({
    super.key,
    required this.package,
  });

  final String package;

  @override
  State<PackageView> createState() => _PackageViewState();
}

class _PackageViewState extends State<PackageView> {
  late final bloc = context.get<PubSearchBloc>();
  late final package = Resource(
    fetcher: () => bloc.getPackage(
      package: widget.package,
    ),
  );
  late final score = Resource(
    fetcher: () => bloc.getPackageScore(package: widget.package),
  );

  @override
  void didUpdateWidget(covariant PackageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.package != oldWidget.package) {
      package.refresh();
      score.refresh();
    }
  }

  @override
  void dispose() {
    package.dispose();
    score.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResourceBuilder(
      resource: package,
      builder: (context, packageState) {
        // when the resource is refreshing, don't render anything
        if (packageState.isRefreshing) {
          return const SizedBox.shrink();
        }
        return packageState.maybeOn(
          ready: (packageValue) {
            return ResourceBuilder(
              resource: score,
              builder: (context, scoreState) {
                return scoreState.maybeOn(
                  ready: (scoreValue) {
                    return InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  packageValue.name,
                                  style: context.textStyles.bodyLarge.bold
                                      .copyWith(
                                    color: context.colors.primary,
                                  ),
                                ),
                                ScoreView(score: scoreValue),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              packageValue.latest.pubspec.description
                                  .replaceAll('\n', ' '),
                              style: context.textStyles.bodySmall,
                            ),
                            if (packageValue.latest.pubspec.topics != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 8,
                                  children: packageValue.latest.pubspec.topics!
                                      .map((t) => Text(
                                            '#$t',
                                            style: context.textStyles.bodyMedium
                                                .copyWith(
                                              color: context
                                                  .colors.scheme.tertiary,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            const SizedBox(height: 4),
                            PackageMetadata(
                                package: packageValue, score: scoreValue),
                            const SizedBox(height: 4),
                            PackageTagBadges(score: scoreValue),
                          ],
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox(),
                  error: (error, stackTrace) => Text('$error'),
                );
              },
            );
          },
          orElse: () => const SizedBox(),
          error: (error, stackTrace) => Text('$error'),
        );
      },
    );
  }
}

class PackageTagBadges extends StatelessWidget {
  const PackageTagBadges({super.key, required this.score});

  final PackageScore score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (score.sdks.isNotEmpty)
          TagBadge(
            name: 'SDK',
            values: score.sdks,
          ),
        if (score.platforms.isNotEmpty)
          TagBadge(
            name: 'PLATFORMS',
            values: score.platforms,
          ),
      ].separatedBy(const SizedBox(height: 4)),
    );
  }
}

class PackageMetadata extends StatefulWidget {
  const PackageMetadata({
    super.key,
    required this.package,
    required this.score,
  });

  final Package package;
  final PackageScore score;

  @override
  State<PackageMetadata> createState() => _PackageMetadataState();
}

class _PackageMetadataState extends State<PackageMetadata> {
  final formatDateWithTimeAgo = Signal(false);

  @override
  void dispose() {
    formatDateWithTimeAgo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Last published version
        RichText(
          text: TextSpan(
            style: context.textStyles.bodySmall,
            children: [
              const TextSpan(
                text: 'v ',
              ),
              TextSpan(
                text: widget.package.latest.pubspec.version,
                style: const TextStyle().copyWith(
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
        // Last published date
        SignalBuilder(
          signal: formatDateWithTimeAgo,
          builder: (context, useTimeAgo, child) {
            final date = widget.package.latest.published;
            final formattedDate = useTimeAgo
                ? timeago.format(date)
                : DateFormat.yMMMd().format(date);
            return InkWell(
              onTap: formatDateWithTimeAgo.toggle,
              child: Text(
                '($formattedDate)',
                style: context.textStyles.bodySmall.light
                    .copyWith(decoration: TextDecoration.underline),
              ),
            );
          },
        ),

        // License
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.balance,
              size: 10,
            ),
            const SizedBox(width: 4),
            Text(
              widget.score.license,
              style: context.textStyles.bodySmall,
            ),
          ],
        ),

        // Flutter favorite
        if (widget.score.isFlutterFavorite)
          BasicBadge(
            label: 'Flutter favorite',
            leading: Image.asset(
              Assets.flutterLogo,
              width: 10,
              height: 10,
            ),
          ),

        // Dart 3 compatible
        BasicBadge(
          label: widget.score.isDart3
              ? 'Dart 3 compatible'
              : 'Dart 3 incompatible',
          color: widget.score.isDart3
              ? context.colors.scheme.primary
              : context.colors.scheme.error,
        ),
        // Null safety
        BasicBadge(
          label: widget.score.isNullSafe ? 'Null safe' : 'Not null safe',
          color: widget.score.isNullSafe
              ? context.colors.scheme.primary
              : context.colors.scheme.error,
        ),
      ],
    );
  }
}

class PageSelector extends StatelessWidget {
  const PageSelector({
    super.key,
    required this.page,
    required this.hasNextPage,
  });

  final int page;
  final bool hasNextPage;

  void onPageTap(BuildContext context, int page) {
    context
        .get<PubSearchBloc>()
        .searchInput
        .updateValue((value) => value.copyWith(page: page));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // previous pages
            for (var i = 1; i < page; i++)
              IconButton(
                onPressed: () => onPageTap(context, i),
                icon: Text('$i'),
                splashRadius: 16,
              ),
            // current page
            IconButton.filled(
              onPressed: () {},
              icon: Text('$page'),
              splashRadius: 16,
            ),
            if (hasNextPage)
              IconButton(
                onPressed: () => onPageTap(context, page + 1),
                icon: Text((page + 1).toString()),
                splashRadius: 16,
              ),
          ].separatedBy(const SizedBox(width: 16)),
        ),
      ),
    );
  }
}
