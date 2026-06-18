# After Task: Phase 1 Rose Signoff

## Goal

Close the Phase 1 Rose audit after the public-claim lint landed, so the fitted,
planned, missing, and unsupported rows in the current public status surfaces are
consistent with the finish capability matrix.

## Implemented

`docs/dev-log/known-limitations.md` now links to
`docs/design/168-r-julia-finish-capability-matrix.md` and describes missing-data
support as a bounded current-preview surface rather than a release-ready
surface. `tools/validate-mission-control.py` now includes the known-limitations
ledger in the public claim reference and scan set, so future release-promotion
or reserved Julia-control wording there fails the mission-control validator.

The dashboard also no longer carries stale active-work text from the earlier
takeover queue slice. Phase 1 now records Rose signoff as verified, with
mission-control metrics at 25/68 verified, 1 active, 0 blocked, and 1 deferred.

## Mathematical Contract

No likelihood, formula grammar, parameterization, estimator, interval method, or
simulation contract changed. This task only changes public-status wording,
dashboard state, and the validator code path that prevents claim drift.

## Files Changed

- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-17-phase1-rose-signoff.md`
- `tools/validate-mission-control.py`

## Checks Run

- `/opt/homebrew/bin/gh run watch 27727624030 --repo itchyshin/drmTMB --interval 60 --exit-status`
- `/opt/homebrew/bin/gh run watch 27728675894 --repo itchyshin/drmTMB --interval 30 --exit-status`
- `python3 -m py_compile tools/validate-mission-control.py`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n 'AI-REML|10k|10,000|GPU|speedup|faster|release-ready|release ready|ready for release|ready to release|CRAN-ready|CRAN ready|engine_control|scale-side phylo|scale-side phylogenetic' README.md ROADMAP.md NEWS.md _pkgdown.yml docs/dev-log/known-limitations.md docs/dev-log/dashboard/README.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/168-r-julia-finish-capability-matrix.md vignettes/model-map.Rmd vignettes/implementation-map.Rmd`
- `rg -n 'Missing data|missing data|missing-data|miss_control|mi\(|impute_model|complete-case|general missing|REML for explicit missing' README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/168-r-julia-finish-capability-matrix.md vignettes/model-map.Rmd vignettes/implementation-map.Rmd`

The validator reported:

```text
mission_control_ok: 25/68 banked_or_verified, 1 active, 17 matrix rows, 11 finish rows, 15 Julia gate rows, 9 Julia capability rows
```

## Tests Of The Tests

The audit found a stale phrase that the previous validator did not protect:
`docs/dev-log/known-limitations.md` still described missing-data support as
release-ready. Adding that file to `PUBLIC_CLAIM_REFERENCE_FILES` makes the same
phrase fail `tools/validate-mission-control.py` in the future, while the matrix
itself remains the allowed place to define the release gate.

## Consistency Audit

The current README, ROADMAP, NEWS, pkgdown navigation, model-map article,
implementation-map article, dashboard matrix, validation-debt register,
pre-simulation readiness matrix, capability-completion worklist, and finish
capability matrix keep fitted, first-slice, planned, unsupported, partial, and
experimental statuses separate. The audit found two stale current-state leaks:
the known-limitations missing-data release wording and the dashboard active-work
metric text. Both are corrected in this slice.

The remaining high-risk terms are still present only where they are being
bounded or recorded as evidence: AI-REML is restricted to exact Gaussian
REML/MME derivation analogues, speed wording is tied to evidence gates, q8 is
diagnostic-only until recovery/coverage/power evidence exists, and
`engine_control` remains a reserved unsupported public surface.

## GitHub Issue Maintenance

No issue was opened or closed. This slice is intended to land through a focused
PR after fresh current-main R-CMD-check on macOS, Ubuntu, and Windows. The
post-#611 main checks and pkgdown deploy were already green before this branch
started. Open-issue searches for `mission-control known-limitations Rose signoff`
and `phase 1 public claim lint` returned no overlapping open issue to update.

## What Did Not Go Smoothly

The previous public-claim lint did not scan `docs/dev-log/known-limitations.md`.
That file is not the first page a user reads, but it is a current status ledger
and can leak stale release language into future docs. Adding it to the validator
turns the Rose finding into a repeatable guard.

## Team Learning

Rose should audit status ledgers as public-facing when they summarize current
support, even if they live under `docs/dev-log/`. Grace gets a stricter
standard-library validator. Ada gets a closed Phase 1 dashboard row with the
next active work reduced to the remaining cross-team visit lane.

## Known Limitations

This signoff is a current-repository audit, not a proof of every historical
after-task note. Historical reports may still quote older metrics or older
status terms as evidence from their own time. The validator now protects the
current public and status-ledger surfaces named in this task.

## Next Actions

Open a PR, run fresh current-main Ubuntu, macOS, and Windows R-CMD-check, merge
only if CI passes, then verify post-merge main R-CMD-check and pkgdown before
starting the next mission-control slice.
