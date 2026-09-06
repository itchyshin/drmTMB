# A8 G1 cell manifest -- bridge-side inference qualification (G3 fence)

Committed BEFORE any G3-qualification fit runs (D-139). Env for every run below:
`OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin clone> threads=FALSE`,
ONE Julia session per script invocation, `devtools::load_all()` on this worktree.
DRM.jl pin: 430ef64cc (carries #631/#633: a profile endpoint that comes back
infinite is a FAILURE, never "expected").

## Pre-flight finding that reshapes this manifest (recorded here, not silently
## worked around)

Before committing target choices, `tools/parity-p2-pilot.R`'s own registry
comment for `plain_binomial_nonphylo` (`bootstrap_ok = FALSE`, citing
drmTMB#1123) was checked against `git log` and found STALE: #1123 was fixed on
this worktree's ancestor commit `6a4a05894` ("rebuild cbind(successes,
failures) response in bootstrap refits"), which `git merge-base --is-ancestor`
confirms is already on `claude/parity-a8`. A direct probe (below) confirms
bootstrap now completes on BOTH engines for this row. The manifest below
therefore includes bootstrap for `plain_binomial_nonphylo`, and
`tools/parity-p2-pilot.R`'s registry is corrected as part of this leaf's
"extend" mandate.

Separately, a pre-flight target probe on `biv_gaussian_residual` (the
committed `gaussian-bivariate-rho12` fixture, engine="julia") found that
`profile_targets()` reports `profile_ready = FALSE` / `profile_note =
"missing_tmb_parameter"` for EVERY row in the inventory (all 9: the 5
fixed-effect coefficients incl. `rho12`, plus the 2 sigma response-scale
aliases) -- confirmed by reading `R/julia-bridge.R`:
`drm_julia_wald_targets()` sets `fixef_profile_ready <- !is_biv &&
!is.null(object$bridge_payload)`, which is unconditionally `FALSE` for any
`biv_gaussian` fit, and `drm_julia_profile_targets_biv()` returns
`empty_profile_targets()` whenever `bridge_payload$tree` is `NULL` (true for
a residual-only, non-phylo bivariate fit -- this route has no phylo term at
all). **No profile or bootstrap target exists on this route through the R
bridge, for any parameter.** This matches the independently-measured
2026-09-03 full-pilot receipt
(`docs/dev-log/evidence/julia-r-parity/p2-pilot/2026-09-03-pilot-receipt.md`):
"`biv_gaussian_residual`'s fixed-effect targets ... are not profile/bootstrap
-ready on the Julia engine ... a pre-existing, documented bridge limitation."

