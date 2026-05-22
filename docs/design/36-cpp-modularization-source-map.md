# C++ Modularization Source Map

## Purpose

Slice 83 records how to split the current single TMB template into smaller
header-only units without changing fitted behavior. The next C++ refactor
should be a sequence of mechanical moves with comparator tests, not a redesign
of the likelihood, formula grammar, or random-effect contract.

`src/drmTMB.cpp` remains the compiled TMB entry point. Any modularization should
include headers from `src/` and keep the package as one TMB template unless a
separate design decision approves multiple templates.

The ordinary Poisson q=1 phylogenetic `mu` intercept added after this source map
was written did not execute the C++ split. It deliberately updated
`src/drmTMB.cpp` in place so the first non-Gaussian structured route could keep
the existing R-to-TMB ABI, report names, profile-target labels, and extractor
contracts stable. The modularization plan therefore remains open, but its count
and structured-effect rows now need to account for that fitted path.

The first modularization slice has now moved only branch-free helper code:
stable scalar transforms live in `src/drm_numeric.h`, and NB2 count-kernel
helpers live in `src/drm_count_kernels.h`. The compiled package still has one
TMB entry point, and branch bodies, reports, `ADREPORT()` names, `DATA_*` and
`PARAMETER_*` declarations, R builders, and public syntax remain in their
previous homes.

## Current Template Shape

The current template has four kinds of code interleaved in one file:

| Current code region | Main responsibility | Proposed first home | Primary gates |
| --- | --- | --- | --- |
| Stable scalar helpers | `drm_log1p_pos()`, `drm_log1mexp()`, inverse-logit log helpers, and NB2 count-kernel helpers | `src/drm_numeric.h` and `src/drm_count_kernels.h` | `test-count-kernels.R`, count-family tests, family-link tests |
| TMB data and parameter declarations | The R-to-TMB ABI for all model families, random effects, known covariance, aggregation, hidden probes, and reports | Keep in `src/drmTMB.cpp` | `test-package-skeleton.R`, full `devtools::test()` |
| Structured-effect branch glue | Family-specific `eta` updates, precision-prior attachment, random-effect reports, and direct SD `ADREPORT()` targets for phylogenetic, spatial, animal, `relmat()`, and the first Poisson q=1 phylogenetic route | Keep branch glue in `src/drmTMB.cpp`; later only pure prior helpers may move to `src/drm_structured_effects.h` | `test-phylo-gaussian.R`, `test-spatial-gaussian.R`, `test-animal-relmat-gaussian.R`, `test-poisson-mean.R`, `test-profile-targets.R`, `test-check-drm.R` |
| Hidden probe branches | `model_type` 93 to 99 branches for isolated phylogenetic and covariance-block algebra checks | Later `src/drm_test_probes.h` after branch inventory is complete | `test-phylo-utils.R`, `test-covariance-block-registry.R` |
| Public likelihood branches | `model_type` 1 to 14 branches for fitted families | Later family headers after pure kernels are extracted | family tests, comparator tests, profile and summary tests |

The immediate refactor should move only pure helpers: functions whose return
values depend only on their arguments and do not call `REPORT()`, `ADREPORT()`,
or mutate shared branch state.

## Proposed Header Boundaries

Use header-only C++ files included by `src/drmTMB.cpp`:

```text
src/drm_numeric.h
src/drm_count_kernels.h
src/drm_continuous_kernels.h
src/drm_random_effects.h
src/drm_structured_effects.h
src/drm_bivariate_gaussian.h
src/drm_test_probes.h
```

The first extraction now owns:

```text
src/drm_numeric.h
  drm_log1p_pos()
  drm_log1p_exp_stable()
  drm_log1mexp()
  drm_log_inv_logit()
  drm_log1m_inv_logit()
  drm_log_inv_logit_diff()

src/drm_count_kernels.h
  drm_nbinom2_log_count_product()
  drm_nbinom2_log_density()
  drm_nbinom2_log_p0()
```

That extraction changed no branch body except replacing local helper
definitions with `#include` directives.

Later extractions can move pure density kernels before moving whole branches.
For example, `drm_continuous_kernels.h` can own row log-density helpers for
Student-t, lognormal, Gamma, beta, beta-binomial, cumulative-logit, and
Poisson pieces. The branch-specific `REPORT()` and `ADREPORT()` calls should
stay in `src/drmTMB.cpp` until there is a small report object or naming
contract that tests can inspect directly.

`src/drm_structured_effects.h` is a later candidate for pure precision-prior
helpers shared by Gaussian phylogenetic, coordinate-spatial, animal,
`relmat()`, hidden-probe, and ordinary Poisson q=1 phylogenetic routes. It
should not own branch-specific linear-predictor updates, `DATA_*` or
`PARAMETER_*` declarations, `REPORT()`/`ADREPORT()` calls, extractor labels, or
the decision about which families may accept a structured term. Those stay in
`src/drmTMB.cpp` and the R builders until the report and ABI contract is
explicitly designed.

## Hidden Branch Inventory

Hidden branches are test fixtures, not public families. They should move only
after their purpose is explicit in `docs/design/03-likelihoods.md`.

