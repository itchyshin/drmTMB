# After Task: FX7 Julia `resd` label (#1551) and `miss_control()` fail-closed (#1454)

Reader: the next Engine A agent scoring the 16 Oct 2026 DRM lane, and
Shinichi when reviewing the draft stacked on #1565. Purpose: record what
this fix changed, the red-proof before and after, and what was left alone.

## Goal

Close two t5 bridge defects that became reachable after #1565 stopped the
JuliaCall setup SIGSEGV: Poisson and Gamma ordinary `(1 | g)` abort after
the Julia fit because `coef_labels` has no `resd` entry (`resd_g`), 54 of
54 unweighted cells; and `miss_control()` with NA in `x` fits on
`engine = "julia"` instead of failing closed, 6 of 6 Gaussian cells.

## Implemented

For #1551, `drm_julia_bridge_payload_coef_labels()` now labels `resd`
with the grouping factor of a single ordinary mean `(1 | g)` when the
family is Poisson or Gamma. The same route sets
`options$marginal = "Laplace"` inside `drm_julia_bridge_payload()`. Native
TMB uses Laplace; DRModels.jl defaults to `:LA` (5-node AGHQ) for this
shape. The t5 receipt measured that default at 4.5e-02 (Poisson) and
5.4e-03 (Gamma) log-likelihood against TMB, and `:Laplace` at about 1e-12.
Sending the label without Laplace would have turned a loud echo abort into
a silent integrator mismatch. That override is a route default, not a
`drm_control()` key, so the optimizer whitelist (`g_tol`, `algorithm`,
`q4_vcov`) is unchanged.

Gaussian ordinary `(1 | g)` still has no `resd` label: it uses the
conditional-components route, and an extra `resd` block would be an
unknown dpar there. nbinom2, beta, and binomial keep the loud `resd` echo.
Labelling those without a supported Laplace path (DRModels.jl#943 refuses
`:Laplace` when `sigma ~ x`) would silently take AGHQ.

For #1454, the A-2 complete-predictor check
(`drm_missing_explicit_predictor_fail()` plus
`drm_validate_complete_predictors()`) now runs before the Julia early
return in `drmTMB()`. `missing = miss_control()` and
`miss_control(predictor = "fail")` with NA in `x` abort with the same
"requires complete predictors" / `Missing values in: "x"` message as
`engine = "tmb"`. Omitted `missing` still reaches the bridge and drops
rows. The `#1450` weights fence and the offset-as-free-coefficient
refusal are not edited.

## Mathematical Contract

Poisson / Gamma `(1 | g)` on `engine = "julia"` now asks DRModels.jl for
the Laplace marginal, the same objective TMB maximises. No new family,
link, or `sigma` parameterisation.

## Files Changed

- `R/julia-bridge.R` — `drm_julia_ordinary_mu_ri_group()`,
  `drm_julia_poisson_gamma_ordinary_ri()`, the `resd` label, and the
  Laplace option.
- `R/drmTMB.R` — A-2 check moved above the Julia early return.
- `tests/testthat/test-julia-ordinary-mu-resd.R` — #1551 red-proof.
- `tests/testthat/test-julia-miss-control-predictor.R` — #1454 red-proof.
- `NEWS.md`, this report, and `docs/dev-log/check-log.md`.

`R/methods.R`, `R/mi-weights.R`, and `src/` were not edited. Offset
bridge rejection and the weights fence were not edited.

## Checks Run

Red-proof on `pkgload::load_all()` against #1565 head `b0cf1d8a` (tests
added, helpers absent):

- `test-julia-ordinary-mu-resd.R`: FAIL 2 / the two label assertions saw
  `labels$resd` NULL for Poisson and Gamma `(1 | g)`.
- `test-julia-miss-control-predictor.R`: the three `miss_control()` calls
  reached `drmTMB_julia_bridge()` at `R/drmTMB.R:336` instead of
  "requires complete predictors".

After the helpers and the moved A-2 check:

- `test-julia-ordinary-mu-resd.R`: FAIL 0 / PASS 12.
- `test-julia-miss-control-predictor.R`: FAIL 0 / PASS 6.

Sibling paths, same load_all:

