# A5 -- the #575 cross-engine objective diagnosis, re-runnable from R

drmjl_ref: 77513aa0663209b96e53a649d232558515f687fa
drmtmb_ref: 09f2a97cbb51b45df796f3b134d42fb717b88ba4

Run: `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R`

## What this is

DRM.jl#575 asked: on the committed `biv-q4-phylo-reml` fixture (bivariate
Gaussian, q=4 phylogenetic location-scale, REML), is the R/TMB engine's
optimum better because DRM.jl's solver stopped short of its own objective, or
because the two engines are maximising different objectives? On 2026-09-01
this was answered by hand in a Julia scratchpad
(`docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/
warmstart_575.jl`, `575-mechanism.md`), and turned into a committed, pinned,
re-runnable script/receipt.

**This is still a DIAGNOSIS artefact -- it measures which engine's objective
is better or worse at which point -- and it does not advance any
capability-ledger row or bridge-route status.** It changes no
`r_bridge_status`, no capability-ledger row, and no fixture tolerance.

## Pin history (each entry is a dated snapshot, kept for the record)

| Date | DRM.jl ref | What changed |
|---|---|---|
| 2026-09-01/02 | `feat/575-objective-at @ dc3ce190` | The diagnostic primitive (`reml_objective_at`), private-name shim, PRE the #575 fix. |
| 2026-09-02 | `main @ e4647333` | #589 (exact REML gradient, the #575 fix) + #590 (supported `drm_bridge_objective_at` entry point). |
| 2026-09-02 (this run) | `main @ 77513aa0` | Carries #577 (`prior_precision` root fix) and #599 (a new coef_labels completeness echo-check, design 258 §7) on top of e4647333. |

## The 2x2 objective table (current: DRM.jl @ 77513aa0)

All numbers are on the normalised (Patterson-Thompson, TMB/lme4/glmmTMB-
comparable) restricted log-likelihood scale that both `-logLik(fit_tmb)` and
DRM.jl's `drm_bridge_objective_at(...)$reml_loglik` report on (#477).

| evaluated at \ objective | TMB's objective | DRM.jl's objective |
|---|---|---|
| TMB's fitted point   | -219.613986 | -219.620688 |
| Julia's fitted point | -219.616013 | -219.614005 |

**Numerically identical to the `e4647333` run** (below) -- #577/#599 do not
move this fixture's numbers; #577 concerns a different (structural-zeros ML)
code path, and #599 is a payload-contract completeness check, not a
numerical change.

Differences:

- TMB's own optimum vs. Julia's point, on TMB's objective: `-219.613986 -
  (-219.616013) = 0.002027` -- TMB's own point remains (very slightly)
  better on TMB's objective, as expected.
- Julia's own optimum vs. TMB's point, on DRM.jl's objective:
  `-219.614005 - (-219.620688) = 0.006683` -- DRM.jl's own solver returns
  the BEST point on DRM.jl's own objective (Julia's own point beats DRM.jl's
  objective evaluated at TMB's point). DRM.jl's own optimum (`-219.614005`)
  and TMB's own optimum (`-219.613986`) agree to `1.9e-5` -- both engines
  land at essentially the SAME point on the SAME restricted likelihood. This
  is the `#575` fix, still holding at this re-pin.

## Self-consistency anchors (both < 2e-4, DRM.jl's documented inner-
## alternation floor)

- TMB anchor: `|TMB objective at TMB's own point - (-logLik(fit_tmb))|` =
  `0.000e+00`.
- DRM.jl anchor: `|DRM.jl's wrapper objective at Julia's own point -
  Julia's own reported reml_loglik|` = `6.042e-09` -- unchanged from the
  `e4647333` run (exact, not finite-difference, REML gradient).

Both anchors are computed, never hard-coded, by re-evaluating each engine's
objective at its OWN reported point and comparing to that engine's OWN
reported logLik/reml_loglik.

## A blocker found and fixed while re-pinning to 77513aa0 (unrelated to the
## receipt's own numbers, but required to get ANY live Julia fit of this
## fixture running at this pin)

DRM.jl#599 (landed between `e4647333` and `77513aa0`) added
`_bridge_echo_coef_labels` (`src/bridge.jl`), a NEW, strict validator of the
R-side `options["coef_labels"]` payload (design 258 §7.1). Getting the
`biv-q4-phylo-reml` fixture to fit at all under `engine = "julia"` at this
pin required two narrow fixes in `R/julia-bridge.R`
(`drm_julia_bridge_payload_coef_labels()`), both empirically diagnosed
(JuliaCall marshalling probes and reading DRM.jl's own error text) before
being applied, neither touching this receipt's numbers or A4's shim:

1. A length-1 R character vector (e.g. an intercept-only dpar's single
   column name) crosses to Julia as a bare scalar `String`, not a 1-element
   `Vector{String}` -- DRM.jl's new validator then iterates it by
   CHARACTER (`"(Intercept)"`, 11 characters, read back as 11 names).
   Fixed by wrapping every dpar's labels in `as.list()` before crossing.
2. The bivariate q=4 phylo route's `phylocov` block (the 4x4 among-axis
   covariance's 10 log-Cholesky entries) has no `formula$entries`
   counterpart at all, so the R-side payload builder never labelled it;
   DRM.jl's new validator requires an entry for EVERY block it fits, not
   only formula-driven ones. Fixed by adding a `phylocov` entry (the same
   `Sigma_a:Lij` lower-triangular naming `drm_julia_phylocov_matrix()`
   already reads back elsewhere in this file) when
   `drm_julia_biv_phylo_dimension(formula) == "q4"`.

Both fixes are recorded with full reasoning as comments in
`R/julia-bridge.R` beside `drm_julia_bridge_payload_coef_labels()`. This is
flagged for the design-258/S7 lane: §7.4's documented exclusion list
(structured/relmat/animal/spatial, bivariate-known-structured, joint routes)
does not mention the bivariate q4/q2 PHYLO route specifically, which is why
it was not already gated out -- worth an explicit decision on whether q4
phylo is IN scope for §7 (as now made to work here) or should be added to
§7.4's exclusion list instead.

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

## A real, separate gap found while building this receipt (unrelated to any
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
Sys.setenv(DRM_JL_PATH = "<path to a 77513aa0-pinned (or descendant) DRM.jl clone>")
Sys.setenv(DRMTMB_JULIA_TESTS = "true")
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
Rscript docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R
# or, with no Julia at all:
Rscript docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R --stable-only
```

The script refuses (loud message, exit 1) if `DRM_JL_PATH` is unset or points
at a clone whose `git rev-parse HEAD` does not start with `77513aa0` -- e.g.
pointing it at the `feat/575-exact-reml-gradient @ cda42b8c` clone (an
earlier, superseded state of the same fix) produces exactly this refusal
rather than a silently mismatched number. Confirmed as a RED control:
pointing `DRM_JL_PATH` at the `cda42b8c` clone produces the refusal message
and a nonzero exit before any Julia fit runs.
