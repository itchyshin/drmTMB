# A9e — refuse a structured-marker non-intercept slope through `engine = "julia"` before Julia boots

Date: 2026-09-05 · Lane: parity-joint-20260905 · Ledger: `.unlazy/parity/gates/leaf-a9e-marker-lhs.md` · Issue: drmTMB#1146 (DRM.jl#620/#621)

## Why now
At the pin (`430ef64cc`, carrying DRM.jl#621's `_check_phylo_re_lhs`), DRM.jl already refuses
`phylo(1 + x | g)` and the equivalent `relmat()`/`animal()`/`spatial()` shapes rather than silently
dropping the slope, so the silent mis-fit #1146 worried about is unreachable today. #1146 asks for the
R-side guard anyway — defense-in-depth so a future DRM.jl refactor of the more specific admission
checks cannot reopen the gap — plus a CI test that fails if the shape ever routes to Julia without a
refusal.

## What was built
`drm_julia_refuse_marker_slope_unsupported()` in `R/julia-bridge.R`, called at the top of
`drmTMB_julia_bridge()` before any Julia interaction (same place `drm_julia_refuse_reml_unsupported()`
style refusals live). It collects every `phylo`/`relmat`/`animal`/`spatial` term across all formula
entries whose left side of the bar is not `(Intercept)` alone (via
`drm_julia_collect_marker_slope_terms()`) and aborts naming the marker, the slope term, the pin's
limitation, and `engine = "tmb"` as the route that fits it. `phylo_interaction` is excluded — its
parser already forces an intercept-only pair effect, so a non-intercept lhs can never reach it.

Capability-gated: `drm_julia_marker_slope_pin_supports()` is the single switch, `FALSE` today because
the pin cannot fit ANY of these constructs. When a future pin lands one (DRM.jl#620's S8 follow-up,
the Gaussian two-SD phylogenetic random slope, is being built right now by leaf A9c), flipping that
function is a one-row change, not a rewrite of the guard.

Registry row `structured_marker_slope` added to `drm_julia_intentional_gates()` (and regenerated into
both `inst/extdata/julia-gates.tsv` and `docs/dev-log/dashboard/julia-gates.tsv`), so
`test-julia-gate-vs-engine.R`'s completeness/uniqueness check covers it.

New test file `tests/testthat/test-julia-marker-slope-guard.R`: refusal for `phylo()`/`relmat()` with a
non-intercept lhs (including the `0 + x` zero-intercept form), non-catch of intercept-only markers,
`engine = "tmb"` still fitting the two-SD Gaussian phylogenetic slope, the registry row, and a
data-contract pin on `drm_julia_collect_marker_slope_terms()`. None of these need a Julia install.

`tests/testthat/test-julia-slope-nongaussian.R`'s existing live-Julia Gamma-slope test was retargeted:
it used to assert DRM.jl's own refusal text after Julia booted; it now asserts the R guard's refusal
text and that Julia is never reached (`expect_false(grepl("Error happens in Julia", ...))`).

## What was measured (this run, reproduced from a killed prior attempt — nothing carried over as a claim)

**G1 — RED, at the pin, guard absent** (`git stash` on `R/julia-bridge.R`, live Julia,
`bf(y ~ phylo(1 + x | species, tree = tree), sigma ~ 1)`, `family = Gamma(link = "log")`,
`engine = "julia"`): reaches the JuliaCall subprocess. DRM.jl's own words, quoted verbatim:

```
Error happens in Julia.
ArgumentError: drm: `phylo(1 + x | species)` is not implemented on the univariate routes — only
`phylo(1 | species)` (intercept) is; drmTMB fits a two-SD phylogenetic random slope on Gaussian only,
tracked as a follow-up
```

`test-julia-slope-nongaussian.R` run against the guard-absent tree: 4 failures (the retargeted
assertions expecting the R guard's wording) — confirms the cell still reaches Julia without the guard.
Wall time for that one live-Julia test file: 31.8s.

`engine = "tmb"` on the same generative model (Gaussian, so this comparison uses the Gaussian DGP
from the ledger, not the Gamma cell) fits two independent structured-slope SDs:
`phylo(1 | species)` estimate 0.9447 (se 0.2119), `phylo(0 + x | species)` estimate 0.1382
(se 0.0867) — unchanged by this PR, native TMB path untouched.

**G2 — guard restored (`git stash pop`, MD5 of `R/julia-bridge.R` unchanged before/after), same Gamma
cell, `engine = "julia"`**: `test-julia-slope-nongaussian.R` now green (9 assertions), wall time 6.8s —
no Julia boot in that time, consistent with a pre-Julia R-side refusal. Message asserted present:
`"cannot fit a random slope"`, `"phylo"`, `"engine = \"tmb\""`, `"DRM.jl#620"`.

**G3 — tests**: `test-julia-marker-slope-guard.R` (new, 24 assertions) all green, no Julia required.
`test-julia-gate-vs-engine.R` (152 assertions, includes the new registry-row expectation) all green,
no Julia required.

**G4 — RED CONTROL**: commented out the `drm_julia_refuse_marker_slope_unsupported(formula)` call site
in `R/julia-bridge.R` (`sed`, single line, verified by `grep`), re-ran
`test-julia-marker-slope-guard.R`: 3 failures — the `phylo(1 + x | ...)` non-intercept case now hits a
*different*, pre-existing admission check (`"engine = \"julia\"` currently supports `phylo(1 | group,
tree = tree)` or `phylo(1+x | group, tree = tree)` in the `mu` formula.`", R/julia-bridge.R:2409) with
different wording, and the `relmat()` case hits its own pre-existing unconditional refusal
(R/julia-bridge.R, `"currently supports only `relmat(1 | group, ...)`"`) — both catch some of these
shapes today by accident of family/marker-specific code, which is exactly why #1146 asks for one
purpose-built, capability-gated guard rather than relying on those to keep covering it. Restored the
file from a pre-edit copy; `md5` before and after the round-trip: `88b6414f36416b676aec636bbad70cf9`
(identical). Re-ran `test-julia-marker-slope-guard.R` after restore: green again (24 assertions).

**G5**: scope held — only `R/julia-bridge.R`, the new test file, both `julia-gates.tsv` copies,
`NEWS.md`, and this after-task doc were touched. PR opened against `main`, not merged.

## Errors made in this resume
- None discovered in the carried-over diff itself. The one correction this pass made was procedural:
  the ledger's G1 example uses a Gaussian family, but Gaussian `phylo(1 + x | g)` is already refused by
  a *different*, pre-existing check (`drm_julia_slope_phylo_families()` excludes Gaussian from the
  cluster-3 admission), so it never reaches DRM.jl live regardless of this guard. The live RED/G1
  verification instead used the Gamma cell (`drm_phylo_slope_gamma_fit()`,
  `test-julia-slope-nongaussian.R`), which is the actual construct that reaches DRM.jl's live refusal
  and that this guard now intercepts earlier — matching what the pre-existing test file and the code
  comments in the diff already targeted.

## Kept from the previous (killed) attempt, and how it was re-verified
Every line of `R/julia-bridge.R`, both `julia-gates.tsv` copies, `test-julia-gate-vs-engine.R`'s diff,
`test-julia-slope-nongaussian.R`'s diff, and the new `test-julia-marker-slope-guard.R` were kept
unchanged from the uncommitted worktree state found at the start of this resume. Every one of them was
re-verified in this run: `test-julia-marker-slope-guard.R` and `test-julia-gate-vs-engine.R` re-run
green with `devtools::load_all()`; the Gamma live-Julia cell re-run RED (guard stashed) and GREEN
(guard restored) with the actual pin; the RED-CONTROL disable/restore cycle re-run with an MD5
byte-identity check. No number in this document is carried over from a prior session's claim — all are
freshly measured here. The `"Verified live at the pin (430ef64cc, 2026-09-05)"` prose already embedded
in the `R/julia-bridge.R` comments and the `julia-gates.tsv` evidence field by the prior attempt is
consistent with what this run independently reproduced.

## What this arc did NOT cover
- The `relmat()`/`animal()`/`spatial()` non-intercept cells were exercised only through the guard's
  pure-R collector and the pre-existing unconditional refusal already in `drm_julia_structured_payload()`
  for `relmat`/`animal`/`spatial` slopes — not against a live DRM.jl call the way the `phylo` Gamma cell
  was, since no test in the suite builds a working `animal()`/`spatial()` slope shape to compare against
  and building one was out of scope for this leaf.
- No change to leaf A9c's in-progress Gaussian two-SD phylogenetic random-slope DRM.jl port; this guard
  only decides what drmTMB refuses today and how the switch will be flipped later.
- The tip-identity / full-suite receipt was not regenerated by this leaf; that is A0's responsibility
  and is unaffected by this change (no `src/` or `.stan`/`.cpp` file touched).
