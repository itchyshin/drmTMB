# After Task: q4 Intercept Hessian/Bootstrap Diagnostic

## 1. Goal

Record the provider-level blocker behind the q4 all-four intercept direct-SD
denominator precheck, without admitting coverage denominators or promoting
interval reliability, coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
HSquared AI-REML, broad bridge support, public support, or DRAC/Totoro
execution.

## 2. Implemented

- Added
  `tools/run-structured-re-q4-intercept-hessian-bootstrap-diagnostic.R`, which
  refits the deterministic q4 all-four intercept smoke fixture and writes a
  provider-level diagnostic sidecar.
- Generated
  `docs/dev-log/dashboard/structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv`
  and its matching artifact under
  `docs/dev-log/simulation-artifacts/2026-06-25-q4-intercept-hessian-bootstrap-diagnostic/`.
- Recorded phylo, fixed-covariance spatial, and K-matrix relmat as
  `pdhess_false;indefinite_cov_fixed`.
- Recorded A-matrix animal as `bootstrap_nonfinite_after_pdhess_true`.
- Wired the new sidecar into mission-control validation and the structured RE
  conversion-contract test.
- Advanced only the q-series support-cell `next_gate` fields from the
  denominator-precheck sidecar to the Hessian/bootstrap diagnostic sidecar.
- Updated the dashboard README and q-series completion map while keeping q4
  intercept interval and coverage statuses planned.

## 3a. Decisions and Rejected Alternatives

- I used a provider-level sidecar instead of another 16-row target-level
  ledger. The target-level denominator precheck already records the direct-SD
  target blockers; this slice answers the next provider-level question:
  `pdHess`/covariance geometry versus bootstrap behavior.
- I refit the deterministic smoke fixture rather than summarizing only the
  existing TSV. The refit lets the sidecar record `cov.fixed` status, selected
  optimizer, direct-SD profile-target counts, and raw Hessian availability.
- I did not promote the A-matrix animal finite Wald/profile rows. Bootstrap
  remains nonfinite for all four direct-SD targets, so denominator admission
  remains blocked.
- I did not route this through DRAC/Totoro. The current slice is a local
  diagnostic sidecar, not a coverage grid.

## 4. Files Touched

- `tools/run-structured-re-q4-intercept-hessian-bootstrap-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-q4-intercept-hessian-bootstrap-diagnostic/structured-re-q4-intercept-hessian-bootstrap-diagnostic-results.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-q4-intercept-hessian-bootstrap-diagnostic.md`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-intercept-interval-smoke.R`
  passed and restored the method-level smoke artifact with 48 rows plus the
  16-row interval status sidecar.
- `Rscript --vanilla tools/run-structured-re-q4-intercept-hessian-bootstrap-diagnostic.R`
  passed and wrote 4 provider-level diagnostic rows.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `air format tools/run-structured-re-q4-intercept-hessian-bootstrap-diagnostic.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,157 assertions, 0 failures, 0 warnings, and 0 skips.
- `python3 tools/validate-mission-control.py` passed and reported 4 structured
  RE q4 intercept Hessian/bootstrap diagnostic rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,873 assertions, 0 failures, 0 warnings, and 0 skips.
- `Rscript --vanilla -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-25-q4-intercept-hessian-bootstrap-diagnostic.md')"`
  passed.
- `git diff --check` passed.

## 6. Tests of the Tests

The new conversion-contract test cross-checks the diagnostic rows against the
denominator precheck and q-series support cells. It asserts the blocker split:
three providers must stay `pdHess = 0` with `finite_indefinite` fixed-effect
covariance, and A-matrix animal must stay `pdHess = 1` with nonfinite bootstrap
rows. The test would fail if the diagnostic accidentally promoted a denominator
or if the q-series next gate drifted away from the new sidecar.

## 7a. Issue Ledger

I searched open GitHub issues with:

- `gh issue list --repo itchyshin/drmTMB --state open --search "q4 intercept Hessian bootstrap" --limit 20`
- `gh issue list --repo itchyshin/drmTMB --state open --search "structured q4 interval denominator" --limit 20`

The first search found broad open issues #5 and #59; the second found #59. I
did not open or comment on a duplicate issue in this slice because the draft PR
will carry the reviewable diagnostic evidence.

## 8. Consistency Audit

I checked the q4 intercept neighbourhood:

- The generator links to both
  `structured-re-q4-intercept-interval-diagnostic-status.tsv` and
  `structured-re-q4-intercept-denominator-precheck.tsv`.
- The validator now requires four provider rows, exact source sidecars,
  provider-specific blocker classes, `coverage_status = not_evaluated`,
  `interval_claim_status = diagnostic_only`, and q-series
  `denominator_policy = fixture_not_coverage`.
- The conversion-contract test checks the same split from the R side.
- The q-series support-cell rows now point to
  `structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv` only as the
  next evidence gate; their interval and coverage statuses remain planned.
- The dashboard README and design map now describe the sidecar as diagnostic
  only.

I also used these stale-wording searches:

- `rg -n "structured-re-q4-intercept-(denominator-precheck|hessian-bootstrap-diagnostic)|q4 all-four intercept Hessian|bootstrap_nonfinite_after_pdhess_true" docs tests tools`
- `rg -n "q4.*intercept.*(coverage|supported|reliable|REML)|native-TMB q4 REML|q4 AI-REML|HSquared AI-REML|denominator admission" README.md ROADMAP.md NEWS.md docs vignettes R tests`

The broad search returned guardrail text and historical notes, but no new
public support, coverage, REML, or AI-REML claim from this slice.

## 9. What Did Not Go Smoothly

The first diagnostic run inherited `artifact_path` and `evidence_rel` from the
smoke helper script after loading helper definitions. That temporarily wrote
the provider rows into the smoke artifact path and pointed the diagnostic
`evidence_url` at the smoke after-task report. I fixed the runner to reset its
own paths after helper loading, reran the smoke script to restore the
method-level artifact, and reran the corrected diagnostic.

## 10. Known Residuals

- No q4 all-four intercept denominator is admitted.
- Phylo, fixed-covariance spatial, and K-matrix relmat still need Hessian
  geometry or stability variants before denominator accounting.
- A-matrix animal still needs bootstrap diagnosis under replicated fixtures
  before denominator accounting.
- Derived-correlation intervals remain blocked on reconstruction design.
- This slice did not run DRAC/Totoro jobs and does not make SR150
  coverage-ready.

## 11. Team Learning

When loading helper definitions from another runner, reset every path and
evidence variable that the helper script may have defined. The q-series
evidence ladder should also keep provider-level diagnostic rows separate from
target-level denominator rows; they answer different failure questions.
