# After Task: Bernoulli ordinary and phylogenetic SD regression

## 1. Goal

Allow a binomial location model to combine an ordinary random intercept with
one phylogenetic random intercept, including predictor-dependent SD formulas
for either or both effects.

## 2. Implemented

The binomial builder now permits the independent ordinary and phylogenetic
intercept contributions together. Their default constant-SD route remains
available, and either effect can use the existing SD-formula target. The
slice changes no other structured provider. The new seeded test recovers two
positive SD slopes for ordinary groups nested within tree tips, checks separate
predictions and binary response simulation, round-trips the fitted object, and
compares constant-SD formulas with the base model.

## 3a. Decisions and Rejected Alternatives

The fitted linear predictor is `eta_ig = X_ig beta + b_g + a_s`, where the two
latent effects are independent, `b_g ~ Normal(0, tau_g^2)`, and
`a ~ Normal(0, D K D)`. The SD formulas use `log(tau_g) = W_g alpha` and
`log(D_ss) = Z_s gamma`. The phylogenetic SD remains a multiplier of the
existing kernel, so its marginal variance includes `K_ss`.

The ordinary-plus-phylogenetic combination is admitted for constant as well
as predictor-dependent SDs because the TMB likelihood already adds these
independent contributions. I rejected an SD-formula-only admission because it
would force users to specify unnecessary regression formulas to fit a valid
constant-SD model. The relmat route remains governed by its separate builder
and was not broadened in this slice.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-binomial-ordinary-phylo-sd.R`
- `docs/design/18-random-effect-scale-models.md`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/known-limitations.md`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-10-20-bernoulli-ordinary-phylo-sd.md`

## 5. Checks Run

- Before the builder change, the new fit test failed at the intended guard:
  binomial phylogenetic effects could not be combined with ordinary random
  effects.
- The final joint test passed: 18 assertions, 0 failures, 0 warnings, 0 skips.
- The broader command
  `devtools::test(filter = "binomial-(sd-integration|sd-profile|sd-simulation|correlated-sd|ordinary-phylo-sd|phylo-sd-regression)")`
  passed 513 assertions in 454.9 seconds. It selected the beta-binomial
  integration file as well because the filename contains `binomial`.
- The updated vignette rendered with the current worktree loaded. Its first
  standalone render used the installed package and failed on the old installed
  binomial SD guard; the corrected render passed with `devtools::load_all()`.
- `pkgdown::check_pkgdown()` reported no problems and printed MathML-option
  deprecation warnings.

## 6. Tests of the Tests

The new fit test was run before changing the guard and failed at the exact
restriction under test. The final DGP has separate ordinary groups nested
within phylogenetic tips, making the two covariance sources distinguishable in
the test fixture. Both SD-slope recovery assertions passed. The test also has
the already-supported neighbouring-feature combination and checks separate
target outputs, constant-SD equivalence, prediction, simulation, and reload.

## 7a. Issue Ledger

Read-only searches for `Bernoulli phylogenetic random effect SD ordinary
intercept` and `random-effect SD regression Bernoulli` returned no open issue
match. No issue was opened, commented on, or closed.

## 8. Consistency Audit

The symbolic equations, R formula, native assembly, and TMB additive
contributions agree. The model note, vignette, NEWS, capability inventory, and
known-limitations text now describe the same native boundary. The full required
capability ledger remains unchanged. The status checks searched:

```sh
rg -n "binomial.*phylo|Bernoulli.*phylo|phylo.*binomial|Bernoulli.*ordinary|ordinary.*phylogenetic" NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md README.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
rg -n "A binomial.*must be fitted without ordinary random effects|requires a phylogenetic-only random-effect model|structured binomial SD-regression route currently covers this phylogenetic intercept|R bridge does not yet expose phylogenetic SD" R/drmTMB.R docs/design/18-random-effect-scale-models.md vignettes/predictor-dependent-random-sd.Rmd docs/dev-log/general-sd-regression/inventory.md docs/dev-log/known-limitations.md NEWS.md
```

The first scan found neighboring formula-grammar entries about other response
families and `phylo_interaction()`, not contradictory claims about this new
combination. The second scan found the generic fallback for structured terms
that do not opt into ordinary-effect support; it no longer names the supported
phylogenetic route. The whole package check was not run because the worktree
contains broad unrelated candidate changes; focused Bernoulli filters covered
the changed route and neighbors.

## 9. What Did Not Go Smoothly

The first targeted test invocation treated a test description as a filename
filter and selected no files; the corrected filename filter exercised the
intended failing test. The first vignette render loaded the installed package
instead of this worktree, so I reran it after `devtools::load_all()`.

## 10. Known Residuals

This is one native point-recovery cell. It does not qualify interval coverage,
general SD-slope identifiability, Julia fitting or joint-provider parity,
animal/relmat/spatial providers, phylogenetic slopes, or bivariate models. The
global required-capability ledger and G0-G8 gates remain open. No remote
compute campaign was launched.

## 11. Team Learning

The initial same-tip simulation gave unstable separation of ordinary and
phylogenetic SD slopes. Nesting multiple ordinary groups within each tip
provided distinct covariance information and recovered both slopes in the
seeded test. Other group structures may behave differently.

## 12. Cross-Product Coverage

| Product cell | Current evidence | Remaining work |
|---|---|---|
| Native TMB, Bernoulli ordinary plus phylogenetic intercept | Joint nested-group DGP, slope recovery, predictions, simulation, save/reload, and constant-SD equivalence | Independent likelihood/covariance oracle and calibrated profile/bootstrap uncertainty |
| Julia engine, same joint effects | No joint fit or live bridge check | Pair this synthetic design with the Julia engine and test outputs and refits |
| Other families, providers, and effect types | Tracked in the unchanged 19,118-row capability ledger | Continue row-by-row implementation, validation, and documented structural exclusions where mathematically justified |

This slice covers native TMB fitting, coefficient extraction, SD prediction,
binary response simulation, and stored-fit reload for ordinary plus
phylogenetic Bernoulli intercepts. It does NOT cover Julia joint fitting,
profile/bootstrap routing or calibration for the joint model, REML, penalized
fits, missing-data routes, aggregation, animal/relmat/spatial providers,
phylogenetic slopes, or bivariate models.

The next concrete step is an independent likelihood/covariance oracle for the
joint Bernoulli model. Then test the same design in Julia and assess profile
and bootstrap coverage on Totoro before any broader campaign.
