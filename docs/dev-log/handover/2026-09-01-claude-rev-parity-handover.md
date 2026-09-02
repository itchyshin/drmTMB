# Handover — drmTMB REVERSE-parity lane (Claude), 2026-09-01 overnight

**Read this first.** Everything below is on local branches. **Nothing is merged, nothing is
pushed, no PR exists, no release motion was taken.** D-164 still holds CRAN.

Lane: `claude/rev-parity-*`, all off `origin/main` @ `27073059e`. Lease
`claude:drmTMB:3829`. Platform: Claude.

---

## In one paragraph

drmTMB can now answer the question the R↔Julia parity programme was stuck on. `drm_control(start = ...)`
starts a fit at a supplied, label-named point; `objective_at()` reports a fit's objective at
such a point without refitting; both use one label vocabulary. Together they perform the
DRM.jl#575 manoeuvre — evaluate one engine's objective at another's fitted point, and cross-start
one engine from the other's point — which on 2026-09-01 had to be done by hand in a Julia
scratchpad. Alongside that, a fit now carries its own final gradient, `check_drm()` reports
Hessian conditioning, builds are identifiable by git SHA, and three places where drmTMB's parity
evidence *could not report a failure* now can.

## The branches

| branch | head | what |
|---|---|---|
| `claude/rev-parity-integration-all` | — | **START HERE.** ARC A + B + D merged, conflicts resolved |
| `…-a0-design35` | `a7ccd5f25` | design 35: public `start=` contract DECIDED + `objective_at` section |
| `…-a1-start-tests` | `049a60c21` | 10 RED test blocks for the contract |
| `…-a2-start-impl` | `cb1671cb7` | `drm_control(start=)` + clamp/REML repairs |
| `…-a3-objective-at` | `7afe0b8fd` | exported `objective_at()` + penalized-fit fix |
| `…-b1-stored-gradient` | `0b0f869d9` | `fit$gradient`, `fit$gradient_max_component` |
| `…-b2-check-conditioning` | `7b89d0279` | `hessian_conditioning` row + tolerance fix |
| `…-c1-naming-spec` | `eb952d119` | `docs/design/258` — spec only, deliberately stops |
| `…-d1-capability-status` | `dd645c778` | landed the stranded R↔Julia parity board |
| `…-d2-loud-julia-skip` | `6f8871468` | #1081 — a green run states its own boundary |
| `…-d3-error-not-skip` | `c8329c80b` | #1083 — parity tests fail on code errors |
| `…-d4-provenance` | `7ab8cf74b` | `drm_provenance()` + configure bake |
| `…-drmjl-findings` | `2648d4422` | findings owed to the DRM.jl lane (+1 correction) |
| `…-board-entry` | `dfeccc931` | lane declared on the coordination board |
| `…-routing-receipt` | `9068317b5` | plan-vs-actual routing input |

## The capability, demonstrated on the merged tree

    anchor: objective_at(own optimum) = 167.361354778 ; -logLik = 167.361354778 ; diff 0.0e+00
    rival point is WORSE by          = 0.301863757
    cross-start from rival returns   = -167.361354778 (orig -167.361354778)
    fit carries its own gradient     = 1.117e-05, worst component beta_sigma
    check_drm conditioning row       = min_eig=212.7; cond=1.429
    build provenance                 = 558d240d074e
    anchor on a PENALIZED fit: diff  = 0.0e+00

## ⚠ Read this first: the full suite CRASHED R, and the count said zero failures

The first full-suite run on the complete integration reported **0 test failures** and then
aborted:

    An irrecoverable exception occurred. R is aborting now ...
    7: tryCatch(object$obj$he(object$opt$par), error = function(e) e)
    8: check_hessian_conditioning(object)
    9: check_drm.drmTMB(fit2)

**`obj$he()` segfaults on a deserialized fit** (a `saveRDS`/`readRDS` round trip nulls the TMB
pointer), and a segfault cannot be caught by `tryCatch()`. So the new `hessian_conditioning`
row could take down a whole R session on any fit a user had saved and reloaded — worse than the
additivity defect the adversarial pass found in the same row.

Measured: after `readRDS` the pointer formats as `<pointer: 0x0>`; **`obj$gr()` tolerates that
and returns**, which is exactly why the pre-existing gradient check never surfaced this; `he()`
does not. And **`check_drm()` revives the pointer** — dead on entry, live afterwards — so a
guard at the top of the function never fires on that path. Hence two guards, the second
immediately before the call. Detection uses `format(ptr)`, not `TMB:::isNullPointer()`, so no
`:::` reaches package code.

**The guard was DISPROVEN, not merely unproven.** The re-run crashed **again**, same line, with
the guard in place — the inner frame is `f(x, type = "ADGrad", order = 1)`. `check_drm()` revives
the pointer, so it is not null when any guard tests it, but the revived **ADGrad tape** is still
unusable. Pointer-nullness is the wrong predicate and no guard of that kind can work.

