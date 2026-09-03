# N7 (#1127): live Julia tests no longer swallow engine errors into skip; one DRM_JL_PATH gate

**Reader**: anyone touching `tests/testthat/test-julia-*.R` or
`test-xfam-bridge.R`, or triaging a green run of the Julia-bridge test suite
that should have failed. Also relevant to anyone re-running the DRM.jl
77513aa0 pinned engine and wondering why three tests are skipped.

## What #1127 found

Sixteen sites across nine `test-julia-*.R` files (plus five more the issue
text under-counted: two nested inside `test-julia-tmb-parity.R`'s own
comment text, which the paren-aware oracle also matches, and five in
`test-xfam-bridge.R`) wrapped a live Julia-engine fit in
`tryCatch(..., error = function(e) testthat::skip(...))`. A hard engine
abort therefore reported as a green SKIP, not a red FAIL/ERROR — the same
defect class #1083 fixed in one place (`test-julia-tmb-parity.R`'s
`drm_parity_run()`) but which persisted everywhere else.

Compounding it: `drm_test_drmjl_path()`, the shared path helper, silently
dropped `DRM_JL_PATH` when called with no argument (its default parameter
was `"DRM_JL_PHYLO_PATH"`, and the fallback-to-phylo branch only fired for a
*different* named argument) — so a live run that set only `DRM_JL_PATH`
skipped the whole phylo test family instead of using it.

The oracle for this ledger (`.unlazy/night/bin/count-skip-swallow.py`)
counted **21** sites across **10** files on `main` (`d3d205486`): the
issue's 16, plus the 2 phantom matches inside a comment in
`test-julia-tmb-parity.R`, plus 5 more (one setup gate + four fits) that
had crept into `test-xfam-bridge.R` without ever being covered by #1083's
fix.

## The fix

### 1. One path helper (`tests/testthat/helper-julia-bridge-path.R`)

`drm_test_drmjl_path(envvar = "DRM_JL_PATH")` now always resolves
`DRM_JL_PATH` first, falling back to `DRM_JL_PHYLO_PATH`. A caller that
still passes a legacy family-specific name (`"DRM_JL_XFAM_PATH"`,
`"DRM_JL_RELMAT_PATH"`, `"DRM_JL_XSIGMA_PATH"`, `"DRM_JL_XFAM_TIER2_PATH"`)
has that name honored first if it is set, then falls through to the same
`DRM_JL_PATH` / `DRM_JL_PHYLO_PATH` pair. No call site needed to change —
the fix is entirely inside the helper. `DRM_JL_PHYLO_PATH` is now read in
exactly one place (gate N7-G3: `grep -rl DRM_JL_PHYLO_PATH tests/testthat`
lists only the helper). One stray literal mention of `DRM_JL_PHYLO_PATH`
in a `test-julia-bridge-summary.R` comment was reworded to `DRM_JL_PATH` so
it doesn't trip that grep.

### 2. Bare engine calls at all 21 sites

Every site below had its `tryCatch(..., error = function(e) skip(...))`
removed so the live engine call runs bare: an engine abort is now a test
**ERROR**, not a skip. The legitimate non-engine gates ahead of each call
(`drm_skip_live_julia()`, `skip_if_not_installed(...)`, the
`skip_if_not(dir.exists(...), ...)` path gate) are untouched — those are
"DRM.jl not available", not "the fit failed", and stay as skips.

`test-julia-tmb-parity.R`'s `drm_parity_run()` (#1083) already did this
correctly: it discriminates a documented environment-absent message
(`testthat::skip()`) from any other error (`testthat::fail()`, not a
skip). Its *inline* error handler still textually matched the oracle's
naive scan for `tryCatch(..., error = function(e) { ... skip(...) ... })`,
so the handler now lives in a separately named function,
`drm_parity_run_error_handler()`, called by name from the `tryCatch()`.
Behaviour is unchanged; only the site is no longer text-matched.

### Site-by-site: file:line (before, on `main` `d3d205486`) -> what runs now

