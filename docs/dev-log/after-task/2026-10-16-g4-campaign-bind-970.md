# 2026-10-16: G4 campaign binds routes with different mask receipts (#970)

Reader: the maintainer, or the next lane working on the missing-response G4/G5
simulation harness in `inst/sim/R/sim_missing_response_g4g5.R`.

## Goal

`mr_g4_run_campaign()` accepts manifests for all 18 routes, but it combined
per-cell records with a bare `rbind()`. The mask receipt is route-dependent:
`biv_gaussian` records carry four paired-mask counts (`mask_complete_pairs`,
`mask_y1_only_missing`, `mask_y2_only_missing`, `mask_both_missing`) that the
other 17 routes lack (35 against 31 columns in the August run recorded on #970;
29 against 25 with the current runner).
A registry spanning both shapes therefore stopped with `numbers of columns of
arguments do not match`. Issue #970 accepts either union-and-pad or an explicit
single-route guard; this change takes union-and-pad.

## Change

The campaign loop now combines records with the existing
`mr_g5_bind_records()`, which unions the field names and pads absent fields with
`NA`. That is the rule `mr_g5_run_campaign()`, `mr_g4_reconcile_checkpoints()`,
and `mr_g5_reconcile_checkpoints()` already apply. The helper's comment now
records the G4 caller, so a later G5-only edit does not silently change G4.

Files:

- `inst/sim/R/sim_missing_response_g4g5.R`: one call site and two comments.
- `tests/testthat/test-missing-response-g4g5-foundation.R`: the forcing test,
  added in `1dbdecb7` and not changed by the fix commit.
- `docs/dev-log/after-task/2026-10-16-g4-campaign-bind-970.md`: this report.

No `R/`, `NAMESPACE`, `DESCRIPTION`, `NEWS.md`, vignette, or design-doc file
changes. The proposed NEWS line is in the PR body.

## Checks

Local environment: Ubuntu 24.04, R 4.3.3, TMB 1.9.10, Matrix 1.6-5,
testthat 3.2.1, package loaded with `pkgload::load_all()`, `NOT_CRAN=true`.

- **Red, on `1dbdecb7` (test without fix).**
  `testthat::test_file("tests/testthat/test-missing-response-g4g5-foundation.R")`:
  45 tests, 251 passing expectations, 0 failures, 1 error. The error is the
  forcing test: `Error in rbind(deparse.level, ...): numbers of columns of
  arguments do not match`, raised from `rbind(records, next_record)` inside
  `mr_g4_run_campaign()`.
- **Green, with the fix.** Same file: 45 tests, 256 passing expectations,
  0 failures, 0 errors; the forcing test passes all 5 of its expectations.
- **CI shard 3/4** (the shard containing this file, from
  `drm_shard_filter(spec = "3/4")`, run with `testthat::test_dir()`): 111
  files, 980 tests, 29,448 passing expectations, 34 skips, 5 failures, and
  21 errors. The foundation file passed in full (45 tests, 256 expectations).
  The 26 failures sit in nine files, none of which sources the simulation
  file, and the same nine files give identical failure and error counts on
  `1dbdecb7`. Their causes are environmental: 24 call base `%||%`, which
  R 4.3.3 lacks (it entered base R in 4.4.0); one snapshot expects the message
  from an installed `emmeans`; and one PCRE pattern is rejected as invalid
  UTF-8 in this locale. CI runs current R release with full Suggests.
- **CI pre-step guards** from `.github/workflows/R-CMD-check.yaml`:
  `python3 tools/capability_ledger.py --check` reported `OK (31 generated
  outputs)`; the six wired `tools/tests/*.py` modules passed (80, 3, 3, 12, 5,
  and 24 tests); `tools/emit-profile-truth-manifest.R --check` reported
  `OK (30 rows)`; `tools/check-evidence-citations.R` reported 0 violations;
  `tools/run-source-tree-tests.R --check` agreed with `.Rbuildignore`
  (38 files). The ledger reads this simulation file only to extract `policy_id`
  from `mr_g5_calibration_gate()`, which is unchanged; it does not hash the
  file.

## `devtools::document()`

Run with roxygen2 8.0.0, the version recorded in `Config/roxygen2/version`,
under R 4.5.3 from conda-forge (Ubuntu ships roxygen2 7.3.1, older than the
`RoxygenNote`). It changed neither `NAMESPACE` nor `DESCRIPTION`, and this PR
gives it no input to change. It did rewrite 39 `man/*.Rd` files, none because
of this PR:

