# After Task: Q-Series Tranche 5 Q4 Location Admission Decision Gate

## 1. Goal

Bank Tranche 5 as a q4 location admission-review tranche, not a coverage
tranche, while preserving zero q4 promotions and zero q4 coverage
authorization.

## 2. Implemented

Added a 21-row Tranche 5 review sidecar that turns the Tranche 4 local `n = 5`
retained-denominator q4 location smoke into a decision ledger. The sidecar
keeps all target, provider, and tranche rows at `coverage_not_authorized` and
`do_not_promote`.

Phylo and spatial remain diagnostic holds. Animal requires cheap failure
taxonomy before any top-up. Relmat is only a host-separated repeat candidate
after Rose/Fisher/Gauss/Noether/Grace review. Kim's rule is recorded as least
compute needed for an honest next decision.

After the blocking reviewers accepted the narrow compute gate, one
host-separated Totoro relmat repeat was run and banked as
`structured-re-q4-location-admission-tranche5-relmat-repeat.tsv`. The repeat is
only post-run review evidence: all four relmat direct-SD targets have 5/5
retained `pdHess`, Wald-finite, and profile-finite rows, but q4 remains
unadmitted and q4 coverage remains unauthorized.

## 3a. Decisions and Rejected Alternatives

The tranche covers only the 16 q4 location direct-SD targets already named by
the Tranche 4 `profile_targets()` map. It does not reconstruct or evaluate
derived q4 correlations and does not widen to q8.

The admission gate remains retained-denominator `pdHess`, Wald-finite, and
profile-finite direct-SD rates of at least 0.95. The local `n = 5` smoke is
review input only; it is not a coverage grid and has no MCSE-controlled
coverage claim.

Rejected alternatives: Tranche 5 does not launch q4 coverage, does not run an
all-provider repeat, does not pool local and host denominators, and does not
promote relmat from a tiny local smoke into q4 admission.

The accepted follow-up was exactly one relmat-only Totoro repeat with source
SHA, dirty flag, host label, remote output path, raw artifact, and run-log
provenance recorded. The repeat denominator is separate from the local smoke
denominator.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-admission-tranche5-review.tsv`
- `docs/dev-log/dashboard/structured-re-q4-location-admission-tranche5-relmat-repeat.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche5-relmat-repeat-totoro/structured-re-q4-location-admission-smoke-results.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche5-relmat-repeat-totoro/structured-re-q4-location-admission-smoke-run-log.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/run-structured-re-q4-location-admission-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tools/run-structured-re-q4-location-admission-smoke.R'));
  invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- TSV width check for
  `structured-re-q4-location-admission-tranche5-review.tsv` and
  `member-discussions.tsv`: passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}'
  docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js &&
  node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 21 q4 location Tranche 5 review rows,
  6 q4 location Tranche 5 relmat-repeat rows, and 42 member discussion rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche5-q4-location-admission-decision-gate.md')"`:
  passed.
- `rg -n "q4 location passed smoke|Tranche 4 completed q4 admission|coverage next|relmat admitted"
  ... || true`: no Tranche 5 stale-claim hit; the only match was a historical
  `no-DRAC-coverage next action` phrase in the older check-log.
- `git diff --check`: passed.

## 6. Tests of the Tests

The new focused test links every Tranche 5 target row back to the Tranche 4
smoke row, verifies provider summary minima, verifies the overall
zero-admission decision, and checks that the Tranche 5 member-board meeting
contains every standing reviewer with the five blocking reviewers marked
`block_until_done`.

The repeat test reads the copied Totoro raw result and run-log artifacts, checks
that host/source/output provenance stays separate from the local smoke, verifies
the 5/5 retained-denominator rates, and asserts the same no-admission,
no-coverage, no-promotion boundary on every repeat row.

## 7a. Issue Ledger

No GitHub issue action was taken. This tranche is a local Mission Control and
decision-ledger update, not a user-facing feature or public-support change.

## 8. Consistency Audit

Rose: every Tranche 5 row says review-only, no coverage, and no promotion.

Fisher: admission remains a retained-denominator precondition; no MCSE or
coverage language moved.

Gauss: failed phylo/spatial/animal rows remain diagnostic; relmat is repeat
candidate only.

Noether: exact direct-SD `profile_targets()` strings remain the target class;
derived correlations and q8 remain out of scope.

Grace: local evidence, optional Totoro/FIIA or DRAC repeat evidence, and any
future host denominator must remain separated.

Post-repeat Grace/Rose/Fisher boundary: the Totoro evidence is banked, not
pooled with local evidence, and not promoted into q4 coverage or support-cell
movement.

## 9. What Did Not Go Smoothly

The first JavaScript extraction check used over-escaped awk syntax and failed
before running `node --check`. Rerunning with the literal `/<\\/script>/`
pattern passed.

The first repeat-contract test patch also preserved literal `NA` too broadly in
older artifact comparisons. Narrowing the `na.strings = character()` override
to only the new Totoro repeat raw/run-log reads restored the existing tests.

## 10. Known Residuals

- The Totoro repeat is only `n = 5` admission-repeat evidence; it has not had a
  post-run admission-review tranche.
- No q4 coverage grid was authorized.
- No support-cell status changed.
- No q4, q8, REML, AI-REML, derived-correlation, bridge, or public-support
  claim moved.

## 11. Team Learning

For high-q admission work, a review sidecar should be banked before spending
cluster time. It lets Rose and Fisher reject claim drift and lets Gauss decide
whether failures need taxonomy or compute.

## Next Actions

Run the post-repeat Rose/Fisher/Grace admission review before any q4 admission
discussion. If that review admits relmat as a q4 location candidate, design the
smallest possible coverage pregrid next; keep local, Totoro/FIIA, DRAC, Nibi,
Rorqual, and Fir denominators separate unless a later reviewed design explicitly
allows otherwise.
