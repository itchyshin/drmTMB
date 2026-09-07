# Mask-preserving bootstrap replicates: mechanism, fix, and re-measurement (#1188)

Leaf `g3-bootstrap-mask`, measured 2026-09-05.

- drmTMB worktree: `claude/parity-g3-bootstrap-mask` off `origin/main` `eccb10299`.
- DRM.jl worktree: `claude/parity-g3-bootstrap-mask` off `origin/main` `aee371cc9`.
- Everything below was measured in this run. `NOT_CRAN=true`,
  `OPENBLAS_NUM_THREADS=1`, at most 4 cores.

## Why the DRM.jl pin was not used

The brief's pin `drmjl-430ef64cc` predates DRM.jl #648, which is what made a
masked-response bootstrap run at all (before it, every replicate died in
`_simulate_once` with `DimensionMismatch`). A calibration measurement is
impossible on a route that throws on every replicate, so the Julia half of
this receipt was measured against DRM.jl `origin/main` `aee371cc9` instead.
Recorded here as a deviation, not hidden.

## 1. The mechanism, verified directly

Fixture: `y = 0.3 + 0.5x + N(0,1) * exp(0.1x)`, `n = 60`, `set.seed(1)`,
`bf(y ~ x, sigma ~ x)`, `family = gaussian()`,
`missing = miss_control(response = "include")`, first `k` responses set to `NA`.

At `k = 18`, `engine = "tmb"`, before any change:

```
SEED FIT nobs: 42
SEED FIT rows in object$data: 60
SEED FIT NA count in object$data$y: 18
simulate() rows = 60  NA count = 0
bootstrap_response_data() replicate rows = 60  NA in y = 0
REPLICATE refit nobs = 60
```

The seed fit observed 42 rows; every replicate refitted on 60. The diagnosis
in #1188 is correct.

**Refinement the issue did not state.** The defect is confined to
`missing = miss_control(response = "include")`. Under the default
`response = "drop"` the fit stores complete-cased data, measured on the same
fixture at `k = 12`:

```
DROP fit: nobs 48   rows(fit$data) 48   NA 0
```

so there is no mask to lose and the replicate already matched the seed fit.
The fix is therefore a strict no-op on every non-`include` fit.

## 2. Measured coverage, before and after

The honest question is not the width ratio on one dataset but coverage. Truth
`beta_mu:x = 0.5`; `S = 200` independent datasets per cell (seeds
`100001..100200`); `B = 99` bootstrap replicates per dataset with a fixed
per-dataset seed; nominal 95% percentile interval on `fixef:mu:x`;
`engine = "tmb"`. Both arms use the SAME datasets and the SAME bootstrap
seeds, so the comparison is paired.

| masked | before | MCSE | after | MCSE | Wald reference | MCSE |
| --- | --- | --- | --- | --- | --- | --- |
| 6 (10%) | 0.8950 | 0.0217 | 0.9100 | 0.0202 | 0.9200 | 0.0192 |
| 18 (30%) | 0.8200 | 0.0272 | 0.8950 | 0.0217 | 0.9250 | 0.0186 |
| 30 (50%) | 0.7200 | 0.0317 | 0.9100 | 0.0202 | 0.9150 | 0.0197 |

Paired (exact McNemar on the discordant datasets):

| masked | diff | gained | lost | p |
| --- | --- | --- | --- | --- |
| 6 (10%) | +0.0150 | 4 | 1 | 0.375 |
| 18 (30%) | +0.0750 | 16 | 1 | 2.75e-04 |
| 30 (50%) | +0.1900 | 38 | 0 | 7.28e-12 |

**At 10% masking the improvement is NOT supported by the Monte Carlo error**
(4 gains against 1 loss, p = 0.375). Only the 30% and 50% cells carry the
claim. `S = 200` was chosen so each cell stayed under the 30-minute run bar
(measured 106-117 s per cell); a larger `S` would be needed to resolve the
10% cell, and this receipt does not resolve it.

Mean interval widths make the mechanism visible directly:

| masked | before boot | after boot | Wald |
| --- | --- | --- | --- |
| 6 (10%) | 0.5135 | 0.5414 | 0.5363 |
| 18 (30%) | 0.5023 | 0.6163 | 0.6073 |
| 30 (50%) | 0.4843 | 0.7209 | 0.7150 |

The pre-fix bootstrap width is flat at ~0.49 across the missing fraction --
it cannot see the mask, because its replicates never had one -- while the
Wald width grows from 0.536 to 0.715. Post-fix the bootstrap width tracks the
Wald width at every fraction.

Note that the post-fix bootstrap coverage (0.910 / 0.895 / 0.910) is still
below the nominal 0.95, but so is Wald (0.920 / 0.925 / 0.915) on the same
datasets. That residual is a small-sample property of an `n = 60`
location-scale fit, not a missing-data effect, and this fix does not claim
to remove it.

