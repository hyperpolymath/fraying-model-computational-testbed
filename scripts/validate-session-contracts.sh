#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Validate the two session policies with their actual Nickel evaluator.
set -euo pipefail
command -v nickel >/dev/null || {
    echo "nickel is required to validate .k9.ncl session policies" >&2
    exit 2
}
if [[ "${1:-}" == --typecheck ]]; then
    shift
    [[ $# -gt 0 ]] || { echo 'Supply the instantiated Nickel or K9 files to typecheck' >&2; exit 2; }
    for file in "$@"; do
        IFS= read -r magic < "$file"
        if [[ "$magic" == 'K9!' ]]; then
            tail -n +2 "$file" | (cd -- "$(dirname -- "$file")" && nickel typecheck)
        else
            nickel typecheck "$file"
        fi
        echo "$file: Nickel typecheck passed (deployment not executed)"
    done
    exit 0
fi
[[ $# -eq 0 ]] || { echo 'Usage: validate-session-contracts.sh [--typecheck FILE...]' >&2; exit 2; }
for file in coordination.k9.ncl session/custom-checks.k9.ncl; do
    IFS= read -r magic < "$file"
    if [[ "$magic" != 'K9!' ]]; then
        echo "$file: missing K9! envelope" >&2
        exit 1
    fi
    # K9! is a transport envelope, not a Nickel expression. These standalone
    # records have no imports; evaluation also exercises their field contracts.
    tail -n +2 "$file" | nickel export --format json >/dev/null
    echo "$file: Nickel evaluation passed"
done
