# Profile-Likelihood Confidence Intervals

Profile-likelihood confidence intervals should become part of `drmTMB` once
random-effect variance components, phylogenetic effects, spatial effects, and
double-hierarchical models are stable enough to need serious inference on
variance and correlation quantities.

## Current Status

Profile-likelihood confidence intervals are partly implemented. `confint(fit)`
returns Wald fixed-effect intervals by default, and
`confint(fit, parm = "fixef:mu:x", method = "profile")` profiles explicit
direct targets. Direct ordinary random-effect SD, ordinary random-effect
correlation, and phylogenetic `mu` SD targets are transformed back to the
response scale. Constant `sigma`, `sigma1`, `sigma2`, and residual `rho12` can
also be profiled as direct response-scale targets with names such as
`parm = "sigma"` or `parm = "rho12"`. When `sigma`, `sigma1`, `sigma2`, or
`rho12` depends on predictors, use `confint()` with `method = "profile"` and
`newdata` to profile each supplied row. The corresponding `rho12` call profiles
the fixed-effect linear predictor for that row and transforms the interval to
the response scale. The first direct covariance rows are also profile-ready:
the univariate and same-response bivariate `mu`/`sigma` random-intercept
correlations in `corpars$mu_sigma`, the bivariate `mu1`/`mu2` random-intercept
correlation in `corpars$mu`, and the bivariate `sigma1`/`sigma2`
random-intercept correlation in `corpars$sigma`. The fitted bivariate
phylogenetic `mu1`/`mu2` SDs and mean-mean correlation are also profile-ready
direct targets, and the first smoke test verifies that the phylogenetic
correlation interval is transformed back to the bounded correlation scale.
`summary(conf.int = TRUE, method = "profile", ci_parm = ...)` can attach these
direct profile intervals to the same parameter rows shown in
`summary(fit)$parameters`. `corpairs(conf.int = TRUE)` can attach
profile-likelihood intervals to fitted correlation-pair rows when their target
is profile-ready, and it records explicit status values for rows that are not
ready yet. `profile_targets(fit)` lists fitted-object target names and
readiness notes; row-specific `newdata` targets are generated at call time.
Transformed ordinal, modelled group-SD, custom multi-row contrasts, conditional
random-effect mode intervals, and derived summary profile intervals remain
planned.

## Phase 6 Slice 51 Target Audit

Slice 51 records the profile-inference boundary before adding more intervals.
The package already has profile code, but the next work should harden the
target inventory and output contracts rather than add undocumented profile
paths.

| Surface | Current interval status | Next Phase 6 work |
| --- | --- | --- |
| Fixed-effect coefficients | Wald intervals by default when `TMB::sdreport()` is computed; selected direct profile targets are available by explicit `fixef:<dpar>:<coef>` names. | Audit target names across families and improve failure messages for unsupported targets. |
| Constant residual scale and residual `rho12` | Direct profile intervals are available for constant `sigma`, `sigma1`, `sigma2`, and `rho12`. | Keep response-scale transformations explicit and test boundary behavior. |
| Predictor-dependent response-scale values | `confint(..., method = "profile", newdata = ...)` profiles supplied rows for scale, residual `rho12`, and fitted q2 `corpair()` values. | Slice 54 adds focused tests for bivariate `sigma1`/`sigma2`, q2 ordinary and phylogenetic `corpair()` rows, and ambiguous `newdata` requests. |
| Ordinary random-effect SDs and correlations | Selected direct SD and correlation targets are profile-ready and appear in `profile_targets()`. | Align `summary()`, `corpairs()`, and target names for every fitted direct registry row. |
| Phylogenetic SDs and q2 correlations | Implemented direct targets include the first bivariate phylogenetic `mu1`/`mu2` SD and mean-mean correlation path. | Keep phylogenetic targets separate from residual `rho12`; add clearer diagnostics for weak SDs and boundary correlations. |
| Spatial SDs | The first univariate coordinate-spatial `mu` SD target is direct and profile-ready where the fitted object retained the TMB object. | Add coverage that spatial profile labels and diagnostics stay distinct from phylogenetic labels. |
| q4 ordinary and phylogenetic correlations | Point estimates are reported, but q4 unstructured-correlation rows are derived targets and not direct profile-ready. | Preserve explicit unavailable statuses until a direct or fix-and-refit derived method exists. |
| ICCs, repeatability, phylogenetic signal, and other nonlinear summaries | Slice 56 adds point-estimate derived-summary rows for simple Gaussian random-intercept repeatability and phylogenetic signal. | Design a fix-and-refit or reparameterized profile path before claiming derived confidence intervals. |

The linked Phase 6 tracking issue is
<https://github.com/itchyshin/drmTMB/issues/30>. The companion Phase 6b
tutorial issue is <https://github.com/itchyshin/drmTMB/issues/31>, because
profile intervals will need examples that show what is profile-ready and what
is status-only.

