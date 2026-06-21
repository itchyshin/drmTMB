# In-process DRM.jl profile/bootstrap intervals ("maximized in Julia")

**Status:** design / scoping note (plan before code). Read-only investigation; no
code change. **Reader:** drmTMB + DRM.jl method developers.
**Source:** owner steer ("speed up profile; this can be maximized in Julia") +
a read-only map of DRM.jl (`src/inference.jl`, `bridge.jl`, `bootstrap_q4_phylo.jl`)
and the drmTMB bridge (`R/julia-bridge.R`, `R/profile.R`), 2026-06-20.

## Purpose

The owner asked whether profile/bootstrap intervals can be "maximized in Julia."
Profile and bootstrap are repeated-re-optimization workloads, exactly where Julia's
compiled objective + AD + warm-started re-solves should win. This note records what
already exists, the real gaps, and a staged, parity-gated plan.

## Verdict: already most of the way there

The in-process loop is **not** green-field — it largely exists, and the framing that
"the callr bridge round-trip swamps per-point profiling" describes an architecture
that was never built:

- **The DRM.jl profile loop is already in-process.** `confint(fit; method=:profile)`
  -> `profile_result` (`DRM.jl src/inference.jl:70-218`) fixes `theta[k]`, re-optimizes
  the nuisance parameters over the stored `fit.nll` / `fit.nllgrad`, **warm-starts each
  profiled solve from the previous optimum**, and root-finds the chi-square_1 crossing
  by the envelope-theorem slope (Venzon-Moolgavkar) with a bisection fallback. It is
  threadable and never re-enters `drm()`.
- **The bridge is batched, not per-point.** `confint(engine="julia")` makes **exactly
  one** `JuliaCall::julia_call()` into `DRM.drm_bridge_inference` (`DRM.jl src/bridge.jl`),
  and that single call runs the *entire* profile grid / bootstrap B-loop inside one
  resident Julia process (`R/julia-bridge.R:718-754`). There is no per-profile-point
  R<->Julia round-trip.
- So the **~3-min cost is per-`confint()`-call session cost** (JuliaCall first-use
  compile + payload re-serialization + one cold `_bridge_fit` re-fit from the payload),
  NOT a per-objective-evaluation cost.

The work is therefore primarily **Julia-side widening + warm-start**, with a thin
R-side change — not a new subsystem.

## Current state (honest)

Already provided, in-process, Julia-side:
- Profile-likelihood CIs for all Gaussian models (general, LocScale q2, sigma-phylo),
  warm-started, exact-gradient-where-available (Takahashi O(p) sparse gradient for q4
  phylo; `_ls_marginal_grad` for LocScale), threadable.
- A one-call bridge primitive (`drm_bridge_inference`) + a persistent R-side Julia
  session (`drm_julia_setup_state`).
- Parametric bootstrap end-to-end (`bootstrap_result` / `bootstrap_sigma_a`).

The real gaps:
1. **Bootstrap is cold-start per replicate** — `run_one!` calls a full `drm(...)` per
   replicate (recomputes E-step mode, prior, sparse matrices, optimizer); no warm start
   from `fit.theta`, no shared state. This is the genuine "re-optimize many times"
   workload not yet exploiting Julia's cheap warm re-solve.
2. **Bridge scope is locked to the SD block** (`:resd*`); coefficient and direct
   scale/correlation profile targets are NOT reachable through the bridge even though
   `profile_result` already computes them. (Coefficients are the native R/TMB weak spot.)
3. **Per-`confint` cold re-fit** — each call re-runs `_bridge_fit` from the serialized
   payload; the resident Julia fit is not reused across inference calls. This is the
   dominant slice of the "3 min."
4. No resident-fit handle R-side; the payload (data + Newick) is re-serialized per call.
5. No coverage/parity evidence banked; the "Julia speedups" matrix row is
   experimental/planned.

## Staged, parity-gated plan

Parity-not-coverage: each stage promotes a cell only with numeric agreement against the
native R/TMB lane on the SAME scope, plus the full claim-guard evidence package
(point estimate, log-lik, CI/status, convergence, failure count, threads, version).

- **Stage A — widen the bridge to direct scalar targets (do this first; small/medium).**
  Generalize `drm_bridge_inference(method="profile")` past `:resd`-only to the direct
  scalar targets `profile_result` already computes (scale/SD/correlation, then
  coefficients); flatten multi-row results. R: per-target response-scale transforms in
  `drm_julia_inference_confint_row*` + extend `drm_julia_profile_targets`. Parity gate:
  `engine="julia"` profile CI vs native `confint.drmTMB(method="profile")` to ~1e-4 on
  the working scale. No new optimizer, no new statistics — pure widening of the only
  validated in-process loop. Unlocks the highest-value R weakness (coefficient profiles).
- **Stage B — warm-started in-process bootstrap (medium; the real algorithmic work).**
  A private `_refit_warm(fit, ynew)` reusing the assembled sparse structure / prior /
  E-step scaffolding and re-optimizing from `fit.theta`, wired into `run_one!` /
  `bootstrap_result` behind `algorithm=:warm` (default stays cold until parity banked).
  Parity gate: per-replicate optima match cold refits; distributions agree within MC
  tolerance; keep cold as the boundary-failure fallback. Bootstrap is the workload
  native TMB cannot make cheap, so this is the clearest Julia differentiator.
