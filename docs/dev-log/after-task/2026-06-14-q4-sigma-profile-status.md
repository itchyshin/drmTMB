# After Task: q4 Sigma Profile Status

## Goal

Extend the native-TMB fallback work for #551 from target visibility to actual
profile interval status for the bivariate q=4 phylogenetic sigma-axis SDs.

## Implemented

The new focused test reuses the small bivariate q=4 phylogenetic
location-scale fixture with matching labelled
`phylo(1 | p | species, tree = tree)` terms in `mu1`, `mu2`, `sigma1`, and
`sigma2`. The fit is intentionally a weak-Hessian case (`pdHess = FALSE`), so
Wald intervals are unsafe.

The test verifies that `confint(method = "profile")` on the two sigma-axis SD
targets returns row-level status rather than a whole-request failure. Successful
rows must have finite positive endpoints that contain the fitted SD estimate;
failed rows must have missing endpoints and a non-`ok` diagnostic message. The
test also keeps the retained-TMB-object guard explicit by checking that a
dropped `fit$obj` still errors before profiling.

## User-Facing Target Selection Note

For a native-TMB ML q=4 bivariate phylogenetic location-scale fit, inspect the
available sigma-axis profile targets before starting a long profile:

```r
targets <- profile_targets(fit)
targets[grepl("sigma[12]:phylo", targets$term), ]
```

The current q=4 joint structured block names the direct sigma-axis SD targets
with the internal `sd:mu:` prefix:

```r
sigma_parms <- c(
  "sd:mu:sigma1:phylo(1 | p | species)",
  "sd:mu:sigma2:phylo(1 | p | species)"
)

confint(fit, parm = sigma_parms, method = "profile")
```

Rows with `conf.status = "profile"` have usable profile endpoints. Rows with
`conf.status = "profile_failed"` should be treated as honest diagnostics, not
as finite intervals. The q=4 phylogenetic correlations remain derived and not
profile-ready in this slice.

## Checks Run

```sh
air format tests/testthat/test-profile-targets.R
Rscript --vanilla -e "devtools::load_all('.', quiet = TRUE); testthat::test_file('tests/testthat/test-profile-targets.R', desc = 'profile intervals report bivariate q4 phylo sigma-axis status')"
Rscript --vanilla -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
git diff --check
```

## Results

- The focused q=4 sigma-axis profile-status test passed with no warnings.
- The full `profile-targets` test file passed.
- `git diff --check` reported no whitespace problems.
- The test records the current local default-profile behavior as row-level
  diagnostics: at least one sigma-axis profile succeeds with finite endpoints;
  any failed row must remain explicit through `conf.status = "profile_failed"`.

## Boundaries

This is not native-TMB REML for the bivariate q=4 model. It does not make q=4
phylogenetic correlations profile-ready, does not validate interval coverage,
does not benchmark the 10k-tip model, and does not claim the across-tree
workflow is unblocked until CI and user-scale timing are checked.
