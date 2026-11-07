# After Task: Bernoulli Crossed Julia SD Output Parity

## 1. Goal

Repair the candidate R-to-Julia bridge for two crossed ordinary Bernoulli
random-intercept SD targets, align public group predictions with native TMB,
and verify marginal simulation and save/reload behavior.

## 2. Implemented

The bridge now derives disambiguated coefficient-block names when a fit has
multiple SD targets. Public stored-group `predict()` removes the target prefix
for ordinary `sd(group)` outputs, returning group labels as native TMB does.
The fitted `sdpars` vectors retain target-qualified names. The test covers
`predict()` and `predict_parameters()` for both targets. A Julia-specific
`simulate()` method now supports marginal simulation for complete-data
Binomial models with predictor-dependent SDs on distinct independent ordinary
random intercepts. It uses fitted group SDs for fresh link-scale draws;
conditional simulation is refused because this non-Gaussian Julia route does
not retain conditional modes.

## 3a. Decisions and Rejected Alternatives

Keep target-qualified names in the fitted `sdpars` vectors because they
identify which SD regression produced each value. Normalize names only in
public stored-group `predict()` output for ordinary SD targets, where native
TMB uses group labels. Structured target naming remains unchanged.
Marginal simulation is limited to the fitted Bernoulli random-intercept slice;
the simulator refuses shapes whose latent draws it cannot reconstruct.

## 3. Mathematical Contract

The fixture has two independent latent intercepts, with
`log(tau_g) = alpha_g0 + alpha_g1 * w_g` and
`log(tau_h) = alpha_h0 + alpha_h1 * v_h`. It adds no residual Bernoulli
dispersion and does not change the likelihood or covariance model.

## 4. Files Touched

