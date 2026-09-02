# After-task: A4 (objective-at bridge) + A5 (cross-engine receipt)

## What was built

- `drm_julia_reml_objective_at(fit, beta, Lambda, rho12 = NULL)`
  (`R/julia-bridge.R`, internal, no export, no Rd): rebuilds the bivariate
  q=4 phylogenetic REML problem from a `engine = "julia"` fit's own stored
  `bridge_payload` (the same formula/data/tree/options that produced the
  fit) and evaluates DRM.jl's `reml_objective_at` at a supplied
  `(beta, Lambda, rho12)` point, via a second Julia function
  (`drmTMB_reml_objective_at`) registered from R the same way
  `drmTMB_drm_bridge` already is.
- `tests/testthat/test-julia-objective-at-bridge.R`: two refuse tests
  (TMB-engine fit; non-4x4/asymmetric Lambda) that run without Julia, plus
  two live-Julia tests ("finite", "anchor") gated by `drm_skip_live_julia()`.
  All four pass against DRM.jl pinned at `feat/575-objective-at @ dc3ce190`.
- `docs/dev-log/evidence/julia-r-parity/ayumi-target/
  2026-09-02-a5-cross-engine-receipt.R` + `.md`: the #575 by-hand manoeuvre
  (`2026-09-01-matched-q4/warmstart_575.jl`) as a committed, pinned,
  re-runnable script producing the 2x2 cross-engine objective table.

## The private DRM.jl names, and the maintenance liability ("YES, but")

The leaf-a4.md spike note (2026-09-01) named `make_problem_from_Q` and
`_q4_structured_precision` as the two private names the shim would need.
**That is wrong for this fixture.** Reading `dc3ce190`'s source directly:
those two names are DRM.jl's LEVEL-INDEXED `relmat`/`animal`/`spatial` q4
route (`_fit_bivariate_q4_structured`, `src/gaussian_bivariate.jl:679`) --
a different front end the `biv-q4-phylo-reml` fixture (kind = phylo) never
reaches. The phylo q4 REML route (`_fit_bivariate_q4_phylo`,
`src/gaussian_bivariate.jl:832`) builds its problem via the PUBLIC
`make_problem(phy, ...)`, after `phy = augmented_phy(tree)` (also PUBLIC) --
matching `warmstart_575.jl` exactly. This was caught by reading the source
before writing code, not discovered by a failing test; the gate CHECK
(`.unlazy/true-parity/gates/leaf-a4.md`, A4-G4) has been corrected in place,
with the correction recorded as EVIDENCE there.

The shim's actual dependency, all in `src/bridge.jl` / `src/gaussian_bivariate.jl`
at `dc3ce190`, reached by qualified name (Julia does not restrict access to
underscore-prefixed module internals -- the same pattern
`drmTMB_drm_bridge_fixef_inference`, already shipped in this file, uses for
`_bridge_data`/`_bridge_formula`/`_bridge_family`/`_bridge_fit`):

- `DRM._bridge_data(data)`
- `DRM._bridge_formula(formula, family, data; labels = true)`
- `DRM._bivariate_q4_marker(rhs)`
- `DRM._design(response, rhs, data)`
- `DRM._phylo_species_index(phy, group_labels)`

**"YES, but"**: reachable with zero DRM.jl edits, but five private names is a
real maintenance liability -- any of these could be renamed without notice
or deprecation, and a rename would fail this shim silently at Julia-call time
rather than at build time. The request to the DRM.jl lane: expose a supported
entry point that accepts `(payload, phi, beta0)` directly (DRM.jl#569 is
already open about bridge-side diagnostics and is the natural home), or fold
`feat/575-objective-at` into PR #579 (`feat/575-exact-reml-gradient`, the
later, still-unmerged fix for the same issue) so this diagnostic and the
eventual fix share one entry point. That request is ours to make; it is
DRM.jl's lane's call whether and how to act on it.

## Numbers measured (fixture: `biv-q4-phylo-reml`, DRM.jl @ `dc3ce190`)

2x2 cross-engine objective table (normalised restricted log-likelihood,
`-logLik(fit_tmb)` / `reml_loglik` scale):

| evaluated at \ objective | TMB's objective | DRM.jl's objective |
|---|---|---|
| TMB's fitted point   | -219.613986 | -219.620688 |
| Julia's fitted point | -219.634993 | -219.630326 |

Self-consistency anchors: TMB `0.000e+00` (exact), DRM.jl wrapper
`9.487e-05` (< DRM.jl's documented 2e-4 inner-alternation floor). This
reproduces the 2026-09-01 by-hand finding within noise: DRM.jl's objective,
evaluated at TMB's fitted point, is BETTER (`-219.620688`) than the point
DRM.jl's own solver returned (`-219.630326`) -- a `+0.009638` gap, matching
the original `+0.009724` -- direct evidence both engines maximise the SAME
restricted likelihood and DRM.jl's own solver stopped short of its own
optimum here (mode-finder, not objective-translation). Full table and
derivation: `2026-09-02-a5-cross-engine-receipt.md`.

## A real gap found in the A2/A3 public-start-label surface (not this
## slice's to fix)

While building A5's receipt, `objective_at()` (R/objective-at.R) was found
NOT to reach this fixture at all: `objective_at(fit_tmb, at =
list("fixef:rho12:(Intercept)" = ...))` aborts "Unknown public start label"
because `biv_gaussian`'s `beta_rho12` TMB start vector carries no column
names; a `sd:mu:mu1:phylo(...)` label aborts the same way because the q4
phylo covariance block (`log_sd_phylo`/`theta_phylo`) lives outside
`spec$random` entirely, while the `sd:` family resolver looks there. Both
verified empirically (fit the fixture, called `objective_at()` directly,
read the error) while building this receipt, not inferred. A5's receipt
therefore computes "TMB objective at TMB's own point" as `-logLik(fit_tmb)`
directly, and "TMB objective at Julia's point" by reusing
`objective_at()`'s own six-line evaluation mechanism
(`drm_pin_tmb_object_to_optimum()` + `obj$fn()`, re-pinned) with the
internal TMB parameter names substituted directly, since the label
translator cannot reach them for this model yet. This is flagged here for
the A2/A3 (`claude/rev-parity-a2-start`, `claude/rev-parity-a3-objective-at`)
lane, not fixed silently by this slice.

## What is NOT covered

- Not a public API: no export, no Rd, `NAMESPACE` unchanged.
- Only the `biv_gaussian` q=4 phylogenetic REML bridge route (all four axes
  sharing one `phylo()` term). A non-phylo (relmat/animal/spatial)
  structured q4 fit, or a q=2 bivariate phylo fit, is refused by the same
  class/dimension/REML check that refuses a TMB-engine fit.
- Pinned to an UNMERGED DRM.jl branch (`feat/575-objective-at @ dc3ce190`).
  The receipt refuses to run (loud message, exit 1) against any other
  `DRM_JL_PATH`, including the later `feat/575-exact-reml-gradient @
  cda42b8c` (PR #579) clone S4 already uses for other diagnostics --
  confirmed as a RED control (A5-G2).
- No coverage, recovery, speed, or interval claim. Diagnosis only, per both
  the receipt's own header and A5-G4's gate.
- The `objective_at()`/public-start-label gap above is reported, not fixed.

## Deviations from the brief

- The brief's leaf-a4.md named `make_problem_from_Q`/`_q4_structured_precision`
  as the two private names; corrected to the five actually used (see above),
  with the gate CHECK text corrected in place and the correction recorded as
  its own EVIDENCE line, rather than silently satisfied by adding unused
  references to the two originally-named (and inapplicable) symbols.