## Slice 164 Refreshed Target Inventory

Slice 164 refreshes the profile-target map before the profile/bootstrap revisit
continues. This is an inventory update, not new inference code.

| Surface | Public target pattern | Direct profile status | Interval status to show elsewhere |
| --- | --- | --- | --- |
| Fixed-effect coefficients | `fixef:<dpar>:<coef>` | Direct and profile-ready when the TMB object is retained. `confint(fit)` still returns Wald intervals by default. | `wald` for default fixed-effect CIs; `profile` when explicitly profiled. |
| Constant distributional parameters | `sigma`, `sigma1`, `sigma2`, `rho12` | Direct only when the corresponding formula is constant. | `profile_ready` in summaries unless requested; `profile` after a successful profile. |
| Predictor-dependent scale or residual correlation rows | Generated by `confint(..., method = "profile", newdata = ...)` for `sigma`, `sigma1`, `sigma2`, and `rho12`. | Row-specific direct linear-combination profiles are generated at call time, not listed as fitted-object targets. | `newdata_required` for fitted surface summaries until a supplied row is profiled. |
| Ordinary random-effect SDs and correlations | `sd:mu:<term>`, `sd:sigma:<term>`, `cor:mu:<pair>`, `cor:mu_sigma:<pair>` | Direct where the fitted block maps to a stored SD or correlation parameter. | `profile_ready` or `profile`; unavailable rows must explain the missing direct target. |
| Modelled group-level SD surfaces | `fixef:sd(group):<coef>` for the scale-model coefficients; fitted `sd(group)` rows are derived surfaces. | Coefficients are direct; fitted group-SD rows are derived and not direct profile targets. | `wald_unavailable` or `derived_interval_unavailable`, depending on the table. |
| Bivariate q2 random-effect covariance rows | `sd:mu:mu1:<term>`, `sd:mu:mu2:<term>`, `cor:mu:<pair>`, and matching `sigma1`/`sigma2` rows where implemented. | Direct for the implemented q2 block parameters. | `profile_ready` or `profile` for direct rows. |
| q4 ordinary or phylogenetic covariance rows | `corpairs()` and covariance-summary rows, but no direct q4 public profile target for derived unstructured correlations yet. | Derived, because reported endpoint correlations are functions of a larger covariance parameterization. | `derived_interval_unavailable`. |
| Phylogenetic and spatial SDs | `sd:mu:phylo(1 | species)` and `sd:mu:spatial(1 | site)` where the fitted object exposes those labels. | Direct for the implemented univariate structured SD paths and for fitted q2 phylogenetic mean-mean rows already covered by tests. | `profile_ready` or `profile`; weak-SD diagnostics still matter. |
| Derived summaries | `derived:repeatability(group)`, `derived:phylogenetic_signal(species)`, and future nonlinear summaries. | Derived and not direct profile-ready. | `derived_interval_unavailable` until a fix-and-refit or reparameterized derived-profile method exists. |
| Ordinal cutpoint internals | `ordinal:theta_ord:<cutpoint>` | Direct internal targets, but not yet a polished response-scale tutorial interval. | Profile-capable internals; transformed ordinal summaries remain later work. |

The inventory rule for the next slices is simple: profile-ready means a direct
target maps to a current TMB parameter or linear combination and the fitted
object retained the TMB object. Predictor-row profiles are valid only after
the user supplies `newdata`; derived summaries must stay status-only until a
validated derived interval method exists.

## Slices 165-168 Profile Example Bridge

Slices 165-168 turn the refreshed inventory into the examples users should see
before the bootstrap and derived-interval revisit. They do not add a new profile
engine. They pin the boundary between direct fitted-object targets, row-specific
`newdata` targets, and derived rows that still need a later method.

Slice 165 records row-specific scale and residual-correlation profiles as the
standard examples for predictor-dependent distributional parameters:

```r
confint(fit, parm = "sigma", method = "profile", newdata = grid)
confint(fit_biv, parm = "sigma1", method = "profile", newdata = grid)
confint(fit_biv, parm = "sigma2", method = "profile", newdata = grid)
confint(fit_biv, parm = "rho12", method = "profile", newdata = grid)
```

Slice 166 keeps constant residual scale separate from predictor-dependent scale.
When the formula is `sigma ~ 1`, `parm = "sigma"` is a fitted-object target and
can be requested through `summary(conf.int = TRUE, method = "profile",
ci_parm = "sigma")` or `confint(fit, parm = "sigma", method = "profile")`.
When the formula is `sigma ~ x`, the response-scale target must be a supplied
row. In both cases, output must expose `profile.boundary` and `profile.message`
so users can identify one-sided or near-boundary intervals.

Slice 167 uses the exact `profile_targets()` row for direct random-effect SDs.
Intercept-only blocks can use short names such as `sd:mu:(1 | id)`, while
random-slope blocks keep the coefficient suffix, for example
`sd:mu:(1 + x | p | id):x`.

