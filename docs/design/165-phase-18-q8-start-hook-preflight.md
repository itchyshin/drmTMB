# Phase 18 Q8 Start-Hook Preflight

This note turns the q8 Hessian rescue result into an implementation preflight.
The reader is the R package contributor deciding where a staged-start rescue can
enter the current `drmTMB()` path without changing public formula grammar or
opening a broad `start =` API before the contract is reviewed.

## Current Source Facts

The q8 surface is the ordinary bivariate Gaussian all-endpoint block:

```r
bf(
  mu1 = y1 ~ x + (1 + x | p | id),
  mu2 = y2 ~ x + (1 + x | p | id),
  sigma1 = ~ x + (1 + x | p | id),
  sigma2 = ~ x + (1 + x | p | id),
  rho12 = ~ 1
)
```

Location means `mu1` and `mu2`, scales `sigma1` and `sigma2`, and residual
coscale `rho12` are separate distributional parameters. Residual `rho12` is a
within-observation residual correlation, not one of the 28 q8 group-level
random-effect correlations.

The current code path builds a bivariate specification, calls
`biv_gaussian_start()`, adds covariance-probe placeholders with
`add_covariance_probe_parameter(spec)`, and then calls `TMB::MakeADFun()` with
`parameters = spec$start`. That means the narrow internal hook point is after
`add_covariance_probe_parameter(spec)` and before `TMB::MakeADFun()`.

The existing start logic is intentionally simple. `biv_gaussian_start()` uses
response-specific OLS starts for `beta_mu1` and `beta_mu2`, residual SD starts
for `beta_sigma1` and `beta_sigma2`, and a clipped residual correlation start
for `beta_rho12`. For q>2 covariance blocks,
`covariance_block_re_start()` starts latent effects `u_re_cov` at zero, starts
`log_sd_re_cov` from endpoint scale heuristics, and starts `theta_re_cov` at
zero.

Public start-like names are still reserved by the optimizer contract tests:
`start`, `starts`, `start_from`, `warm_start`, `warm_starts`,
`warm_start_from`, `map`, `fixed`, and multi-start/fallback names cannot be
passed through `control`. This preflight keeps that boundary. The next q8 rescue
should not add user-facing syntax in the same change.

## Internal Hook Contract

The first implementation should be an internal spec-level helper, not a public
argument:

```r
spec <- add_covariance_probe_parameter(spec)
spec <- drm_apply_start_override(spec, override, provenance = provenance)
obj <- TMB::MakeADFun(parameters = spec$start, ...)
```

The private helper now exists as `drm_apply_start_override()`, and the ordinary
fit tail is factored into `drm_fit_spec()` so internal tooling can fit a
prepared specification with an override. The ordinary `drmTMB()` path calls the
override helper with no override, so the default cold-start path is unchanged
and no public start argument is exposed. When internal q8 diagnostic code
supplies an override, the helper must:

1. accept only named TMB parameter blocks already present in `spec$start`;
2. reject unknown names and length mismatches before `TMB::MakeADFun()`;
3. preserve `spec$map`, `spec$random_names`, and covariance-probe placeholders;
4. leave mapped or absent parameters unchanged;
5. record provenance and an applied-count table on `spec$start_override`.

The no-op override is part of the tested contract: applying an empty override
gives the same `spec$start` as the current cold path. Focused tests also check
unknown names, wrong lengths, non-finite values, duplicate names, mapped
parameter preservation, provenance recording, fixed-effect inheritance by
column name, endpoint-SD inheritance by q>2 member key, and optional packed
`theta_re_cov` inheritance through a validated pair-key mapper.

## Staged-Start Ladder

The staged ladder should stay close to fitted surfaces that already exist:

1. fixed-effect bivariate Gaussian location-scale model;
2. q4 location block for `mu1` and `mu2`;
3. q6 location block when the target contains additional location endpoints;
4. q8 all-endpoint block with inherited starts only where names and block
   members match.

The staged-start comparison must use paired seeds and identical data-generating
conditions. For each diagnostic condition, report cold q8 versus staged q8 on
convergence, `TMB::sdreport()` status, maximum gradient, minimum q8 correlation
eigenvalue, q8 correlation condition number, warning text, and elapsed time.

## Parameter Map

Fixed effects are the safest first inheritance target. Copy `beta_mu1`,
`beta_mu2`, `beta_sigma1`, `beta_sigma2`, and `beta_rho12` only by
distributional parameter and model-matrix column name. If a target column has no
source column, keep the current cold-start value.

Endpoint SD starts can be copied by covariance-member keys. The key should
include block label, group, distributional parameter, coefficient name, and
member order as recorded in the q>2 covariance registry. A q4 or q6 source can
initialize the common `log_sd_re_cov` members in q8; target-only members should
use the current `covariance_block_re_start()` heuristic.

Packed q>2 correlation starts need a stricter gate. `theta_re_cov` is passed to
`density::UNSTRUCTURED_CORR_t`, then converted to a correlation matrix. The
mapper must never copy `theta_re_cov` by raw position from a smaller source
block into q8. The implemented gate maps source pair labels into the target
q8 pair table, shrinks the source correlations, regularizes the target
correlation matrix if needed, packs it back to TMB's unstructured-correlation
theta scale, and verifies that unpacking reconstructs the intended target
matrix. If a diagnostic runner does not request this path,
`copy_theta_re_cov = FALSE` keeps target `theta_re_cov` at zero.

