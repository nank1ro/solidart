#!/usr/bin/env bash
#
# Orchestrates pub.dev publishing for the solidart monorepo.
#
# For every publishable package, in dependency order, this script:
#   1. reads the `version:` from its pubspec.yaml,
#   2. skips it if that version is already on pub.dev (no-op for unchanged packages),
#   3. otherwise creates a GitHub Release + tag (`<name>-v<version>`), which triggers
#      the package's existing `publish_<name>.yaml` workflow,
#   4. waits until pub.dev actually serves the new version before moving on to the
#      packages that depend on it.
#
# It does NOT publish directly and it does NOT bump versions — version bumps and
# CHANGELOG edits stay manual. The pubspec `version:` is the source of truth.
#
# Requires: gh, curl, jq, git (all preinstalled on ubuntu-latest).
# Environment:
#   GH_TOKEN   a non-GITHUB_TOKEN identity (PAT / App token) so the tag push it
#              creates triggers the downstream publish_*.yaml workflows.
#   GITHUB_SHA the commit to tag (auto-set by GitHub Actions).
#   DRY_RUN    "true" to log the plan without creating any tags/releases.
#
set -euo pipefail

# Publishable packages in topological order. A package is only released after
# every in-repo dependency it has is already live on pub.dev.
#   solidart            -> (no in-repo deps)
#   flutter_solidart    -> solidart
#   solidart_hooks      -> flutter_solidart
#   solidart_lint       -> solidart, flutter_solidart (dev_dependencies)
PACKAGES=(
  "solidart:packages/solidart"
  "flutter_solidart:packages/flutter_solidart"
  "solidart_hooks:packages/solidart_hooks"
  "solidart_lint:packages/solidart_lint"
)

DRY_RUN="${DRY_RUN:-false}"
PUB_API="https://pub.dev/api/packages"
POLL_ATTEMPTS=60   # 60 * 30s = up to 30 min, to absorb pub.dev propagation lag
POLL_INTERVAL=30

# Read the package version from its pubspec (first `version:` line, value only).
read_version() {
  awk '/^version:/{print $2; exit}' "$1/pubspec.yaml"
}

# True when <version> ($2) is already published for package <name> ($1).
# A cache-busting query + no-cache header avoid a stale CDN response masking a
# just-published version. Network/HTTP errors are treated as "not published".
is_published() {
  local body
  body="$(curl -fsS -H 'Cache-Control: no-cache' "${PUB_API}/$1?_=${RANDOM}" 2>/dev/null || true)"
  [ -n "$body" ] || return 1
  printf '%s' "$body" | jq -e --arg v "$2" '.versions[]?.version | select(. == $v)' >/dev/null 2>&1
}

# True when the tag <tag> ($1) already exists on the remote.
tag_exists() {
  [ -n "$(git ls-remote --tags origin "refs/tags/$1")" ]
}

# Print the CHANGELOG section for <version> ($2) from <dir>/CHANGELOG.md ($1):
# everything between the `## <version>` heading and the next `## ` heading.
# Uses a literal heading compare to avoid regex-escaping the version string.
changelog_notes() {
  local file="$1/CHANGELOG.md"
  [ -f "$file" ] || return 0
  awk -v h="## $2" '
    { line = $0; sub(/[[:space:]]+$/, "", line) }
    line == h { f = 1; next }
    /^## / { if (f) exit }
    f { print }
  ' "$file"
}

# Block until <version> ($2) of <name> ($1) is live on pub.dev, or fail.
wait_for_publish() {
  local name="$1" version="$2" i
  for ((i = 1; i <= POLL_ATTEMPTS; i++)); do
    if is_published "$name" "$version"; then
      return 0
    fi
    echo "    …not on pub.dev yet (attempt ${i}/${POLL_ATTEMPTS}); sleeping ${POLL_INTERVAL}s"
    sleep "$POLL_INTERVAL"
  done
  echo "  ✗ timed out after $((POLL_ATTEMPTS * POLL_INTERVAL / 60)) min waiting for ${name} ${version} on pub.dev" >&2
  return 1
}

[ "$DRY_RUN" = "true" ] && echo "DRY RUN — no tags or releases will be created."

for entry in "${PACKAGES[@]}"; do
  name="${entry%%:*}"
  dir="${entry#*:}"
  version="$(read_version "$dir")"

  if [ -z "$version" ]; then
    echo "✗ could not read version from ${dir}/pubspec.yaml" >&2
    exit 1
  fi

  tag="${name}-v${version}"
  echo "── ${name} ${version}  (tag ${tag})"

  if is_published "$name" "$version"; then
    echo "  ✓ already on pub.dev — skipping"
    continue
  fi

  if tag_exists "$tag"; then
    echo "  ✗ tag ${tag} exists but ${version} is not on pub.dev — a previous publish likely failed."
    echo "    Re-run the failed '${name}' publish workflow, or delete the tag and re-run this workflow."
    if [ "$DRY_RUN" = "true" ]; then
      echo "    [dry-run] continuing"
      continue
    fi
    exit 1
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "  [dry-run] would create release + tag ${tag}, then wait for pub.dev"
    continue
  fi

  notes="$(changelog_notes "$dir" "$version")"

  echo "  → creating GitHub release + tag ${tag}"
  release_args=("$tag" --title "$tag" --notes "${notes:-Release $tag}" --target "${GITHUB_SHA}")
  case "$version" in
    *-*) release_args+=(--prerelease) ;; # e.g. 3.0.0-dev.1
  esac
  gh release create "${release_args[@]}"

  echo "  → waiting for ${name} ${version} to appear on pub.dev"
  wait_for_publish "$name" "$version"
  echo "  ✓ ${name} ${version} is live on pub.dev"
done

echo "Done."