Slice 168 gives correlation examples without merging correlation layers.
Residual `rho12` is a distributional residual-correlation target; group-level,
location-scale, phylogenetic, or spatial random-effect correlations are separate
latent correlation rows such as `cor:mu:cor((Intercept),x | p | id)`,
`cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`, or
`cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)`. Only rows
marked `profile_ready` by `profile_targets()` should be requested as direct
profile intervals.

## Slices 169-176 Interval-Readiness Gate

Slices 169-176 close the profile/bootstrap revisit before the Gaussian
random-slope block. The implemented claim is narrower than "all intervals are
done": direct Wald and profile intervals have a stable status vocabulary, while
derived q4 and bootstrap intervals remain blocked.

Slice 169 fixes the q4 boundary. Ordinary and phylogenetic q4 endpoint
correlations are reported from a fitted four-dimensional covariance block. A
reported endpoint correlation is:

```text
rho_ij = Sigma[i, j] / sqrt(Sigma[i, i] * Sigma[j, j])
```

and a reported covariance product is:

```text
cov_ij = sd_i * sd_j * rho_ij
```

Those rows are functions of several optimized covariance coordinates rather
than one direct atanh-correlation parameter. Until a reparameterized or
fix-and-refit derived-profile method exists, q4 correlations and covariance
products must stay `derived_interval_unavailable`.

Slice 170 audits parametric bootstrap feasibility. A safe bootstrap interval
method needs four pieces before it can become a public `method` value:

1. a deterministic simulation-and-refit harness that preserves formula
   preprocessing, offsets, known covariance, structured effects, and
   memory-light controls;
2. a target extractor that returns the same target names and row order as
   `confint()`, `summary()`, `corpairs()`, and prediction tables;
3. a failure ledger for non-convergence, missing covariance, boundary fits, and
   failed target extraction;
4. runtime controls and reproducibility rules for long bootstrap runs.

That audit does not pass yet for a package-level bootstrap API. Therefore
Slices 171-172 do not add `method = "bootstrap"` or bootstrap interval-status
columns. Requests for `method = "bootstrap"` or
`method = "parametric_bootstrap"` now fail before fitting intervals, with a
message that current methods are `wald` and `profile`.

Slice 173 keeps the evidence target modest. The focused tests for this gate
check the status vocabulary, unsupported-bootstrap errors, q4 derived status
rows, and the existing direct profile paths. Coverage simulations comparing
Wald, profile, and bootstrap intervals remain a later long-run simulation task.

Slice 174 records diagnostics boundaries. Profile rows can report
`profile.boundary` and `profile.message`; failed profile construction names
boundary, one-sided, non-monotone, and failed-inner-optimization profiles as
possible causes. Failed bootstrap is not a table status yet because bootstrap
requests do not enter an interval table.

Slice 175 centralizes the current interval vocabulary with internal helpers:

```text
interval_status_levels()
interval_source_levels()
```

The current status values are `wald`, `profile`, `profile_ready`,
`newdata_required`, `derived_interval_unavailable`, `wald_unavailable`,
`target_unavailable`, `profile_unavailable`, and `not_requested`. The current
interval-source values are `wald`, `profile`, and `not_available`.

Slice 176 closes this gate by keeping the next work honest: derived q4
intervals and bootstrap intervals are not implemented, but their absence is now
documented, tested at the method boundary, and visible in status-bearing output.

The first implementation must therefore start from a stable target inventory,
not from ad hoc parameter names in the C++ template. Public targets should be
named using user-facing quantities:

```text
fixef:mu:x
fixef:sigma:x
sigma
sigma1
sigma2
sd:mu:(1 | id)
sd:sigma:(1 | id)
sd:mu:phylo(1 | species)
sd:mu:mu1:phylo(1 | species)
cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)
cor:mu:cor((Intercept),x | id)
cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)
cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)
fixef:rho12:(Intercept)
rho12
```

These targets use labels stored in the fitted object, such as `sdpars` and
`corpars`, not the full model-building syntax. For example,
`sd:mu:phylo(1 | species)` identifies the fitted phylogenetic standard
deviation even though the original formula must provide the tree object through
syntax such as `phylo(1 | species, tree = tree)`.
For the first bivariate phylogenetic location slice,
`sd:mu:mu1:phylo(1 | species)` and `sd:mu:mu2:phylo(1 | species)` identify the
two fitted phylogenetic location SDs, while
`cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)` identifies
the phylogenetic mean-mean correlation. These names remain separate from the
residual target `rho12`.

Those names can then map internally to TMB parameters such as `beta_mu`,
`beta_sigma`, `log_sd_mu`, `log_sd_sigma`, `log_sd_phylo`, `eta_cor_mu`,
`eta_cor_mu_sigma`, `beta_sd_mu`, and `beta_rho12`. The short `sigma`,
`sigma1`, `sigma2`, and `rho12` targets are available only when the
corresponding model formula is constant. Predictor-dependent scale and
residual-correlation models expose their link-scale coefficients in
`profile_targets(fit)` and support row-specific response-scale profiles through
`newdata`; arbitrary contrasts remain planned.

