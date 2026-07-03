# After Task: Q-Series Tranche 125 q1 mu one-slope spatial DRAC dependency-route review

## 1. Goal

Convert the Tranche 124 `devtools_available = FALSE` terminal blocker into a
reviewed no-compute dependency route, then stop before any repeat host-separated
Rorqual execution.

## 2. Implemented

Added the T125 Mission Control sidecar, local dry-run/review artifacts, member
discussion rows, validator guards, focused conversion-contract tests, dashboard
README wording, completion-map wording, and q1 `mu` one-slope queue update. The
DRAC runner and wrapper now expose `--load-source=true|false`, with the default
kept at `true` for old behavior and `--load-source=false` available for the next
installed-package packet.

## 3a. Decisions and Rejected Alternatives

Decision: use the installed-package route as the next candidate path. The
patched runner and wrapper expose `--load-source=false` /
`DRMTMB_Q1MU_SLOPE_T85_LOAD_SOURCE=false`, which should avoid the Tranche 124
`devtools_available = FALSE` pre-runner stop.

Rejected alternatives: do not broaden into a full devtools prestage/install
tranche, do not rerun immediately, do not count any T125 artifact as a retained
denominator, do not authorize coverage, do not move the support cell, and do not
pool this route review with any local, Totoro, DRAC, Nibi, Rorqual, Trillium,
Fir, or other-host denominator.

No statistical model was evaluated in T125. The only target identity preserved
for the future packet is the q1 `mu` one-slope spatial direct-SD target pair
`sd_mu_intercept;sd_mu_x`. T125 records no `profile_targets()` output, Hessian,
`pdHess`, Wald interval, profile interval, retained denominator, admission pass,
coverage rule, derived-correlation target, REML, or AI-REML evidence.

## 4. Files Touched

- `tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.R`
- `tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.sh`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche125-spatial-drac-dependency-route-review.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche125-spatial-drac-dependency-route-review/`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JavaScript extraction plus `/Users/z3437171/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node --check`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Structured support-cell invariant scan: 104 Q-Series cells, 8
  interval-and-coverage `inference_ready` rows, 0 structured `supported` rows,
  and 0 q4 coverage-authorized rows.
- `git diff --check`

## 6. Tests of the Tests

The focused conversion-contract test now reads the T125 sidecar, checks the
installed-package route selection, verifies the runner and wrapper dry-run
artifacts, confirms the q1 `mu` one-slope spatial support cell remains
`point_fit/planned/planned`, and checks the queue points to Tranche 126 before
any repeat model-smoke execution. The validator also checks that the blocking
member rows keep the no-compute next gate.

## 7a. Issue Ledger

No GitHub issue was opened or updated. T125 changes internal Q-Series evidence
plumbing and a tranche runner option; it does not change public API, formula
grammar, package behavior, support status, or user-facing documentation outside
Mission Control and the completion ledger.

## 8. Consistency Audit

Mission Control, the validator, focused tests, dashboard README, completion map,
next-campaign queue, check log, and member-board rows now agree that T125 is a
no-compute dependency-route review. The reviewed route is
`--load-source=false` / `DRMTMB_Q1MU_SLOPE_T85_LOAD_SOURCE=false`, and the next
gate is a T126 no-compute patched-runner packet checkpoint.

## 9. What Did Not Go Smoothly

`Rscript` was not on the non-interactive shell `PATH`, so the local dry-run
artifacts and focused R test used `/usr/local/bin/Rscript --no-init-file`.
During validator tightening, historical Tranche 90-92 helper hashes also needed
to stay frozen so T125 runner/wrapper edits did not rewrite old evidence.

## 10. Known Residuals

T125 proves only that the next packet has an reviewed installed-package route.
It does not prove that Rorqual can load the installed package under allocation,
does not run a model, and provides no `pdHess`, Wald/profile interval,
admission, coverage, or support evidence.

## 11. Team Learning

Grace's provenance rule caught the clean route distinction: a future execution
packet should prove whether it used installed-package loading rather than
silently falling back to source loading. Rose and Fisher's boundary remains the
main guard: a dependency-route review creates no denominator and cannot move a
support-cell status.

## Next Actions

Open Tranche 126 as a no-compute patched-runner packet checkpoint. The packet
should use the installed-package route, keep host/source/output provenance
separate, and stop for Rose/Fisher/Gauss/Noether/Grace review before any repeat
host-separated Rorqual model-smoke execution.
