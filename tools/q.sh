#!/usr/bin/env bash
# usage: tools/q.sh <me|bot> <add|jump|remove> <pr>
set -euo pipefail
R=Merge-queue-testing523/merge-queue-playground
who=$1; action=$2; pr=$3
[ "$who" = bot ] && user=StarmaniaBot || user=Starmania
export GH_TOKEN; GH_TOKEN=$(gh auth token --hostname github.com --user "$user")
id=$(gh api "repos/$R/pulls/$pr" --jq .node_id)
case "$action" in
  add)    gh api graphql -f id="$id" -f query='mutation($id:ID!){enqueuePullRequest(input:{pullRequestId:$id}){mergeQueueEntry{position state}}}' ;;
  jump)   gh api graphql -f id="$id" -f query='mutation($id:ID!){enqueuePullRequest(input:{pullRequestId:$id,jump:true}){mergeQueueEntry{position state}}}' ;;
  remove) gh api graphql -f id="$id" -f query='mutation($id:ID!){dequeuePullRequest(input:{id:$id}){mergeQueueEntry{state}}}' ;;
  *) echo "unknown action: $action"; exit 2 ;;
esac
echo