Conditional random-effect modes should also stay zero in the first hook. Copying
`u_re_cov` from smaller models would require identical group levels, identical
member keys, and a clear conditional-mode interpretation after the covariance
dimension changes. That is useful later, but it is not needed for the first
Hessian-rescue test.

## Required Tests Before A Grid

The first implementation slices now cover the validator-level and source-mapper
checks before any larger q8 grid:

1. the public reserved-name tests still reject `start`, `warm_start`, and
   `map`;
2. unknown start names, wrong-length overrides, duplicate names, and non-finite
   values fail before `TMB::MakeADFun()`;
3. an empty override leaves the current cold `spec$start` unchanged;
4. mapped slots remain unchanged and are counted as fixed in
   `spec$start_override$applied`;
5. fixed-effect starts are copied by model-matrix column names, not by position;
6. q>2 member keys are stable for the q4-to-q8 endpoint fixture;
7. `theta_re_cov` is copied only through the validated pair-key/packing helper,
   otherwise it stays at zero.

Items 5-7 are now source-tested by `drm_qgt2_staged_start_override()` and
`correlation_matrix_to_tmb_unstructured_theta()`. The default still leaves
`theta_re_cov` neutral; `q4_theta_staged` is an explicit diagnostic strategy,
not the ordinary q8 start.

The first paired pilot is recorded in
`docs/dev-log/simulation-artifacts/2026-06-08-q8-staged-start-pilot/`. On the
low-replication diagnostic condition `q8_diag_001` with seed `20260641`, the
cold q8 fit returned optimizer convergence code 1, objective 232.4051, maximum
gradient 1.78e-4, minimum q8 correlation eigenvalue 5.57e-14, and condition
number 5.90e13. The q4-staged q8 fit on the same data returned convergence
code 0, objective 232.3794, maximum gradient 1.22e-4, minimum q8 correlation
eigenvalue 2.26e-7, and condition number 1.43e7. The source matched the four
intercept endpoint SDs and left the four slope endpoint SDs at cold starts;
`theta_re_cov` stayed on the target neutral start.

The follow-up fallback pilot is recorded in
`docs/dev-log/simulation-artifacts/2026-06-08-q8-profile-bootstrap-fallback-pilot/`.
Across five hard diagnostic rows, q4-staged q8 starts rescued the
low-replication row again, but did not rescue the weak-SD-ratio or residual
`rho12` stress rows and worsened the high-correlation row relative to the cold
start. The `se = TRUE` comparison left weak-SD-ratio nonconverged with
`pdHess = FALSE`; the high-correlation cold start returned convergence code 0
and `pdHess = TRUE`, while the staged high-correlation fit returned convergence
code 1 and `pdHess = FALSE`. That pattern argues against promoting the current
q4-staged mapper as a general Hessian rescue.

The same fallback pilot separates the interval paths. Endpoint profiles can work
for direct q8 SD targets: the staged low-replication fit returned a 70% profile
interval of 0.239 to 0.359 for the first `sd:mu` intercept target. The generic
public bootstrap route did not rescue that fit, returning 0/3 successful refits
for the same direct target. Derived q8 group-level correlations remain outside
`confint(..., method = "bootstrap")`; a correlation interval would need a
custom derived-statistic bootstrap artifact.

The 2026-06-09 usability pilot is recorded in
`docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-pilot/`. It compared
cold, q4 SD-staged, and q4 theta-staged starts on the five hard rows and a
sample-size ladder. This changed the q8 conclusion from "rescued or not" to
"sample-size and conditioning dependent." At 96 groups x 12 repeats, cold and
SD-staged `se = TRUE` fits reported `pdHess = TRUE` and q8 correlation
condition numbers near 1.27e6 and 6.11e5, much better than the baseline row's
near-singular matrices. Those fits still returned optimizer code 1 under the
800-iteration budget. Theta-staged starts helped the weak-SD row and one low
sample-size row, but they were not uniformly better and had `pdHess = FALSE` on
the high sample-size `se = TRUE` row.

The 2026-06-09 inference pilot is recorded in
`docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-inference-pilot/`.
It adds a bounded developer lane for direct endpoint-SD profiles and derived
q8-correlation bootstrap refits. On the weak-SD row, one direct SD profile
returned a 70% interval of 0.135 to 0.194, while the two-refit
derived-correlation bootstrap produced no interval rows because one refit was
nonconverged and one errored.

The 2026-06-09 optimizer-budget pilot is recorded in
`docs/dev-log/simulation-artifacts/2026-06-09-q8-optimizer-budget-pilot/`.
It reran the high sample-size row with `se = TRUE`, the same cold, q4
SD-staged, and q4 theta-staged starts, and 800 versus 1600
evaluations/iterations. The larger budget did not change convergence status or
the printed diagnostics: cold and SD-staged fits stayed at convergence code 1
with `pdHess = TRUE`, while theta-staged fits stayed at convergence code 1 with
`pdHess = FALSE`. This closes the simple "increase the `nlminb` budget" slice
for this high-replication row.

## Decision

The private start-override foundation, q4-to-q8 SD mapper, q4-to-q8 theta
mapper, sample-size usability pilot, direct-SD profile artifact, and
derived-correlation bootstrap artifact are implemented and source-tested. Q8
remains fitted and diagnostic-artifact ready only. It is not coverage-ready or
power-ready until a deliberately sized row also shows stable optimizer
convergence, positive-Hessian diagnostics, and interval behaviour on the targets
that will enter the simulation. The high sample-size row improved Hessian and
conditioning behaviour, but doubling the single-optimizer budget did not change
optimizer convergence.
