# After Task: Codex Recovery Checkpoint Tool

## Goal

Reduce damage from Codex compaction or stream failures by adding a durable,
repo-local checkpoint command that captures the current working-tree state and
recent validation evidence in one compact Markdown file.

## Implemented

Added `tools/codex-checkpoint.R`, a base-R script that records:

- current branch and short status;
- changed tracked files and untracked files;
- `git diff --stat`;
- current `HEAD`;
- newest `docs/dev-log/check-log.md` sections;
- newest after-task reports;
- exact recovery commands for the next Codex or human run.

Also added a short `AGENTS.md` recovery-checkpoint section so future agents use
the script before long handoffs or after stream failures.

## Files Changed

- `tools/codex-checkpoint.R`
- `AGENTS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-codex-recovery-checkpoint-tool.md`
- `docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md`

## Checks Run

- First smoke run of `Rscript tools/codex-checkpoint.R --stdout --goal "Smoke test recovery checkpoint" --next "Inspect git status" --sections 2`:
  failed with an invalid regular expression in the path-shortening helper.
  Replaced the regex trim with a simpler `startsWith()`-based path trim.
- `Rscript tools/codex-checkpoint.R --stdout --goal "Smoke test recovery checkpoint" --next "Inspect git status" --sections 2`:
  passed and printed the expected branch/status, changed files, diff stat,
  newest check-log entries, newest after-task reports, and recovery commands.
- `Rscript tools/codex-checkpoint.R --output docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md --goal "Recover from repeated Codex compaction or stream failures during the current covariance-profile branch" --next "Review this checkpoint, rerun git status and git diff, then preserve a commit boundary or run focused validation" --sections 4`:
  passed and wrote the checkpoint file.
- `air format tools/codex-checkpoint.R`: passed.
- `Rscript -e "invisible(parse(file = 'tools/codex-checkpoint.R')); cat('parse ok\\n')"`:
  passed.
- `git diff --check`: passed.

## Consistency Audit

This is a workflow tool only. It does not change package code, formula grammar,
likelihood parameterization, roxygen topics, pkgdown navigation, or user-facing
model documentation.

## Tests Of The Tests

The validation checked both `--stdout` mode and file-writing mode so the script
can be used either for quick inspection or for durable handoff files.

## What Did Not Go Smoothly

The first smoke test exposed a real bug: the initial relative-path helper tried
to escape the repository path with a regular expression that R's default regex
engine rejected. The fix avoids regex escaping entirely and uses
`startsWith()` plus `substring()` for repo-relative paths.

The existing working tree is already large, so this tool was added as a narrow
process slice without modifying the current `mu`/`sigma` covariance
implementation.

## Team Learning

- Ada made the recovery protocol concrete instead of leaving it as chat advice.
- Grace kept the tool dependency-light so it can run before the package is
  loaded or recompiled.
- Rose kept the checkpoint subordinate to the actual repository state.

## Known Limitations

- The checkpoint records compact git evidence and recent project logs, not a
  full diff copy.
- It does not replace a commit, patch file, or full validation run.
- It cannot prevent Codex platform stream failures; it only makes recovery less
  lossy.

## Next Actions

1. Use the tool before the next broad validation or commit boundary.
2. If the current branch is preserved as a PR, mention the checkpoint tool in
   the PR notes as a recovery aid rather than a modelling feature.