- `test-miss-control-evaluated.R` — 11 pass (native A-2 unchanged).
- `test-missing-data-control.R` — 15 pass.
- Gaussian `(1 | g)` still has `labels$resd` NULL
  (`test-coefficient-labels.R` and the #1551 sibling test).
- nbinom2 `(1 | g)` still has `labels$resd` NULL.
- Optimizer whitelist still exactly `g_tol`, `algorithm`, `q4_vcov`.

Live Julia smoke (`DRMODELS_JL_PATH=/tmp/DRModels.jl` at `f71b2923`,
`JULIA_PROJECT` unset, official Julia 1.12.7, `%||%` shimmed into the
package imports env for R 4.3.3 / #1550):

- Poisson `(1 | g)`: native logLik `-125.347330813`, Julia
  `-125.347330809`, delta `3.933e-09`, `nobs = 80`. Completes; no
  `resd_g` echo abort.
- Gamma `(1 | g)`: native logLik `-66.250176824`, Julia
  `-66.2501768231`, delta `8.137e-10`. Completes.
- `#1454` `missing = miss_control()` with NA in `x`:
  `requires complete predictors` / `Missing values in: "x"`.
- `#1450` `weights = NULL` still fences:
  `engine = "julia" does not support weights yet`.

C17 is recertified because `R/drmTMB.R` changed. The A-2 move sits
outside the authenticated model-15 anchors (zero-one-beta sigma/zoi
routes). Numbers are recorded in the check-log after
`python3 tools/recertify-c17.py --label fx7-julia-resd-misscontrol --tolerance 1e-10`.

The full `testthat` suite is recorded in the check-log / PR receipt.

## Tests Of The Tests

The #1551 tests failed on the unfixed label helper with the exact missing
`resd` entry t5 reported (`Julia names: ["resd_g"]`). The #1454 tests
failed by entering the Julia bridge, the same early-return skip t5
measured on J6. After the fix they demand the predictor-fail message and
name `"x"`. Omitted `missing` is mocked through to the bridge so the
drop path stays open. A stored `miss_control()` fails like the literal
call, matching #1484.

## Consistency Audit

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]|meta_known_V\\(V = V\\).*(current|preferred|stable|default)" \
  R/julia-bridge.R R/drmTMB.R tests/testthat/test-julia-ordinary-mu-resd.R \
  tests/testthat/test-julia-miss-control-predictor.R NEWS.md \
  docs/dev-log/after-task/2026-10-16-fx7-julia-resd-misscontrol.md
rg "resd|miss_control|marginal = \"Laplace\"|predictor = \"fail\"" \
  R/julia-bridge.R R/drmTMB.R tests/testthat/test-julia-ordinary-mu-resd.R \
  tests/testthat/test-julia-miss-control-predictor.R NEWS.md
```

No new `meta_gaussian` / `tau ~` / `rho ~` wording. Terms `sigma` and
`rho12` were not renamed. `marginal = "Laplace"` is a bridge option, not
a user formula.

## GitHub Issue Maintenance

Refs #1551 and #1454 only. Never Closes. #1450 (weights fence, including
`weights = NULL`) and the offset-as-free-coefficient refusal are left to
their own lanes. PR #1504 still claims a broader #1454 alignment fix;
this change is the t5 fail-closed predictor case only.

## Design-doc / pkgdown / inventory

No formula-grammar or likelihood parameterisation change, so
`docs/design/01-formula-grammar.md` and `docs/design/03-likelihoods.md`
were left alone. Design 149 already names `predictor = "fail"` as the
first safe predictor policy; this change applies that same A-2 check
before the Julia early return. User-facing note:
`vignettes/julia-engine.Rmd` under Missing responses. NEWS bullets for
#1551 and #1454. Status inventory (`README.md` current status,
`docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`,
`vignettes/formula-grammar.Rmd`, `_pkgdown.yml`) did not need a new
capability row: this is a bridge-contract and fail-closed alignment, not
a new family or formula.

## What Did Not Go Smoothly

This cloud snapshot had no R or Julia at boot. R 4.3.3 and TMB were
installed here. R 4.3.3 lacks base `%||%` (#1550); assigning into the
locked namespace fails, so live smoke and the suite shim `%||%` into
the unlocked `imports:drmTMB` environment. The red-proof asserts labels
and the Laplace helper without calling `drm_julia_bridge_payload()`.
Live fits against DRModels.jl `f71b2923` then succeeded with
`JULIA_PROJECT` unset.

## Team Learning

A Julia early return that skips a later TMB-only guard will replay every
later data-policy fix as an engine split. Put shared fail-closed checks
before the engine branch. For non-Gaussian ordinary `(1 | g)`, a missing
`resd` label and a missing `marginal = "Laplace"` are one defect: fixing
only the label is worse than the current abort.

## Known Limitations

nbinom2, beta, and binomial ordinary `(1 | g)` still abort at the `resd`
echo. For nbinom2/beta with `sigma ~ x`, DRModels.jl cannot take Laplace
today. Structured and q2 NA alignment items in #1454 are not this change.
#1450 remains the weights fence.

## Next Actions

Re-run the t5 unweighted Poisson/Gamma cells and the six Gaussian
`miss_control()` cells on #1565 plus this head, with `DRMODELS_JL_PATH`
at `f71b2923` and `JULIA_PROJECT` unset. Draft only. Do not merge.
