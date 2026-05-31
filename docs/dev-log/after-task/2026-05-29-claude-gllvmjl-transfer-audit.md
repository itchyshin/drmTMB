# After Task: Claude GLLVM.jl Transfer Audit

## Goal

Audit Claude's untracked `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md`
note before treating it as a `drmTMB` plan of record, then make only the
smallest useful `rho12` interval change if the gap was real.

## Source Evidence

Claude's note is useful as a triage input, not as verified project state. I
checked the highest-priority claims against the cited sister-repo files and the
current `drmTMB` source:

- The `GLLVM.jl` local checkout path
  `gllvmTMB.jl/src/confint_derived_wald.jl` implements transformed-Wald
  intervals for bounded derived quantities by applying Fisher-z to correlations
  and logit to quantities in `[0, 1]`, then mapping intervals back to the
  response scale. The public wrappers include `correlation_wald_ci()` for
  correlation targets.
- `gllvmTMB-julia-bench/report/comparison-final.md` reports that transformed
  Wald matched bootstrap for interior derived bounded quantities in that pilot,
  while profile intervals collapsed for some phylogenetic derived quantities.
  This evidence is about GLLVM.jl fixtures; it should not be copied into
  `drmTMB` as a coverage claim without a package-specific simulation.
- `R/profile.R` already documents and implements direct correlation Wald
  intervals on the fitted TMB link scale before transforming back to the
  correlation scale. For constant residual `rho12`, the target row uses
  `transformation = "rho12_tanh"`, and `drm_wald_confint()` builds link-scale
  intervals before `rho_response()` maps endpoints back.
- `R/predict-parameters.R` already has row-specific fixed-effect Wald intervals
  for prediction grids. For residual `rho12`, this is the row-specific
  transformed-Wald route Claude's note was pointing toward: the linear predictor
  is intervalled on the atanh scale and then mapped back with the guarded
  inverse link.
- `R/drmTMB.R` already uses `lm.fit()` starts for Gaussian location terms,
  residual-scale starts, and a Fisher-z start for bivariate `rho12`. Claude's
  closed-form warm-start item is therefore partly already implemented.
- `R/drmTMB.R` calls `TMB::MakeADFun()` without a `profile =` argument, so
  analytic `sigma` profile-out is not currently wired into the optimizer. That
  remains a larger design task, not a quick follow-on edit.

## Triage

| Claude item | Current `drmTMB` status | Decision |
| --- | --- | --- |
| Transformed-Wald CIs for bounded correlation targets | Direct constant `rho12` and direct random-effect correlations already use link-scale Wald intervals and back-transformation. Row-specific fixed-effect `rho12` intervals are available through `predict_parameters(..., newdata = grid, dpar = "rho12", conf.int = TRUE)`. | Lock and document the existing route rather than add a new CI engine. |
| Closed-form warm starts | Gaussian and bivariate Gaussian starts already use `lm.fit()`, residual SD estimates, and Fisher-z `rho12` starts. | Defer broader startup work until there is a measured iteration-count problem in a specific family. |
| `sigma ~ 1` profile-out | Not wired through `MakeADFun(profile = ...)` or an equivalent package-level parameter reduction. | Defer as a separate design and validation slice. It changes optimization geometry and `vcov()` expectations. |
| Sparse phylogenetic precision and relaxed-clock edge incidence | Promising but much larger than this interval audit and tied to different GLLVM.jl model structure. | Keep as a later design/ADEMP lane. |

## Changes

- Added a focused regression check in
  `tests/testthat/test-predict-parameters.R` showing that row-specific
  `rho12` Wald intervals from `predict_parameters()` are computed on the
  atanh-scale linear predictor and back-transformed with `rho_response()`.
- Updated `docs/design/12-profile-likelihood-cis.md` so the interval status
  table distinguishes the cheap row-specific Wald route in
  `predict_parameters()` from the slower row-specific profile route in
  `confint(..., method = "profile", newdata = ...)`.

## Validation

```sh
air format tests/testthat/test-predict-parameters.R
Rscript --vanilla -e "devtools::test(filter = 'predict-parameters', reporter = 'summary')"
rg -n "predictor-dependent.*rho12|row-specific.*profile|confint\\(.*rho12.*newdata|rho12.*newdata.*profile|predict_parameters\\(.*rho12|row-specific Wald|Fisher-z Wald" README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**'
git diff --check
gh issue list --search "rho12 interval predict_parameters transformed Wald" --limit 20
gh issue list --search "Claude GLLVM.jl transformed Wald rho12" --limit 20
```

Result:

- `test-predict-parameters.R` passed.
- The stale-wording scan found profile-focused public wording in README,
  vignettes, roadmap, and historical design notes. These are not contradictory:
  `confint(..., method = "profile", newdata = ...)` remains the likelihood-shape
  route, while `predict_parameters()` is the cheap grid-Wald route now recorded
  in the profile-CI design table.
- `git diff --check` was clean.
- The issue searches returned no matching open issue that needed an update.

## Review Notes

- Ada kept the slice to the verified `rho12` interval surface rather than
  starting a new CI engine.
- Fisher treated the GLLVM.jl coverage table as a transferable hypothesis, not
  as direct `drmTMB` evidence.
- Rose separated current source facts from Claude's unverified benchmark
  claims.
- Grace checked the focused test. Broader package checks were not rerun for
  this small audit slice.
- No spawned subagents were running.

## Known Limitations

The GLLVM.jl coverage table remains sister-repo evidence only. A `drmTMB`
coverage claim for row-specific `rho12` Wald intervals would need a focused
simulation that compares Wald, profile, and bootstrap under ordinary and
boundary-prone residual-correlation settings.
