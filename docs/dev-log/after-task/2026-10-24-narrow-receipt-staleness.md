# Narrow the receipt-staleness guard to the runner's call path

## Goal

Stop `tools/ci-receipt-staleness.sh` going red on every `R/` change. Before this
change it failed on any `R/*.R` file whose SHA-256 differed from
`docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json`, even a
roxygen wording edit in a file the receipt's runner never reaches. Owner decision,
24 Oct 2026.

## Implemented

The guard now fails on a differing, or newly added and unrecorded, `R/` file only
when the file is on the runner's call path. A differing `R/` file off that path is
printed as a `NOTE` and does not fail. The call path comes from
`tools/receipt-exercised-files.R`, a base-R static call graph over `R/*.R` rooted
at `tools/run-julia-phylo-labels-public.R` and at load-time code (rule, over-
approximation direction and one blind spot are written in the file header).
Unchanged on purpose: the receipt JSON, every numeric tolerance, the runner-hash
check, the checker's structural validation, the C17 check, and the rule that a
recorded `R/` file that is now absent fails. If the path tool fails or its list
lacks `R/drmTMB.R`, the guard exits 2 (it never passes silently).

## Files Changed

`tools/ci-receipt-staleness.sh`, `tools/receipt-exercised-files.R` (new),
`tools/tests/test_receipt_staleness_narrowing.py` (new),
`.github/workflows/R-CMD-check.yaml` (one line wiring the new test into the ledger
step), this report, and its `docs/dev-log/check-log.d/` row.

## Checks Run

On origin/main `5d996e531`, before: 13 recorded `R/` files differ and `R/utils.R`
is unrecorded, so the guard prints 13 STALE lines plus one for `R/utils.R` and
exits 1. After: it prints 10 STALE lines (on the call path) plus `R/utils.R`
(on the call path), 3 NOTE lines (`R/heritability.R`, `R/meta-vcov.R`,
`R/parallel-docs.R`), and still exits 1. The path tool puts 35 of 58 `R/` files
on the call path. `python3 -m unittest tools/tests/test_receipt_staleness_narrowing.py`
passed 11 of 11 on the Mac and on Totoro (2 threads).

## Tests Of The Tests

The same 11 tests run against the previous guard script: 6 fail (note-not-failure,
entry change, change two calls deep, unrecorded off path, unrecorded on path, and
the fail-closed exit 2). The remaining 5 assert behaviour both versions share
(fresh tree, runner change, deleted file, comment-only edit on path, S3 method).

## Consistency Audit

The 10 on-path changed files include several that the Gaussian run almost
certainly executes (`R/drmTMB.R`, `R/julia-bridge.R`, `R/parse-formula.R`,
`R/formula-markers.R`, `R/methods.R`, `R/mspl-estimator.R`, `R/family.R`) and three
that the static rule cannot clear although the run probably does not execute them
(`R/family-dpq.R`, `R/julia-family-cumulative_logit.R`, `R/profile.R`). They stay
on the path because the rule is deliberately an over-approximation.

## What Did Not Go Smoothly

The task text expected 8 changed `R/` files; the checkout has 13 differing plus
one unrecorded. The mismatch is recorded here and in the PR body. The disk was
nearly full during the work; no user files were deleted.

## Team Learning

A whole-file hash guard is only as narrow as the question "which files does the
run read". Deriving that from the code is cheap, but a static rule can only
over-approximate. An exact rule needs the runner to record the files it actually
executed.

## Design-document Updates

None: guard maintenance only.

## pkgdown/documentation Updates

None.

## GitHub Issue Maintenance

None inspected or edited. Relates to the receipt-drift family around #1150.

## Known Limitations and Next Actions

The receipt on main is still stale on the exercised path, so main stays red until
a live regeneration (Julia plus the pinned DRM.jl clone, then the C17 receipt on
the Mac at exact tolerance). This change does not do that and does not edit the
receipt. A file that is on the path and only had a comment edit still fails,
because the receipt holds whole-file hashes. Follow-up for the next regeneration:
have the runner record the executed `R/` files so the rule can be exact.
