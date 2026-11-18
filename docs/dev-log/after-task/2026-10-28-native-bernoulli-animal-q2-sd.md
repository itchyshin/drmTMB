# After Task: Native Bernoulli animal q2 SD regression

## 1. Goal

Extend native R/TMB Bernoulli animal q2 SD regression from logit to probit and cloglog, retaining separate predictor-dependent SDs for the intercept and one numeric slope.

## 2. Implemented

The Binomial builder admits an unlabelled animal q2 block with matching coefficient-selected `sd_animal()` formulas for supplied `A`, `Ainv`, or pedigree inputs under logit, probit, and cloglog links. The shared q2 simulation helper reads both animal and related-matrix SD targets. The older related-matrix test checks that this animal route is admitted.

## 3a. Decisions and Rejected Alternatives

For each coefficient field `j`, the model uses `u_j ~ N(0, A)`, independently across the intercept and slope, and `b_j = D_j u_j`, where `log(sd_jg) = W_jg alpha_j`. Thus `Cov(b_j) = D_j A D_j`. The supplied covariance keeps its raw scale: when `A_gg != 1`, the marginal SD is `sd_jg * sqrt(A_gg)`. The formula-level SD remains a multiplier of the supplied kernel.

## 4. Files Touched

- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-binomial-animal-q2-sd.R`
- `R/random-effect-scale-formulas.R`
- `man/random_effect_scale_formulas.Rd`
- `docs/design/18-random-effect-scale-models.md`
- `man/simulate.drmTMB.Rd` (regenerated from the current Julia simulation documentation source already present in this worktree)
- `tests/testthat/test-binomial-relmat-q2-sd.R`
- This report and `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- Animal q2 focused recovery and workflow test: 27 expectations passed. It checks both SD trends, coefficient-to-node prediction mapping, deterministic marginal simulation, save/reload, profile target identity, and two bootstrap refits.
- Animal q2 assembly checks: 12 expectations passed; one recovery test was deliberately skipped in assembly-only mode. The checks cover `A`, `Ainv`, pedigree, and rejection of one-target and probit q2 forms.
- New assembly checks admit probit and cloglog animal q2 SD forms. The focused file then completed its logit workflow plus probit and cloglog synthetic recovery, gradient, prediction, and simulation checks without reported failures.
- `devtools::document()` regenerated the formula reference. `pkgdown::check_pkgdown()` passed; it emitted the existing Pandoc `--mathml` deprecation warnings.
- Existing Binomial relmat q2 suite: 98 expectations passed.
- Existing Binomial animal q1 slope suite: 32 expectations passed.
- The after-task structure check passed. The acceptance ledger checker reports `UNKNOWN` because its runner is missing; no programme gate is claimed.
- Full package tests, `R CMD check`, pkgdown rendering, Julia parity, and interval-coverage calibration were not run.
- `git diff --check` reports one unrelated existing blank line at end of `tests/testthat/test-binomial-sd-integration.R:225`; that file was left unchanged.

## 6. Tests of the Tests

Before the link-gate change, the assembly test failed because the Binomial animal validator refused q2 outside the logit route. After the change, probit and cloglog assembly and recovery checks completed. A negative assertion still confirms that one SD target does not satisfy the two-coefficient route. The non-unit diagonal covariance fixture checks recovery under raw `A` scaling.

## 8. Consistency Audit

The R syntax names both coefficient-specific SD targets. The builder maps them to the two independent q2 latent fields, and marginal simulation orders each fitted SD column by the animal node labels. The C++ likelihood already supported these fields for all three links, so no C++ change was needed. The formula reference and random-effect-scale design guide now state the q2 boundary and link support. README, NEWS, and the formula-grammar status inventory still need review for stale or incomplete wording.

The check-log preflight found 451 divergent refs. The documentation-audit lane has been asked to record this slice there; the SD lane left that shared file unchanged.

The inventory search used:

```sh
rg -n -i 'Binomial.*(animal|q2|slope)|animal.*(Binomial|Bernoulli|q2)|Bernoulli.*animal' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml
```

## 7a. Issue Ledger

The open-issue search returned only unrelated test-sweep tracker #1464. No issue was changed or opened.

## 9. What Did Not Go Smoothly

The first direct `test_file()` invocation did not load package functions. Loading the package with `devtools::load_all()` fixed that. The first full relmat run then exposed an outdated assertion that expected animal q2 to be rejected; the assertion now verifies the new admission.

## 11. Team Learning

Animal q2 uses the common structured q2 machinery once the R admission and target resolver route it to the right provider. Marginal simulation must recognize the provider-specific `sd_animal()` name while keeping coefficient and node labels aligned.

## 10. Known Residuals

This is native TMB Binomial q2 animal support for logit, probit, and cloglog. It covers one unlabelled intercept-plus-one-slope block with separate group-level SD predictors, complete unweighted 0/1 responses, and no additional random effects. The two coefficient fields are independent. It does not establish Julia parity, interval coverage, correlated coefficient fields, labelled blocks, or broader prediction semantics beyond the tested outputs.

## 12. Cross-Product Coverage

This slice covers native TMB Binomial `mu` with one unlabelled animal intercept-plus-slope block, separate group-level SD predictors, and `A`, `Ainv`, or pedigree input under logit, probit, and cloglog. It does NOT cover Julia parity, interval coverage, labelled blocks, other providers, or additional random effects. Continue with the next unresolved Bernoulli structured or block row after path preflight.
