#!/usr/bin/env bash

set -euo pipefail

usage() {
	echo "usage: $0 [TREE]"
	echo
	echo "Normalize TREE using the executable-file modes tracked by this repository."
	echo "TREE defaults to the repository root."
}

case "${1:-}" in
	-h|--help)
		usage
		exit 0
		;;
esac

repo_root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
tree=${1:-"$repo_root"}

if [[ ! -d "$tree" ]]; then
	echo "error: tree does not exist: $tree" >&2
	exit 1
fi

tree=$(cd "$tree" && pwd -P)

find "$tree" \
	-path "$tree/.git" -prune -o \
	-type d -exec chmod 0755 {} +

find "$tree" \
	-path "$tree/.git" -prune -o \
	-type f -exec chmod 0644 {} +

while IFS= read -r -d '' entry; do
	mode=${entry%% *}
	path=${entry#*$'\t'}

	if [[ "$mode" == 100755 && -f "$tree/$path" ]]; then
		chmod 0755 "$tree/$path"
	fi
done < <(git -C "$repo_root" ls-files --stage -z)

if [[ "$tree" == "$repo_root" ]]; then
	chmod 0755 "$repo_root/scripts/normalize_permissions.sh"
fi

echo "Normalized permissions under $tree"