## Phase 6 Slice 52 Target Namespace Contract

Slice 52 turns the target inventory into a small tested contract. Every row in
`profile_targets(fit)` must use these public columns:

```text
parm
target_class
dpar
term
tmb_parameter
index
estimate
link_estimate
scale
transformation
target_type
profile_ready
profile_note
```

The target name in `parm` is the string users pass to `confint()`. It should be
stable, user-facing, and based on fitted-model labels, not on raw TMB storage
details. `tmb_parameter` and `index` are allowed to expose the implementation
mapping because they are diagnostic columns, but they are not the public target
name.

`target_type` has only two meanings:

| Value | Meaning | Interval status |
| --- | --- | --- |
| `direct` | The row maps to one fitted TMB parameter or one TMB linear combination. | Can be profile-ready when the fitted object kept `fit$obj` and the internal parameter is present. |
| `derived` | The row is a reported point estimate from a transformed, multi-parameter, or surface-level quantity. | Not directly profile-ready until a direct reparameterization or fix-and-refit method exists. |

`profile_ready = TRUE` is deliberately stricter than "the optimizer vector has
this parameter". It means a direct target is available and the fitted object
retained the TMB automatic-differentiation object needed by
`TMB::tmbprofile()`. Memory-light fits created with
`drm_control(keep_tmb_object = FALSE)` still list their target names, but their
direct rows use:

```text
profile_ready = FALSE
profile_note = "tmb_object_required"
```

The currently allowed `profile_note` values are:

| Value | Use |
| --- | --- |
| `ready` | The direct target can be sent to `confint(..., method = "profile")`. |
| `tmb_object_required` | The target is otherwise direct, but the fit dropped `fit$obj`; refit with `drm_control(keep_tmb_object = TRUE)`. |
| `missing_tmb_parameter` | The fitted object does not contain the internal parameter needed for that direct target. |
| `derived_target` | The row is a derived SD or fitted surface, not a one-parameter profile target. |
| `derived_unstructured_correlation` | The row is an unstructured q4 correlation derived from a Cholesky-style covariance parameterization. |

The currently allowed `transformation` values are `linear_predictor`, `exp`,
`rho12_tanh`, `tanh`, `variance_ratio`, `derived_group_scale`,
`unstructured_corr`, and `ordered_cutpoint`. Slice 52 tests representative fixed-effect,
distributional-scale, random-effect SD, random-effect correlation, residual
correlation, ordinal cutpoint, modelled-SD, q4 derived-correlation, and
memory-light fitted-object rows against this contract.

## Phase 6 Slice 57 Output Integration

Slice 57 adds the first shared interval-status vocabulary to returned tables.
Successful `confint()` rows now include `conf.status = "wald"` or
`conf.status = "profile"` alongside the existing `method` column. When
`summary(conf.int = TRUE)` attaches interval columns, fixed-effect and parameter
tables also carry `conf.status` so the reader can distinguish these states:

| Status | Meaning |
| --- | --- |
| `wald` | A Wald interval was returned for this row. |
| `profile` | A profile-likelihood interval was returned for this row. |
| `profile_ready` | The row is a direct profile target, but this summary call did not request that target. |
| `newdata_required` | The row is a fitted surface summary; use `confint(..., newdata = ...)` to profile a supplied row. |
| `derived_interval_unavailable` | The point estimate is derived from multiple quantities and has no validated derived-interval method yet. |
| `wald_unavailable` | Wald intervals are not reported for this non-fixed-effect summary row, or fixed-effect Wald uncertainty is unavailable because `TMB::sdreport()` was skipped or failed. |
| `target_unavailable` | The row is a descriptive range or other summary with no current direct interval target. |

This does not make Wald intervals the default for variance components or
correlations. It only makes the output tables say why an interval is present or
absent. `profile_targets()` remains the inventory for deciding which direct
targets can be passed to `confint(..., method = "profile")`; `corpairs()` keeps
its existing `conf.status` column for latent and residual correlation-pair rows.

Slice 106 adds local delta-method standard errors to direct response-scale
`summary()` parameter rows when `TMB::sdreport()` succeeds. These standard
errors use the optimized TMB parameter covariance and the row's response-scale
transformation, such as `exp()` for SDs or guarded `tanh()` for correlations.
They are not a replacement for profile-likelihood confidence intervals, and
they are not reported for descriptive fitted ranges or derived variance ratios.

## Phase 6 Slice 58 Profile Diagnostics

Slice 58 adds lightweight diagnostics to successful profile-interval rows and
clearer failure messages for profiles that cannot be constructed. Successful
profile rows returned by `confint()` now include:

