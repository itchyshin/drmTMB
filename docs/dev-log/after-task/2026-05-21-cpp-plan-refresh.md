# After Task: C++ Modularization Plan Refresh

## Goal

Clarify what happened to the C++ modularization plan after the ordinary Poisson
q=1 phylogenetic `mu` route landed.

## Answer

The C++ split did not happen in the Poisson q=1 slice. The feature was added
inside `src/drmTMB.cpp` on purpose, because it needed to preserve the existing
single-template ABI, report names, profile-target names, `ranef()` labels, and
`check_drm()` diagnostics while opening only one non-Gaussian structured route.

That means the modularization plan remains active, but the source map needed a
refresh. The plan now treats `model_type = 6` separately from the other count
branches and names the Poisson q=1 phylogenetic pieces that should not be moved
casually: `u_phylo`, `log_sd_phylo`, `Q_phylo`, `log_det_Q_phylo`,
`phylo_mu_node_index`, `phylo_mu_value`, `sd_phylo`, `quadratic`, and
`phylo_mu_contribution`.

## User Value

This helps contributors refactor safely without changing fitted behavior. For
applied users, the important outcome is stability: the syntax
`phylo(1 | species, tree = tree)` for ordinary Poisson keeps the same extractor,
profile-target, and diagnostic surface while C++ cleanup remains internal.

## Files Changed

- `docs/design/36-cpp-modularization-source-map.md`
- `vignettes/source-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks

Validation for this docs-only correction:

```sh
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

Both checks passed. The post-merge R-CMD-check for the preceding Poisson q=1 PR
also passed on macOS, Ubuntu, and Windows before this follow-up was committed.

## Standing Review

Ada kept the change scoped to documentation and source-map consistency. Gauss
and Noether checked that the C++ terms match the implemented Poisson q=1
contract. Emmy checked ABI and extractor-label boundaries. Grace owned pkgdown
validation. Rose checked that the plan no longer hides the difference between a
landed feature and an unperformed modularization refactor.