- **Stage C — resident fit handle (small/medium).** A session-scoped Julia fit registry
  + R handle so repeated `confint`s skip the cold re-fit + payload re-serialization;
  fall back to the payload path on session restart. This is where most of the per-call
  "3 min" goes away for the 2nd+ inference call on a fit.

## The key design decision

Keep the whole loop in ONE Julia session and reuse a RESIDENT fit — extend the
existing in-process discipline to the fit object (Stage C) and the bootstrap inner
solve (Stage B warm start), rather than "building" an in-process loop that already
exists. Reuse the optimizer/AD DRM.jl already standardizes on (Optim.jl LBFGS +
ForwardDiff, exact stored gradients where available); do NOT add a second solver/AD.

## Risks and boundaries

- Keep the three lanes separate (native R/TMB / direct DRM.jl / Julia-via-R), each
  independently parity-gated; do not let warm-start leak into the native TMB lane.
- Speed, not new statistics: no new families/RE structures/boundary claims/missing-data.
  REML + location-only stay in DRM.jl `src/experimental/`, off the bridge surface.
- Warm-start (Stage B) can land on a different near-boundary optimum: per-replicate
  parity gate + cold fallback are mandatory.
- Handle invalidation (Stage C): detect session restart, fall back to payload path;
  never cache across R sessions.

## Recommendation

**Stage A now** — highest value-per-effort: pure widening of an already-validated
in-process loop, unlocking coefficient/scale/correlation Julia profiles (the native R
weak spot), and the cheapest credible first evidence for the "Julia speedups" row.
Sequence B (warm bootstrap) and C (resident handle) after; do not block A on them.
Relative to other threads, Stage A is a clean near-term slice; Stage B is the marquee
Julia differentiator (bootstrap is what native TMB cannot make cheap) but carries the
real implementation risk, so it wants its own focused effort.

## Stage A — exact change site (code-verified 2026-06-20)

Confirmed against the code so a fresh session can execute Stage A immediately (the
cross-repo edit + ~3-min callr parity loop is what needs the fresh session, not more
scoping):

- **The capability already exists and is TESTED.** `DRM.jl/test/test_profile_ci.jl`
  fits `drm(bf(@formula(y ~ x + z), @formula(sigma ~ 1)), Gaussian(); data)` and
  asserts `confint(fit; method = :profile)` returns one profile row per coefficient
  (param/coef/estimate/lower/upper), profile ≈ Wald for the mu coefficients. So
  DRM.jl natively profiles coefficients; `parm` filters by parameter BLOCK
  (`:mu`, `:sigma`, `:resd`, ...) and `parm = nothing` returns ALL coefficients
  (`DRM.jl/src/inference.jl:101-104, 142-224`).
- **The bridge is the only thing locking it to the SD block.**
  `DRM.jl/src/bridge.jl:74-95` (the `bridge_method == "profile"` branch) hardcodes
  `profile_result(fit; parm = [:resd_sigma, :resd, :resd_mu])` then
  `row = _bridge_pick_sd_row(result.ci)` (a SINGLE SD row) and flattens that one row
  via `_bridge_inference_flatten` (`:416`). The bootstrap branch (`:95-119`) is the
  same single-SD-row shape.
- **Julia edit (small):** add an `opts[:parm]`/`opts[:targets]` passthrough; when
  absent keep `[:resd_sigma, :resd, :resd_mu]` + single SD row (BACKWARD COMPAT for
  the current R side); when present pass it (or `nothing` = all) to `profile_result`
  and return ALL rows via a multi-row variant of `_bridge_inference_flatten`.
- **R edit (the intricate part):** the confint bridge path
  (`drmTMB/R/julia-bridge.R` `drm_julia_inference_confint_row`/`_multi`,
  `drm_julia_profile_targets`) must request the wider target set, parse the multi-row
  response, and map each returned `(param, coef)` to the drmTMB parm name +
  per-target response-scale transform (linear_predictor identity for coefficients,
  exp/tanh for scale/SD/correlation -- the same transforms native confint uses).
- **NOT splittable into a value-delivering Julia-only increment:** the Julia change
  alone changes no user-facing behaviour (the current R side still asks for SD-only);
  value lands only when both sides change together, and the only full-path check is
  the callr Julia harness (`tests/testthat/helper-julia-bridge-path.R`,
  `test-julia-inference.R`) at ~3 min/round-trip. Make both edits, run ONE harness
  parity check (engine="julia" profile coefficient CI vs native
  `confint.drmTMB(method="profile")` to ~1e-4), and revert BOTH if it fails.
- **Verification env confirmed:** Julia 1.10.0 at `/Users/z3437171/.juliaup/bin`,
  DRM.jl on `shannon/overnight-audit-verify-20260619`, bridge harness helpers present.

## Boundary

Design/scoping note only; no grammar/likelihood/bridge code changed here. Each stage
ships with its own parity evidence + claim-guard package before any "Julia speedups"
cell moves.