```text
profile.boundary
profile.message
```

The current diagnostic is deliberately simple. It reports `profile.message =
"ok"` for ordinary finite intervals, `"near_sd_boundary"` when a transformed SD
interval reaches the lower boundary guard, and `"near_correlation_boundary"`
when a transformed correlation interval approaches the correlation guard.
`profile.boundary` is `TRUE` for those boundary-like cases.

Failed `TMB::tmbprofile()` calls and failed interval extraction errors now say
that the failure can reflect a boundary, one-sided, non-monotone, or
failed-inner-optimization profile. This does not yet implement one-sided
profile intervals or automatic recovery from non-monotone profiles; it only
records the diagnostic pathway so later slices can add stronger recovery.

## Phase 6 Slice 59 Reader-Facing Contract

Slice 59 syncs public prose with the implemented output contract. Reader-facing
pages should teach three rules:

1. use `profile_targets(fit)` to find direct profile-ready targets;
2. read `conf.status` before interpreting confidence limits;
3. read `profile.boundary` and `profile.message` for profile intervals before
   treating an interval as well behaved.

The current documentation should not claim profile intervals for q=4 derived
correlations, repeatability, phylogenetic signal, conditional random-effect
modes, or marginal-effect helpers. Those rows may have point estimates and
explicit unavailable statuses, but their intervals remain future derived-profile
or bootstrap work.

## Phase 6 Slice 53 Direct Profile Robustness

Slice 53 keeps the same statistical targets but hardens the failure boundary
around direct profile calculations. `drmTMB` controls the target-specific
arguments passed to `TMB::tmbprofile()`:

```text
obj
name
lincomb
trace
```

Users choose the target with `parm` and may still tune profile controls such as
`ystep`, `ytol`, `maxit`, `parm.range`, `slice`, and `adaptive`. Passing
`obj`, `name`, `lincomb`, or `trace` through `...` now errors before entering
TMB, because those arguments would otherwise create ambiguous "which target is
being profiled?" calls.

Direct profile failures are caught and rethrown with the public target name:

```text
Profile likelihood failed while profiling target "fixef:mu:x".
```

The message points users back to `profile_targets(fit)`, profile controls, and
`check_drm(fit)`. Interval extraction from a completed TMB profile is also
wrapped separately, because a profile can be computed yet fail to cross the
likelihood-ratio threshold on both sides. This slice does not change the
likelihood, the target transformations, or which derived targets are
profile-ready.

## Phase 6 Slice 54 Response-Scale Row Profiles

Slice 54 treats row-specific profile intervals as a tested response-scale
contract. These calls profile a single fixed-effect linear predictor row and
then transform the interval back to the public parameter scale:

```r
confint(fit, parm = "sigma", newdata = grid, method = "profile")
confint(fit, parm = "sigma1", newdata = grid, method = "profile")
confint(fit, parm = "sigma2", newdata = grid, method = "profile")
confint(fit, parm = "rho12", newdata = grid, method = "profile")
confint(
  fit,
  parm = 'corpair(id, level = "group", block = "p", from = "mu1", to = "mu2")',
  newdata = grid,
  method = "profile"
)
confint(
  fit,
  parm = 'corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2")',
  newdata = grid,
  method = "profile"
)
```

The `sigma*` rows use the exponential transformation, residual `rho12` uses the
guarded residual-correlation transform, and q=2 `corpair()` rows use the
guarded latent random-effect correlation transform. `newdata` targets are not
listed in `profile_targets(fit)`, because they are generated from supplied rows
at call time. `corpairs(conf.int = TRUE)` still reports `newdata_required` for
modelled q=2 `corpair()` summary rows: that summary is a mean/range over fitted
group or species correlations, whereas `confint(..., newdata = ...)` profiles
one supplied predictor row.

The row-profile path is intentionally single-target. It rejects missing
`parm`, multiple `parm` values, non-data-frame `newdata`, and empty `newdata`
before calling TMB. Arbitrary multi-row or multi-parameter contrasts remain a
later design target.

## Phase 6 Slice 55 Random-Effect SD and Correlation Intervals

Slice 55 closes the current direct random-effect interval contract. The fitted
targets covered by tests are:

- ordinary grouped SDs such as `sd:mu:(1 | id)`;
- ordinary grouped correlations such as
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` and
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`;
- the first coordinate-spatial SD target,
  `sd:mu:spatial(1 | site)`;
- bivariate phylogenetic `mu1`/`mu2` SD targets such as
  `sd:mu:mu1:phylo(1 | species)`;
- the bivariate phylogenetic mean-mean correlation target
  `cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)`.

`summary(conf.int = TRUE, method = "profile", ci_parm = ...)` attaches
intervals to `summary(fit)$parameters` for the requested direct rows. For
random-effect covariance summaries, the same profile interval table is reused
to populate `correlation_conf.*`, `from_sd_conf.*`, and `to_sd_conf.*` columns
where those direct targets were requested. The nonlinear covariance itself is
still reported as `covariance_conf.status = "derived_interval_unavailable"`
because it combines multiple profiled quantities and is not yet a single direct
profile target.

