# After Task: Ayumi q4 Bootstrap Harness

## Goal

Extend the Ayumi q4 status harness so the next benchmark pass can test whether
the Julia bootstrap route is alive, separately from native TMB point fits,
native profile attempts, and the full 10,440-tip wall-time blocker.

## Implemented

- Added `DRMTMB_AYUMI_Q4_BOOTSTRAP`, `DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS`, and
  `DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED` controls to
  `tools/ayumi-q4-status-harness.R`.
- Added a `bootstrap` interval phase that calls
  `confint(..., method = "bootstrap")`, captures warnings/messages/errors, and
  appends row-level interval evidence to `intervals.csv`.
- Let the harness choose `none`, `first_sigma`, `all_sigma`, or `all_q4`
  bootstrap targets. When bootstrap replicates are requested and no explicit
  target mode is supplied, the harness now defaults to `all_q4`, because the
  Julia q4 bootstrap naturally returns the four phylogenetic SD axes.
- Recorded bootstrap controls in `metadata.md`.
- Added a negative-value guard for `DRMTMB_AYUMI_Q4_BOOTSTRAP`.

## Mathematical Contract

This slice does not change the likelihood, formula grammar, REML gate, or
interval algorithm. It only exposes a harness phase for the existing q4 Julia
bootstrap interface. A bootstrap smoke with `R = 2` checks plumbing and
row-shape only; it is not a calibrated confidence-interval or coverage result.

## Files Changed

- `tools/ayumi-q4-status-harness.R`
- `docs/dev-log/after-task/2026-06-15-ayumi-q4-bootstrap-harness.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tools/ayumi-q4-status-harness.R
Rscript --vanilla -e 'invisible(parse("tools/ayumi-q4-status-harness.R")); cat("parse ok\n")'
git diff --check
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-biv-confint.R")'
```

The targeted Julia bivariate `confint()` test file passed with 31 expectations.

The Ayumi-bundle bootstrap smoke used the real `for_test/` RDS at 30 tips:

```sh
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/DRM.jl" \
JULIA_HOME="/Users/z3437171/.juliaup/bin" \
JULIA_NUM_THREADS=4 \
OPENBLAS_NUM_THREADS=1 \
OMP_NUM_THREADS=1 \
DRMTMB_AYUMI_Q4_RDS=/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_SIZES=30 \
DRMTMB_AYUMI_Q4_ENGINES=julia \
DRMTMB_AYUMI_Q4_REML=false \
DRMTMB_AYUMI_Q4_PROFILE=none \
DRMTMB_AYUMI_Q4_BOOTSTRAP=2 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=all_q4 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED=20260615 \
DRMTMB_AYUMI_Q4_TIME_LIMIT=300 \
DRMTMB_AYUMI_Q4_OUT=/tmp/drmtmb-ayumi-q4-status/harness-bootstrap-30 \
Rscript --vanilla tools/ayumi-q4-status-harness.R
```

The fit row was `status = "ok"`, `convergence = 0`, and
`fit_diagnostic_status = "fit_returned_converged_pdhess_false"` with fit
elapsed time 36.19 s. The bootstrap phase wrote four q4 SD rows with
`conf.status = "bootstrap"`, `bootstrap.n = 2`, `bootstrap.failed = 0`, and
`julia.elapsed = 1.13` s. Total R-side bootstrap phase elapsed time was
10.46 s.

## Tests Of The Tests

The 30-tip smoke uses Ayumi's real bundle and the exact q4 formula family, but
it is deliberately too small to support statistical claims. It confirms that
the harness can invoke the Julia q4 bootstrap route, record all four SD rows,
and preserve failure counts. Larger size-ladder runs remain the real speed and
robustness tests.

## Consistency Audit

No user-facing documentation, formula grammar, likelihood parameterization,
NEWS, pkgdown navigation, or capability status changed. The stale-claim search
for this internal harness slice was:

```sh
rg -n "DRMTMB_AYUMI_Q4_BOOTSTRAP|bootstrap_targets|all_q4|Ayumi q4 status harness" tools docs/dev-log/check-log.md docs/dev-log/after-task
```

## GitHub Issue Maintenance

This slice belongs under `drmTMB#544`, the bridge-gate-drift and bridge evidence
tracker. No issue comment has been posted yet; the next public comment should
wait until this harness PR is opened and CI is green.

## What Did Not Go Smoothly

The first harness draft only selected sigma-axis bootstrap rows. That would
have been enough for Ayumi's sigma-phylo boundary question, but it wasted the
Julia q4 bootstrap result shape. The target selector was widened to `all_q4` so
tiny smoke runs can show all four SD axes while still allowing focused
`first_sigma` and `all_sigma` modes.

## Team Learning

Ada kept this as a tool/evidence slice rather than a model-speed claim. Fisher
and Rose keep the boundary clear: `R = 2` proves interface plumbing, not
coverage or 10k-tip feasibility. Grace gets a repeatable command and CSV output
for the next overnight size ladder.

## Known Limitations

- This does not make native `engine = "tmb"` a bivariate q4 REML fallback.
- This does not fix the 10,440-tip Julia wall-time problem.
- This does not calibrate bootstrap coverage or prove that full across-tree
  bootstrap runs are practical.
- The harness still relies on R's elapsed-time limit, which cannot interrupt
  every compiled-code or Julia-side long-running section.

## Next Actions

1. Open the bootstrap-harness PR and wait for CI.
2. Run an overnight size ladder that separates native TMB ML, Julia ML, Julia
   REML, profile, and bootstrap phases.
3. Use the resulting evidence in the draft reply to Ayumi, with the bootstrap
   smoke described as plumbing evidence only.
