# A8b: profile and bootstrap intervals for the residual bivariate Gaussian Julia route (#544)

**Reader**: anyone who fits `bf(mu1 = ..., mu2 = ..., rho12 = ...)` with
`engine = "julia"` and wants a confidence interval on a coefficient (including
`rho12`); anyone maintaining `drm_julia_wald_targets()` or the readiness rules
in `R/julia-bridge.R`; anyone reading the `biv_gaussian_residual` capability row
and wondering what `supported` now means there; and whoever picks up leaf A8's
remaining routes.

Leaf ledger: `.unlazy/parity/gates/leaf-a8b-biv-inference.md`. Worktree branch
`claude/parity-a8b-biv-inference` off `origin/main` (3714cc80e, after #1182).
DRM.jl worktree `claude/parity-a8b-biv-inference-drmjl` off DRM.jl `origin/main`
(4fea04338); DRM.jl pin `430ef64cc` used for the RED baseline only.

## 1. Goal

Close the gap leaf A8 measured and reported as NOT COVERED: through
`engine = "julia"`, the residual-only bivariate Gaussian route had **no profile
or bootstrap interval target on any parameter**. A8's own receipt says so in as
many words -- "`profile_targets()` reports `profile_ready = FALSE` for all 9
rows" -- and named it a structural gap outside that leaf's scope.

Capability parity (D-181 #2): one fixture, one target per block, no coverage
claim.

## 2. What was actually broken

Two independent blockers, one per side, and the R-side one hid the Julia-side
one completely.

**R side.** `drm_julia_wald_targets()` (R/julia-bridge.R) computed

```r
fixef_profile_ready <- !is_biv && !is.null(object$bridge_payload)
```

-- unconditionally `FALSE` for EVERY row of EVERY bivariate fit. The rows
themselves already existed and were already generic over `names(blocks)`; the
one boolean is what stamped them not-ready. Everything downstream
(`profile_match_confint_targets` -> `drm_julia_validate_inference_targets` ->
`drm_julia_call_fixef_inference`) was already generic and needed no change.

**Julia side.** `DRM._bootstrap_fit_formula` refused every
`BivariateDrmFormula`. Behind it sat three more blockers that only became
reachable once the first was lifted, which is why the scouting note found one
and the implementation found four:

1. the refit closure in `bootstrap_result(::DrmFit{<:Gaussian})` forwards
   `algorithm`, a keyword `drm(::BivariateDrmFormula, ::Gaussian; ...)` does not
   declare -- a `MethodError` on replicate 1;
2. `_bootstrap_result` was typed `formula::DrmFormula`;
3. `_bootstrap_data` had no method for the `Dict(:mu1, :mu2)` draw that
   `_simulate_once` returns for a bivariate fit.

`profile_result` needed **no** Julia change: a residual bivariate fit attaches a
plain closure via `_withnll`, matches none of the specialised branches, and
already reached the generic ForwardDiff path. The RED control below proves that
rather than asserting it -- with the source reverted, the profile testset still
passes 27/27 while the bootstrap testset errors.

## 3. Implemented

**DRM.jl** (PR #647, opened, NOT merged):

- `src/inference.jl`: widened `_bootstrap_fit_formula`; branched the Gaussian
  refit closure so the bivariate arm omits `algorithm`/`refit_options`; widened
  `_bootstrap_result`'s `formula` type; added a `BivariateDrmFormula` method for
  `_bootstrap_data` plus `_bootstrap_keep_unobserved`.
- `test/test_bridge_biv_inference.jl` (new, 71 assertions) + `test/runtests.jl`.
- `NEWS.md`.

**drmTMB** (this branch):

- `R/julia-bridge.R`, `drm_julia_wald_targets()`: the bivariate rule is now a
  SPLIT. A bivariate fit carrying a covariance provider (`payload$tree`,
  `payload$matrix`, `payload$kwarg`) is the STRUCTURED route and its
  fixed-effect rows stay not-ready; one carrying none is the residual route and
  is ready on the same precondition every univariate route uses. The provider
  test deliberately does **not** read `payload$tree` alone -- relmat / animal /
  spatial bivariate routes carry their covariance in `payload$matrix` under
  `payload$kwarg`, so a tree-only test would have wrongly admitted them.
- `R/julia-bridge.R`, `drm_julia_profile_targets_biv()`: documentation only,
  recording why it correctly stays EMPTY for the residual route.
- `R/julia-bridge.R`, above `drm_julia_call_fixef_inference()`: documentation
  only, recording that the bivariate route reaches it unchanged.
- `R/julia-bridge.R`, `drm_julia_capability_comparison()` row 2 only:
  `r_bridge_status` `partial` -> `supported`, the G3 fence sentence replaced by
  the measured qualification, `next_action` rewritten.
- `tests/testthat/test-julia-biv-inference.R` (new, 57 expectations, 6 offline
  + 1 live).
- `tools/parity-p2-pilot.R`: new `--g3-qualify-biv` mode.
- Receipts under `docs/dev-log/evidence/julia-r-parity/p2-g3/`.
- Regenerated `inst/extdata/julia-capabilities.tsv` +
  `docs/dev-log/dashboard/julia-capabilities.tsv`; `NEWS.md`.

## 4. Measured

Committed `gaussian-bivariate-rho12` fixture (n = 180), both engines, ONE Julia
session, `threads = FALSE`, `OPENBLAS_NUM_THREADS=1`. Full receipt:
`docs/dev-log/evidence/julia-r-parity/p2-g3/a8b-biv-qualification-receipt.md`.

| gate | measurement |
|---|---|
| G3 target inventory | 9 rows, 7 profile-ready, all 7 fixed-effect (was: 0 ready) |
| G3 per-target profile | all 7 return a finite interval, `conf.status = "profile"` |
| G4 Wald `fixef:mu1:x` | delta [3.43e-14, 3.43e-14], bar 1e-6, PASS |
| G4 Wald `fixef:rho12:(Intercept)` | delta [2.97e-07, 4.58e-07], bar 1e-6, PASS |
| G4 profile `fixef:mu1:x` | delta [2.15e-06, 2.15e-06], bar 1e-4, PASS |
| G4 profile `fixef:rho12:(Intercept)` | delta [6.45e-06, 5.66e-06], bar 1e-4, PASS |
| G4 bootstrap R = 99 | 0/99 failed on BOTH engines, both targets; OVERLAP = TRUE |
| G5 estimator | `fit$estimator` == `fit$bridge$estim_method` == `ML` |
| G6(a) red control | both targets FAIL at 1e-9 -- the comparison is live |
| G6(b) red control | readiness reverted -> 3 failures + 3 errors; restored byte-identically |
| DRM.jl red control | source reverted -> bootstrap testset errors with the baseline `ArgumentError`; profile testset still 27/27 |

Test runs (all with the live bridge exercised, not mocked away):

- `test-julia-biv-inference.R`: 57 expectations, 0 failed, 0 errors, 0 skipped.
- Neighbour suites (`julia-gate-vs-engine`, `julia-inference`,
  `profile-targets`, `capability`, `reml-route-table`, `bridge-payload`,
  `julia-biv-inference`): 8 files, 1432 expectations, 0 failed, 0 errors.
- DRM.jl `test_bridge_biv_inference.jl`: 71 assertions, all passing; neighbour
  bootstrap/bivariate suites (q4 inference 22, LSS bootstrap contract 60,
  bootstrap tree 18, thread flags 2, gaussian bivariate 12, missing-response
  bivariate 16) all green.
- `python3 tools/capability_ledger.py --check`: `OK (31 generated outputs)`.
- `python3 tools/validate-mission-control.py`: 32 errors on this branch vs 33 on
  clean `origin/main` in `wt-main-probe`. **0 new errors**; the one that
  disappeared is `biv_gaussian_residual: invalid r_bridge_status 'partial'` --
  see the defect below.
- `Rscript tools/write-reml-route-table.R`: regenerated
  `docs/design/261-reml-by-route.md` **byte-identically** (that generator cites
  `capability_id`s, not statuses).

## 5. A pre-existing defect this leaf surfaced but did not fix

`tools/validate-mission-control.py` line 12888 has

```python
R_BRIDGE_STATUSES = {"supported", "experimental", "intentional_error", "planned", "unsupported"}
```

It never learned `"partial"`, which was added to the `r_bridge_status`
vocabulary on 2026-09-02 (wave-1 promotion; design/168 and design/192 both
document it, and `tests/testthat/test-julia-gate-vs-engine.R` already accepts
it). Consequence: clean `origin/main` reports a spurious
`invalid r_bridge_status 'partial'` for **11** rows. Promoting
`biv_gaussian_residual` to `supported` removed one of those 11 as a side effect.
Not fixed here -- out of this leaf's OWNS and a separate defect -- and flagged
as a follow-up task.

## 5b. Neighbour probe -- where the widened rule stops

Full record:
`docs/dev-log/evidence/julia-r-parity/p2-g3/a8b-biv-neighbour-probe.md`.

The obvious way the new rule could be wrong is a bivariate route with real
random structure that stores no provider in its payload. Four live probes
looked for one:

| probe | result |
|---|---|
| bivariate + ordinary `(1 \| g)` | REFUSED by DRM.jl before any fit ("bivariate q=4 structured fits support only phylo/relmat/animal/spatial markers, not ordinary random effects"), so the predicate is never consulted |
| REAL bivariate q4 phylo fit (12 tips, n = 60) | payload carries `tree`; 7 rows, **0 ready** -- the SPLIT verified on a live structured fit, not only on synthetic payloads |
| bivariate `meta_V(V = ...)` | NOT REACHABLE through the bridge at all (a per-row 2x2 array cannot cross the `data.frame` marshalling) |
| bivariate with 8 masked `y1` cells | 7 ready, profile and bootstrap both finite -- but `response = "drop"` removes those rows R-side, so it is a complete-case fit and no missing cell reaches Julia |

The q2 known-covariance bivariate route was checked by reading
`drm_julia_biv_known_structured_payload()`: it sets `matrix` and `kwarg`, so
`has_covariance_provider` is TRUE and its fixed-effect rows stay not-ready.

## 6. Scope deviations, declared

- **`tests/testthat/test-julia-gate-vs-engine.R` is NOT in the leaf's OWNS list
  and was edited anyway.** Its wave-1 lock asserted
  `all(wave1_promoted$r_bridge_status == "partial")` across four rows including
  `biv_gaussian_residual`, so G7's promotion cannot land without touching it.
  The assertion was SPLIT, not loosened: the three rows that did not move are
  still asserted `partial` and the promoted row is asserted `supported`, so
  either drifting still fails loudly. This is the deliberate-promotion case the
  lock's own comment anticipates ("inverted rather than deleted ... so an
  accidental reversion fails loudly").
- **The leaf brief asked for "a fixed-effect (and rho12) target path" inside
  `drm_julia_profile_targets_biv()`. That was NOT done, on purpose.**
  `drm_julia_profile_target_union()` and `confint.drmTMB_julia()` both
  `rbind()` that function's rows with `drm_julia_wald_targets()`'s, so adding
  the fixed-effect rows there as well would DUPLICATE every one of them and
  make the one-row match in `drm_julia_validate_inference_targets()` reject a
  valid `parm`. R/profile.R records the same trap in its own comment. The
  fixed-effect path lives in `drm_julia_wald_targets()` alone, and
  `drm_julia_profile_targets_biv()` gained a comment saying why it stays empty.
  A test asserts the union has no duplicated `parm`.
- **`tools/parity-p2-pilot.R` gained `--g3-qualify-biv`, a sibling of A8's
  `--g3-qualify`, rather than an edit of it.** `--g3-qualify` lives on the
  unmerged branch `claude/parity-a8` (PR #1183) and does not exist on
  `origin/main`, so there was nothing to extend; a separate mode lets the two
  branches add rather than conflict.

## 7. What this does NOT cover

- **Interval COVERAGE.** One fixture, one seed, one target per block. Nothing
  here says a 95% interval covers 95% of the time on this route.
- **A same-seed bootstrap comparison.** `engine = "tmb"` draws replicates from
  R's RNG and `engine = "julia"` from a Julia `MersenneTwister`; the same `seed`
  value does not produce the same replicates. The strongest honest claim from
  those two numbers is distributional overlap, and that is what is reported.
- **`meta_V` (known-V) bivariate fits.** Probed and found NOT REACHABLE through
  `engine = "julia"` at all: the bridge column-subsets a `data.frame`, so the
  per-row 2x2 sampling-covariance array cannot cross, and the fit is refused
  with `could not find model variable "Vk" in data`. That is true with or
  without this leaf's change. DRM.jl's own `meta_v` `nll` branch is therefore
  untouched and unexercised here.
- **A masked bivariate likelihood.** An R-side fit with `y1[1:8] <- NA` DOES
  now list 7 ready targets and profiles/bootstraps them (20/20 refits, 0
  failed) -- but under the drmTMB default `response = "drop"` the bridge drops
  those rows BEFORE marshalling, so it is a complete-case fit on 172 rows and
  **no missing cell reaches Julia**. Consequently DRM.jl's new
  `_bootstrap_keep_unobserved` (which keeps an unobserved cell unobserved
  across replicates) is Julia-side correctness for direct callers and for a
  future `response = "include"` bivariate route; it is unit-tested there, and
  is NOT exercised through the R bridge today.
- **The STRUCTURED (q = 4 / q = 2) bivariate route.** Its fixed-effect rows
  stay deliberately not-ready; only its four among-axis SDs are its target, and
  that is a different ledger row.
- **The `missing_tmb_parameter` note wording for a structured bivariate
  fixed-effect row.** It is now the only inventory note that row can carry, and
  it is vague for that case (the real reason is "this route's target is the
  four among-axis SDs"). Changing it would break an assertion in
  `test-julia-inference.R`, which is outside OWNS. Left as-is and named here.
- **`R CMD check` / `devtools::check()`** was not run; the neighbour test files
  were run directly instead.

## 8. Merge order

DRM.jl PR #647 first (drmTMB's bootstrap half does not work without it). The
drmTMB PR merges after #1184 (shared `drm_julia_capability_comparison()`).
Neither is merged here; no auto-merge; no message sent to any collaborator.
