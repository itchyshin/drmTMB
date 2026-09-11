# After Task: Phylogenetic-temporal OU Phase 0 bootstrap

## 1. Goal

Create a reviewable, fail-closed execution substrate for the approved first
phylogenetic-temporal slice before parser, likelihood, simulation, or campaign
work begins.

## 2. Implemented

Phase 0 adds two portable R gate runners, a focused test file, a cited temporal
source map, a source fingerprint receipt, and P1 G1 evidence. The worktree is
pinned at `a1d01dab3dbcd6e12bec0486ac0425f939f20c2d` on
`codex/phylo-temporal-ou-exec-v1-20260909`.

## 3a. Decisions and Rejected Alternatives

The first P1 contract remains a stable phylogenetic intercept plus an
independent within-species OU deviation. The separable phylogeny-by-OU field is
explicitly rejected for this slice. The receipt records a source-input hash
rather than a nonexistent binary hash: no native compilation was run in Phase 0.

## 4. Files Touched

- `tools/phylo-temporal-ou-gates.R`
- `tools/temporal-source-map-gates.R`
- `tests/testthat/test-phylo-temporal-ou-gate-runner.R`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/source-map.md`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/source-fingerprint.md`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/unlazy/GATES.md`
- `docs/dev-log/plan-actual/2026-09-09-phylo-temporal-ou-phase0.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

`Rscript --vanilla tools/phylo-temporal-ou-gates.R --self-test` returned
`PHYLO_TEMPORAL_OU_RUNNER_SELFTEST_PASS controls=1`.

`Rscript --vanilla tools/phylo-temporal-ou-gates.R G1` returned
`PHYLO_TEMPORAL_OU_G1_PASS`.

`Rscript --vanilla tools/temporal-source-map-gates.R --self-test`,
`M01-bootstrap`, `M02`, and `M03` returned their four expected PASS markers.

`Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-phylo-temporal-ou-gate-runner.R")'`
completed with 6 passes and no failures, warnings, or skips. `git diff --check`
passed.

## 6. Tests of the Tests

The P1 runner creates and validates a fixture, deletes it, then confirms the
missing fixture is rejected. The source-map runner rejects an uncited verified
section and an incomplete fingerprint. The focused test runs the scripts from
`tests/testthat`, proving that their repository-root discovery does not depend
on the caller's working directory.

## 7a. Issue Ledger

Open-issue search found #1302, `Feature: phylogenetically correlated temporal
OU series`, which already tracks this exact implementation. No issue was opened
or commented on because this local bootstrap adds no user-facing state and no
external message was authorized.

## 8. Consistency Audit

The source-map prose was reviewed for a statistical-method-developer reader:
every factual package or literature statement has a link, and the map states
that source comparison does not validate drmTMB. The active-doc scan was
`rg -n --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**'
'phylo\(.*temporal|phylogenetic.*OU|separable.*OU|homtoep|hettoep|hetar1'
README.md NEWS.md docs vignettes R tests _pkgdown.yml`. It found existing
phylogeny and temporal records but no current public claim for this unbuilt
combined model. No README, NEWS, formula grammar, likelihood design document,
vignette, known-limitation entry, or pkgdown navigation changed because package
behaviour did not change.

## 9. What Did Not Go Smoothly

The first source-map runner only checked headings, then its citation expression
contained an invalid R escape. A focused test also exposed a working-directory
assumption in both runners. The repaired version checks citations and
fingerprints, uses its own script path as the repository anchor, and passes the
same negative controls.

## 10. Known Residuals

NotebookLM processed the accessible GLMMTMB, Matilda, and Felsenstein pages,
but returned no synthesis text. The paywalled Pourahmadi publisher record was
unavailable through NotebookLM, so it remains an unverified lead. No
source-map claim chooses a Toeplitz parameterization.

## 11. Team Learning

A gate runner is only evidence when it is portable and rejects the relevant
forgery. Phase 0 now treats an absent native library truthfully: it records a
source-input hash and requires a source-built binary hash before P1 numerical
or campaign evidence can be retained.

## 12. Cross-Product Coverage

This Phase-0 bootstrap covers only the source and evidence substrate: the P1
plan contract, gate-runner portability, citation separation, and source/R/TMB
fingerprint. It does NOT cover formula parsing, missing-data handling, tree
alignment, OU transitions, phylogenetic covariance construction, native TMB
likelihood, fixed-effect intervals, simulation, profiling, REML, non-Gaussian
families, Julia engine parity, package build/check, rendered documentation, or
remote campaign computation. Those downstream products remain owned by later
P1 gates and cannot inherit a pass from this bootstrap.
