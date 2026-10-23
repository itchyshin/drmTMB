# q4 SE-axis parity receipt (Slice S4, 2026-09-02)

drmjl_ref: cda42b8c5b36c9c39b9588560c0087ed347f5681
drmtmb_ref: 14035812feafb62afe8a1dde459c3607d2ba0731
tmb_converged: TRUE
julia_converged: TRUE

## What this measures

One same-draw comparison on the committed `biv_q4_phylo_reml` fixture
(`test/parity/q4-reml/biv-q4-phylo-reml/` in DRM.jl: `data.csv`, `tree.newick`,
128 rows, 16 tips), fit ONCE with `engine = "tmb"` and ONCE with
`engine = "julia"` on the identical data (no re-simulation), comparing
`coef()` and `sqrt(diag(vcov()))` per coefficient. This is the SE-axis
measurement that A2/A2-diagnosis (2026-09-01, `575-mechanism.md`) and the
DRM.jl lane's own fixture note both named as outstanding before the
`biv_q4_phylo_reml` capability row could be reconsidered for promotion, and
before the fixture's `rtol_coef = 10%` tolerance (currently sized as "10% of
drmTMB's own Wald SEs, refit on this fixture" -- see `expected.toml`'s
`reml_restriction_note`) could be re-derived from a converged Julia SE rather
than assumed unjustified.

DRM.jl ref is PINNED by the DRM.jl lane to `feat/575-exact-reml-gradient`
@ `cda42b8c` (PR #579 head, src/test byte-identical to `c1773e21` per the
lane's own statement) -- the exact-REML-gradient fix for issue #575 (Julia's
q4 REML route landing at a worse optimum than TMB). Obtained via a throwaway
clone at `scratchpad/drmjl-579`; the local DRM.jl checkout at
`/Users/z3437171/Dropbox/Github Local/DRM.jl` was never touched, fetched, or
written to.

## Coefficient-name canonicalisation (recorded, not guessed over)

`coef()` uses `.` as the dpar/term separator on both engines (e.g.
`mu1.(Intercept)`). `vcov()` row names use `:` on the tmb engine
(`mu1:(Intercept)`) and `_` on the julia engine (`mu1_(Intercept)`) -- a
display-convention difference only, confirmed by reading both separators off
the same fitted objects. The script canonicalises every name to
`<dpar>:<term>` before matching across all four of coef(tmb)/coef(julia)/
names(vcov(tmb))/names(vcov(julia)); all 7 coefficients matched with no
name left over (no mismatch to report).

## Results

| coefficient | se_tmb | se_julia | se_abs_delta | se_rel_delta | coef_tmb | coef_julia |
|---|---|---|---|---|---|---|
| mu1:(Intercept) | 0.39242521 | NaN | NaN | NaN | 0.72825797 | 0.72826369 |
| mu1:x | 0.02966654 | NaN | NaN | NaN | 0.34026631 | 0.34028425 |
| mu2:(Intercept) | 0.30270138 | NaN | NaN | NaN | 0.23947771 | 0.23945868 |
| mu2:x | 0.05482400 | NaN | NaN | NaN | 0.47229421 | 0.47225353 |
| sigma1:(Intercept) | 0.38813154 | NaN | NaN | NaN | -1.29498554 | -1.29507818 |
| sigma2:(Intercept) | 0.25135158 | NaN | NaN | NaN | -0.44125369 | -0.44108541 |
| rho12:(Intercept) | 0.09513290 | NaN | NaN | NaN | 0.06560641 | 0.06565029 |

max se_rel_delta = **NaN (undefined)** -- see "Central finding" below.

- logLik (tmb): -219.613986
- logLik (julia): -219.614005
- |logLik delta|: 1.9e-05 (down from 0.016245 pre-#579, per `575-mechanism.md`
  A1; consistent with the exact-REML-gradient fix resolving the #575
  worse-optimum mechanism on this cell)
- max |coef_abs_delta|: 1.68e-04 (sigma2:(Intercept)), well inside the
  fixture's current `atol_coef = 0.0251`
- tmb `sdr$pdHess`: TRUE
- julia `$uncertainty`: `status = "unavailable"`, message: "DRM.jl bridge did
  not return finite fixed-effect covariance for this route."
