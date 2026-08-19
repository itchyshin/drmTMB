# Rights and consent receipt — candidate `6b45164b…`

Date: 2026-08-18

This receipt applies the existing Gate 1 component audit to the exact 945-entry
tarball and records the two source changes that close the prior image-provenance
findings.

## Package authorship and consent

`DESCRIPTION` names Shinichi Nakagawa as the sole author, maintainer, and
copyright holder. No additional author consent is required for self-authored
package material.

## Adapted code

`inst/COPYRIGHTS` identifies the exact gllvmTMB source commits, licence, files,
transformations, and excluded upstream behaviour for the mesh/SPDE helpers,
normalized GMRF density, and binomial link/log-pnorm adaptations. The 2026-08-15
Gate 1 audit independently verified those source commits and concluded that the
GPL-3 material is compatible with drmTMB's `GPL (>= 3)` licence. The current
candidate does not add or alter adapted code.

## Artwork

The tarball contains the four package-logo PNG/SVG assets under `man/figures/`.
`inst/COPYRIGHTS` now identifies their first and later commits, Shinichi
Nakagawa as author/copyright holder, the absence of embedded third-party images
or fonts, and distribution under the package licence.

The unverified `vignettes/function-map-cheatsheet.png` found by the prior audit
is absent from the source tree and tarball. Its pkgdown-only article is retained
as text and contains no corresponding generated image.

## Other package components

The exact inventory contains no bundled executable, downloaded installation
asset, font file, or unexplained data archive. Julia capability tables are
self-generated package metadata. TMB/RcppEigen are linked dependencies rather
than copied source components.

## Verdict

Rights ownership, consent, licence compatibility, and installed-image
provenance are clear for this candidate. This is release evidence, not legal
advice, and it does not authorize submission.

