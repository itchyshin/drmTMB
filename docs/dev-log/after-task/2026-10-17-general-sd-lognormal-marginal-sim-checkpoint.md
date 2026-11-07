# General SD regression: lognormal ordinary-intercept checkpoint

## Task goal

Verify that an ordinary random intercept with predictor-dependent SD can be fitted and used in marginal simulation for a non-Bernoulli family. This is a native R/TMB implementation checkpoint within the broader SD-regression programme.

## Files created or changed

The implementation and focused tests are in `R/methods.R`, `tests/testthat/test-binomial-sd-simulation.R`, and the new lognormal assembly, reference, and integration tests. `NEWS.md` and generated help were refreshed. Compiled Totoro receipts are under `docs/dev-log/general-sd-regression/evidence/lognormal-20261017/`.

## Checks and exact outcomes

- Fresh package build and installation on Totoro succeeded; source SHA-256 is `bad56b4bf70e56972bc1fde2a10a578690789ccca6159e131e09e54176870ffa`.
- Compiled lognormal integration tests passed: 24 expectations, zero failures or errors.
- Existing Bernoulli simulation regression passed: 15 expectations, zero failures or errors.
- `tools::checkRd("man/simulate.drmTMB.Rd")` and `pkgdown::check_pkgdown()` passed; pkgdown reported no problems.
- Lognormal tests cover coefficient recovery, an independent marginal-likelihood oracle, a wrong-group-design negative control, group-specific SD prediction, profile intervals, save/reload, marginal simulation, fresh-effect variance scaling, bootstrap refits, and constant-SD reduction.
- `git diff --check` passed after the Totoro receipts were collected.

Exact run logs, installation output, and source hash are retained in the evidence directory above. The earlier smaller recovery fixture failure is preserved beside the corrected run.

## Consistency audit

The simulator applies the fitted ordinary location SD by group on the link scale. Structured scale effects, multi-coefficient covariance blocks, and correlation-pair routes remain guarded. The Bernoulli wording in the legacy test name is historical; that regression test now checks that a supported ordinary Gaussian scale route is not mistakenly rejected.

## Tests of the tests

The lognormal integration test uses a separate scalar marginal-likelihood calculation and a deliberately wrong group-to-SD design as a negative control. A deterministic fresh-effect simulation checks the predicted variance ratio. The original failed recovery fixture remains retained; the fixture was enlarged from 60 to 180 groups after the oracle showed that the initial failure was low information rather than a likelihood mismatch.

## What did not go smoothly

The first compiled lognormal run exposed a fixture target-label mismatch, an incorrect accessor in the test, and the old family-specific marginal-simulation guard. These were corrected before rebuilding and rerunning. Running roxygen regenerated unrelated help files; a guarded attempt to restore that generated noise was rejected, so those generated files remain for review.

## Team learning and process improvements

For SD regression, test target labels and the accessor against a fitted constant-SD object before interpreting a coefficient-recovery failure. For marginal simulation, verify the group-specific variance ratio directly, in addition to checking the code path.

## Design-document updates

The mathematical contract remains log SD linear in fixed predictors, with Bernoulli SD on the link scale and no free Bernoulli residual scale. This checkpoint changes the ordinary location marginal-simulation support boundary; it does not ratify the full family, effect, provider, or backend universe.

## Documentation and pkgdown

The `simulate.drmTMB` help and NEWS now describe group-specific ordinary location SDs in marginal draws and the remaining structured-scale limitation. No navigation change was needed. The generated reference page passed Rd checking and `pkgdown::check_pkgdown()` reported no problems.

## GitHub issue maintenance

No direct open issue matched predictor-dependent random-effect SD regression in the repository issue search. The nearby search results concerned other simulation and family work, so the tracker was left unchanged.

## Limitations and next actions

This is evidence for native ordinary-intercept lognormal and existing Bernoulli simulation paths only. It provides no Bernoulli coverage qualification, Julia parity, structured-effect support, or broad family claim. Continue with the Bernoulli uncertainty gate after the independent stage-two adapter review passes; then advance the family map one supported row at a time.