`corpairs(conf.int = TRUE)` attaches profile-likelihood intervals only to
constant fitted correlation-pair rows whose `profile_targets()` row is
`profile_ready`. Modelled `corpair(...) ~ x` summary rows still report
`newdata_required`; q4 unstructured ordinary or phylogenetic rows still report
`derived_interval_unavailable`. This keeps constant latent correlations,
predictor-dependent latent correlations, residual `rho12`, and derived q4 rows
separate in both output and inference claims.

## Phase 6 Slice 56 Derived-Target Status

Slice 56 makes the first nonlinear variance-ratio summaries explicit without
pretending they are profile-ready. For a univariate Gaussian model with a
constant residual `sigma` and an intercept-only group random effect,
`summary(fit)$derived` reports:

```text
repeatability_group =
  sigma_group^2 / (sigma_group^2 + sigma^2)
```

The same rule gives a phylogenetic-signal point estimate for a univariate
Gaussian `phylo(1 | species, tree = tree)` location model:

```text
phylogenetic_signal =
  sigma_phylo^2 / (sigma_phylo^2 + sigma^2)
```

These rows also appear in `profile_targets()` as `target_class =
"derived-summary"`, `target_type = "derived"`, `transformation =
"variance_ratio"`, and `profile_note = "derived_target"`. They are deliberately
not profile-ready. If a user requests `conf.int = TRUE`, the summary marks the
row with `conf.status = "derived_interval_unavailable"` and leaves interval
bounds empty. If a user passes the derived target to `confint(..., method =
"profile")`, the call fails before starting `TMB::tmbprofile()`.

This is a status contract, not a derived-inference method. It tells readers
where the point estimate comes from and why the 95% interval is not yet
available. Future derived intervals for repeatability, ICCs, phylogenetic
signal with additional variance components, total variance, covariance
products, and q4 correlation functions should use a fix-and-refit or
reparameterized profile method.

## Core Definition

For a single parameter `theta`, the likelihood-ratio statistic is:

```text
D(theta_0) = 2 * (logLik_hat - logLik_profile(theta_0))
```

where `logLik_hat` is the joint maximum log likelihood and
`logLik_profile(theta_0)` is the maximum log likelihood after fixing `theta` at
`theta_0` and re-optimizing all other free parameters.

A 95% profile-likelihood confidence interval is the set of values where:

```text
logLik_hat - logLik_profile(theta) <= qchisq(0.95, df = 1) / 2
```

The right-hand side is approximately `1.92`.

This is a profile, not a slice: all nuisance parameters are re-optimized at each
candidate value.

## Preferred Implementation

The first implementation should use:

- `TMB::tmbprofile()` for direct TMB parameters;
- `uniroot()` to find lower and upper threshold crossings when both exist;
- warm starts from the joint MLE wherever possible;
- response-scale transformations after profiling on the stable internal scale.

This is preferable to a dense grid because most grid points do not matter. A
grid can still be useful for diagnostics and teaching plots.

The profile API should return a tidy data frame with at least:

```text
parm
estimate
conf.low
conf.high
scale
method
boundary
converged
message
```

Boundary and convergence flags are part of the result, not optional warnings
that disappear in scripts.

Boundary control flow should be explicit. If a lower variance-component bound
is the parameter-space boundary, such as `sd = 0`, the lower endpoint should be
reported as that boundary and `boundary = TRUE`. If only one interior root
exists, the other endpoint should be encoded as the boundary or as missing with
a clear `message`, depending on the parameter space. Nonregular cases should
not be silently turned into symmetric intervals.

## Quantity Classes

### Direct TMB Parameters

Examples:

- log random-effect SDs;
- log residual SD or dispersion parameters;
- ordinal cutpoints;
- transformed correlation parameters when they are direct entries in the TMB
  parameter vector.

These are the first target because `TMB::tmbprofile()` can profile them
directly by name.

Current high-value direct targets are:

```text
log_sd_mu          -> sdpars$mu
log_sd_sigma       -> sdpars$sigma
log_sd_phylo       -> sdpars$mu["phylo(1 | species)"]
log_sd_phylo       -> sdpars$mu["spatial(1 | site)"] in the first spatial slice
eta_cor_mu         -> corpars$mu
eta_cor_mu_sigma   -> corpars$mu_sigma
beta_rho12         -> fixed effects in residual correlation formulae
```

For `beta_rho12`, the profile is on the atanh linear-predictor scale unless a
single interpretable row-specific value is requested with `newdata` and
transformed back through `tanh()`.

### Linear Combinations

Examples:

- total variance as the sum of two variance components;
- simple contrasts of direct parameters on an internal scale.

