# After-task: opt-in t-quantile (Satterthwaite) Wald CI in confint.drmTMB

Meta: 2026-06-27 · Claude (ultracode) + Gauss (tmb_engineer) · SHIPPED engine
feature. Realizes the maintainer's t-based-CI hypothesis as a real, opt-in,
parity-verified `confint` path. Supersedes the "make it the default" line of
`2026-06-27-t-interval-decomposition.md` (see Refinement).

## What shipped

`confint.drmTMB(..., method = "wald", small_sample_df = c("none", "group"))`.

- `"none"` (default): ordinary normal quantile `z = qnorm((1+level)/2)` for every
  target. **Byte-identical to previous behaviour** (`all.equal` TRUE; all 141
  conversion "planned" assertions and the confint/wald/profile suites unchanged).
- `"group"` (opt-in): for each structured-RE SD target (`phylo`/`spatial`/
  `animal`/`relmat`) with a resolvable group count `g`, references a t-quantile
  with `df = g - 1`; every other target (and any SD target whose `g` cannot be
  uniquely matched) keeps the normal quantile.

Surface: `R/profile.R` only (+ regenerated `man/confint.drmTMB.Rd`). New helpers
`wald_target_df` / `structured_sd_group_count` / `wald_sd_target_group_count` /
`registry_sd_target_group_count`. The scalar `z` became a per-target `crit`
vector; the interval construction uses `crit[interval_ready]`.

## Where the design doc was wrong (engine reality)

The plan said `g` lives in `covariance_blocks$blocks$n_groups`. Empirically that
registry is **empty** for these structured q-series models. The real group count
is `length(object$model$structured$phylo_mu$group_levels)`. Two traps avoided:

- All four providers route through `tmb_parameter = "log_sd_phylo"` (the
  provider-specific names do not exist); matching is by structured `$label`.
- phylo's `n_re = 14` (8 tips + 6 internal nodes) **overstates** `g`; the helper
  uses `group_levels` (= 8 → df = 7), not `n_re` (would give df = 13).

`phylo_interaction` is left NA (two clades, no single `g`). Any ambiguous/missing
match falls back to the normal quantile and never errors.

## Verification (this Mac, R 4.6, `R_PROFILE_USER=/dev/null Rscript --no-init-file`)

- **Parity** (phylo mu1:x SD, g=8, df=7, seed 730001): engine t-interval
  `[0.71375, 2.34424]` reproduces the post-hoc `exp(m ± qt(.975,7)·s)` to ~1e-16.
- **Non-breaking**: `confint(method="wald")` ≡ `small_sample_df="none"` (`all.equal`
  TRUE); non-SD rows identical between `"none"` and `"group"`.
- **Tests**: `profile|confint|wald` all green; `conversion` = 4 FAIL on **clean
  main and with this change identically** (PASS 6205 both) → the 4 are pre-existing
  (artifact-path `file.path(artifact_parts, …)` construction in
  `test-structured-re-conversion-contracts.R`), NOT introduced here. Flagged for a
  separate fix.

## Evidence the feature is calibrated (fresh recompute, paired z-vs-t on identical fits)

`docs/dev-log/simulation-artifacts/2026-06-27-t-interval-recompute/` (g=8/16/32):

| lane | g | Wald-z | Wald-t (df=g−1) | profile |
|---|---|---|---|---|
| q2 mu-slope SD | 8 | 0.885 | **0.931** | 0.91 |
| q2 mu-slope SD | 32 | 0.944 | 0.956 | 0.95 |
| sigma SD | 8 | 0.975 | 0.999 | 0.96 |

t lifts the under-covering q2 lane toward nominal and converges to z by g=32
(df-narrowness, validated); the cheap quantile swap ≈ the expensive profile.

## Refinement (supersedes the decomposition after-task)

`2026-06-27-t-interval-decomposition.md` recommended adopting t "as the **default**
small-sample interval (closes df-narrowness for ALL lanes)." The fresh paired
recompute shows that is **wrong for the dispersion axis**: sigma SDs already
over-cover under z (0.975 at g=8), so t over-inflates them toward 1.0. Hence the
shipped feature is **opt-in and scoped**, not a default. (Flagged cross-team to
gllvmTMB#565.)

## Boundary

Promotes **no** mission-control cell; `coverage_status` stays `planned` on all
106 cells; `mission_control_ok` green. This is an interval-method addition, not a
support claim. Full nominal at the deployment g=8 still needs the SD-shrinkage
(REML) fix, which remains engine-blocked for biv_gaussian structured RE — t
corrects the reference distribution, not the biased centre.
