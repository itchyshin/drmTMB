# A5 -- the #575 cross-engine objective diagnosis, re-runnable from R

drmjl_ref: dc3ce1908369e4734e92c37220dad951647b4844
drmtmb_ref: 89bfd210ad358c2e703b04e66973e51bfc725456

Run: `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R`

## What this is

DRM.jl#575 asked: on the committed `biv-q4-phylo-reml` fixture (bivariate
Gaussian, q=4 phylogenetic location-scale, REML), is the R/TMB engine's
optimum better because DRM.jl's solver stopped short of its own objective, or
because the two engines are maximising different objectives? On 2026-09-01
this was answered by hand in a Julia scratchpad
(`docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/
warmstart_575.jl`, `575-mechanism.md`). This script and receipt turn that
manoeuvre into a committed, pinned, re-runnable artefact: evaluate BOTH
engines' REML objective at BOTH engines' fitted points, on the SAME fixture.

**This is a DIAGNOSIS, not a fix of #575, and it does not advance any
capability-ledger row or bridge-route status.** It measures which engine's
objective is better or worse at which point. It changes no `r_bridge_status`,
no capability-ledger row, and no fixture tolerance.

## The 2x2 objective table

All numbers are on the normalised (Patterson-Thompson, TMB/lme4/glmmTMB-
comparable) restricted log-likelihood scale that both `-logLik(fit_tmb)` and
DRM.jl's `reml_objective_at(...).reml_loglik` report on (#477).

| evaluated at \ objective | TMB's objective | DRM.jl's objective |
|---|---|---|
| TMB's fitted point   | -219.613986 | -219.620688 |
| Julia's fitted point | -219.634993 | -219.630326 |

Differences:

- TMB's own optimum vs. Julia's point, on TMB's objective: `-219.613986 -
  (-219.634993) = 0.021007` -- TMB's own point is better on TMB's objective,
  as expected (it is TMB's optimum).
- Julia's own optimum vs. TMB's point, on DRM.jl's objective:
  `-219.630326 - (-219.620688) = -0.009638` -- DRM.jl's objective, evaluated
  AT TMB's fitted point (with the four profiled fixed-effect axes reprofiled
  by DRM.jl's own conditional-Newton alternation), is **better** than the
  point DRM.jl's own solver actually returned. This reproduces the
  2026-09-01 by-hand finding (there: Julia_at_TMB - Julia_own = +0.009724;
  here: +0.009638, the same sign and magnitude within the alternation's own
  noise floor) -- direct evidence that both engines maximise the SAME
  restricted likelihood and that DRM.jl's own solver stopped short of its own
  optimum on this cell (a mode-finder gap, not an objective-translation
  bug).

## Self-consistency anchors (both < 2e-4, DRM.jl's documented inner-
## alternation floor)

- TMB anchor: `|TMB objective at TMB's own point - (-logLik(fit_tmb))|` =
  `0.000e+00`.
- DRM.jl anchor: `|DRM.jl's wrapper objective at Julia's own point -
  Julia's own reported reml_loglik|` = `9.487e-05`.

Both anchors are computed, never hard-coded, by re-evaluating each engine's
objective at its OWN reported point and comparing to that engine's OWN
reported logLik/reml_loglik.

## A real, separate gap found while building this receipt

`objective_at()` (R/objective-at.R, A3) evaluates the native TMB objective on
the public start-label vocabulary (`fixef:<dpar>:<col>`, `sd:<dpar>:<term>`,
`cor:<dpar>:<term>`). That vocabulary does not yet reach this fixture at all:
`objective_at(fit_tmb, at = list("fixef:rho12:(Intercept)" = ...))` aborts
with "Unknown public start label" because `biv_gaussian`'s `beta_rho12` TMB
start component carries no column names for `drm_resolve_public_start_target()`
to match against; a `sd:mu:mu1:phylo(1 | p | species)` label aborts the same
way because the q4 phylo covariance block lives in TMB's `log_sd_phylo`/
`theta_phylo` parameters, outside `spec$random` entirely, while the `sd:`
family's resolver looks for `spec$random[[dpar]]$labels`. Both were verified
empirically (not inferred) while building this receipt.

This is not this slice's (A4/A5, `R/julia-bridge.R` + this receipt) to fix
silently. "TMB objective at TMB's own point" in the table above is therefore
`-logLik(fit_tmb)` directly (definitionally what `objective_at()` would
return at a fit's own optimum, and independently verified as an exact
anchor); "TMB objective at Julia's point" reuses `objective_at()`'s OWN
evaluation mechanism (`drm_pin_tmb_object_to_optimum()` + `obj$fn()`,
re-pinned afterwards -- the exact same six lines `objective_at.drmTMB` runs)
with the internal TMB parameter names (`log_sd_phylo`, `theta_phylo`,
`beta_rho12`) substituted directly, since the public label translator cannot
reach them for this model. This is flagged for the A2/A3 lane in the A4
after-task note.

## Reproducing

```r
Sys.setenv(DRM_JL_PATH = "<path to a dc3ce190-pinned DRM.jl clone>")
Sys.setenv(DRMTMB_JULIA_TESTS = "true")
Rscript docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R
# or, with no Julia at all:
Rscript docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R --stable-only
```

The script refuses (loud message, exit 1) if `DRM_JL_PATH` is unset or points
at a clone whose `git rev-parse HEAD` does not start with `dc3ce190` -- e.g.
pointing it at the `feat/575-exact-reml-gradient @ cda42b8c` clone (PR #579,
a DIFFERENT, later fix for #575) produces exactly this refusal rather than a
silently mismatched number.