- 38 are the exact inverse of `592aecaa` (#1400, "replace internal process
  language in reference help"), which edited `man/` directly without updating
  the roxygen blocks in `R/`. For 35 of them the regenerated file is
  byte-identical to its pre-#1400 version.
- `man/drmTMB-parallel.Rd` changes only one link anchor
  (`parallel:makeCluster` to `parallel:makePSOCKcluster`), a toolchain
  difference rather than a source change.

The lane instruction was to run `document()` and commit its output. The output
was run but **not committed**, a deliberate departure for the maintainer to
confirm or overrule, for two reasons:

- It would revert the maintainer's own help text across 38 files, in a PR about
  a simulation harness (`CLAUDE.md`: do not revert human changes unless asked).
- It would break the pkgdown build. Rendered with `tools::Rd2HTML()` and
  scanned with the patterns in `tools/check-pkgdown-public-surface.R`, none of
  the 39 pages at HEAD trips the guard, but 10 of the regenerated pages do
  (issue numbers in `confint.drmTMB` and `drm_control`; `docs/dev-log` paths or
  "capability ledger" in `drmTMB`, `qq_plot`, `relmat`, `residuals.drmTMB`,
  `rho_latent`, `summary.drmTMB_julia_xfam`, and `worm_plot`; a `D-` decision
  identifier in `heritability`). The scheduled pkgdown run on `main` would
  then fail its "Verify public documentation surface" step.

The durable fix is to port the #1400 wording into the roxygen blocks in `R/`,
after which `document()` is idempotent again. That is a separate documentation
task.

## Consistency audit

`rg "mr_g4_run_campaign|mr_g5_bind_records"` finds only the two campaign
runners and the foundation tests. The DRAC scripts in `tools/` are G5-only:
each array task runs one registry cell through `mr_g5_run_campaign()`, and
`mr_g5_reconcile_checkpoints()` merges them. No `tools/` script calls any
`mr_g4_*` function, so none is affected. The change does not touch
grammar, families, likelihoods, random effects, or the public API, so the status
inventory (`README.md`, roadmap, `NEWS.md`, known limitations, formula grammar)
needs no update.

## Tests of the tests

The forcing test stubs `mr_g4_run_route()` and `mr_g4_validate_campaign()` in
its own environment. `source_missing_response_g4g5()` sources the runner into
that same environment, so `mr_g4_run_campaign()` finds the stubs by lexical
scope and no model is fitted. The red run shows the stub reaches the combining
step: the error comes from `rbind(records, next_record)`, not from a fit. The
assertions check one record per registry cell (54 = 18 routes x 3 rungs), that
two of the paired-mask fields (`mask_complete_pairs`, `mask_both_missing`)
exist, and that `mask_complete_pairs` is filled for `biv_gaussian` and `NA`
elsewhere. In registry order `gaussian` precedes `biv_gaussian`, so both bind
directions run: a wider record joining narrower ones, and the reverse.

Because the validator is stubbed, the test does not show that padded records
pass `mr_g4_validate_campaign()`. Reading the validator, it requires only
fields that every route carries, so padding cannot change its verdict; that
claim rests on the code, not on a test.

## What did not go smoothly

The session that authored `1dbdecb7` had no R packages, so it pushed the
forcing test without the fix described in the PR body. Its CI run stayed queued
behind other lanes and is superseded by the fix push (`cancel-in-progress` for
pull requests), so the red evidence is the local run above, not CI. CRAN and
Posit were blocked here as well; the R stack came from Ubuntu `r-cran-*`
packages, and roxygen2 8.0.0 from conda-forge.

## Team learning

- Do not state that `document()` has no output without running it. On current
  `main` it is not idempotent, because of #1400.
- A lane that cannot run R should not push a red-proof commit on its own: the
  PR is left red until another session can finish it.

## Issues and next actions

Refs #970; it stays open for the maintainer to close on merge. The lane
commented its plan on #970 before starting. No issue was opened: the follow-ups
below are left to the maintainer to file or fold in. `docs/dev-log/check-log.md`
was deliberately not edited, because the lane plan on #970 kept this PR clear
of shared ledger files.

1. **Fixture-failure records are not campaign-ready** (pre-existing; this PR
   makes the path reachable). When `mr_g4g5_route_fixture()` fails,
   `mr_g4_run_route()` returns `mr_g4_failure_records()` before it adds
   `information_rung`, `information_multiplier`, the design stamp, and the mask
   receipt. Fit failures are unaffected because they return through the normal
   path. Before this fix a full-registry campaign never got past cell 2 (the
   #970 error itself), so the path was unreachable. Now, reproduced with stubbed
   fixtures and fits:
   - If the failing cell is not the first, the row is padded with `NA` for the
     rung and saved to `checkpoint_path`. The loop finishes, and
     `mr_g4_validate_campaign()` then stops with "G4 records must retain
     exactly one result for every frozen target and information rung." Each
     resume re-runs that cell and appends another unkeyed row, so the
     checkpoint can only be repaired by hand.
   - If it is the first cell of a fresh run, the next iteration's resume-key
     lookup stops with `undefined columns selected`, before and after this fix.
     The saved checkpoint lacks `information_rung`, so every resume stops with
     "G4 checkpoint must contain retained target records."

   The G5 fixture-failure branch in `mr_g5_run_attempt()` already stamps the
   rung, the design state, and an `NA` mask receipt; porting that to G4 fixes
   both cases. It also matters outside campaigns: during reconciliation,
   `mr_g4g5_check_design_agreement()` marks an unstamped G4 failure record
   `UNAUTHENTICATED`, with a warning that it predates design stamping (#982),
   even though it was written afterwards.
2. **`mr_g4_run_campaign()` never checks design agreement.** A checkpoint
   written before #982 used to fail to resume at `rbind()`. It now resumes, and
   its rows keep `design_state = NA` beside freshly stamped rows, with no
   `UNAUTHENTICATED` marker. Both reconcilers call
   `mr_g4g5_check_design_agreement()`; the G4 and G5 campaign runners do not.
3. **`man/` and `R/` roxygen have drifted** since #1400, as described above.
4. **`%||%` without a definition.** `R/julia-bridge.R`,
   `R/julia-diagnostics.R`, `R/julia-family-registry.R`, and
   `R/mspl-estimator.R` call `%||%`, but the package neither defines nor
   imports it, while `DESCRIPTION` declares `Depends: R (>= 4.1.0)`. Those
   paths fail on R 4.1 to 4.3 (seen in the local shard run above).
