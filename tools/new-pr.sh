#!/usr/bin/env bash
# usage: tools/new-pr.sh <me|bot> <name>     adds notes/<name>.md on a new branch and opens a PR
set -euo pipefail
R=Merge-queue-testing523/merge-queue-playground
who=$1; name=$2
[ "$who" = bot ] && user=StarmaniaBot || user=Starmania
export GH_TOKEN; GH_TOKEN=$(gh auth token --hostname github.com --user "$user")
sha=$(gh api repos/$R/git/ref/heads/main --jq .object.sha)
gh api -X POST repos/$R/git/refs -f ref="refs/heads/$name" -f sha="$sha" --silent
gh api -X PUT "repos/$R/contents/notes/$name.md" -f message="docs: add $name" -f content="$(printf '%s\n' "$name" | base64 -w0)" -f branch="$name" --silent
gh api repos/$R/pulls -f title="docs: add $name" -f head="$name" -f base=main --jq .html_url