**Consequence for this leaf's scope:** `biv_gaussian_residual` CANNOT be
qualified against G2/G3 -- there is no target to profile or bootstrap. This is
a structural gap in the bridge's target inventory (a residual bivariate fit
has no SD row to profile and its fixed-effect rows are unconditionally
excluded), not a numerical fluke and not something fixable inside this leaf's
OWNS (`R/julia-bridge.R`'s comparison-function rows only). Per this leaf's own
"never round up" rule, `biv_gaussian_residual` is reported **NOT COVERED**:
its `r_bridge_status` stays `partial`, its G3 fence sentence is RETAINED
verbatim, and its `next_action` is updated to name this concrete blocker
instead of the generic "Qualify bridge-side inference (G3)" text. A follow-up
capability leaf (adding a residual-bivariate profile/bootstrap route to the
bridge) is flagged separately, out of scope here.

The remaining three routes below ARE fully qualifiable and are the ones this
manifest plans fits for.

## Routes and targets

| route (capability_id) | fixture | target profiled | bootstrap | R | time estimate |
|---|---|---|---|---|---|
| `base_gaussian_location_scale` | DRM.jl pin `test/parity/fixtures/gaussian-locscale/data.csv` (committed) | `fixef:mu:x` | yes | 99 | 3 min |
| `gaussian_response_mask` | synthetic, `row_gaussian_response_mask_data()` in `tools/parity-p2-pilot.R` (seed=1, n=60, `y[1:6] <- NA`, `missing = miss_control(response = "include")`) -- matches `tests/testthat/test-julia-missing.R`'s live-Julia recipe exactly | `fixef:mu:x` | yes | 99 | 3 min |
| `plain_binomial_nonphylo` | DRM.jl pin `test/parity/fixtures/binomial-trials/data.csv` (committed) | `fixef:mu:x` | yes (#1123 fixed; both engines confirmed to complete in a pre-flight probe, ~8s at R=5) | 99 | 3 min |
| `biv_gaussian_residual` | DRM.jl pin `test/parity/fixtures/gaussian-bivariate-rho12/data.csv` (committed) | NONE READY -- see finding above | NOT ATTEMPTED (no ready target) | -- | 1 min (record the refusal message only) |

One target per route (a single named fixed-effect coefficient, `fixef:mu:x`)
keeps this a capability-parity check, not a coverage campaign -- each route
gets exactly the ONE profiled quantity the ledger's G1 gate asks for.

## Tolerances (stated a priori, before any number is measured)

- **Wald / profile CI agreement** (link-scale `lower`/`upper` from `confint()`):
  `abs(delta) <= 1e-4` on both bounds, matching this repo's existing coefficient
  /logLik same-target parity bar (e.g. the location-scale and Workflow-G rows'
  claim_boundary text). Historical same-fixture deltas measured 2026-09-03 were
  1e-5 to 1.6e-5 (profile) and 1e-6 to 4e-6 (wald), so 1e-4 is a real,
  non-vacuous bar with headroom, not a bar set to the measured number.
- **Bootstrap CI agreement**: DRM.jl's `bootstrap_result` and drmTMB's native
  bootstrap draw from INDEPENDENT RNG streams even when both are called with
  the same nominal `seed` -- confirmed by the same 2026-09-03 receipt
  (bootstrap deltas were 1e-1 to 1e-2 scale vs 1e-5 to 1e-6 for
  wald/profile on the identical fixtures). This run does not expect the seed
  to be honoured identically and states the DISTRIBUTIONAL check up front:
  the two engines' 95% percentile bootstrap CIs must OVERLAP (`max(lower) <=
  min(upper)`), and the nonconverged-replicate count (`bootstrap.failed`) is
  quoted for both engines rather than compared pointwise.
- **G6 red control**: re-checking the SAME measured profile/wald deltas against
  a tightened `1e-9` tolerance is expected, a priori, to FAIL on at least one
  route (proving the 1e-4 bar is discriminating, not vacuous), since the
  historical deltas above (1e-5 to 1.6e-5) already exceed 1e-9 by 4-5 orders of
  magnitude.

## Boundary-honesty cell (G4) and the #631 regression test (G8)

ONE additional, PURPOSE-BUILT cell -- not one of the four routes above, and not
claimed as a G2/G3 same-target comparison: a SYNTHETIC `plain_binomial_nonphylo`
-shaped fixture engineered for quasi-complete separation (`n=40`, `x in
{-2, +2}`, success probabilities `{0.02, 0.98}`, `trials=8`), so the `mu:x`
coefficient's MLE sits at/near a real boundary (the profile likelihood does not
cross the LR threshold on at least one arm). A pre-flight probe (this run,
below) already exercised this cell once to confirm the mechanism before
committing to it:

- `engine="julia"`: `coef(mu:x) = 312` (the optimizer runs toward the
  boundary); `confint(..., method="profile")` on `fixef:mu:x` raises an R-level
  error propagated from DRM.jl's own #631 backstop
  (`_bridge_inference_flatten`), message containing "refusing to return an
  infinite bound" -- never a silently-returned `Inf`. A direct read of the raw
  Julia `profile_result(...).stats` for this coefficient (bypassing the R
  flatten step, for audit only) shows `lower_endpoint_failed = TRUE`,
  `upper_unbounded = TRUE`, `lower/upper = -Inf/Inf` on the AUDITABLE surface --
  exactly the ±Inf-plus-flags convention #631's docstring describes.
- `engine="tmb"`: `coef(mu:x) = 2.26`, `confint(..., method="profile")`
  returns a normal finite interval with `profile.boundary = FALSE` -- TMB's own
  optimizer does not land at the same boundary on this fixture (a genuine,
  separately-noted engine difference in how far each optimizer runs under
  quasi-separation, not a numerics bug in either engine).

This is the vehicle for BOTH G4 (both engines report boundary status honestly;
DRM.jl's `lower_endpoint_failed`/`upper_endpoint_failed` flags read and quoted)
and G8 (a real, reproducible fixture that exercises the #631 refusal path
through the ACTUAL public `confint.drmTMB_julia()` entry point -- the path A0
found no test reached -- with an assertion that the call never yields a
non-finite bound to an R caller). Estimate: already run once above (~15s); the
qualification script re-runs it once more for the receipt, budgeted at 2 min.

## Time budget

3 min x 3 qualifiable routes + 1 min (biv_gaussian_residual refusal receipt) +
2 min (boundary/G8 cell) + ~5 min script/session overhead (one JuliaCall boot,
paid once) = **~20 minutes total**, comfortably inside the 30-min/cell and
~2-hour leaf budgets. All four routes' evidence (including the one that
cannot be qualified) fits in a single script invocation / single Julia
session.