| TMB branch | Purpose | Tests |
| --- | --- | --- |
| `model_type = 93` | q=4 phylogenetic precision-prior parity with `theta_phylo` and `log_sd_phylo` | `tests/testthat/test-phylo-utils.R` |
| `model_type = 94` | q=4 phylogenetic precision-prior parity with a supplied covariance matrix | `tests/testthat/test-phylo-utils.R` |
| `model_type = 95` | q=4 bivariate Gaussian likelihood probe for labelled covariance-block contributions | `tests/testthat/test-covariance-block-registry.R` |
| `model_type = 96` | univariate Gaussian likelihood probe for labelled covariance-block contributions | `tests/testthat/test-covariance-block-registry.R` |
| `model_type = 97` | contribution-map probe for labelled covariance-block blocks and members | `tests/testthat/test-covariance-block-registry.R` |
| `model_type = 98` | non-centred unstructured-correlation transform probe | `tests/testthat/test-covariance-block-registry.R` |
| `model_type = 99` | q=1 sparse phylogenetic precision-prior parity branch | `tests/testthat/test-phylo-utils.R` |

When these branches move, keep their numeric branch IDs unchanged and keep them
unreachable from public `drmTMB()` builders.

## Public Branch Inventory

Public fitted branches should move only after pure helper extraction is green:

| TMB branch | Candidate header | Must-pass focused tests before broader checks |
| --- | --- | --- |
| `model_type = 1` Gaussian | `src/drm_gaussian.h` only after random-effect helpers are stable | `test-gaussian-location-scale.R`, `test-gaussian-random-intercepts.R`, `test-gaussian-random-effect-scale.R`, `test-meta-known-v.R`, `test-phylo-gaussian.R`, `test-spatial-gaussian.R`, `test-gaussian-aggregation.R` |
| `model_type = 2` bivariate Gaussian | `src/drm_bivariate_gaussian.h` | `test-biv-gaussian.R`, `test-corpairs.R`, `test-profile-targets.R`, `test-summary.R` |
| `model_type = 3`, `4`, `5`, `10`, `13`, `14` continuous/proportion/ordinal families | `src/drm_continuous_kernels.h` first, branch movement later | corresponding family tests plus `test-family-link-contract.R` |
| `model_type = 6` ordinary Poisson | `src/drm_count_kernels.h` first for pure count pieces; branch movement later | `test-poisson-mean.R`, `test-nongaussian-structured-boundary.R`, `test-profile-targets.R`, `test-check-drm.R`, `test-count-kernels.R` |
| `model_type = 7`, `8`, `9`, `11`, `12` remaining count families | `src/drm_count_kernels.h` first, branch movement later | `test-count-kernels.R`, count-family tests, `test-comparators.R` |

The `model_type = 6` branch now includes fixed-effect Poisson, ordinary
non-zero-inflated `mu` random effects, and the first ordinary Poisson q=1
phylogenetic `mu` intercept. That does not make `src/drm_count_kernels.h` the
home for structured random-effect logic. Count-kernel extraction can still move
pure log-density helpers, but the Poisson phylogenetic linear-predictor
contribution, sparse precision-prior attachment, and direct `log_sd_phylo`
reporting should remain with the branch until a structured-effect helper
contract exists.

## What Should Not Move Yet

Do not move these pieces in the first modularization pass:

- the `DATA_*` and `PARAMETER_*` declarations, because they are the current
  R-to-TMB ABI;
- `REPORT()` and `ADREPORT()` calls, because R methods and tests depend on
  their exact names;
- `model_type` numeric assignments;
- R builders, formula parsing, family registration, or marker syntax;
- profile-target, `summary()`, `corpairs()`, `ranef()`, or `check_drm()`
  extraction logic;
- phylogenetic and spatial output labels, especially the current internal reuse
  of `u_phylo` for the first coordinate-spatial `mu` effect;
- Poisson q=1 phylogenetic ABI pieces, including `u_phylo`, `log_sd_phylo`,
  `Q_phylo`, `log_det_Q_phylo`, `phylo_mu_node_index`, `phylo_mu_value`,
  `sd_phylo`, `quadratic`, and `phylo_mu_contribution`;
- hidden probe behavior, until the hidden-branch inventory in this note and
  `docs/design/03-likelihoods.md` stays synchronized.

## Refactor Sequence

1. Move stable numeric and NB2 count helpers to headers. No branch bodies move.
2. Move pure row-density kernels for count and continuous fixed-effect
   families. Branches still own vector construction, weights, reports, and
   `ADREPORT()` calls.
3. Add tiny internal helper tests only when a helper has a non-obvious
   numerical boundary. Prefer objective-level tests when possible.
4. Move hidden probe branches into `src/drm_test_probes.h` only after their
   reports and branch IDs are checked by source-map tests or focused `rg`
   scans.
5. Consider moving public branch bodies only after report ownership is designed
   explicitly.

## Review And Test Gates

Every modularization pull request should record:

```sh
Rscript -e 'devtools::test(filter = "<touched family or branch>", reporter = "summary")'
Rscript -e 'devtools::test(reporter = "summary")'
Rscript -e 'pkgdown::check_pkgdown()'
Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'
git diff --check
```

If public docs or vignettes change, run `pkgdown::build_site()` before
`pkgdown::check_pkgdown()`. If roxygen changes, run `devtools::document()`.

## Team Ownership

- Ada keeps each modularization pull request narrow and rejects behavior
  changes hiding inside file moves.
- Gauss reviews numerical helpers, especially branch-free TMB code and
  near-boundary transforms.
- Noether checks that equations, helper names, and TMB parameterization still
  match the design docs.
- Curie owns objective-level and comparator tests for moved kernels.
- Emmy reviews header boundaries and R-to-TMB ABI stability.
- Grace runs package, pkgdown, and platform-risk checks.
- Rose checks source-map drift after each move.
