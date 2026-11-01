# Merge queue playground

Queue PRs, watch what happens, and make them fail. PRs #1 to #13 are ready to use, and CI takes about 90 seconds so you have time to click.

**For each mission, guess the outcome before opening its "What we saw" section.**

## Setup

```bash
gh repo clone Merge-queue-testing523/merge-queue-playground && cd merge-queue-playground
tools/watch.sh     # leave this running in a second terminal
```

- **Queue page:** https://github.com/Merge-queue-testing523/merge-queue-playground/queue/main
- **As yourself:** click **Merge when ready** on the PR, or run `tools/q.sh me add 1`.
- **As StarmaniaBot:** run `tools/q.sh bot add 2`. It has **write** access to start with.
- **Other actions:** `tools/q.sh <me|bot> jump <pr>`, `tools/q.sh <me|bot> remove <pr>`.
- **More PRs:** `tools/new-pr.sh <me|bot> <name>`.

The "What we saw" notes come from API runs with a 45-second CI on [merge-queue-lab](https://github.com/Merge-queue-testing523/merge-queue-lab), whose PR timelines are still there to read. The buttons weren't tested, so they may behave differently.

## Mission 1: a good run

Queue #1, then #2 within about a minute. Watch the temporary branches.

<details><summary>What we saw</summary>

Each PR gets a `gh-readonly-queue/main/pr-N-<sha>` branch and its own `merge_group` run. The branch for the second PR is built on top of the first. Both land as separate squash commits, roughly 15 to 30 seconds after their checks turn green. The temporary branches are then deleted. ([lab #1](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/1), [lab #2](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/2))
</details>

## Mission 2: a PR that is already broken

#3 fails its own check. Try to queue it, with the button and with `tools/q.sh me add 3`.

<details><summary>What we saw</summary>

The API refuses: `Pull request has failing required statuses`. It never enters the queue. The button is untested.
</details>

## Mission 3: a failure inside the queue

#4 passes on `pull_request` and fails only on `merge_group`, like a flaky test. Queue #4, then #5 behind it. Watch what happens to #5.

<details><summary>What we saw</summary>

#4's run fails and it's removed about 30 seconds later with reason `failed_checks`. #5's first run also fails because it included #4. #5 is then rebuilt without #4, passes and merges. A failure costs everyone behind it a rebuild. ([lab #4](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/4), [lab #5](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/5))
</details>

## Mission 4: PRs that only fail together

#6 and #7 each add two files, and the limit is three. Both are green. This is the problem a merge queue exists to solve. Queue #6, then #7. Afterwards, look at #7's checks and try queueing it again.

<details><summary>What we saw</summary>

#6 merges and #7 is removed with `failed_checks`. #7 **still shows a green check**, because its PR check ran against the old `main`, and GitHub accepts it back into the queue. Without the queue, it would have broken `main`. ([lab #7](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/7))
</details>

## Mission 5: a real merge conflict

#8 and #9 create the same file with different content. Both show as mergeable. Queue #8, then #9.

<details><summary>What we saw</summary>

#9 goes to state `UNMERGEABLE` straight away, gets no temporary branch and no CI run, and is removed with `merge_conflict` once #8 merges. ([lab #17](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/17))
</details>

## Mission 6: jumping the queue

Queue #10 and #11. Wait until their runs are in progress, then run `tools/q.sh bot jump 12`. Count the runs afterwards in `tools/watch.sh`.

<details><summary>What we saw</summary>

#12 moves to position 1, and #10 and #11 are rebuilt, so each runs CI twice. **The bot could do this with write access alone**, so anyone who can queue can make everyone else rebuild. If you jump before any build has started, nothing gets rebuilt. ([lab #11](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/11), [lab #13](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/13))
</details>

## Mission 7: interfering with a queued PR

Queue #13 as yourself. While it's queued, remove it as the bot with `tools/q.sh bot remove 13`. Queue it again and try pushing a commit to its branch.

<details><summary>What we saw</summary>

The bot can remove a PR it didn't queue, and the reason is recorded as `manual`. The push is refused with HTTP 409: `Branches that are queued for merging cannot be updated`. ([lab #14](https://github.com/Merge-queue-testing523/merge-queue-lab/pull/14))
</details>

## Mission 8: the low-privilege view

Change the bot's role, then repeat what it did above. Compare what the page shows if you sign in as the bot.

```bash
gh api -X PUT repos/Merge-queue-testing523/merge-queue-playground/collaborators/StarmaniaBot -f permission=pull    # or triage, push
```

<details><summary>What we saw</summary>

| Action | read | triage | write | admin |
|---|---|---|---|---|
| Open a PR | from a fork | not tested | yes | yes |
| Create a branch on the repo | no | not tested | yes | yes |
| Add a label | no | yes | not tested | not tested |
| Add a PR to the queue | no | no | **yes** | yes |
| Jump, or remove someone else's PR | not tested | not tested | **yes** | yes (add and remove) |
| Merge outside the queue with the REST API | not tested | no | no | no |
| Commit directly to `main` | not tested | not tested | no | not tested |
| Disable the ruleset | not tested | not tested | no | yes |

Admin is refused the REST merge too, because the ruleset has no bypass actors. The admin can still edit that.
</details>

## Open questions: nobody has tested these yet

1. **Merge when ready while CI is still running.** The docs say this enables auto-merge even if the repo disallows it. The API refused both enqueueing and auto-merge here, so does the button differ? Use a new PR from `tools/new-pr.sh` and click right away.
2. **Only merge non-failing pull requests off** (`HEADGREEN`). Repeat mission 3. Does #4 get merged because the group passed?
3. **Build concurrency 1.** Queue three PRs. Do the builds run one at a time, and how much slower is it?
4. **Minimum 3 PRs to merge, with a 5-minute wait.** Queue two and watch them wait for a third.
5. **Merge method.** Switch from squash to merge or rebase and compare the history on `main`.

Change these in **Settings → Rules → Rulesets → main merge queue**.

## Current settings

Pull request and `check` required, no bypass actors. Queue: squash, up to 5 PRs building and up to 5 merging at once, minimum 1 with a 1-minute wait, 10-minute CI timeout, and only non-failing PRs merge (`ALLGREEN`).
