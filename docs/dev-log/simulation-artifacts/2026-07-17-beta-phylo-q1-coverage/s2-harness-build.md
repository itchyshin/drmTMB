# Beta phylogenetic q1 direct-SD coverage harness — S2 build report

> Scope: BUILD + SMOKE-TEST only. This does not launch the promotion-arm
> campaign (S3). Estimand/scale/gate contract:
> `docs/dev-log/2026-07-17-beta-phylo-q1-coverage-estimand-alignment.md` (S0).

## What was built

`tools/run-beta-phylo-q1-sd-coverage.R` — a sibling harness that
`sys.source()`s `tools/run-beta-phylo-q1-sd-interior-recovery.R` (which itself
`sys.source()`s the immutable predecessor
`tools/run-beta-phylo-q1-sd-regression-recovery.R`) and adds Wald/profile
interval coverage scoring. The point-recovery scoring path in both sourced
runners is untouched; every new function uses the `pr2c_` prefix.

Reused from the sourced runners (file:line):
- DGP `beta_phylo_sd_regression_dgp()` — `tools/run-beta-phylo-q1-sd-interior-recovery.R:212-258`
  (interior/machine-strict version; supersedes the stopped lineage's own
  definition of the same name).
- `draw_machine_interior_beta()` — `tools/run-beta-phylo-q1-sd-interior-recovery.R:157-210`.
- `pr2_cells()` — `tools/run-beta-phylo-q1-sd-regression-recovery.R:81-107`.
- `pr2_seed_grid()` (successor, certification base `2080000000L`, 400 reps/cell)
  — `tools/run-beta-phylo-q1-sd-interior-recovery.R:58-76`.
- `stopped_pr2_seed_grid()` (stopped lineage's own grids, used only for
  seed-disjointness auditing) — `tools/run-beta-phylo-q1-sd-interior-recovery.R:78-94`.
- `with_pr2_rng()` — `tools/run-beta-phylo-q1-sd-regression-recovery.R:61-79`.
- `clean_pr2_text()` — `tools/run-beta-phylo-q1-sd-regression-recovery.R:272-274`.
- Fit call (`bf()`/`family = beta()`/`drm_control(...)`) mirrored verbatim
  from `stopped_pr2_recovery_attempt()` — `tools/run-beta-phylo-q1-sd-regression-recovery.R:338-353`
  — but the new `pr2c_recovery_attempt()` retains `fit` (needed for
  `confint(..., method = "profile")`) instead of discarding it, so DGP + fit
  happen exactly once per replicate, not twice. The gradient/condition-number
  and `min_tau`/`max_tau` diagnostics are mirrored from
  `tools/run-beta-phylo-q1-sd-regression-recovery.R:380-392`.
- `drm_phylo_tip_covariance()` (package internal, `correlation = TRUE`
  default) — `R/phylo-utils.R:200` — used both inside the DGP and again here
  for the per-replicate tree-structure summary.

New (`pr2c_`) pieces: estimand map (`pr2c_coefficients`,
`pr2c_coefficient_parm`, `pr2c_truths` — `alpha_0 = log(0.30)`,
`alpha_1 = 0.25`, matching S0 Sec 3 exactly); pure coverage-scoring helpers
(`pr2c_covered`, `pr2c_miss_direction`, `pr2c_mcse`, `pr2c_exact_ci` via
`stats::binom.test`); the scale-match guard and confint wrapper
(`pr2c_confint_method`, hard `stop()` if `scale != "link"`); the wide
per-replicate row builder (`pr2c_recovery_attempt`, `pr2c_widen_confint`,
`pr2c_attempt_columns`); the phylo structure summary (`pr2c_tree_summary`,
tree depth / mean pairwise cophenetic distance / mean off-diagonal
correlation / a design-effect effective-N proxy `g / (1 + (g-1)*rho_bar)`);
crash-safe lock-serialized incremental TSV append + resume
(`pr2c_append_row`, `pr2c_done_keys`); per-cell aggregation
(`pr2c_aggregate_coverage`, `pr2c_aggregate_tree`); cell/role/priority-order
scaffolding (`pr2c_cells` — excludes `g=1024,m=2`, tags `role` = promotion
for the two `g1024_m04` arms vs. context for the 8 `g∈{256,512}` cells, sorts
promotion first); frozen-seed reuse plus disjoint extension beyond N=400
(`pr2c_seed_grid`, `pr2c_seed_audit`); and the driver
(`run_pr2c_coverage`) with a thin CLI (`--n-promotion=`, `--n-context=`,
`--cores=`, `--output=`, `--resume`) guarded by `if (sys.nframe() == 0L)` so
sourcing/testing never auto-launches a campaign.

