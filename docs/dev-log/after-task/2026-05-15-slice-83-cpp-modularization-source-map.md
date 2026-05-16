# After Task: Slice 83 C++ Modularization Source Map

## Goal

Plan a safe split of the current single TMB template into smaller header-only
units without moving code or changing fitted behavior.

## Implemented

- Added `docs/design/36-cpp-modularization-source-map.md`.
- Named the first safe helper-extraction boundaries:
  `src/drm_numeric.hpp` and `src/drm_count_kernels.hpp`.
- Recorded later candidate boundaries for continuous kernels, random effects,
  structured effects, bivariate Gaussian code, and hidden test probes.
- Documented hidden `model_type` 93 to 99 probe branches and their tests.
- Updated `docs/design/03-likelihoods.md` so the implemented routing table
  names all current hidden probe branches, not only 94 and 99.
- Linked the modularization source map from `vignettes/source-map.Rmd`.
- Marked Slice 83 complete in `ROADMAP.md` and recorded the developer-doc
  change in `NEWS.md`.

## Mathematical Contract

No likelihood, parameter scale, formula grammar, fitted output, or TMB data
contract changed. This slice is a source-map and refactor plan only.

The central invariant for later refactors is:

```text
Move pure helpers first; keep model_type IDs, DATA/PARAMETER declarations,
REPORT/ADREPORT names, and R builders fixed until separate tests protect them.
```

## Files Changed

- `docs/design/36-cpp-modularization-source-map.md`
- `docs/design/03-likelihoods.md`
- `vignettes/source-map.Rmd`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format docs/design/36-cpp-modularization-source-map.md docs/design/03-likelihoods.md vignettes/source-map.Rmd ROADMAP.md NEWS.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "package-skeleton|count-kernels|covariance-block-registry|phylo-utils|biv-gaussian|gaussian-random-intercepts|spatial-gaussian", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered scans for the new design note, hidden branch IDs, proposed
  helper headers, and stale wording that would imply code has already moved.

All tests and checks passed. `pkgdown::check_pkgdown()` found no problems.
`devtools::check()` passed with 0 errors, 0 warnings, and 0 notes in 2m 17.2s.

## Tests Of The Tests

The focused test gate intentionally covered the branches named by the source
map: NB2 count kernels, covariance-block hidden probes, phylogenetic hidden
probes, bivariate Gaussian, ordinary Gaussian random effects, spatial Gaussian
effects, and package skeleton checks.

## Consistency Audit

`docs/design/03-likelihoods.md` now agrees with `src/drmTMB.cpp` that hidden
test-only branches 93, 94, 95, 96, 97, 98, and 99 exist. The source-map article
points contributors to the new modularization plan before moving template code.
ROADMAP and NEWS describe this as developer documentation and a future
header-only split plan, not as an implemented code split.

## What Did Not Go Smoothly

The first rendered/source scan used Markdown backticks inside a double-quoted
shell pattern, which made zsh try to execute `model_type`. The scan was rerun
with safer quoting and no repository files changed.

## Team Learning

- Ada kept Slice 83 as a plan and source-map slice.
- Jason inventoried the current public and hidden TMB branches before proposing
  file boundaries.
- Emmy kept the R-to-TMB ABI, report names, and model-type IDs out of the first
  move.
- Gauss and Noether kept the first candidate move limited to pure helpers.
- Curie selected focused tests that warm the branches named by the source map.
- Grace ran pkgdown and package-check gates.
- Rose caught the hidden-branch documentation drift and the shell-quoting
  mistake.

## Known Limitations

- No C++ files were split in this slice.
- The proposed header names are a plan, not existing source files.
- The first actual helper extraction still needs its own focused commit,
  checks, and after-task report.

## Next Actions

- Continue to Slice 84: Phase 6d gate.
- If there is time after the gate, start the first mechanical helper extraction
  as a separate slice, beginning with numeric and NB2 count helpers only.
