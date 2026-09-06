# After Task: Hurdle NB2 through `engine = "julia"` (parity leaf fam-hurdle-nbinom2)

## 1. Goal

Make ONE identical call fit the hurdle negative binomial on both engines. Before
this leaf, `engine = "tmb"` fitted `family = truncated_nbinom2()` + `hu ~ ...`
and refused `nbinom2()` + `hu`, while `engine = "julia"` did the opposite --
the asymmetry `drm_julia_capability_comparison()`'s own `hurdle_nbinom2` row
named as the defect blocking its promotion.

## 2. Implemented

* **DRM.jl (PR #662, merges first).** `TruncatedNegBinomial2()` accepts an
  optional `hu` formula part and delegates to the existing `NegBinomial2`
  hurdle kernel `_fit_negbin2_hu`, so the two spellings are one code path. The
  delegation is declared in the docstring and asserted in the test (the fit
  reports `NegBinomial2`), because `_conditional_dist(::TruncatedNegBinomial2)`
  applies a zero-truncation PIT correction a hurdle fit must not get. Second
  change: a formula part the family does not consume is now an ERROR instead of
  a silent drop.
* **drmTMB.** `drm_julia_bridge_model_type()` gives a bridge hurdle fit the
  NATIVE `model_type` `"hurdle_nbinom2"` instead of the family tag
  `truncated_nbinom2`, which is what makes `predict(fit, dpar = "hu")` resolve
  its logit link. The `hurdle_nbinom2` ledger row is re-measured on the
  identical call and promoted `experimental -> partial`. No registry row is
  added: `hurdle_nbinom2` is a model_type, not a family_type.

## 3. Mathematical Contract

Hurdle, confirmed from both likelihoods before any code was written, not from
the names. drmTMB `src/drmTMB.cpp` model_type 12:
`y == 0 -> nll -= w * log_hu`; `y > 0 -> nll -= w * (log_one_minus_hu +
log NB2(y) - log1mexp(log NB2(0)))`. DRM.jl `src/negbinomial.jl`
`_fit_negbin2_hu`: the same two branches. `hu = logistic(X_hu b)` is `P(y = 0)`;
the positive counts are the ZERO-TRUNCATED NB2; the NB2 size is `1/sigma^2` on
both sides. The zero-INFLATED neighbours are different code on both sides
(drmTMB model_type 9, DRM.jl `_fit_negbin2_zi`, `P(0) = pi + (1-pi) NB(0)` with
an UNTRUNCATED count component), and both engines refuse `zi` and `hu`
together.

## 3a. Decisions and Rejected Alternatives

* **Delegate to `NegBinomial2` rather than re-type the hurdle nll under
  `TruncatedNegBinomial2`.** Considered making `_fit_negbin2_hu` accept either
  family so the fit would report `TruncatedNegBinomial2`. REJECTED after
  reading `src/quantile_residuals.jl`: `_conditional_dist(::TruncatedNegBinomial2)`
  routes the discrete PIT through a zero-truncation branch that would be wrong
  for a hurdle (and undefined at `y = 0`). Family-correct labelling would have
  bought a cosmetic name and a silently wrong diagnostic.
* **DROPPED: the count-modifier fence.** Refusing `nbinom2() + hu`,
  `poisson() + hu` and `truncated_nbinom2() + zi` through `engine = "julia"`
  (so the bridge is never MORE permissive than native) was in this leaf's first
  ledger draft. Dropped with a written reason: it is not needed to close the
  spelling asymmetry, and it would falsify `pm_test_modifier_routes()`'s
  `bridge_family = "nbinom2"` pin in `tests/testthat/test-parity-matrix.R` and
  its twin in `tools/write-parity-matrix.R`, neither of which this leaf owns
  (both are held by the concurrent docs-staleness lane). Recorded as an
  integrator follow-up in the row's `next_action`, with the measured refusal.
* **`fitted()` left divergent, declared not hidden.** See section 10.

## 4. Files Touched

drmTMB: `R/julia-bridge.R` (the `drm_julia_bridge_model_type()` helper + its one
call site; the `hurdle_nbinom2` row's syntax / r_bridge_status / drmjl_status /
claim_boundary / next_action), `R/julia-family-registry.R` (comment only, no
row), `tests/testthat/test-julia-family-hurdle_nbinom2.R` (new),
`tests/testthat/test-julia-family-truncated_nbinom2.R` (the falsified
`err_hurdle` probe, plus its `err_ranef` assertion which was already red on
origin/main), `inst/extdata/julia-capabilities.tsv` and
`docs/dev-log/dashboard/julia-capabilities.tsv` (REGENERATED),
`docs/design/258-coefficient-naming-contract.md` (new section 8.10; section
8.1's now-false hurdle paragraph marked SUPERSEDED), `NEWS.md`, this report.

DRM.jl: `src/negbinomial.jl`, `test/test_hurdle.jl`.

## 5. Checks Run

All numbers below were measured in this run.

* **RED FIRST.** `truncated_nbinom2() + hu` through `engine = "julia"` at the
  pin 430ef64cc: `TruncatedNegBinomial2() requires positive integer counts (>= 1)
  as the response`. The same `bf()` with `family = nbinom2()` natively:
  ``nbinom2()` models only support `mu`, `sigma`, and optional `zi`. Unsupported
  parameter: "hu".` -- and it FITS through `engine = "julia"` (logLik
  -2941.45558666657, the same value the native `truncated_nbinom2()` fit reaches,
  -2941.45558666655; the two engines were already fitting the same likelihood
  under different spellings).
* **DRM.jl tests**: `include("test/test_hurdle.jl")` -> 4 testsets, 25 passes,
  0 fail, 0 error. Neighbours (`test_truncated_nb.jl`,
  `test_quantile_residuals.jl`, `test_niterations.jl`,
  `test_missing_response_nongaussian.jl`, `test_simulate_scale_conventions.jl`,
  `test_api_stability.jl`, `test_bf_grammar.jl`) all pass, no Fail/Error line.
* **Same-call parity** (`tools/parity_fixture.R` comparator, cell list narrowed,
  comparator `tools/parity_numeric.R` byte-identical to the pin's):
  `hurdle_nbinom2 PARITY_PASS coef_diff=9.429e-12 loglik_diff=2.183e-11`,
  `max_abs_coef_diff 9.4286800589316e-12`, `loglik_tmb -2941.45558666655`,
  `loglik_julia -2941.45558666657`, tol 1e-4.
* **SE axis** (`tools/parity_se.R`): `se_hurdle_nbinom2 SE_PASS
  abs_diff=1.537e-07 rel_diff=1.101e-06` over 8 SEs at rtol 1e-3; the
  comparator's own negative control read `negative_control_perturbed
  NEGATIVE_CONTROL_OK abs_diff=4.809e-03 rel_diff=9.091e-02`.
  `drmtmb_code_hash bd4159e33719cad38602daf55dac0b7c7fe19712b266829642e462190ccccbda`.
* **Post-fit surface**: `model_type` `"hurdle_nbinom2"` on both engines;
  `predict(dpar = "hu")` agrees to 7.295e-13 and equals `plogis` of the link
  prediction; `mu` 5.771e-12, `sigma` 3.405e-11; estimator `"ML"` ==
  `bridge$estim_method` `"ML"`; AIC 5898.91117333 on both; `df` 8, `nobs` 1800
  on both; `REML = TRUE` refused R-side.
* **Offline sweep**, `NOT_CRAN=true`, no Julia: 55 files
  (`test-julia-*.R` + hurdle/parity-matrix/coefficient-labels/estimator-surface/
  truncated-locscale) -> passed=2100 failed=0 error=0 skipped=48 warning=0.
* **Live**, at the DRM.jl branch:
  `test-julia-family-hurdle_nbinom2.R` 7 tests / 62 passed / 0 failed / 0 error
  / 0 skipped; `test-julia-family-truncated_nbinom2.R` 3 / 33 / 0 / 0 / 0.
* `python3 tools/capability_ledger.py --check` -> `capability-ledger: OK
  (31 generated outputs)`. TSVs regenerated by
  `Rscript tools/write-julia-capability-comparison.R` (25 rows), never
  hand-edited.

## 6. Tests of the Tests

Two red controls, both restored byte-identically.

1. **DRM.jl silent-drop guard.** With the part-name guard removed,
   `drm(bf(y ~ x, sigma ~ 1, zi ~ w), TruncatedNegBinomial2())` RETURNS A FIT and
   the captured error string is empty:
   `Expression: occursin("unsupported formula part `zi`", err) / Evaluated:
   occursin("unsupported formula part `zi`", "")` -- 3 passed, 2 failed.
   `src/negbinomial.jl` sha256
   `614a71c51f086c684b6ff943b03ea45f13ebb3681b2a702d9338f05cd00ca5c5` before and
   after; tests green again.
2. **drmTMB model_type helper.** With `model_type = family_type` restored, the
   bridge fit reports `truncated_nbinom2` and `predict(fj, dpar = "hu")` ABORTS:
   ``predict()` has no canonical prediction link for Julia-engine `hu``.
   `R/julia-bridge.R` sha256
   `f485e2ef126ad3e5f239328a8ebfd038a527bb0a80234f3e09a928b2a9c30538` before and
   after; `MODEL_TYPE: hurdle_nbinom2 / PREDICT_HU: OK range 0.0907894 0.7206794`
   afterwards.

The SE comparator carries its own negative control (above). The new test file's
`fitted()` testset is a positive control on the gap: it asserts the native
hurdle mean is reproducible from the BRIDGE's dpars to 1e-6, so a future dpar
regression cannot hide behind the known aggregation difference.

## 7a. Issue Ledger

`hurdle_nbinom2` in `drm_julia_capability_comparison()`: `r_bridge_status`
`experimental -> partial` on the wave-1 bar (same-target point + SE receipt).
`claim_status` stays `partial`. `next_action` now lists three follow-ups:
the `fitted()`/`residuals()` aggregation gap (owned by the zi_nbinom2 leaf's
`_bridge_fitted_marginal`), the bridge's remaining over-permissiveness about
count modifiers (an integrator change), and the absent G3 profile/bootstrap
receipt.

## 8. Consistency Audit

Walked the neighbours the change falsifies. Design 258 section 8.1 claimed the
`hu` part is caught by the coef_labels echo as an "unknown dpar" -- now false,
marked SUPERSEDED with a pointer to 8.10. `test-julia-family-truncated_nbinom2.R`'s
`err_hurdle` probe asserted that same echo message -- replaced with the `zi`
probe, which is the part the family genuinely does not consume. The registry's
NOT-ADMITTED comment listed `hurdle_nbinom2` among tags "the Julia bridge has no
case for" -- corrected, with the same correction made for `zi_poisson` /
`zi_nbinom2`, which are also model_types rather than family_types.
`tests/testthat/test-parity-matrix.R` was re-run: its modifier-route pin
(`bridge_family = "nbinom2"` for the hurdle route) is still TRUE, because this
leaf does not fence off the `nbinom2() + hu` spelling, and the row's new syntax
names both.

## 9. What Did Not Go Smoothly

The first ledger draft planned a count-modifier fence and had to be cut once the
parity-matrix pins were read (section 3a). The live run also surfaced a failure
that is NOT this leaf's: `test-julia-family-truncated_nbinom2.R`'s `err_ranef`
assertion expects DRM.jl's "TruncatedNegBinomial2() currently supports fixed
effects only", but drmTMB's A4.G17 fe-only fence (already on origin/main) now
refuses R-side first, so that live assertion is red on main. Fixed here, in the
same file, and flagged rather than passed over.

## 10. Known Residuals

* **`fitted()` and `residuals()` DIVERGE on this route** -- max abs 1.094 on
  this fixture. DRM.jl's `fitted()` is `means[:mu]`, the UNTRUNCATED NB2 mean;
  native returns the hurdle mean `(1 - hu) * mu / (1 - P0)`. Every dpar the
  bridge returns is correct: `hurdle_nbinom2_mean()` reproduces the native
  `fitted()` from the bridge dpars to 4.045e-11. Pre-existing, shared with every
  `zi`/`hu` fit, and owned by the zi_nbinom2 leaf (`_bridge_fitted_marginal`).
  NOT fixed here, and declared in the ledger row's `claim_boundary`.
* `sigma()` returns a numeric natively and a list through the bridge on these
  mixture routes; `coef()` block ORDER is alphabetical through the bridge
  (`hu, mu, sigma`) versus native `mu, sigma, hu`, because
  `new_drmTMB_julia()` builds the blocks with `split()`. Both are pre-existing
  and family-general (`student` gets `mu, nu, sigma` the same way), so they are
  a separate leaf, not this one. The new tests compare the dpar SET, not the
  order.
* `residuals(type = :quantile)` in DRM.jl ignores `hu`/`zi` entirely for these
  fits (`_conditional_dist` sees only the count component). Recorded in the
  DRM.jl PR.
* No phylogenetic, random-effect or structured hurdle route; one fixture, one
  seed; no interval coverage; bridge-side inference (G3) unqualified.

## 11. Team Learning

The premise handed to this leaf -- "native family_type `hurdle_nbinom2`, add a
registry row" -- was wrong, and reading `R/drmTMB.R` for ten minutes before
writing the ledger is what caught it. `hurdle_nbinom2` is a post-fit
`model_type`; the family is `truncated_nbinom2()`. The generalisable rule: the
bridge's family registry keys on `drm_family_type(family)`, so any drmTMB model
reached by a FORMULA PART (`zi`, `hu`) rather than by a constructor needs no
registry row at all -- but it does need its `model_type` corrected on the way
back, or every model_type-keyed surface (links, summary labels, family-specific
means) silently reads the wrong model.

## 12. Cross-Product Coverage

Fixed effects x {mu, sigma, hu} with covariates on all three, on one fixture
with 486 zeros and 1314 positive counts. NOT covered: random effects, `phylo()`,
`relmat()`/`animal()`/`spatial()`, offsets, weights, missing-data routes,
`newdata` prediction, profile/bootstrap intervals, and more than one seed.

## Next Actions

1. Merge DRM.jl PR #662 first; the drmTMB PR's receipt does not reproduce
   without it (the pin refuses the call).
2. When the zi_nbinom2 leaf's `_bridge_fitted_marginal` lands, re-measure
   `FITTED_MAXDIFF` (1.094 today) and update the row's `claim_boundary`.
3. Integrator: decide whether `engine = "julia"` should stop accepting
   `nbinom2() + hu` / `poisson() + hu`, which native refuses. That needs the
   parity-matrix modifier-route pin and its tool twin to move together.
