# A5 -- the #575 cross-engine objective diagnosis, re-runnable from R

drmjl_ref: e46473337713111158f3425ad6d20e1b00201e1f
drmtmb_ref: 1291772bca3bd75648cdc921714e9d769e958b96

Run: `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R`

## What this is

DRM.jl#575 asked: on the committed `biv-q4-phylo-reml` fixture (bivariate
Gaussian, q=4 phylogenetic location-scale, REML), is the R/TMB engine's
optimum better because DRM.jl's solver stopped short of its own objective, or
because the two engines are maximising different objectives? On 2026-09-01
this was answered by hand in a Julia scratchpad
(`docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/
warmstart_575.jl`, `575-mechanism.md`), and turned into a committed, pinned,
re-runnable script/receipt against DRM.jl `feat/575-objective-at @ dc3ce190`
(the diagnostic primitive, pre-fix). DRM.jl#589 (exact REML gradient) and
#590 (the supported `drm_bridge_objective_at` bridge entry point) have since
merged to `main @ e4647333`; this receipt is re-pinned there and now
**reports the #575 fix**, not only the diagnosis that motivated it.

**This is still a DIAGNOSIS artefact -- it measures which engine's objective
is better or worse at which point -- and it does not advance any
capability-ledger row or bridge-route status.** It changes no
`r_bridge_status`, no capability-ledger row, and no fixture tolerance.

## The 2x2 objective table (DRM.jl @ e4647333, post-#575-fix)

All numbers are on the normalised (Patterson-Thompson, TMB/lme4/glmmTMB-
comparable) restricted log-likelihood scale that both `-logLik(fit_tmb)` and
DRM.jl's `drm_bridge_objective_at(...)$reml_loglik` report on (#477).

| evaluated at \ objective | TMB's objective | DRM.jl's objective |
|---|---|---|
| TMB's fitted point   | -219.613986 | -219.620688 |
| Julia's fitted point | -219.616013 | -219.614005 |

Differences:

- TMB's own optimum vs. Julia's point, on TMB's objective: `-219.613986 -
  (-219.616013) = 0.002027` -- TMB's own point remains (very slightly)
  better on TMB's objective, as expected.
- Julia's own optimum vs. TMB's point, on DRM.jl's objective:
  `-219.614005 - (-219.620688) = 0.006683` -- DRM.jl's own solver now
  returns the BEST point on DRM.jl's own objective (Julia's own point beats
  DRM.jl's objective evaluated at TMB's point), the opposite ordering from
  before the fix (see "Before the fix" below). DRM.jl's own optimum
  (`-219.614005`) and TMB's own optimum (`-219.613986`) now agree to
  `1.9e-5` -- both engines land at essentially the SAME point on the SAME
  restricted likelihood.

This is the `#575` fix, confirmed on this receipt's own fixture: the
mode-finder gap the 2026-09-01 diagnosis found is closed.

## Self-consistency anchors (both < 2e-4, DRM.jl's documented inner-
## alternation floor)

- TMB anchor: `|TMB objective at TMB's own point - (-logLik(fit_tmb))|` =
  `0.000e+00`.
- DRM.jl anchor: `|DRM.jl's wrapper objective at Julia's own point -
  Julia's own reported reml_loglik|` = `6.042e-09` -- three orders of
  magnitude tighter than the pre-fix `9.487e-05`, consistent with the exact
  (not finite-difference) REML gradient DRM.jl#589 landed.

Both anchors are computed, never hard-coded, by re-evaluating each engine's
objective at its OWN reported point and comparing to that engine's OWN
reported logLik/reml_loglik.

## Before the fix (DRM.jl `feat/575-objective-at @ dc3ce190`, for the record)

Kept here so the fix is legible against what it fixed, not overwritten:

| evaluated at \ objective | TMB's objective | DRM.jl's objective |
|---|---|---|
| TMB's fitted point   | -219.613986 | -219.620688 |
| Julia's fitted point | -219.634993 | -219.630326 |

At `dc3ce190`, DRM.jl's objective evaluated AT TMB's fitted point
(`-219.620688`) was BETTER than the point DRM.jl's own solver actually
returned (`-219.630326`) -- direct evidence DRM.jl's own solver stopped
short of its own optimum on this cell (a mode-finder gap, not an
objective-translation bug), reproducing the 2026-09-01 by-hand finding
(there: `+0.009724`; here: `+0.009638`). Self-consistency anchors at
`dc3ce190`: TMB `0.000e+00`, DRM.jl wrapper `9.487e-05` (finite-difference
gradient noise floor).

## A real, separate gap found while building this receipt (unrelated to the
## DRM.jl re-pin)

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
silently. "TMB objective at TMB's own point" in the tables above is
therefore `-logLik(fit_tmb)` directly (definitionally what `objective_at()`
would return at a fit's own optimum, and independently verified as an exact
anchor); "TMB objective at Julia's point" reuses `objective_at()`'s OWN
evaluation mechanism (`drm_pin_tmb_object_to_optimum()` + `obj$fn()`,
re-pinned afterwards -- the exact same six lines `objective_at.drmTMB` runs)
with the internal TMB parameter names (`log_sd_phylo`, `theta_phylo`,
`beta_rho12`) substituted directly, since the public label translator cannot
reach them for this model. This is flagged for the A2/A3 lane in the A4
after-task note.

## Reproducing

```r
Sys.setenv(DRM_JL_PATH = "<path to an e4647333-pinned (or descendant) DRM.jl clone>")
Sys.setenv(DRMTMB_JULIA_TESTS = "true")
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
Rscript docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R
# or, with no Julia at all:
Rscript docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R --stable-only
```

The script refuses (loud message, exit 1) if `DRM_JL_PATH` is unset or points
at a clone whose `git rev-parse HEAD` does not start with `e4647333` -- e.g.
pointing it at the `feat/575-exact-reml-gradient @ cda42b8c` clone (an
earlier, superseded state of the same fix) produces exactly this refusal
rather than a silently mismatched number. Confirmed as a RED control:
pointing `DRM_JL_PATH` at the `cda42b8c` clone produces the refusal message
and a nonzero exit before any Julia fit runs.