- `test-julia-inference.R:699` (`confint() profiles and bootstraps an
  ordinary fixed effect on a live Julia phylo fit`) -> bare
  `drm_julia_fixef_fit(n_tip = 24L)`.
- `test-julia-inference.R:816` (`confint(method = 'bootstrap') works for a
  non-Gaussian (Poisson) fixed effect`) -> bare
  `drm_julia_fixef_poisson_fit(n = 60L, phylo = FALSE)`.
- `test-julia-inference.R:846` (`confint(method = 'bootstrap') works for a
  phylo non-Gaussian fixed effect`) -> bare
  `drm_julia_fixef_poisson_fit(n = 15L, phylo = TRUE)`.
- `test-julia-inference.R:938` (`confint() on a Poisson phylo Julia fit
  returns finite Wald CIs`) -> bare `drm_julia_inference_fit(n_tip = 24L)`.
- `test-julia-missing.R:27` (`engine='julia' fits Gaussian
  response='include' (observed-data, design kept)`) -> the inline
  `callr::r(...)` round-trip runs bare (removed the outer
  `tryCatch({...}, error=...)` wrapping the whole `pkg <-`/`callr::r()`
  block).
- `test-julia-missing.R:89` (`engine='julia' response='include' on
  Gaussian MEAN-phylo equals the drop fit (D-179 #2)`) -> same pattern,
  bare `callr::r(...)`.
