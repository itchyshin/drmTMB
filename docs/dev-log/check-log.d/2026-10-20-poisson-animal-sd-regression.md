# Native Poisson animal-model SD regression

The non-inflated Poisson builder now accepts one complete-data q1
`animal(1 | id, A = A)` location intercept with
`sd(id, level = "animal") ~ z`. This reuses the existing known-relatedness
structured covariance path and preserves the supplied matrix scale.

The test-first run failed at the expected Poisson unsupported-parameter check.
With the target admitted, it reached the fitted model and showed that an
initial 64-group fixture was too noisy for a useful point-recovery check. The
final 192-group, 24-observation-per-group fixture uses a log-SD slope of 0.35
and passed the fixed-seed recovery tolerance. After independent review showed
that reversal left the stationary covariance numerically unchanged, the test
and example switched to a non-invariant interleaved matrix order. The test
covers covariance-dimname alignment, group-SD predictions, marginal simulation, save/reload prediction,
and equivalence to the constant-SD fit. The focused test passed 11 assertions.

The combined focused run
`devtools::test(filter = "poisson-animal-sd-regression|binomial-animal-sd-regression|poisson-relmat-sd-regression|sd-level-grammar")`
passed 74 assertions, with one existing warning from the legacy `sd_phylo()`
deprecation-throttle test and no failures or skips. The live Julia engine did
not run. `devtools::document()`, a current-source render of
`vignettes/predictor-dependent-random-sd.Rmd`, and
`pkgdown::check_pkgdown()` passed. The full `pkgdown::build_site()` did not
finish because it attempted to fetch CRAN metadata from `cloud.r-project.org`,
which did not resolve in this restricted network. It also reported that the
user-level Sass cache was not writable; no files outside the worktree were
changed.

The exact inventory scan used was:

```sh
rg -n 'animal.*(direct-SD|SD regression|scale formula|random-effect SD)|direct-SD.*animal|animal.*predictor-dependent SD|animal model.*SD' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The design note, formula reference, package help, NEWS, known-limitations
ledger, inventory, roadmap, tutorial, active gate evidence, check log, and
recovery checkpoint now describe this exact cell. No navigation or README
change was indicated by the inventory scan. The prior read-only issue search
for animal-model SD support found no matching open issue; no issue was changed.

This is one native Poisson q1 supplied-`A` point-recovery cell. It does not
establish animal pedigree or `Ainv` inputs, other animal effect shapes, Julia
parity, interval calibration, or broader Poisson structured-effect support.
