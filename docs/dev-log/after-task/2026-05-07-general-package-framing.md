# After Task: General Package Framing

## Task Goal

Broaden package-level wording so `drmTMB` is not presented as limited to one
domain. The examples and early tutorials can emphasize ecology, evolution, and
environmental science, but the package identity should remain general, closer
to the scope of packages such as `glmmTMB`.

## Files Created Or Changed

- Updated `README.md` to describe `drmTMB` as a broadly useful distributional
  regression package, with examples motivated by ecology, evolution, and
  environmental science.
- Updated the getting-started vignette title to "Distributional regression with
  drmTMB".
- Broadened tutorial titles:
  - "When variance carries signal";
  - "Changing residual coupling with rho12";
  - "Choosing response families";
  - "Structured dependence: phylogeny and space roadmap".
- Updated `_pkgdown.yml` menu text to match the broader article titles.
- Updated `docs/design/00-vision.md` to state that package-level headings
  should remain general while examples can focus on ecological and evolutionary
  questions.

## Checks Run

- Emmy reviewed the pkgdown/documentation framing and recommended broad
  package-level titles with ecological/evolutionary examples retained.
- `rg` stale-heading scan over README, vignettes, docs, and `_pkgdown.yml`.
- `git diff --check`: passed.
- `Rscript -e "devtools::test()"`: 148 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no problems;
  site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Consistency Audit

- Confirmed no remaining matches for the old narrow package-level headings or
  old domain-limited navigation labels in active package docs.
- Confirmed the package `DESCRIPTION` already used broad wording and did not
  need a change.

## Tests Of The Tests

- This is a documentation-only framing change. The relevant test is the stale
  heading scan plus pkgdown rebuild.
- Full package tests were rerun before committing to guard against accidental
  changes.

## Design-Doc Updates

- `docs/design/00-vision.md` now records the policy: broad package identity,
  domain-focused examples.

## Pkgdown And Documentation Updates

- The pkgdown menu and article titles now align with the broad package framing.
- The ecology/evolution emphasis remains in examples and tutorials rather than
  the top-level package identity.

## Known Limitations And Next Actions

- We should revisit the site structure later with Pat and Emmy once more
  examples exist, because a broader package identity will need examples outside
  ecology/evolution eventually.