- `test-julia-missing.R:258` (`engine='julia' count phylo fit with NA
  response drops rows, matches native (live)`) -> same pattern, bare
  `callr::r(...)`; the `native_cc <- tryCatch(..., error = function(e) e)`
  and `jl_na <- tryCatch(..., error = function(e) e)` INSIDE that
  subprocess call are untouched — they inspect the condition (build
  `jl_errored`/`jl_message` for the test's own assertions), they don't
  call `skip()`, so the oracle never flagged them.
- `test-julia-phylo-count.R:166` (`Poisson phylo fit via engine = 'julia'
  is finite, sane, TMB-parity`) -> bare `drm_phylo_count_fit(n_tip = 24L)`.
- `test-julia-phylo-nongaussian.R:250` (`Gamma phylo fit via engine =
  'julia' is finite and sane`) -> bare `drm_phylo_gamma_fit(n_tip = 24L)`.
- `test-julia-phylo-nongaussian.R:287` (`Binomial phylo fit via engine =
  'julia' is finite and sane`) -> bare `drm_phylo_binom_fit(n_tip = 24L)`.
- `test-julia-phylo-q4-corpairs.R:302` (`q4 bivariate phylo location-scale
  corpairs surfaces among-axis correlations (live)`) -> bare
  `drm_phylo_q4_corpairs_fit(n_tip = 30L, m = 3L)`; the trailing
  `skip_if(is.null(res))` (dead once `res` can no longer be `NULL`) was
  removed with it.
- `test-julia-q2-phylo-point-export.R:74` (`private q2 phylo point-export
  bridge primitive returns diagnostic payload`) -> bare
  `drm_q2_phylo_point_export()`.
- `test-julia-sigma-phylo-reml.R:527` (`Gaussian sigma-phylo REML fit via
  engine = 'julia' is finite and sane`) -> bare
  `drm_sigma_phylo_reml_fits(n_tip = 32L)`, **then found genuinely broken
  live** (see below) and given a visible, reasoned `skip()`.
- `test-julia-structured.R:460` (`Poisson relmat fit via engine = 'julia'
  is finite and sane`) -> bare `drm_structured_relmat_fit(n = 30L)`.
- `test-julia-tmb-parity.R:67` and `:70` (both textual matches inside/near
  `drm_parity_run()`'s own definition — one from the pre-existing comment
  literally containing the old pattern's source text, one from the real
  `tryCatch()` call) -> `drm_parity_run()`'s error handler extracted to
  named `drm_parity_run_error_handler()`; the discriminating logic
  (skip only on a documented environment-absent message, fail on anything
  else) is unchanged. The comment was reworded so it no longer contains
  literal matchable `tryCatch(...)` text (twice — the first reword
  accidentally reintroduced the pattern; caught by re-running the oracle).
- `test-xfam-bridge.R:273` (setup gate inside `Gaussian x Poisson
  cross-family fit returns latent rho + profile CI`) -> bare
  `drmTMB:::drm_julia_setup()`; the `ready`/`skip_if_not(isTRUE(ready), ...)`
  indirection is gone since there is no longer a value to gate on.
- `test-xfam-bridge.R:296` (fit inside the same test) -> bare `drmTMB(...)`.
- `test-xfam-bridge.R:428` (`Gamma x Poisson cross-family fit returns
  latent rho + profile CI`) -> bare `drm_xfam_tier2_fit(...)`.
- `test-xfam-bridge.R:472` (`NB2 x Gaussian cross-family fit returns
  latent rho + profile CI`) -> bare `drm_xfam_tier2_fit(...)`.
- `test-xfam-bridge.R:580` (`cross-family covariate sigma sub-model
  returns finite beta_sigma`) -> bare `drm_xfam_xsigma_fit(n = 150L)`.

### 3. Measured-broken constructs found by the live run (not re-wrapped)

Running the de-swallowed suite live against the pinned DRM.jl checkout
(commit `77513aa0`, 2026-09-03) surfaced **one genuine defect class** hit
by three tests. `drm_bridge()` on the Julia side errors:

```
drm_bridge: coef_labels is missing an entry for dpar "resd_sigma"
(1 fixed-effect columns; Julia names: ["resd_sigma_species:sd_sigma"]);
the R side must supply names for every dpar when sending coef_labels
```

and, on a different route, the same message for dpar `"phylocov"`
(Julia names `["phylocov_Sigma_a:L11", "phylocov_Sigma_a:L21",
"phylocov_Sigma_a:L22"]`). This is an R-side `coef_labels` dict that does
not cover every dpar DRM.jl's bridge echoes back for these two structured
covariance blocks — a genuine bridge-marshalling bug, not an
environment-absence. Per #1127's instruction, this is not re-wrapped in a
skip-on-any-error `tryCatch`; each site gets one reasoned, visible
`skip()` placed **before** the engine call:

- `test-julia-sigma-phylo-reml.R:532` (`Gaussian sigma-phylo REML fit`) —
  `skip("measured broken under DRM.jl 77513aa0: drm_bridge errors
  coef_labels is missing an entry for dpar \"resd_sigma\"; see #1127
  after-task")`.
- `test-julia-tmb-parity.R:348` (`q2 Gaussian phylo residual-correlation
  bridge parity is banked narrowly`) — same pattern, dpar `"phylocov"`.
- `test-julia-tmb-parity.R:1331` (`q1 Gaussian sigma-phylo and mu+sigma ML
  parity are banked`) — same pattern, dpar `"resd_sigma"` (same root
  cause as the REML test above; both routes fit a phylo-structured sigma
  block).

Before this fix, all three read as a green SKIP with a vague "round-trip
unavailable" message (or, for the two `drm_parity_run()` sites, would have
correctly `fail()`ed already — #1083 was working as designed there; the
live run confirms it). After this fix, a bare run would ERROR (verified:
see the G5 live-run evidence below, first pass, before these three skips
were added). The visible skip is a deliberate, reasoned stand-in until the
`coef_labels` bridge defect is fixed; it names the exact engine message so
nobody has to re-discover it, and CI's default lane (Julia absent) never
reaches it anyway.

## What this does NOT cover

- **No `R/` change.** This is a test-only fix; the `coef_labels` defect
  found above is unfixed (either in `R/` or in DRM.jl) — the three skips
  above are the honest record of that gap, not a repair.
- **No DRM.jl edit.** The pinned engine checkout is read-only for this
  arc.
