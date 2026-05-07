# After Task: Location-Coscale Phylogenetic Sources

## Purpose

Record the importance of the location-coscale and phylogenetic location-scale
papers for the package identity.

## Sources Checked

Local PDFs:

```text
/Users/z3437171/Downloads/Bivariate_location_coscale.pdf
/Users/z3437171/Downloads/Mammalian_location_co_scale_trade_offs_protocol.pdf
dis_reg_models/Methods Ecol Evol - 2025 - Nakagawa - Quantifying macro-evolutionary patterns of trait mean and variance with phylogenetic.pdf
```

## Design Interpretation

The MEE phylogenetic location-scale paper is the foundation: it treats trait
means and residual variation as linked macro-evolutionary quantities. The
location-coscale note extends that idea by also making residual correlation a
modelled parameter. The mammalian body mass-litter size protocol gives the
flagship biological use case: partition trait association into phylogenetic and
non-phylogenetic components, then ask whether lifestyle changes means,
dispersion, and trait coupling.

## Changes Created

- Added `docs/design/15-location-coscale-phylogenetic-extension.md`.
- Updated `docs/design/00-vision.md` to emphasize `rho12 ~ predictors` as the
  core package contribution.
- Updated `docs/design/06-distribution-roadmap.md` to keep bivariate coscale
  ahead of expanding the family list.
- Updated `docs/design/09-phylogenetic-and-spatial-speed.md` with the MEE PLSM
  to coscale extension path.
- Updated `docs/design/11-reference-programme.md` with location-coscale and
  mammalian protocol implications.
- Updated the bivariate and phylogenetic-spatial vignettes with biological
  examples and the distinction between residual `rho12` and group-level
  phylogenetic correlations.
- Added local-source bibliography entries for the location-coscale note and
  mammalian protocol.

## Checks Run

Commands run:

- `pdfinfo` on the three source PDFs.
- `pdftotext` plus `rg` source searches for coscale, residual correlation,
  phylogenetic correlation, lifestyle, body mass, litter size, and PLSM
  extension terms.
- `rg` consistency search over README, vignettes, docs, ROADMAP, and
  `REFERENCES.bib`.
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- Source searches confirmed the package interpretation:
  - MEE PLSM is the foundation for modelling means and variances together;
  - location-coscale extends this by modelling residual correlation;
  - the mammal protocol provides the body mass-litter size lifestyle example.
- Consistency search showed the intended docs and vignettes mention residual
  `rho12`, location-coscale, body mass-litter size, and phylogenetic
  correlation distinctions.
- `git diff --check`: no whitespace errors.
- `devtools::test()`: 148 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `air format .`: not available locally.
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

## Follow-Up

- Future implementation should keep the staged path conservative: fixed-effect
  `rho12` first, then phylogenetic mean structure, then scale structure, and
  only later phylogenetic effects in `atanh(rho12)`.