- `R/julia-bridge.R`
- `R/julia-simulate.R`
- `NAMESPACE`
- `man/simulate.drmTMB.Rd`
- `tests/testthat/test-julia-binomial-crossed-sd.R`
- `NEWS.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/general-sd-regression/julia-output-contract.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/julia-engine.Rmd`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-23-julia-binomial-crossed-current-source-rerun.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-crossed-bridge-20261023-current/`
- This report.

## 5. Checks Run

The live focused test passed 30 assertions, with no failures or skips. Both
engines converged; coefficient comparisons used tolerance `0.02`, group SD
predictions and prediction-table estimates used tolerance `0.03`, and the
absolute log-likelihood difference was required to be below `1e-3`. JuliaCall
reported one nonfatal warning while trying to precompile
`LogExpFunctionsInverseFunctionsExt` (`UndefVarError: loglogistic`); the Julia
fits and assertions completed. The test also checked that coefficients and
group SD predictions survive RDS save/reload, and compared seeded marginal
simulation against an independently reconstructed pair of group-level normal
draws followed by Bernoulli sampling. Repeating the simulator with the same
seed returned identical responses.

Current-source rerun on 2026-10-23:

- The same R-to-Julia test completed with exit status 0 against drmTMB HEAD
  `425bee81572c625a634b2b083050c5c57c1dc1f1` and the paired DRM.jl worktree at
  HEAD `70dbf564eb670144c63c08f61ea099084d95add2`. One live Julia bridge test
  ran, with no reported failed assertions or skips. JuliaCall emitted its
  existing non-fatal `LogExpFunctionsInverseFunctionsExt` precompile warning
  (`UndefVarError: loglogistic`).
- The paired Julia test `test/test_binomial_crossed_sd_regression.jl` was also
  rerun against the current Julia source and passed 20/20 assertions in 20.2
  seconds.
- Current R, TMB, Julia and test-source hashes are retained in
  `docs/dev-log/general-sd-regression/evidence/julia-binomial-crossed-bridge-20261023-current/source-manifest.json`.
  These are focused workflow and output checks, not recovery across seeds or
  interval-calibration evidence.

SHA-256: `R/julia-bridge.R` is
`00cc734af9e843cf57e4ac79bd95ec1f89e6aeeddde70bdfa312fa114e87d7c2`;
`tests/testthat/test-julia-binomial-crossed-sd.R` is
`c1e14ef006dc7f8ada4fdbd2de43228b2280623ba32204194a0d6ed98cb0eb07`.

`pkgdown::check_pkgdown()` reported no problems. The updated Julia vignette
rendered to `/private/tmp/general-sd-julia-engine-20261023.html`. Pandoc emitted
its existing deprecated MathML/MathJax option warnings.

## 6. Tests of the Tests

The live crossed fixture initially reproduced the missing coefficient-block
failure. After block lookup was fixed, assertions caught the target-prefixed
Julia prediction names that differed from TMB. The final test checks the hashed
block identity, both target coefficient vectors, group names and values from
both prediction APIs, retained target-qualified `sdpars` names, RDS
preservation, and the seeded marginal simulation oracle. A first simulation
attempt exposed the missing Julia S3 method; the next exposed that public SD
predictions use unprefixed group names. The implemented simulator follows that
public naming contract.

## 7a. Issue Ledger

The GitHub issue search failed because `api.github.com` was unreachable. No
issue was changed, and overlap with open issues remains unverified.

## 8. Consistency Audit

The bridge retains formula-derived target aliases and changes names only at
the public stored-group prediction boundary for ordinary targets. Structured
target naming and `newdata` row naming are unchanged. The new simulator is
registered as an S3 method and its reference page documents the marginal-only
Bernoulli intercept boundary. The full general SD programme remains at one of
nine formal gates: G2 is met; the other gates remain open. This adds partial
output-workflow evidence to G4, which remains open.

The status inventory search used:

```sh
rg -n "crossed two-group|group-level names|group labels, matching native TMB|target-qualified names" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd vignettes/predictor-dependent-random-sd.Rmd
```

No formula grammar or pkgdown navigation change was needed.

## 9. What Did Not Go Smoothly

The first hand-built parity script assigned SD predictors in the wrong row
order and correctly stopped at the within-group validation. The fixed-seed
test now assigns predictors by group ID. A default test run also skipped live
Julia; rerunning with `DRMTMB_JULIA_TESTS=true` exercised the engine. The
nonfatal JuliaCall extension warning remains environmental and unrelated to
the passing fit.

## 10. Known Residuals

This is one synthetic point-parity and seeded marginal-simulation fixture on
the dirty drmTMB candidate at
`425bee81572c625a634b2b083050c5c57c1dc1f1` paired with DRM.jl candidate
`70dbf564eb670144c63c08f61ea099084d95add2`. It does not establish recovery
across seeds, conditional simulation, slopes, correlated or structured latent
effects, other response families, calibrated intervals, or released Julia
availability. The candidate branches remain dirty and behind their bases.
Whole-worktree `git diff --check` also reports a pre-existing blank line at
`tests/testthat/test-binomial-sd-integration.R:225`; that file was not changed
for this slice.

## 11. Team Learning

Cross-engine tests for multi-target models should assert target lookup and
public output labels as well as successful fitting. Keep internal target
identities qualified while matching native group labels at the public
prediction boundary.

## Next Actions

Continue the Bernoulli capability map across random-effect types and engines,
then proceed through the remaining family rows. Keep G3 and G5 open until the
required implementation inventory and calibrated-uncertainty evidence pass.

## 12. Cross-Product Coverage

This slice covers two independent ordinary Bernoulli intercept SD targets on
separate crossed groups, using native TMB and the paired Julia candidate. It
checks formula-target identity, coefficient extraction, likelihood, group SD
prediction, `predict_parameters()`, RDS preservation, and marginal simulation
for this one fixed-seed fixture. This fixture does NOT cover conditional
simulation, structured or correlated providers, random slopes, other response
families, bivariate models, missing-data routes, calibration, or released
Julia availability. The overall programme remains at G2 only, with eight
formal gates still open.
