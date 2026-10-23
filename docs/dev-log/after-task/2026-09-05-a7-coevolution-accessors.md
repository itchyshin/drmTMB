# A7 (#1118): port DRM.jl's coevolution_cor() / coevolution_vc() / coevolution_summary()

**Reader**: anyone reading a q = 4 structured bivariate location-scale
("coevolution") fit's among-axis correlation or variance components in R,
anyone touching `R/coevolution-accessors.R`, and the integrator merging the
parity-joint leaves (A7 is independent; no dependency on A5/A6/A9/A10).

**Resume note**: a first attempt of this leaf died at a rate limit on the
evening of 2026-09-04 with uncommitted files and no report. This run kept the
uncommitted `R/coevolution-accessors.R`, `man/coevolution-accessors.Rd`,
`tests/testthat/test-coevolution-accessors.R`, and the NAMESPACE/NEWS hunks
only after re-verifying each against the DRM.jl pin and re-measuring every
number below in this run. Nothing from the previous attempt is quoted.

## 1. Goal

Port DRM.jl's three coevolution accessors to native R over drmTMB's existing
q = 4 fit objects (both engines), with DRM.jl's own implementation at pin
`430ef64cc` as the oracle, and prove same-target agreement live.

## 2. Implemented

- `coevolution_cor(object)`: the 4 x 4 among-axis correlation
  `R = D^{-1/2} Sigma_a D^{-1/2}` over `mu1, mu2, sigma1, sigma2`, symmetrised
  and with an exact unit diagonal, returned as `list(cor, axes)`. Follows
  `src/coevo_accessors.jl` lines 85-95.
- `coevolution_vc(object)`: `list(axes, variance, sd, cov)` with
  `variance = diag(Sigma_a)`. Follows lines 120-126.