- Julia version: 1.10.0
- fit wall time (excludes Julia session startup, after one throwaway
  60-row warm-up fit): tmb 1.503 s, julia 1.614 s

## Central finding

**Julia's `vcov()` for this route returns an all-`NaN` fixed-effect
covariance matrix**, self-reported by the bridge as
`uncertainty$status = "unavailable"` (`R/julia-bridge.R`, the
`uncertainty_status` computed from `finite_vcov`/`partial_vcov` around line
2260-2270). This is not a script bug or a name-matching failure -- the same
"not available for the bivariate q = 4 route" limitation is already
documented in `confint.drmTMB_julia`'s own roxygen text ("ordinary
fixed-effect coefficients ... not available for the bivariate q = 4 route
(`biv_gaussian`), whose fixed effects are not individually profiled here").
Every `se_julia`/`se_abs_delta`/`se_rel_delta` cell is therefore `NaN`, and
`max se_rel_delta` is undefined, not zero and not small.

drmTMB's own (`engine = "tmb"`) Wald SEs are all finite with `sdr$pdHess =
TRUE`; the sigma2 SE (0.25135158) reproduces the fixture's own recorded
"median SE across the 7 coefficients ... 0.251352" (`expected.toml`'s
`reml_restriction_note`) to 6 significant figures, confirming this is the
same TMB reference the fixture's `rtol_coef = 10%` tolerance was derived
from.

## What this receipt DOES claim

- On this one fixture and this one same-draw pair of fits: TMB and Julia
  (at the #579 exact-gradient ref) land on point estimates that agree to
  ~2e-4 in coefficients and ~2e-5 in logLik -- a large improvement over the
  pre-#579 0.016 logLik gap that was issue #575.
- TMB's own Wald SEs on this fixture are finite, `pdHess = TRUE`, and match
  the number the fixture's current coefficient tolerance was built from.
- Both engines report `converged = TRUE` on this draw.

## What this receipt does NOT claim

- **No SE-axis parity measurement is possible on this fixture** -- Julia
  does not currently emit a usable fixed-effect covariance for the
  `biv_gaussian` q4-phylo REML route, so `se_abs_delta`/`se_rel_delta` are
  undefined (NaN), not "small" or "passing".
  Consequently, the DRM.jl lane's stated open question -- whether
  `rtol_coef = 10%` can be re-derived against a converged Julia SE rather
  than only drmTMB's own Wald SE -- is **not answered** by this receipt; it
  cannot be, until DRM.jl's bridge returns a finite fixed-effect covariance
  for this route.
- **Not interval coverage.** A single point/SE comparison on one fixture
  says nothing about calibrated coverage of Wald or profile intervals.
- **Not a promotion.** This receipt does not edit
  `inst/extdata/julia-capabilities.tsv` or
  `docs/dev-log/dashboard/julia-capabilities.tsv`, and none should be edited
  on the strength of this file alone -- if anything, the missing Julia SE is
  a reason the `biv_q4_phylo_reml` row's uncertainty story stays open.

## Exact command

```
Sys.setenv(DRM_JL_PATH = "<worktree>/scratchpad/drmjl-579")
Sys.setenv(DRMTMB_JULIA_TESTS = "true")
Rscript docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.R
```
run from `/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/7db7461b-e1ee-4ad0-a526-010c1c2e26a6/scratchpad/wt-s4`
(branch `claude/rev-parity-q4-se-receipt`), against a throwaway clone of
DRM.jl at `feat/575-exact-reml-gradient` @ `cda42b8c` (`git clone
git@github.com:itchyshin/DRM.jl.git scratchpad/drmjl-579 && git -C
scratchpad/drmjl-579 checkout cda42b8c`), after one `julia --project=.
-e 'using Pkg; Pkg.instantiate()'` in that clone to materialise its
`Manifest.toml` dependencies (the shared depot at `~/.julia` already had
`~85` of the 86 recorded dependencies precompiled; instantiate + first
precompile took ~14 s). Full script run (package load, one throwaway
60-row Julia warm-up fit, then the two timed comparison fits) took ~90 s
wall time end to end, comfortably under the 30-minute D-139 line; no
scale-up was needed.

See also: `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.R`
(the script that produced every number above).