## 3. Single-fixture spread, before and after

`set.seed(1)` fixture, `R = 199`, seed `20260905`, `engine = "tmb"`. Wald SE
is derived from the Wald interval as `width / (2 * qnorm(0.975))`.

| masked | Wald SE | before boot sd | before sd/SE | after boot sd | after sd/SE |
| --- | --- | --- | --- | --- | --- |
| 0 (control) | -- | -- | (identical) | -- | (identical) |
| 6 (10%) | 0.1747 | 0.1359 | 0.7781 | 0.1453 | 0.8315 |
| 18 (30%) | 0.1930 | 0.1263 | 0.6542 | 0.1614 | 0.8361 |
| 30 (50%) | 0.2080 | 0.1312 | 0.6307 | 0.2090 | 1.0048 |

The `k = 0` control produced byte-identical before/after rows, confirming the
change is inert without a mask. The relative standard error of a bootstrap sd
at `R = 199` is about `1 / sqrt(2 (R - 1))` = 5%, so the post-fix figures
(-16.9% / -16.4% / +0.5%) are not all one constant; what they no longer show
is the monotone worsening with the missing fraction that the pre-fix arm has
(-22.2% / -34.6% / -36.9%).

These single-fixture numbers differ from those recorded in #1188
(-7.35% / -26.54% / -40.02%). The difference is expected and is not a
contradiction: #1188 quotes a bootstrap **sd** against a **Wald SE** on a
different RNG stream, and a one-dataset spread ratio is a noisy statistic.
The coverage table in section 2 is the load-bearing measurement here.

## 4. `engine = "julia"`, end to end through the bridge

Same fixture at `k = 30` (50% masked), `R = 99`, seed `20260905`,
`DRM_JL_PATH` pointed at the DRM.jl worktree above.

```
ARM: after  | engine julia seed fit nobs = 30 | converged = TRUE
bootstrap: 99 used, 0 failed, status bootstrap
ARM=after  wald width=0.815275 | boot width=0.875403 | width_ratio=1.0738

ARM: before | engine julia seed fit nobs = 30 | converged = TRUE
bootstrap: 99 used, 0 failed, status bootstrap
ARM=before wald width=0.815275 | boot width=0.474775 | width_ratio=0.5823
```

The `before` arm was produced by disabling the mask restoration inside
`_restore_response_mask!` and re-running; the file was restored
byte-identically afterwards (sha256 `edb7caee...`).

## 5. Red controls

**R.** With `bootstrap_restore_response_mask()` reduced to `return(values)`,
`tests/testthat/test-bootstrap-response-mask.R` fails 9 assertions, including:

```
Expected `nobs(refit)` to be identical to `nobs(fit)`.
  `actual`: 60
`expected`: 30

Expected `ratio` > 0.75.
Actual comparison: 0.65 <= 0.75
```

Restored byte-identically (sha256 `33ca7e37...` before and after).

**Julia.** With the mask branch in `_restore_response_mask!` disabled,
`test/test_bridge_response_mask_inference.jl` fails 2 of 24:

```
Expression: findall(isnan, datab.y) == findall(isnan, y_masked)
 Evaluated: Int64[] == [1, 2, 3, 4, 5, 6]

Expression: nobs(drm(f, Gaussian(); data = datab)) == n_observed
 Evaluated: 60 == 54
```

Restored byte-identically (sha256 `edb7caee...` before and after).

## 6. Suites run

| suite | result |
| --- | --- |
| drmTMB, 12 files touching `method = "bootstrap"` | 1534 pass, 0 fail, 0 error, 1 skip (a live-Julia test) |
| drmTMB, 19 missing-response / missing-data files | 1151 pass, 0 fail, 0 error, 4 skips (live-Julia) |
| DRM.jl, 14 bootstrap files | 461 pass, 2 fail |

The 2 DRM.jl failures are in `test_bootstrap_marginal.jl`
(`#461 a degenerate optimum is not reported as converged`, `Evaluated: 59 == 60`)
and are **pre-existing on `origin/main`**: restoring `src/inference.jl` from
`HEAD` and re-running that file alone reproduces the identical 4 pass / 2 fail.
Not caused by this change and not fixed here.

## 7. Known consequence, not fixed here

DRM.jl's `drm` warns whenever it drops missing-response rows (the #258
"never silent" contract). Before this change a replicate table carried no
missing values, so a bootstrap warned once (for the seed fit); now every
replicate legitimately drops rows and warns, so `B = 999` emits ~1000
warnings. Suppressing replicate-level logs was considered and rejected: the
same channel carries the saturated-fit (`residual dof 0`) warning, which is
exactly what a user needs to see when replicates on a heavily masked fit
degenerate. A scoped fix belongs with the owner of the #258 contract.
