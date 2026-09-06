# The three inference capabilities, measured on both engines

Leaf `uncited-inference` of the parity-joint programme, 2026-09-05. This file is
the receipt behind the `Wald SEs and CIs (observed information)`,
`Profile-likelihood CIs` and `Parametric bootstrap CIs` rows of
`docs/design/parity-matrix.md`. Every number below was produced in ONE run of
`tools/parity-uncited-inference.R` on this machine; nothing is quoted from an
earlier leaf.

## What this run was against

| input | value |
|---|---|
| DRM.jl | `aee371cc9627c24945859f4caa749e0d5b691782` (checkout `drmjl-ref-aee371cc`) |
| drmTMB | `2fcbb0fbfa95a40c90adec601889e3834f362682` (`origin/main`, worktree `wt-uncited-inference`) |
| fixture | DRM.jl `test/parity/fixtures/gaussian-locscale/data.csv`, n = 180 (committed, not re-simulated) |
| call | `drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat, engine = <engine>)` |
| env | `OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true`, `pkgload::load_all()` on the worktree |

The programme pin `430ef64cc` was NOT used: it predates DRM.jl #646 and #648
and cannot fit the masked-response route at all. Quote the DRM.jl sha above
whenever you quote a number from this file.

## G1 -- same-target coefficients and logLik

Name-matched, 4 of 4 shared, 0 only-tmb, 0 only-julia.

| coefficient | engine = "tmb" | engine = "julia" | abs diff |
|---|---|---|---|
| `mu:(Intercept)` | 0.34971888063488 | 0.349718880636197 | 1.317280e-12 |
| `mu:x` | -0.647315500654207 | -0.647315500653048 | 1.159184e-12 |
| `sigma:(Intercept)` | -0.202036411066566 | -0.202036411065339 | 1.226880e-12 |
| `sigma:x` | 0.273421904563131 | 0.273421904563985 | 8.544832e-13 |

- coefficient max abs diff: **1.31728e-12**
- logLik: tmb `-215.46254513737`, julia `-215.46254513737`, abs diff **5.68434e-14**
- converged: tmb TRUE, julia TRUE

## G2 -- Wald standard errors (both engines report SEs)

Read as `sqrt(diag(vcov(fit)))`; the bridge's `"<dpar>_<term>"` covariance names
are normalised to the native `"<dpar>:<term>"` spelling before matching.

| coefficient | SE tmb | SE julia | abs diff | rel diff |
|---|---|---|---|---|
| `mu:(Intercept)` | 0.0658538083899558 | 0.0658538086620648 | 2.721090e-10 | 4.132016e-09 |
| `mu:x` | 0.0508374368359872 | 0.0508374334193023 | 3.416685e-09 | 6.720805e-08 |
| `sigma:(Intercept)` | 0.0528349880746957 | 0.0528350049639909 | 1.688930e-08 | 3.196612e-07 |
| `sigma:x` | 0.0509977248043767 | 0.0509977888676252 | 6.406325e-08 | 1.256198e-06 |

- 4 of 4 matched; max abs diff **6.40632e-08**, max rel diff **1.2562e-06**

## G3 -- Wald CIs, target `fixef:mu:x`

- tmb `[-0.746955045919072, -0.547675955389343]`
- julia `[-0.746955039221334, -0.547675962084763]`
- endpoint deltas **6.69774e-09** (lower) / **6.69542e-09** (upper)

## G4 -- profile-likelihood CIs, target `fixef:mu:x`

- tmb `[-0.748655006367853, -0.548137173933176]`, `conf.status = "profile"`
- julia `[-0.748657802907507, -0.548136585070512]`, `conf.status = "profile"`
- endpoint deltas **2.79654e-06** (lower) / **5.88863e-07** (upper)
- PASS at the committed 1e-4 bar: **TRUE**

## G5 -- parametric bootstrap CIs, target `fixef:mu:x`, R = 99, seed = 20260905

- tmb `[-0.753363864652452, -0.538942897768286]`, used 99, failed **0/99**
- julia `[-0.739445948407711, -0.544051720304868]`, used 99, failed **0/99**
- intervals OVERLAP: **TRUE**

The two engines draw replicates from independent RNG streams, so the claim here
is distributional overlap plus a zero failure rate on both sides -- NOT endpoint
equality, and NOT interval coverage.

## G6 -- RED CONTROL (the check can fail)

The same two profile deltas re-checked at a tightened 1e-9 bar:

```
d_profile = 2.79654e-06 5.88863e-07
PASS(tol=1e-9) = FALSE
```

The comparison is live, not vacuous. `tol_ci` is a script argument, not stored
state, so nothing had to be restored afterwards.

## G7 -- the bivariate boundary, measured not asserted

Fixture DRM.jl `test/parity/fixtures/gaussian-bivariate-rho12/data.csv`,
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)`,
`family = biv_gaussian()`, `engine = "julia"`. The fit succeeds;
`model_type = "biv_gaussian"`.

`profile_targets()` returns 9 inventory rows and **0** of them are
`profile_ready`:

```
                     parm profile_ready          profile_note
    fixef:mu1:(Intercept)         FALSE missing_tmb_parameter
              fixef:mu1:x         FALSE missing_tmb_parameter
    fixef:mu2:(Intercept)         FALSE missing_tmb_parameter
              fixef:mu2:x         FALSE missing_tmb_parameter
  fixef:rho12:(Intercept)         FALSE missing_tmb_parameter
 fixef:sigma1:(Intercept)         FALSE missing_tmb_parameter
 fixef:sigma2:(Intercept)         FALSE missing_tmb_parameter
                   sigma1         FALSE missing_tmb_parameter
                   sigma2         FALSE missing_tmb_parameter
