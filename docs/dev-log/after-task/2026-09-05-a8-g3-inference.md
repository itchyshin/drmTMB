# A8: bridge-side inference (G3) qualified on 2 of 4 routes -- the other 2 are new, real findings, not rounded up

**Reader**: the parity-joint integrator merging leaf A8; anyone deciding
whether `confint(fit, engine = "julia", method = "profile" | "bootstrap")`
can be trusted on `base_gaussian_location_scale`,
`plain_binomial_nonphylo`, `biv_gaussian_residual`, or
`gaussian_response_mask`; the owner of the two new defects this leaf found
but did not fix.

Worktree `~/local-scratch/parity-joint/wt-a8`, branch `claude/parity-a8`, cut
from `origin/main` 2026-09-05 ~11:25. DRM.jl pin `430ef64cc` (carries #631/
#633). Ledger `.unlazy/parity/gates/leaf-a8.md`. LOCAL ONLY (Totoro's R
segfaults on JuliaCall); `threads = FALSE` everywhere; one Julia session per
run.

## 1. Goal

The single fence sentence "bridge-side inference (profile/bootstrap through
engine=\"julia\") remains unqualified (G3)" is repeated verbatim in four
`drm_julia_capability_comparison()` rows: `base_gaussian_location_scale`,
`biv_gaussian_residual`, `gaussian_response_mask`, `plain_binomial_nonphylo`.
Qualify it on small convergent cells per route: profile and bootstrap
intervals through `engine = "julia"` must complete, be finite, agree with
`engine = "tmb"` within a stated tolerance, and report boundary honesty
rather than a fabricated finite bound. Capability parity, not coverage
(D-181 #2) -- no multi-seed campaign, no interval-coverage claim.

## 2. Result: 2 of 4 promoted, not 4 -- never rounded up

`base_gaussian_location_scale` and `plain_binomial_nonphylo`: `r_bridge_status`
`partial` -> `supported`. Profile and bootstrap CIs on `fixef:mu:x` agree with
`engine = "tmb"` well inside the 1e-4 bar, both engines converge, both
bootstraps (`R = 99`) complete with 0/99 failed replicates on both sides and
overlapping intervals, and `estimator` reads `"ML"` on both (the #1155
cross-check is enforced unconditionally inside the bridge at fit time, so a
completed fit already proves it passed).

`biv_gaussian_residual` and `gaussian_response_mask`: **NOT promoted**, and
the G3 fence sentence is **retained verbatim** on both rows. This is a
deliberate deviation from the ledger's original framing ("promoting ... for
the four rows") -- the pre-flight manifest and the qualification run both
surfaced concrete, measured reasons neither route can be honestly qualified
right now:

- **`biv_gaussian_residual`**: no profile or bootstrap target exists on this
  route for ANY parameter through the R bridge. `drm_julia_wald_targets()`
  sets `fixef_profile_ready <- !is_biv && ...` -- unconditionally `FALSE` for
  any bivariate fit -- and `drm_julia_profile_targets_biv()` returns no SD row
  when `bridge_payload$tree` is `NULL`, which is always true for a
  residual-only (non-phylo) bivariate fit. A live probe confirms
  `profile_targets()` reports `profile_ready = FALSE` for all 9 inventory
  rows (`profile_note = "missing_tmb_parameter"`), and `confint(method =
  "profile")` is refused by the bridge itself before any Julia round-trip.
  This is a structural gap in the bridge's target inventory, not a numerical
  fluke, and fixing it (a residual-bivariate profile/bootstrap route) is
  outside this leaf's OWNS (`drm_julia_capability_comparison()` rows only).
- **`gaussian_response_mask`**: TWO new findings, both real, neither
  investigated further here. (1) The Julia fit's own optimizer convergence
  flag reads `FALSE` (`is_converged()` checks `opt$convergence == 0L`; it is
  `1`) on the exact fixture `tests/testthat/test-julia-missing.R` already
  uses (seed=1, n=60, `y[1:6] <- NA`), even though the profile CI on
  `fixef:mu:x` tracks `engine = "tmb"` to `5.1e-06`/`7.2e-06`. No existing
  test had ever read this flag on this fixture (`test-julia-missing.R` checks
  only `logLik` finiteness and `nobs == 54`). (2) `confint(..., method =
  "bootstrap", R = 99)` on `engine = "julia"` fails ALL 99 replicates outright
  -- DRM.jl's own `bootstrap_result` throws `"all 99 bootstrap replicates
  failed"` -- so there is no bootstrap comparison to report for this route at
  all; `engine = "tmb"`'s own bootstrap on the identical fixture succeeds
  normally. Both findings are quoted verbatim in the row's `claim_boundary`
  and `next_action`.

## 3. What ran, and what it found

`tools/parity-p2-pilot.R --g3-qualify` (new mode, single script, single Julia
session, 50.9s wall time measured):

1. Fit `tmb` + `julia` on the 3 qualifiable routes' committed/matching
   fixtures, compare `wald` and `profile` CIs on `fixef:mu:x` (tol `1e-4`,
   both bounds), compare `bootstrap` CIs (`R = 99`) by distributional overlap
   (the two engines do not honour the same nominal `seed` identically --
   independent RNG streams, confirmed by the 2026-09-03 pilot receipt's
   bootstrap deltas being two orders of magnitude larger than its
   wald/profile deltas on the same fixtures).
2. Attempt `biv_gaussian_residual` and record the bridge's own refusal
   verbatim.
3. Fit a purpose-built quasi-complete-separation binomial cell (`n = 40`,
   `x in {-2, 2}`, `p in {0.02, 0.98}`, `trials = 8`) so `fixef:mu:x`'s MLE
   sits at/near a real boundary. `engine = "julia"`'s coefficient runs to
   `312`; its optimizer's raw estimate is genuinely at a boundary.
   `confint(..., method = "profile")` on this coefficient RAISES, propagated
   from DRM.jl's own `#631` backstop in `_bridge_inference_flatten`:
   `"refusing to return an infinite bound for `mu:x` under status
   `profile_failed` — profile endpoint solve failed: lower (nuisance=
   below_reference; lbfgs_forward; fallback=false)"`. This is the FIRST time
   any test in this repo exercises that backstop through the live R bridge
   rather than through DRM.jl's own mocked Julia-side unit test
   (`test_bridge_profile_status.jl`) -- the path A0 found no test reached. A
   diagnostic-only direct read of the raw `profile_result().stats` (bypassing
   the R flatten step) confirms the mixed reason: `lower_endpoint_failed =
   TRUE` (a genuine nuisance-solve bug-class failure) and `upper_unbounded =
   TRUE` (a legitimate "never crosses the LR threshold" result on the
   quasi-separated side) -- exactly DRM.jl's documented convention. `engine =
   "tmb"` on the same fixture reports a normal finite interval
   (`profile.boundary = FALSE`) -- its own optimizer does not run to the same
   boundary here, a genuine engine difference noted for context, not claimed
   as agreement.
4. G6 red control: re-check the measured profile deltas at `tol = 1e-9` --
   all 3 qualifiable routes FAIL (deltas `2.8e-06` to `7.2e-06`, four to five
   orders of magnitude over `1e-9`), proving the `1e-4` bar is discriminating.
5. Second red control, on the promotion itself: `r_bridge_status[1]`
   (`base_gaussian_location_scale`) was planted back to `"partial"`
   (`R/julia-bridge.R` md5 recorded before/after:
   `40913a03e5d2d814b8352f57134db471`, identical), the TSV regenerated, and
   `tests/testthat/test-julia-gate-vs-engine.R`'s locked assertion FAILED
   exactly as expected; restored byte-identically (md5 matched), TSV
   regenerated back, test green again.

Full numbers: `docs/dev-log/evidence/julia-r-parity/p2-g3/manifest.md` (G1,
committed before any fit ran) and `.../g3-qualification-receipt.md` (this
run's measurements) and `.../g3-qualification-summary.tsv`.

## 4. Files touched, and one deviation from strict OWNS

- `tools/parity-p2-pilot.R`: new `--g3-qualify` mode; corrected
  `plain_binomial_nonphylo`'s stale `bootstrap_ok = FALSE` to `TRUE`
  (drmTMB#1123 was fixed on an ancestor commit; re-probed live).
- `docs/dev-log/evidence/julia-r-parity/p2-g3/`: new, per-cell receipts.
- `R/julia-bridge.R`: `drm_julia_capability_comparison()` only -- rows 1, 2,
  4, 11 (`base_gaussian_location_scale`, `biv_gaussian_residual`,
  `gaussian_response_mask`, `plain_binomial_nonphylo`; TSV rows 2/3/5/12).
  `git diff --stat` for `R/` confirms no other function in this file, and no
  other `R/` file, changed.
- `inst/extdata/julia-capabilities.tsv` and
  `docs/dev-log/dashboard/julia-capabilities.tsv`: regenerated (both are
  always regenerated together by `tools/write-julia-capability-comparison.R`
  -- confirmed as the established pattern in every prior promotion commit).
- `NEWS.md`: one bullet.
- **Deviation from strict OWNS, disclosed rather than hidden**:
  `tests/testthat/test-julia-gate-vs-engine.R` had three assertions that
  hardcode the pre-promotion `r_bridge_status` values for exactly these rows
  -- a deliberately "locked" pattern per the file's own comments ("asserted
  rather than merely edited... so an accidental reversion fails loudly").
  Promoting 2 of the 4 rows without updating these assertions would leave
  the suite red on purpose (that is the assertion's entire design). This
  file is not in the ledger's OWNS list, but leaving a test red as a direct,
  unavoidable, and intended consequence of an OWNS-authorized change seemed
  worse than a minimal, mechanical edit to the three specific expected
  values (one `binomial_row` check, one four-row `wave1_promoted` block
  split into a still-partial pair and a now-supported pair). No other test
  file was touched. Verified green with live Julia after the edit:
  `test-julia-gate-vs-engine.R`, `test-julia-family-registry.R`,
  `test-julia-bridge.R`, `test-julia-bridge-summary.R`,
  `test-profile-targets-julia.R`, `test-julia-missing.R`,
  `test-julia-inference.R` -- all pass, live tests ran (not skipped).

## 5. Ordering note (per the ledger's own instruction)

The ledger's WORKTREE line notes the original "after A6" ordering is relaxed
by measurement: A6 found the five formula constructs already at parity
(<=2.9e-11) and only added a refusal for non-treatment contrasts, so A8's
cells -- plain numeric designs on the four routes -- compare identical models
with or without A6. Confirmed: none of this leaf's fixtures or formulas use
a factor contrast that A6 touches.

## 6. What this does NOT claim

Not an interval-coverage claim (one fixture, one target, one seed per route
-- D-181 #2, capability parity only). Not a claim that
`biv_gaussian_residual` or `gaussian_response_mask` are broken in general --
only that their profile/bootstrap inference specifically could not be
qualified today, for named, measured reasons. Not a fix for either named
defect (both are flagged as follow-up work, out of this leaf's OWNS). Not a
speed number (A10). `threads = FALSE` throughout; the #631/#633 threaded
race was not re-exposed.

## 7. Suggested follow-ups (not done here)

1. Add a residual-bivariate (no phylo tree) profile/bootstrap target to the
   Julia bridge's inference-target inventory, so `biv_gaussian_residual` (and
   any other non-phylo bivariate route) has something to profile.
2. Investigate why `engine = "julia"`'s optimizer reports `opt$convergence ==
   1` on the `gaussian_response_mask` missing-response fixture despite a
   point estimate and profile CI that closely track `engine = "tmb"`, and why
   `bootstrap_result` fails all 99 replicates on the same fixture.

## Reviewer corrections (Fisher, 2026-09-05)

- The bootstrap comparison is overlap only (the Julia interval is nested inside the TMB interval); no same-seed design exists across engines, so G3 is partially met and the promotion rests on profile + Wald agreement.
- G5: the #1155 abort is unreachable under ML; the evidence is the direct oracle read `fit$bridge$estim_method == "ML" == fit$estimator` on every cell.
- gaussian_response_mask defects: DRM.jl #646.
