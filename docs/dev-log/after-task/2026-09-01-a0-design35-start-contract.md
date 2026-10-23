# After-task — A0: decide the public start contract (design 35)

**Lane:** `claude/rev-parity-a0-design35`, Claude, drmTMB reverse-parity ARC A.
**Branch base:** `origin/main` @ `27073059e`. Docs-only.

## What changed

`docs/design/35-optimizer-start-map-multistart.md`:

1. "Future Start Contract" -> "Public Start Contract (DECIDED 2026-09-01;
   implementation in progress)". The label namespace (`fixef:` / `sd:` / `cor:`)
   and all five binding requirements are carried over **verbatim** — only the
   status changed.
2. New section "Objective At A Point", defining `objective_at()` over the same
   label vocabulary, with the self-consistency anchor
   `objective_at(fit, <own optimum>) == -logLik(fit)` as a required test.
3. New "2026-09-01 Amendment" section stating what the amendment does not do.

## Why

DRM.jl#575 blocks q4 bridge promotion, which blocks the parity programme. Its
diagnosis requires evaluating each engine's objective at the other's fitted
point. DRM.jl has `reml_objective_at`; drmTMB could do neither half, so the
2026-09-01 diagnosis was done by hand in a scratchpad and is not reproducible
from the package.

## A correction recorded, not repaired quietly

The committed bridge design note
(`docs/dev-log/evidence/julia-r-parity/ayumi-target/objective-at-bridge-note.md`)
assumes an R-side wrapper can reuse a fitted object's cached Julia-side
`prob`/`Q_cond` handles. **That premise does not hold.** `Q_cond` appears nowhere
in this repository; `drm_julia_call_bridge()` passes formula/data/tree/options
into `DRM.drm_bridge` in one `JuliaCall::julia_call`, and everything built
Julia-side is discarded on return — R keeps only the flat result list as
`fit$bridge`. This is recorded in design 35 and is owed to the DRM.jl parity
lane (session `DRM.jl2`), which owns that note.

## Two design calls made here

1. **Surface is `drm_control(start = )`, not `drmTMB(start = )`.** `start` is
   already reserved in `drm_control_reserved_names()`, and `drmTMB()` rejects
   arguments it does not name, so a second control channel would compete.
2. **All three label families ship together.** A `fixef:`-only start would not
   serve the motivating case, whose whole dispute is in the variance block.

## Verification

Docs-only; no code path touched, so no test or check was run. That is the
correct scope for this slice, not an omission — the implementation slices A1-A3
carry the TDD burden.

## NOT claimed

Nothing is implemented. `start` remains reserved and `drm_control()` still
errors on it. No bridge route promoted, no `r_bridge_status` changed, no row of
`inst/extdata/julia-capabilities.tsv` touched, DRM.jl#575 unresolved, and no
release motion — D-164 holds drmTMB's CRAN submission. Not merged to `main`.
