# gllvmTMB Profile and CI Audit

## Purpose

This note records a source-only audit of the local `gllvmTMB` profile,
confidence-interval, and bootstrap code after Ayumi's Bergmann timing report.
The aim is not to copy code. The aim is to identify which design lessons should
inform `drmTMB` now that `confint()` has fast direct Wald intervals,
`profile_precision = "fast"`, and a narrow direct-target bootstrap route.

No `gllvmTMB` source was ported in this slice. If a later slice ports code
rather than re-implementing an idea inside the `drmTMB` contract, update
`inst/COPYRIGHTS` before treating the change as complete.

## Source Findings

The main `gllvmTMB` profile wrapper is an R wrapper around
`TMB::tmbprofile()`, not a separate package-specific C++ profiling engine.
The local source explicitly says the profile is computed through TMB's C++
inner optimization and warm-started from the joint MLE
(`../gllvmTMB/R/profile-ci.R`, lines 130-132). The speed-oriented defaults are
coarser profile controls: `ystep = 0.5` and `ytol = 2`
(`../gllvmTMB/R/profile-ci.R`, lines 155-187), passed directly to
`TMB::tmbprofile()` for named parameters or linear combinations
(`../gllvmTMB/R/profile-ci.R`, lines 200-224).

The wrapper also records a useful boundary convention for variance and
correlation targets. When a log-SD profile runs to the natural lower boundary,
the transformed lower bound should be the natural boundary, such as 0 for SD
or -1 for a `tanh` correlation transform; `NA` is reserved for genuine profile
failure (`../gllvmTMB/R/profile-ci.R`, lines 165-175). That convention is worth
considering for future `drmTMB` profile-boundary polishing, but it should be
added as its own tested change rather than folded into this CI slice.

`gllvmTMB` makes `method = "profile"` the first `confint()` method for
`gllvmTMB_multi` objects (`../gllvmTMB/R/z-confint-gllvmTMB.R`, lines 286-297).
Direct profile-target labels route through `profile_targets()` and
`tmbprofile_wrapper()` (`../gllvmTMB/R/z-confint-gllvmTMB.R`, lines 47-104 and
311-322). Direct variance or dispersion bootstrap is not wired through that
generic direct-target path; the source says it falls through to the older
fixed-effect bootstrap fallback (`../gllvmTMB/R/z-confint-gllvmTMB.R`, lines
323-341).

The richest bootstrap path in the local `gllvmTMB` source is the Sigma helper.
`bootstrap_Sigma()` has explicit `n_boot`, `seed`, `n_cores`, `keep_draws`,
and `link_residual` controls (`../gllvmTMB/R/bootstrap-sigma.R`, lines
138-149). It reconstructs the formula and family from the fit, pre-draws all
simulated responses for reproducibility, forwards structured-effect auxiliary
objects such as phylogenetic matrices and spatial meshes, refits each
replicate, returns NA-shaped summaries for failures, supports
`future`/`future.apply` multicore execution, and records the number of failed
refits (`../gllvmTMB/R/bootstrap-sigma.R`, lines 193-335).

For implied cross-trait correlations, `gllvmTMB` exposes a separate
`extract_correlations()` interface with four methods: `"fisher-z"`,
`"profile"`, `"wald"` as a Fisher-z alias, and `"bootstrap"`
(`../gllvmTMB/R/extract-correlations.R`, lines 1-33). The Fisher-z route uses
`atanh(rho)`, `1 / sqrt(n_eff - 3)`, and `tanh()` back-transformation, with an
effective-sample-size heuristic and an override (`../gllvmTMB/R/extract-correlations.R`,
lines 49-64 and 413-465).

## What Transfers To drmTMB Now

The profile-speed lesson transfers cleanly: `profile_precision = "fast"` should
be advertised as the quick first-pass route for long SD or correlation
profiles. It is not a new profile engine. It is the same `TMB::tmbprofile()`
path with coarser `ystep` and `ytol` controls.

The default interval strategy should stay different from `gllvmTMB`.
`drmTMB` is a one- or two-response distributional-regression package, and the
user-facing need after the Bergmann report is a fast, reliable default. The
default `confint()` route should therefore remain Wald for fixed effects and
direct fitted scale, SD, and correlation targets when `sdreport()` covariance
is available. Profile and bootstrap should be targeted follow-up steps.

The correlation lesson transfers only at the transformation level. For direct
fitted correlation parameters, `drmTMB` should use the TMB covariance on the
fitted correlation-link scale and transform endpoints back to the correlation
scale. It should not use a sample-correlation `n_eff` Fisher-z heuristic as
the default interval for model-parameter correlations. That heuristic is
better suited to derived or extractor-specific correlation summaries where a
separate effective-sample-size contract has been designed.

The bootstrap ergonomics lesson is strong: direct-target bootstrap intervals
should report success and failure counts, support bounded parallel refits, and
make refit controls visible. The first `drmTMB` route now does that for
selected `confint()` direct targets. Broader bootstrap integration for
`summary()`, `corpairs()`, prediction tables, derived q4 covariance summaries,
repeatability, and phylogenetic signal should remain separate slices with
their own target extractors and failure ledgers.

## Later Transfer Candidates

1. Add a `confint_inspect()`-style profile diagnostic surface for checking
   one-sided, non-monotone, or boundary-limited profiles before relying on an
   interval.
2. Harden `drmTMB` profile-boundary handling so natural lower or correlation
   boundaries are separated from genuine profile failures in a tested way.
3. Add an optional bootstrap draw ledger, with per-refit convergence and
   target-extraction status, before exposing bootstrap results outside
   `confint()`.
4. Keep the sister-package audit loop active, but adapt only the pieces that
   respect `drmTMB`'s univariate/bivariate scope.

## Current Decision

For long models such as a large phylogenetic Gaussian fit, the recommended
`drmTMB` order is:

```r
confint(fit)
confint(fit, parm = "variance_components")
confint(fit, parm = "sd:mu:phylo(1 | species)", method = "profile",
        profile_precision = "fast")
confint(fit, parm = "variance_components", method = "bootstrap", R = 99)
```

The first two calls are the fast reporting path. The targeted profile call is
for variance or correlation targets where likelihood shape matters. The
bootstrap call is a refit-based uncertainty pilot, not a replacement for a
formal simulation coverage audit.
