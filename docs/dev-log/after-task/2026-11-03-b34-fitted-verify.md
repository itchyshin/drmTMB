# After-task: batch 34, independent verification of the conditional fitted() and residuals() patches

Date: 2026-11-03. Lane: codex/general-sd-regression (private archive of 81553915d, patch checked against the later heads 5d4979208 and 91a56224f). DRModels.jl private copy of ab8b67127 with its own Manifest.toml. Nothing was edited or committed in either worktree.

## 1. Goal

Verify, as a skeptical second party, the worker patches `b34-fitted-r.patch` and `b34-fitted-jl.patch`: `fitted()` and `residuals()` on `engine = "julia"` fits with a structured `relmat()`, `animal()` or `spatial()` mean field should return the conditional mean, as native `fitted()` does. Confirm the old mismatch on unpatched code, show it gone on patched code, check that the tests catch broken code, and correct anything that over-claims.

## 2. Implemented

Verdicts: R patch ACCEPT WITH FIXES, Julia patch ACCEPT WITH FIXES (one comment fix). The two patches in this delivery are the worker patches plus my corrections.

- R: NEWS and `docs/dev-log/known-limitations.md` now say that structured fields fitted WITHOUT an `sd(id, level = ...)` formula keep the population-level value (measured below), and the NEWS opening sentence is limited to the listed routes.
- Julia: the header comment of `test/test_structured_conditional_export.jl` said the stored objective is unchanged to 1e-9; the test (correctly) uses 1e-4 against `nll(theta_hat)`. The comment now says that.
- This note.

## 3a. Decisions and Rejected Alternatives

- Kept the worker design (per-row `eta_re` plus modes in the payload, R rebuilds `linkinv(linkfun(population) + eta_re)`). Rejected: a rewrite of the R side to recompute loadings, which would copy each fitter's parametrisation.
- Did not widen scope to `predict()` on stored rows; the worker left it population level and listed that.
- Did not loosen any tolerance. The R tolerance (1e-4 relative) and the Julia oracle tolerance (1e-6 on scale 1 + max |oracle|) were fixed before my runs and are the worker's.

## 4. Files Touched

drmTMB patch: `NEWS.md`, `R/julia-bridge.R`, `docs/dev-log/known-limitations.md`, `docs/dev-log/after-task/2026-11-03-b34-fitted.md`, `docs/dev-log/after-task/2026-11-03-b34-fitted-verify.md` (this note), `tests/testthat/test-julia-b34-structured-fitted-bridge.R`, and the two edited b32 tests.

DRModels.jl patch: the nine `src/` files, `news/b34-structured-conditional-export.md`, `test/test_structured_conditional_export.jl`.

## 5. Checks Run

Reproduction of the old mismatch (my own fixtures, seeds 20262001 to 20262005 and 20262100, not the worker seeds; native `engine = "tmb"` against Julia, relative gap = max |julia - native| / max |native|; Mac, one R process at a time, Julia 1.10.0):

| fixture | unpatched fitted gap | patched fitted gap | patched residual gap |
|---|---|---|---|
| Poisson relmat intercept | 0.57 | 3.8e-8 | 2.9e-8 |
| Gaussian relmat slope | 0.86 | 4.6e-12 | 2.0e-11 |
| Gamma relmat intercept | 0.91 | 4.3e-9 | 9.8e-9 |
| NB2 relmat intercept | 0.95 | 2.9e-9 | 3.7e-9 |
| Binomial relmat intercept | 0.33 | 8.7e-9 | 9.7e-9 |
| Poisson relmat, two NA rows in `x` | 0.89 | 3.4e-9 | 8.6e-9 |

Julia (Totoro, cores 300-305, Julia 1.10.12, one thread per process, taskset):

- New `test_structured_conditional_export.jl` on the patched copy: 114 pass in the oracle testset and 6 pass in the bridge testset, 0 fail. On the unpatched copy with the same file: `UndefVarError: structured_conditional` in every fixture, exit 1.
- Neighbouring files, 92 run as separate processes: all exit 0 except the seven `test_lss_*` files that need `StableRNGs`, which is not in the DRModels project environment (an environment gap, the same on the unpatched tree). Those seven passed (exit 0) with `StableRNGs` on the load path.

R (Mac, private copy, `DRM_JL_PATH` at the private patched Julia copy, `NOT_CRAN=true`):