- `coevolution_summary(object)`: the tidy long form over the six unordered
  axis pairs in DRM.jl's `i < j` order (`mu1:mu2, mu1:sigma1, mu1:sigma2,
  mu2:sigma1, mu2:sigma2, sigma1:sigma2`), plus the two matrices. Follows lines
  147-174.
- Shared guard `drm_coevolution_sigma_a()` (DRM.jl `_coevo_sigma_a`, lines
  32-43): native fits rebuild `Sigma_a = D R D` from `object$sdpars$mu` and
  `object$corpars[[key]]` (the C++ `phylo_q4_covariance` construction);
  `engine = "julia"` fits reconstruct it from the `phylocov` log-Cholesky slot
  via the existing `drm_julia_phylocov_matrix()` and rescale by the tree
  height (`sd_scale^2`) to drmTMB's unit-height convention, the same factor
  `drm_julia_profile_targets_biv()` applies to the axis SDs.
- Refusals, one message: residual-only bivariate fits, univariate fits, q = 2
  blocks, q = 4 blocks whose axes are not the four location-scale axes,
  `sd_phylo(...) ~` fits, and non-fit objects.
- NAMESPACE exports (3 lines) and `man/coevolution-accessors.Rd`, generated at
  roxygen2 7.3.2 from a scratch library (the installed roxygen2 is 8.0.0).
- One NEWS bullet under 0.7.0.

## 3a. Decisions and Rejected Alternatives

- Return plain lists with DRM.jl's field names (`cor`, `axes`, `variance`,
  `sd`, `cov`, `pair`, `correlation`, `covariance`) instead of a data frame
  or an S3 class, so the port is checkable field-by-field against the
  oracle. A tidy data-frame view already exists via `corpairs(fit, level =
  "phylogenetic")`, which the tests cross-check.
- Report `engine = "julia"` values on the unit-height convention rather than
  DRM.jl's raw branch-length scale, so the same model prints the same numbers
  under both engines. Rejected: reporting raw-scale values for julia fits
  (would disagree with `confint()`/`profile_targets()` on the same fit).
- Accept block-diagonal q = 4 blocks (two labelled 2 x 2 blocks) and report
  the exact zeros, rather than refuse. DRM.jl cannot fit that shape; the
  stored covariance is nonetheless a 4 x 4 `Sigma_a`, so the contract holds.
- Native-only test on `animal(1 | p | id, Ainv = Q)` added in this run to back
  the documented claim that non-phylo markers flow through the same slot.
  `spatial()` on all four axes is refused by drmTMB for the approximate
  spatial path (`test-reml-bivariate-spatial-q2.R`), so it is documented as
  accepted-by-shape but is NOT exercised (see 12).

## 4. Files Touched

Created:
- `R/coevolution-accessors.R`
- `tests/testthat/test-coevolution-accessors.R`
- `man/coevolution-accessors.Rd`
- `docs/dev-log/after-task/2026-09-05-a7-coevolution-accessors.md` (this file)

Modified:
- `NAMESPACE` (+3 export lines only)
- `NEWS.md` (one bullet block under 0.7.0)
- `.unlazy/parity/gates/leaf-a7-coevolution-accessors.md` (EVIDENCE lines; in
  the main checkout, the ledger's home)

Not touched (and reverted when a roxygen run drifted them): `man/beta.Rd`,
`man/confint.drmTMB.Rd`, `man/drmTMB-package.Rd`, `man/drmTMB.Rd`,
`man/drm_quantile_residuals.Rd`, `man/make_mesh.Rd`,
`man/model-fit-extractors.Rd`, and two never-committed
`man/drm_julia_joint_*.Rd` files. See 8.

## 5. Checks Run

All run 2026-09-05 in the worktree on macOS, R 4.6, DRM.jl 430ef64cc,
`OPENBLAS_NUM_THREADS=1`, `threads = FALSE`.

- G1 citation check: `grep -c 'coevo_accessors.jl\` lines'` = 4, test file
  cites `test_coevo_accessors.jl` -> `G1_CITED_OK`.
- G2 (native only, `env -u DRM_JL_PATH -u DRMTMB_JULIA_TESTS`): 6 non-live
  tests, 77 expectations, 0 failed, 0 error, 0 skipped -> `G2_PORT_OK`
  (per-test nb: 21, 4, 33, 5, 8, 6). First run before the animal() test: 5
  tests / 69 expectations, 8.9 s.
- G3 (live, DRM_JL_PATH at the pin): 2 live tests, nb = 22 and 24, 0 failed,
  0 skipped -> `G3_LIVE_PARITY_OK`; wall 2 min 25 s.
- G4: the single `guard:` test, nb = 6, 0 failed/skipped -> `G4_GUARD_OK`.
- G5 red control: planted `R <- -(R + t(R)) / 2` ->
  `live_tests=2 live_failed=12 live_skipped=0 RED_CONTROL_G3_FAILS`, then
  `RESTORED_BYTE_IDENTICAL` (`diff -q` against the backup).
- G6: `git diff --name-only origin/main...HEAD -- R/` =
  `R/coevolution-accessors.R` only, R/ clean -> `G6_SCOPE_OK`.
- G7: `RoxygenNote: 7.3.2` unchanged; NAMESPACE diff = exactly 3 lines, all
  `export(...)`; man/ + DESCRIPTION diff = `man/coevolution-accessors.Rd`
  only; `tools::checkRd()` returns nothing -> `G7_ROXYGEN_OK`.
- Ledger re-verification with `gate-check.mjs --approve`: recorded on the
  ledger's EVIDENCE lines (G8 merge gate left pending).

Measured parity numbers (scratch script `a7/measure.R`, re-running the test
file's own `coevo_live_run()` in a fresh R + Julia subprocess):

| fixture | height | oracle estimator | max abs diff, R port on julia fit vs DRM.jl `coevolution_*` | vs DRM.jl `q4_point_export$correlation` |
|---|---|---|---|---|
| pinned `test/parity/q4-reml/biv-q4-phylo-reml` | 0.98229160969 | REML | cor 1.11e-16; cov (x height) 3.117e-11; sd (x sqrt height) 2.143e-11 | 2.22e-16 |
| seeded unit-height coalescent (N = 30, m = 3, seed 42) | 1 | ML | cor 4.441e-16; cov 5.551e-17; sd 0 | 2.22e-16 |

Pinned fixture, six correlations (oracle = R port on the julia fit to 10
significant digits): `0.6564138692 -0.2425698181 -0.5245473842 -0.4812783853
-0.1127251247 -0.3610391889`; unit-height axis SDs `0.7273111313 0.534250736
0.6973939802 0.4080596981`. Seeded fixture: `0.6670494237 0.2694649797
-0.07436829459 -0.5376541619 -0.7918790133 0.9394517678`; SDs `0.7051170621
0.7697014107 0.1187776209 0.2247134632`.

Native TMB refit of the same data vs the DRM.jl oracle (a different optimiser
on a flat q = 4 likelihood; the test bound is 0.05):

| fixture | TMB `opt$convergence` | max abs gradient | logLik TMB / DRM.jl | max abs diff cor | max abs diff sd |
|---|---|---|---|---|---|
| pinned REML | 0 | 4.665e-10 | -219.613986303 / -219.614005474 | 7.244e-4 | 4.489e-4 |
| seeded ML | 1 | 1.895e-3 | -179.849838542 / -179.852318266 | 9.869e-3 | 3.166e-3 |

## 6. Tests of the Tests

- The G5 red control above: a sign error planted in the symmetrisation step
  of `coevolution_cor()` makes 12 live expectations fail; restored
  byte-identically.
- Tier 1 recovers a hand-built `Sigma_a` to 1e-12 from a synthetic
  `drmTMB_julia` fixture, including the `sd_scale = 1.7` rescale and the
  refusal when the `phylocov` slot is removed, so a wrong scale factor or a
  wrong pair order would fail without Julia present.
- Tier 2 compares the native accessors to the C++ `phylo_q4_covariance`
  report (1e-10) and to `corpairs()` (1e-12), two independent readers of the
  same stored state.
- The live tests skip only on engine availability (`drm_skip_live_julia()`);
  an engine error is an error, not a skip. With the pin present the gate
  requires `skipped == 0`.

## 7a. Issue Ledger

- #1118 (DRM.jl feature this ports): covered by this leaf.
- #693 (julia scale convention): reused; no new issue.
- #1140 (roxygen 8.0.0 vs pinned 7.3.2): avoided by regenerating at 7.3.2
  from a scratch library; no repo change.
- Deferred: `man/` drift on origin/main under roxygen2 7.3.2 (see 8), not
  mine to fix in this leaf.

## 8. Consistency Audit

- Walked every internal helper the port calls and confirmed each exists on
  origin/main at the stated place: `has_structured_mu_effect()`
  (`R/methods.R:6112`), `structured_mu_q()`, `drm_phylo_mu_axis_labels()`,
  `phylo_mu_sd_labels()`, `structured_mu_correlation_key()`,
  `phylo_mu_pair_table()` (`R/drmTMB.R`), `drm_julia_phylocov_matrix()`
  (`R/julia-bridge.R:4971`), `object$model$random_scale$phylo$n_models`
  (`R/methods.R:6202`).
- Confirmed `object$bridge$q4_point_export` is real: DRM.jl `src/bridge.jl`
  lines 1530-1532 emit it and `new_drmTMB_julia()` stores the result dict as
  `bridge`; live `export_axes` read back as `mu1,mu2,sigma1,sigma2` on both
  fixtures.
- Roxygen collateral: running roxygen2 8.0.0 changed `man/confint.drmTMB.Rd`
  and created two `man/drm_julia_joint_*.Rd`; running 7.3.2 additionally
  changed six more man files (a `base::beta` link target, the Authors block
  of `drmTMB-package.Rd`, `\code{}` wrapping in `confint.drmTMB.Rd`, and
  similar). This is pre-existing drift between origin/main's roxygen comments
  and its committed `man/`, outside OWNS; all reverted forward from HEAD. My
  own Rd was byte-identical under both versions.
- The refusal text names `phylo/animal/relmat/spatial` as DRM.jl's does; the
  `animal()` path is now exercised natively, `relmat()` shares the identical
  code path (`Ainv = Q` vs `Q = Q` marker only), `spatial()` on all four
  axes is refused upstream by drmTMB itself for the approximate path.
- Memory receipt: the ledger, the plan's standing rules, design 258 (naming
  contract; no new coefficient names introduced), design 168 (four limbs:
  implementation, focused tests, public docs, and diagnostic evidence via the
  live parity table above). CROSS-REPO guard applied: source truth read via
  `git show origin/main:<path>` and the pin clone, never the main checkouts.
  Golden Set: not run; no known-mistake class from the Golden Set was in
  scope beyond the roxygen-version one, which the G7 gate mechanises.

## 9. What Did Not Go Smoothly

- The resume: the previous attempt left no commit, no PR, and no report, so
  every file had to be re-read against the pin before being trusted.
- The first parity-measurement script set its working directory to
  `tests/testthat`, where `testthat::test_path("..", "..")` cannot resolve;
  fixed by running from the package root.
- `devtools::document()` at the installed roxygen2 8.0.0 touched collateral
  man files; the destructive-command guard (rightly) blocked
  `git checkout -- man/`, so the seven files were restored one by one with
  `git show HEAD:<path>` after backing up the drifted versions to scratch.
- On the seeded fixture the native TMB refit reports `convergence = 1`
  despite a max gradient of 1.9e-3 and a log-likelihood 0.0025 above
  DRM.jl's; the 0.05 comparison bound absorbs it, and the test does not
  assert TMB convergence there. Stated in 10.

## 10. Known Residuals

- The native-vs-oracle comparison (0.05 bound) says both engines read the
  same structure off the same data; it is not accessor-precision parity
  (that is the 1e-16/1e-11 row) and the seeded fixture's TMB refit did not
  flag clean convergence.
- No uncertainty (SE/CI) on the correlations: DRM.jl reports point estimates
  only here, so does the port.
- `relmat()` and `spatial()` q = 4 native fits are not exercised by the new
  tests (see 12).
- The two `q4_point_export`-based expectations depend on DRM.jl's bridge
  export staying present; it is at pin 430ef64cc.

## 11. Team Learning

- When a gate pins a roxygen version that is not the one installed, install
  the pinned version into a scratch library and call
  `roxygen2::roxygenise()` with `.libPaths()` prepended; do not touch the
  user library and do not accept the collateral a newer version emits.
- For a resumed leaf, treat the previous attempt's files as a draft to
  re-verify: the citations, helper names, and export slots here all checked
  out, but only because each was traced back to the pin and to origin/main.

## 12. Cross-Product Coverage

This leaf touched two cross-cutting things: the engine axis and the
structured-marker axis.

Engine axis, for the three accessors:
- covers ✓ `engine = "tmb"` (native) q = 4 `phylo()` and `animal()` fits.
- covers ✓ `engine = "julia"` q = 4 `phylo()` fits, ML and REML, unit and
  non-unit tree height.
- does NOT cover ✗ `engine = "julia"` fits of `animal()`/`relmat()`/`spatial()`
  q = 4 blocks (DRM.jl's bridge export is read the same way, but no such
  fixture was fitted).

Structured-marker axis (native):
- covers ✓ `phylo()` single labelled block; `phylo()` block-diagonal (two
  2 x 2 blocks); `animal(Ainv = Q)`.
- does NOT cover ✗ `relmat()` (same code path, not fitted here);
  `spatial()` on all four axes (drmTMB refuses the approximate spatial q = 4
  shape; the exact fixed-covariance spatial variant was not fitted);
  `sd_phylo(...) ~` fits (refused by design, refusal not exercised in a test).

Beyond the accessors:
- does NOT cover ✗ `summary()`/`print()` integration, `tidy()` methods,
  pkgdown reference index placement, or `R CMD check` end to end (only
  `tools::checkRd()` on the new Rd and the focused test file were run).