- **Other test families are untouched.** `test-julia-predict-newdata.R`,
  `test-julia-slope-nongaussian.R`, and `test-julia-workflow-g.R` call
  `drm_test_drmjl_path()` too (and so benefit from the `DRM_JL_PATH` fix
  above) but had no `tryCatch(..., skip(...))` sites — the oracle never
  named them, and they are outside this arc's `OWNS` scope.
- **`test-coefficient-labels.R`** already reads `DRM_JL_PATH` directly
  (not through the helper) and has no skip-swallow sites; left alone.
- **The nine touched files' OTHER skips are untouched** — every
  `drm_skip_live_julia()`, `skip_if_not_installed(...)`, and
  `skip_if_not(dir.exists(...), ...)` gate ahead of an engine call is
  exactly as it was; only the *error handler after the fit already ran*
  changed.
- **No promotion of any bridge capability row.** The Route-12/parity
  ledger is unaffected; the three new skips document an *existing* gap
  the ledger did not previously have live evidence for.

## Gate evidence

- **N7-G1** (oracle = 0): `python3 .unlazy/night/bin/count-skip-swallow.py`
  -> `SKIP_SWALLOW_SITES 0`.
- **N7-G2** (RED CONTROL): re-added one `tryCatch(..., error =
  function(e) skip(...))` site at `test-julia-phylo-count.R:168`; the
  oracle reported `tests/testthat/test-julia-phylo-count.R:168` /
  `SKIP_SWALLOW_SITES 1` (G1 correctly fails); reverted via `Edit` back to
  the bare call; oracle re-run gave `SKIP_SWALLOW_SITES 0` again and
  `git diff HEAD -- tests/testthat/test-julia-phylo-count.R` was empty.
- **N7-G3** (one gate): `grep -rln DRM_JL_PHYLO_PATH tests/testthat | grep
  -v helper-julia-bridge-path.R | wc -l` -> `0`; helper contains it ->
  `ONE_GATE_OK`.
- **N7-G4** (CI-like, no Julia env vars): all touched files skip through
  the one gate, `0` failed, `0` error -> `N7_CI_OK`.
- **N7-G5** (live, `DRM_JL_PATH` at the pinned `77513aa0` clone,
  `DRMTMB_JULIA_TESTS=true`, `OPENBLAS_NUM_THREADS=1`): first pass (before
  the three measured-broken skips) gave `test-julia-sigma-phylo-reml.R 0 1
  0 54` and `test-julia-tmb-parity.R 7 2 0 98` — the coef_labels defect
  surfacing exactly as an ERROR/FAIL, confirming the de-swallow worked.
  After adding the three visible skips: `0` failed, `0` error in every
  touched file, every file has `passed > 0` -> `N7_LIVE_OK`.

## Addendum after the Rose pass (coordinator, 2026-09-03 ~05:20 UTC)

Rose's pass (verdict `scratchpad/rose/2026-09-03-rose-n7-verdict.md`) found one more swallow the oracle's pattern missed: `tests/testthat/test-julia-slope-nongaussian.R:59-60` spelled it as `error = function(e) NULL` followed by `skip_if(is.null(res))`. The oracle now matches that shape too (22 sites on main, 0 on this branch). Removing it exposed a fourth measured-broken construct: the Gamma phylogenetic random-slope fit `(1 + x | species)` under `engine = "julia"` aborts at DRM.jl 77513aa0 with `coef_labels is missing an entry for dpar "resd" (Julia names: ["resd_species"])`, because the R-side producer does not label the `resd` block of a random-slope phylo term. Design 258 S7.7 already lists random-slope phylo blocks as outside the contract; the test now carries a visible skip naming that, placed before the engine call, with its assertions preserved below. The four measured-broken constructs for the morning are therefore: `resd_sigma` (sigma-side phylo, two sites), `phylocov` (`test-julia-tmb-parity.R:348`), and `resd` for a random-slope phylo block (this file). Rose's other four attacks survived: no `expect_` removed across 11 files, the three earlier skips are correctly placed, the helper fallback runs live on `DRM_JL_PHYLO_PATH` alone, and a fake DRM.jl directory produces a test error rather than a skip.