## Smoke test (S2 gate)

Ran `pkgload::load_all(".")` then `run_pr2c_coverage()` restricted to cell
`distinct_g0256_m02` (context role), `N = 3`, both methods, `cores = 1`.
Output: `docs/dev-log/simulation-artifacts/2026-07-17-beta-phylo-q1-coverage/smoke-s2/`
(`raw-coverage.tsv`, `progress.log`).

Per-replicate elapsed (fit / wald / profile): rep 1 = 4.0s / 0.12s / 156.4s;
rep 2 = 4.8s / 0.14s / 201.8s; rep 3 = 3.5s / 0.10s / 265.1s. All three
`fit_success = TRUE`, `pdHess = TRUE`. This brackets the S1 probe's ~157s
profile figure for g=256,m=2 and shows real per-replicate variance (curvature-
dependent `tmbprofile()` cost), useful for S3 sizing.

Gate checks:
- **(a) incremental writes, non-NA lower/upper/coverage:** confirmed — the
  4-line TSV (header + 3 rows) grew one row at a time as `progress.log`
  timestamps show (rep 1 done 18:07:00 UTC, rep 2 18:10:26, rep 3 18:14:55);
  zero NAs across all 8 `{wald,profile}_{alpha_intercept,alpha_x}_{lower,upper}`
  columns.
- **(b) `scale == "link"` assertion:** confirmed — all 4 `*_scale` columns
  are `"link"` for all 3 replicates; the hard guard in `pr2c_confint_method`
  never fired (no errors in `progress.log`), i.e. it was live and passed
  rather than untested.
- **(c) coverage indicator hand spot-check (replicate 1, seed 2079989999):**
  `truth_alpha_intercept = -1.203973` (`= log(0.30)`), `truth_alpha_x = 0.25`.
  Wald `alpha_intercept`: `[-1.319634, -0.505193]` → covers, harness says
  `TRUE`, hand check `TRUE`, match. Wald `alpha_x`: `[0.203881, 0.462810]` →
  covers, match. Profile `alpha_intercept`: `[-1.312954, -0.505786]` →
  covers, match. Profile `alpha_x`: `[0.209589, 0.470311]` → covers, match.
  All 4 harness-vs-hand comparisons identical.
- **(d) per-cell aggregation:** `pr2c_aggregate_coverage(raw)` produced 4
  rows (2 methods × 2 coefficients) with `attempted=3`, `interval_finite_n=3`,
  `hits`, `rate`, `mcse`, `exact_ci_lower/upper` (Clopper-Pearson via
  `binom.test`), `mean_width`. At N=3 the 3-replicate coverage was
  `alpha_intercept`: 3/3 both methods; `alpha_x`: 2/3 both methods (rep 3
  missed above truth for both wald and profile) — noise at this toy N, not a
  calibration claim. `pr2c_aggregate_tree(raw)` produced the 1-row phylo
  summary (`mean_tree_depth ≈ 1.88`, `mean_pairwise_distance ≈ 1.38`,
  `mean_offdiag_correlation ≈ 0.56`, `mean_effective_n_proxy ≈ 1.9`).
- **(e) resume:** re-running `run_pr2c_coverage(..., resume = TRUE)` against
  the same output reported "0 pending of 3 total replicates", left
  `raw-coverage.tsv` at 3 rows, and `identical()` to the pre-resume table.

## Test file