- `test-julia-b34-structured-fitted-bridge.R`: 162 pass, 0 fail, 0 error, 1 warning (native optimiser on the Gamma relmat slope fixture). Same file on the unpatched R and Julia copies: 57 pass, 101 fail, 1 error.
- The two edited b32 tests 55 and 98 pass; `test-julia-bridge.R` 158, `test-julia-conditional-components.R` 27, `test-julia-conditional-prediction.R` 20, `test-julia-missing-alignment.R` 71, `test-julia-admission-docs.R` 26 pass, all 0 fail.
- The 24 native comparisons in the new file reproduced the worker gaps (fitted 2.2e-13 to 9.2e-8, residuals 2.9e-13 to 1.7e-7, tolerance 1e-4; old population-level value 0.42 to 1.1 away).

Oracle independence: the Julia test builds a dense Newton solve of the inner problem with hand-derived derivatives and calls no fitter code; the Binomial animal q2 test solves the inner problem in base R with a hand-built Kronecker prior at the Julia estimates; the other R comparisons use native TMB, a separate engine.

## 6. Tests of the Tests

My own mutants, each asserted far above tolerance:

- Julia: Gamma loading multiplied by 0.9. The two Gamma fixtures fail with an `eta_re` gap of 0.127 and 0.241 against a tolerance near 3e-6 (about 40000 times).
- Julia: Gaussian row contribution read with reversed group index. Both Gaussian fixtures fail with gaps 1.82 and 3.60 against about 3e-6.
- R: `eta_re` halved in `drm_julia_conditional_structured_fitted()`. Native gaps become 0.31 to 2.4 against 1e-4.
- The population-level value (the old behaviour) sits 0.33 to 1.1 from native, at least 3300 times the R tolerance.

## 7a. Issue Ledger

- Fixed: NEWS and known-limitations implied that every structured Julia fit became conditional. Measured: Gaussian `relmat(1 | id, K = K)`, Poisson `relmat(1 | id, K = K)` and Poisson `animal(1 | id, A = A)` fitted WITHOUT an `sd(...)` formula still return the population-level value (fitted gap 0.84 to 0.89 on the patched code). Both documents now say so.
- Fixed: Julia test header comment (1e-9 versus the 1e-4 actually used).
- Found, not fixed: `test-julia-fitted-definition.R` errors in its callr subprocess because it loads the installed drmTMB; the worker read this as an environment issue and I did not rerun it on a clean tree.
- Found, not fixed: seven `test_lss_*` files need `StableRNGs` that the project environment lacks.
- Found, not fixed (worker report, confirmed by reading): the NB2 fitter stores its log-likelihood from a boxed variable shared with its closures.

## 8. Consistency Audit

- Read every fitter that now records `cond_*`; Poisson, Gamma, Binomial and Gaussian skip the phylogenetic and REML routes as claimed. The slope-only Gamma and Poisson animal fitters inherit the payload through the shared fitter, but the bridge refuses those formulas, so they are unreachable from R (tested: refused).
- Offset and an added ordinary `(1 | g2)` term are refused by the bridge for the Poisson and Gaussian structured routes, so the payload cannot be combined with a missing ordinary-effect mode.
- No em dashes in anything added; NEWS pairs `engine = "julia"` with named families and routes, never with all, any or every family.
- No new evidence ids or ledger rows were added by this batch, so there is no fragment hash or row_key to grant.

## 9. What Did Not Go Smoothly

- My first launch of the Julia neighbour batch ran twice on the same cores and truncated logs; I killed both sets (matched by working directory under my own scratch tree) and relaunched once.
- The R worktree HEAD moved twice while I worked; the patch applies to each head I checked.

## 10. Known Residuals

- Still population level on the Julia engine: structured fields without an `sd(...)` formula, phylogenetic fields, Binomial structured plus ordinary `(1 | g)`, mesh, crossed, `phylo_interaction`, Gamma animal intercept-plus-slope, Gaussian REML structured, and `predict()` on stored rows (so `predict()` no longer equals `fitted()` on the fixed routes).
- One fixture per route and seed; no standard-error, coverage, calibration or broad parity claim.
- Not run: `devtools::check()`, `document()`, the full testthat suite, the after-task validator.

## 11. Team Learning

When a documentation claim is made for a route family, measure one route OUTSIDE the family on the patched code. Here that one extra fit (plain `relmat(1 | id)`) showed the claim was one step too broad.

## 12. Cross-Product Coverage

Engine `julia`, structured mean field, `fitted()` and `residuals()` against native (this verification does NOT cover the items marked ✗):

- Gaussian, Poisson, NB2, Gamma, Binomial with `sd(id, level = ...)` and relmat intercept ✓ (my fixtures, 5 families plus an NA-row fixture); animal, spatial, slope, probit, cloglog, `Ainv`, q2 ✓ through the worker fixtures, reproduced.
- Structured field without an `sd(...)` formula ✗ (population level, documented).
- Phylogenetic, REML, ordinary plus structured, mesh, crossed, Beta, beta-binomial, other families ✗.
- `predict()`, `simulate()`, standard errors, intervals ✗.