Use TMB's `lincomb` machinery where the target is truly linear in the internal
parameterization.

Do not use `lincomb` for sums of variances unless the internal parameters are
already variances. A sum such as `sigma_phylo^2 + sigma_species^2` is nonlinear
in `log_sd_phylo` and `log_sd_mu`.

### Nonlinear Derived Quantities

Examples:

- ICCs;
- repeatability;
- heritability-like ratios;
- cross-trait correlations derived from covariance matrices;
- correlations among individual averages, mean-model slopes, residual scale,
  and scale-model slopes in double-hierarchical individual-difference models.

These are not direct `tmbprofile()` targets. The first robust path should be a
fix-and-refit profile:

1. choose a candidate derived value;
2. impose the corresponding constraint through a mapped or rebuilt TMB object;
3. re-optimize all other parameters;
4. use `uniroot()` to find where the profile log likelihood drops by `1.92`.

An alternative is to create a new TMB parameterization where the derived
quantity is a direct parameter, such as `(logit_ICC, log_total_variance)`, but
that is more invasive and should be reserved for high-value quantities.

For `drmTMB`, the first nonlinear derived targets are likely:

```text
ICC_study = omega_study^2 / (omega_study^2 + sigma^2)
phylogenetic_signal = sigma_phylo^2 /
  (sigma_phylo^2 + sigma_species^2 + sigma^2)
repeatability = sigma_group^2 / (sigma_group^2 + sigma^2)
```

These should be implemented only after the corresponding variance components
have stable extractors and simulation tests.

## Correlation Intervals

For a covariance matrix `Sigma`, a correlation is:

```text
rho_ij = Sigma[i, j] / sqrt(Sigma[i, i] * Sigma[j, j])
```

For a candidate `rho_0`, the constrained profile should enforce:

```text
Sigma[i, j] = rho_0 * sqrt(Sigma[i, i] * Sigma[j, j])
```

and then re-optimize all other parameters. This applies to group-level
correlations, not residual `rho12 ~ predictors`, unless the residual correlation
parameter is being profiled directly.

Candidate correlations should be searched on the open bounded response scale,
with numerical guards such as `(-0.999999, 0.999999)` rather than exactly
`[-1, 1]`. Direct TMB parameters such as `eta_cor_mu` and residual-correlation
linear predictors such as `beta_rho12` can be profiled internally on an
unbounded scale, but reported intervals for correlations must be transformed
back through `tanh()`. Profiles that approach the numerical guard should be
flagged as near-boundary intervals.

## Pitfalls And Fallbacks

- Boundary variance components can produce one-sided intervals. Return the
  boundary, such as zero, and flag the interval.
- Non-monotone or multi-modal profiles can invalidate simple `uniroot()` logic.
  Detect these cases and fall back to a plotted profile or parametric bootstrap.
- Constrained inner optimizations can fail near boundaries. Retry with perturbed
  starts before falling back.
- Wald intervals for variance components and correlations should not be the main
  default because they are often poor near boundaries.

## First Implementation Slice

The first code slice should not attempt every interval type. It should expose a
target inventory while keeping the internal TMB mapping in one helper:

```r
profile_targets(fit)
```

This public helper is the target table behind the profile/confidence interval
API. It returns target names, target classes, internal TMB parameter names,
current estimates, transformation labels, whether the target is direct or
derived, and a short note explaining whether the target is ready for direct
profiling. `confint(fit, method = "profile")` accepts targets from this table.
Unsupported targets fail before expensive optimization.

A second internal helper now profiles direct fixed-effect targets from this
inventory, and the public `confint()` method exposes the first user-facing
slice:

```r
confint(fit, parm = "fixef:mu:x", method = "profile")
```

By default, `confint(fit)` returns fast Wald intervals for fixed-effect
coefficients on their link scales. Profile intervals must be requested by name
because they can be slow. The profile path wraps `TMB::tmbprofile()` for ready
fixed-effect, constant distributional-scale, ordinary random-effect SD,
ordinary random-effect correlation, phylogenetic `mu` SD, constant residual
`rho12`, univariate `mu`/`sigma` random-intercept covariance target rows,
bivariate Gaussian group-level `mu1`/`mu2` random-intercept SD and correlation
target rows, and row-specific `newdata` profiles for predictor-dependent
`sigma`, `sigma1`, `sigma2`, `rho12`, and fitted ordinary or phylogenetic q=2
`corpair()` values. `summary(conf.int = TRUE, method = "profile")` reuses the same direct
target table when `ci_parm` names one of these rows. Unsupported
ordinal-transform, modelled group-SD, custom multi-row contrast, and
derived-summary targets still fail before doing expensive optimization.

The first fitted targets should be direct parameters in this order:

1. fixed-effect coefficients for `mu`, `sigma`, `nu`, `zi`, `hu`, and `rho12`;
2. constant `sigma`, `sigma1`, `sigma2`, residual `rho12`, and row-specific
   `newdata` profiles for predictor-dependent scale, residual-correlation, and
   fitted ordinary q=2 `corpair()` values;
