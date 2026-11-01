#!/usr/bin/env bash
# Prints the queue, its temporary branches and recent merge_group runs whenever they change. Ctrl-C to stop.
R=Merge-queue-testing523/merge-queue-playground
last=""
while :; do
  q=$(gh api graphql -f query='query{repository(owner:"Merge-queue-testing523",name:"merge-queue-playground"){mergeQueue(branch:"main"){entries(first:20){nodes{position state pullRequest{number}}}}}}' --jq '[.data.repository.mergeQueue.entries.nodes[]|"#\(.pullRequest.number)@\(.position):\(.state)"]|join("  ")')
  t=$(gh api repos/$R/git/matching-refs/heads/gh-readonly-queue --jq '[.[].ref|sub("refs/heads/gh-readonly-queue/main/";"")|sub("-[0-9a-f]{40}$";"")]|join(" ")')
  r=$(gh run list -R $R --event merge_group --limit 6 --json status,conclusion,headBranch --jq '[.[]|(.headBranch|sub("gh-readonly-queue/main/";"")|sub("-[0-9a-f]{40}$";""))+"="+(if .status=="completed" then .conclusion else .status end)]|join(" ")')
  s="queue: ${q:-empty}"$'\n'"  temp branches: ${t:-none}"$'\n'"  latest runs:   ${r:-none}"
  [ "$s" != "$last" ] && { echo "[$(date +%T)] $s"; last=$s; }
  sleep 5
done