**So `obj$he()` is being removed entirely**, in favour of `sdreport`'s fixed-effect covariance —
measured as carrying the *same* numbers (`cond(H) = 2.408905027` vs `cond(cov) = 2.408903421`;
`min_eig(H) = 180` vs `1/max_eig(cov) = 180.00012`), surviving serialisation intact, and needing
no C++ call at all. **It also closes the random-effect gap**: `he()` errors outright on RE fits
("Hessian not yet implemented for models with random effects"), while `cov.fixed` is present and
gave `cond = 7.065` on a test fit — so the limitation Rose documented becomes a capability.

I took that call while you were away because the alternative was leaving code that **kills a
user's R session** on any saved-and-reloaded fit; it is on an unmerged branch you will review;
and it is strictly better on three independent axes. The reasoning is recorded in the ledger.

**The durable fix is yours to decide.** Stop calling `he()` and take the conditioning from
`sdreport`'s covariance instead: already materialised, serialization-safe, and carrying the
*same* condition number (`cond(H) == cond(H⁻¹)`). That removes the class rather than guarding one
instance — but it changes what the row reports, so it is a design call, not an overnight one.

## What an adversarial pass refuted — and this is the part worth reading

A fresh Opus reviewer attacked the claims I had marked verified. **It refuted two, and a third
error was mine.** All three are fixed and re-verified; none was papered over.

1. **The anchor was broken on penalized fits.** `objective_at(fit, own optimum)` differed from
   `-logLik(fit)` by *exactly* `fit$phylo_penalty`, **silently**. Cause: `R/drmTMB.R:684` stores
   `logLik` unpenalized while `objective_at()` returned the penalized objective. **My own
   verification had used a fixed-effect Gaussian fit — i.e. I verified the anchor only where it
   could not fail.** Fixed (`ddc9b3e3e`): adopts `logLik()`'s convention and re-evaluates the
   penalty *at the queried point*, so the invariant holds away from the optimum too.
2. **`hessian_conditioning` was not purely additive.** It flipped `attr(x,"ok")` to FALSE on a fit
   `origin/main` calls healthy, driven by `min_eig = -2.7e-14` against a top eigenvalue of ~860 —
   round-off dust through a bare sign test. Fixed (`7b89d0279`) with a scaled tolerance
   (`100·eps·max_eig`), justified by AD's O(eps) floor versus finite differences' O(√eps).
   **It also corrected me**: my "clean separation" demo was itself roundoff-dominated — across
   seeds the `min_eig` sign flips and `cond` swings 1.4e18 / 2.5e15 / 1.1e16. I had reported that
   as evidence; it was noise.
3. **I relayed a false finding twice.** I said DRM.jl has no label-map producer. **It does** —
   `src/bridge.jl:1272-1279`. A sub-agent claimed it; I verified the *easy* half (the spec's
   base-R column, 7/7 rows against `model.matrix()`) and never checked the *negative existence
   claim*. Corrected in the handover at `2648d4422` before it reached that lane.

It also found three defects nobody had claimed, all now fixed: a start outside the log-sigma clamp
band returned **`converged` without moving** (`tanh` saturates, gradient ~1e-13, `nlminb` reports
code 0) — the exact false answer the #575 manoeuvre must never give; a `fixef:` start under REML
was silently ignored while the same label *errored* in `objective_at()`; and `hessian_conditioning`
is permanently `NA` for **every random-effect or REML fit** (`obj$he()` has no Laplace support) —
now stated plainly in three places rather than left to be discovered.

## Decisions waiting for you

1. **Naming authority** (blocks C2–C4). Should canonical coefficient names follow **base-R
   spelling** (drmTMB authoritative, DRM.jl's fixtures translate) or **DRM.jl's translated map**?
   The spec is `docs/design/258`; it recommends base-R and refuses to settle it, because it is
   cross-repo governance. Note the sharpened question from the correction above: a producer
   *does* exist on both sides — the real issue is whether the map is **populated and correct for
   the constructs that fail**.
2. **Ultracode opt-in**, still unspent, for two places it would pay: an adversarial
   breaking-change audit of the naming change, and a loop-until-dry gap sweep to learn whether
   the ten-gap list is actually complete.
3. **PR #1112 ordering.** It rewrites 216 lines of `R/julia-bridge.R`. **A4 and A5 are HELD**
   behind it (D-87 — the overlap is yours to resolve, not mine). A4's core question is already
   answered from source: the shim is reachable with zero DRM.jl edits, but only via two DRM.jl
   **private** names, so it is a "yes, but".
4. **The Student-t `nu` labels** and the **RE/REML conditioning gap** are recorded limitations,
   not bugs. Widening either is a design call.

## Fences that held all night

DRM.jl untouched — a pinned baseline (`main@f4778964`) re-checked after every step, `FENCE HELD`
every time. All 14 branches diffed for `inst/extdata/julia-capabilities.tsv` and
`.github/workflows/`: **0 forbidden-path changes on every one**. No route promoted, no ledger row
changed, no version bump, nothing merged or pushed.

## If you want the detail

- Acceptance ledger: `.unlazy/rev-parity/` (git-excluded run state) — 51 gates, per-slice evidence,
  two honest `ABANDON`s, the cross-arc merge map, and my own four wrong gates recorded.
- Per-slice after-task notes: `docs/dev-log/after-task/2026-09-01-*.md`.
- Routing + reconciliation: `docs/dev-log/plan-actual/2026-09-01-*`.