3. ordinary Gaussian random-effect SDs in `sdpars$mu`;
4. ordinary Gaussian random-effect correlations in `corpars$mu`;
5. univariate `mu`/`sigma` random-intercept SD and correlation rows, with the
   fitted correlation in `corpars$mu_sigma`;
6. bivariate Gaussian group-level `mu1`/`mu2` random-intercept SDs and
   correlations, still under the `mu` random-effect target namespace;
7. phylogenetic `mu` SDs;
8. ordinal cutpoints.

Ordinal rows in the internal inventory currently refer to raw `theta_ord`
parameters. A later user-facing interval table can add transformed cutpoint
rows, but it should keep `theta_ord` visible as the profiled TMB parameter.

Derived summaries such as simple Gaussian repeatability and phylogenetic signal
now have named point-estimate rows, but their profile intervals still wait for
a derived-quantity method. More complex ICCs with known sampling variance,
multiple variance components, double-hierarchical correlation-pair summaries,
and q4 covariance functions should not be treated as interval-ready.

## Implementation Stage

Do not treat profile CIs as complete for the Gaussian random-effect and
correlation phases. Add broader profile support after:

1. random-effect variance components are represented cleanly in fitted objects;
2. profile targets can be named consistently;
3. refit/update machinery can fix or map parameters reliably;
4. simulation tests cover boundary and sparse-group cases.

The first user-facing function should use the same target grammar exposed by
the fitted object:

```r
confint(fit, parm = "sd:mu:(1 | id)", method = "profile")
confint(fit, parm = "sd:mu:(1 + x | p | id):x", method = "profile")
confint(
  fit,
  parm = "cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)",
  method = "profile"
)
confint(fit, parm = "sd:mu:mu1:(1 | p | id)", method = "profile")
confint(
  fit,
  parm = "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)",
  method = "profile"
)
confint(fit, parm = "sd:mu:phylo(1 | species)", method = "profile")
confint(fit, parm = "cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)", method = "profile")
confint(fit, parm = "cor:mu:cor((Intercept),x | id)", method = "profile")
confint(fit, parm = "sigma", method = "profile", newdata = data.frame(x = 0))
confint(fit, parm = "rho12", method = "profile", newdata = data.frame(w = 0))
confint(
  fit,
  parm = 'corpair(id, level = "group", block = "p", from = "mu1", to = "mu2")',
  method = "profile",
  newdata = data.frame(w = 0)
)
confint(fit, parm = "derived:ICC(id)", method = "profile")
```

Multi-coefficient random-effect blocks should keep the fitted-object
coefficient suffix, such as `:x`, in the canonical target name. Intercept-only
blocks can keep the shorter target name shown by `sdpars`.
Bivariate `mu1`/`mu2` covariance blocks keep the response label in the term so
users can tell group-level targets such as `sd:mu:mu1:(1 | p | id)` apart from
the residual-correlation target `rho12`.

For the first fitted ordinary q=2 `corpair()` regression, `newdata` must contain
the group-level predictors used on the right-hand side of the `corpair()`
formula. The interval is for the response-scale latent random-effect
correlation at that supplied predictor row. The `corpairs(conf.int = TRUE)`
extractor still reports `newdata_required` for modelled rows because its
summary row is a mean and range over many fitted group-level correlations, not
one profile target.

The implementation should reject unsupported profile targets with a message
that lists available targets from the fitted object.

## Tests Required Before Implementation Is Done

Profile-likelihood support is done only when these checks exist:

- direct `log_sd_mu` and `log_sd_sigma` intervals recover the simulated SD on
  the response scale;
- `log_sd_phylo` profile intervals work for the implemented
  `phylo(1 | species, tree = tree)` path and for the first fitted
  `spatial(1 | site, coords = coords)` path, where the same internal TMB
  parameter stores the single structured-effect SD;
- `profile_targets()` lists the fitted bivariate phylogenetic `mu1`/`mu2` SDs
  and mean-mean correlation separately from residual `rho12`;
- `eta_cor_phylo` profile intervals transform to bounded bivariate
  phylogenetic `mu1`/`mu2` correlations;
- `eta_cor_mu` profile intervals transform to bounded group-level correlations;
- `eta_cor_mu_sigma` profile intervals transform to bounded `mu`/`sigma`
  group-level correlations;
- `summary(conf.int = TRUE, method = "profile")` attaches finite bounds to
  profile-ready direct covariance rows;
- boundary SDs return one-sided intervals with `boundary = TRUE`;
- a small diagnostic grid agrees with the `uniroot()` bounds in at least one
  simple model;
- unsupported derived targets fail with a clear available-target message;
- long simulations compare profile, Wald, and bootstrap coverage for a small
  set of variance components.