`tests/testthat/test-beta-phylo-q1-sd-coverage-runner.R` — 15 `test_that()`
blocks / 75 assertions, all pure (no live fit): `pr2c_covered`,
`pr2c_miss_direction`, `pr2c_mcse`, `pr2c_exact_ci` (checked against
`stats::binom.test` reference bounds); `pr2c_cells` role/exclusion/priority
order; `pr2c_seed_grid`/`pr2c_seed_audit` for frozen reuse (N≤400, byte-exact
match to `pr2_seed_grid("certification")`), disjoint extension beyond N=400,
and two deliberate audit-failure cases (corrupted frozen seed, duplicate
seed); `pr2c_widen_confint` (populated and all-NA/error paths);
`pr2c_confint_method(NULL, "wald")` short-circuit; `pr2c_attempt_columns`
uniqueness/naming; `pr2c_aggregate_coverage`/`pr2c_aggregate_tree` against a
synthetic fixture with hand-verified hits/N/MCSE/exact-CI/directional-miss/
mean-width; `pr2c_append_row`/`pr2c_done_keys` round-trip. Ran via
`testthat::test_file(...)`: **PASS, 0 failures.** Also re-ran the 5 existing
`beta-phylo*` test files afterward — all still pass (no regressions).

## API surprises / notes for S3

1. **`commandArgs()` precedence gotcha.** `pr2c_here()` (mirroring the
   sibling `successor_script_path()` pattern) checks `commandArgs(FALSE)`
   for `--file=` *before* the `drmTMB.coverage.runner_path` option. If the
   coverage tool is invoked indirectly as `Rscript wrapper.R` (wrapper then
   `sys.source()`s the tool), `commandArgs(FALSE)` reflects the *outer*
   process's `--file=wrapper.R`, not the tool's own path, and path resolution
   silently breaks. Fix: invoke via `Rscript -e "source(...)"` (no matching
   `--file=`) or set both `drmTMB.coverage.runner_path` **and**
   `drmTMB.successor.runner_path` explicitly before sourcing — the interior
   runner does its own independent `commandArgs()`/option check one layer
   down. This bit the smoke-test driver during S2 and is now handled
   correctly in both the harness and the test file, but any S3 launch script
   that wraps the Rscript call needs the same care.
2. **`effective_n_proxy` is a deliberately naive design-effect proxy**
   (`g / (1 + (g-1) * mean_offdiag_correlation)`), not a rigorous
   phylogenetic ESS — it assumes a constant pairwise correlation, which a
   real (heterogeneous) phylogenetic correlation matrix does not have. For
   `ape::rcoal()` trees at g=256 the mean off-diagonal correlation was
   ~0.5-0.8 in the smoke sample, driving the proxy down to ~1-2 — expected
   given the formula, but worth reading as a coarse signal (per S0 Sec 5,
   "a simple tree-structure summary"), not a load-bearing ESS estimate.
3. **Wide, not long, per-replicate schema.** One row per replicate with
   `{method}_{coefficient}_{field}` columns (32 coverage columns + elapsed +
   diagnostics + telemetry + tree summary = 68 columns total via
   `pr2c_attempt_columns()`), matching the existing `pr2_attempt_columns()`
   convention rather than a long method×coefficient table; aggregation
   reshapes at read time (`pr2c_aggregate_coverage`).
4. **Runtime scale-out reminder for S3.** Profile confint at g=256,m=2 costs
   ~156-265s/replicate here for *one* fit; at N=400 (context cells) that is
   single-core-days per cell, and the two promotion arms at g=1024,m=4 were
   already profiled at ~25 min/replicate by S1 — confirms S3 needs
   multi-core `parallel::mclapply` (already wired via `cores=`) and a Totoro/
   DRAC launch, not a local run.

## Files

- `tools/run-beta-phylo-q1-sd-coverage.R` — the harness.
- `tests/testthat/test-beta-phylo-q1-sd-coverage-runner.R` — the test file.
- `docs/dev-log/simulation-artifacts/2026-07-17-beta-phylo-q1-coverage/smoke-s2/` —
  smoke-run evidence (`raw-coverage.tsv`, `progress.log`).