```

`confint(method = "profile")` and `confint(method = "bootstrap")` on
`fixef:mu1:x` are both refused by the R side, before any Julia round-trip, with
the identical message:

```
Julia-engine target "fixef:mu1:x" is not ready for profile or bootstrap
intervals.
i Inventory note: "missing_tmb_parameter".
```

The mechanism has a file and a line: `drm_julia_wald_targets()` sets

```r
fixef_profile_ready <- !is_biv && !is.null(object$bridge_payload)
```

at `R/julia-bridge.R:4533`, which is unconditionally FALSE for any bivariate
fit, and `drm_julia_profile_targets_biv()` (`R/julia-bridge.R:3880`) contributes
no SD row when `bridge_payload$tree` is NULL -- always true for a residual-only
bivariate fit, which has no phylogenetic term. This is a route that does not
exist, not a solve that failed.

### G7 RED CONTROL -- the cited line really is the fence

`R/julia-bridge.R:4533` was edited in place, changing only `!is_biv` to `TRUE`:

```r
fixef_profile_ready <- TRUE && !is.null(object$bridge_payload)  # RED CONTROL
```

Re-running the same live bivariate fit with nothing else changed:

```
RED CONTROL: profile_ready TRUE count = 7 of 9
                     parm profile_ready          profile_note
    fixef:mu1:(Intercept)          TRUE                 ready
              fixef:mu1:x          TRUE                 ready
    fixef:mu2:(Intercept)          TRUE                 ready
              fixef:mu2:x          TRUE                 ready
  fixef:rho12:(Intercept)          TRUE                 ready
 fixef:sigma1:(Intercept)          TRUE                 ready
 fixef:sigma2:(Intercept)          TRUE                 ready
                   sigma1         FALSE missing_tmb_parameter
                   sigma2         FALSE missing_tmb_parameter
RED CONTROL confint: NO REFUSAL; returned [ 0.19889327638842 , 0.460707537305189 ] status= profile
```

That one token is the whole fence for the 7 fixed-effect rows: flipping it makes
`confint(method = "profile")` return an interval instead of refusing. The
remaining two rows are fenced elsewhere and by design -- `sigma1` / `sigma2` are
the response-scale display aliases built by `drm_julia_wald_scale_targets()`,
documented Wald-only and deliberately not wired into the profile / bootstrap
inventory (`R/julia-bridge.R:4583`).

This control shows only WHERE the fence is. It says nothing about whether the
interval the patched build returned is correct -- no comparator was run against
it, and it is exactly the interval PR #1187 exists to produce properly.

The file was restored with `git show HEAD:R/julia-bridge.R > R/julia-bridge.R`;
its sha256 before the plant and after the restore is identical
(`36fb2decc42edb520e4e1998c09be9d74b01b143e180a205491223c1cba204f7`), and
`git diff -- R/` is empty.

**What a user should do instead:** on a bivariate Julia fit, use
`confint(method = "wald")`, which is served by the same
`drm_julia_wald_targets()` table and does not require a profile-ready target; or
fit with `engine = "tmb"`, where the native profile route covers bivariate
targets. Open PR #1187 adds the missing bivariate profile/bootstrap route to the
bridge.

## What these numbers do NOT cover

- **Interval coverage.** Fenced out of this programme by D-181 #2. Nothing here
  is a calibration claim; capability parity and coverage are different
  questions and conflating them is the specific error this leaf avoided.
- **Routes other than `base_gaussian_location_scale`.** One fixture, one draw,
  one target (`fixef:mu:x`). Other routes carry their own per-row receipts.
- **Bivariate profile or bootstrap intervals.** Structurally absent; see G7.
- **Bootstrap under a preserved response mask.** drmTMB #1188: replicates do not
  preserve the mask under `missing = miss_control(response = "include")`. The
  default `response = "drop"` is unaffected. Open PR #1226.
- **The upstream interval receipt.** DRM.jl's
  `docs/dev-log/evidence/parity-intervals.tsv` still records `profile` and
  `bootstrap` on `gauss_locscale_fe` as `UNSUPPORTED_JULIA` at
  `drmtmb_version = 0.7.0` -- written before the per-coefficient route existed.
  It understates the engine, and it is keyed by `cell_id` with no
  `capability_id` column, so it cannot be joined by a capability_id-keyed
  reader. Refreshing it needs DRM.jl's own `tools/parity_intervals.R` run
  against a current INSTALLED drmTMB, which this leaf did not do: that script
  reads `.libPaths()`, and re-installing drmTMB there would have changed shared
  state other lanes on this machine are using.

## Reproducing

```
OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true \
  DRMTMB_WT=<drmTMB worktree> \
  DRM_JL_PATH=<DRM.jl checkout> DRM_JL_PHYLO_PATH=<same> \
  Rscript tools/parity-uncited-inference.R
```
