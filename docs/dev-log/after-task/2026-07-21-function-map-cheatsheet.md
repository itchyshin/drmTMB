# After Task: Function map and cheat sheet

## 1. Goal

Add a compact, searchable reader path that helps an applied user find the
smallest useful `drmTMB` workflow and the relevant functions without turning a
visual summary into a capability claim.

## 2. Implemented

- Added `vignettes/function-map-cheatsheet.Rmd`, a six-step function map plus
  a visible quick-reference table, copy-paste first-fit, extraction,
  prediction, bivariate, and structured dependence routes.
- Added accessible figure alt text and a generated static map asset stored next
  to the vignette.
- Added the guide to the `Get Started` navbar, pkgdown article index, README,
  and the canonical reader-learning-path design note.
- Kept `engine = "tmb"` primary and described Julia as optional post-0.6
  maintenance, not a parity or release claim.

## 3a. Decisions and Rejected Alternatives

The first example is a Gaussian location-scale model with `mu ~ x` and
`log(sigma) ~ x`. The prose states that `sigma` coefficients are log residual
SD effects; it distinguishes residual `rho12` from group-level or structured
correlation and sends readers to the capability map for evidence boundaries.
Rejected: a comprehensive capability matrix inside the cheat sheet, an
interactive JavaScript inventory, and any Julia-parity framing. Those would
duplicate or widen the generated ledger rather than orient a new reader.

## 4. Files Touched

- `README.md`
- `_pkgdown.yml`
- `vignettes/function-map-cheatsheet.Rmd`
- `vignettes/function-map-cheatsheet.png`
- `docs/design/226-reader-learning-path.md`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --vanilla -e 'pkgdown::build_article("function-map-cheatsheet", lazy = FALSE); pkgdown::check_pkgdown()'`: PASS.
- The first article render found a missing image caused by an unsupported
  `man/figures` vignette path. Moving the asset into `vignettes/` and rendering
  again: PASS, no missing images.
- Rendered HTML inspection verified the `Get Started` navigation entry, figure
  source, figure alt text, linked reference functions, and the quick-reference
  table directly below the map.
- The bivariate copy-paste route was executed as a real Gaussian pair fit;
  `rho12()` and `corpairs()` returned typed outputs.
- `git diff --check`: PASS.
- `pkgdown::build_site()` reached the home-page build but failed the external
  CRAN-link request because `cloud.r-project.org` DNS was unavailable in this
  environment. This does not invalidate the focused article render or
  `pkgdown::check_pkgdown()` result.

## 6. Tests of the Tests

No runtime behavior or test was added. The executable vignette chunks ran
during the successful article build; the first render's missing-image warning
confirmed that the render check detects the asset-path failure it is meant to
catch. The bivariate snippet was also run outside the vignette to confirm its
declared `y1`/`y2` data construction and extractor calls work together.

## 8. Consistency Audit

Ran:

```sh
rg -n 'function map and cheat sheet|function-map-cheatsheet|Julia.*post-0\\.6|post-0\\.6.*Julia' \
  README.md _pkgdown.yml vignettes docs/design/226-reader-learning-path.md \
  docs/dev-log/known-limitations.md ROADMAP.md NEWS.md
```

The new guide is discoverable from README and the `Get Started` menu. The
reader-path design document now counts 34 vignettes and places the guide in
stage 1. No family, formula-grammar, diagnostic, or capability-status wording
was changed.

## 7a. Issue Ledger

Searched open issues for `pkgdown`, `documentation`, `cheat sheet`, and
`function map`. No dedicated issue exists. No issue action was taken; #61 is
the broad release gate and does not need a progress comment for this local
documentation slice.

## 9. What Did Not Go Smoothly

The source image path first targeted `man/figures`, which pkgdown cannot use
from this vignette. The focused render exposed the problem immediately; the
asset now travels with its source vignette. A complete `pkgdown::build_site()`
could not finish because the sandboxed environment could not resolve the CRAN
hostname while constructing the home-page package link.

## 11. Team Learning

Florence/Pat/Rose perspective: a visual map works as orientation only when the
searchable page carries exact functions, links, and visible inference limits.
The page should not replace the capability ledger or make its six boxes look
like uniform support.

## 10. Known Residuals

- The map is a static PNG; it is not an interactive API inventory.
- The full-site home-page build still needs a network-enabled rerun after this
  documentation slice is integrated.
- The planned comprehensive Rd reader audit remains a separate pre-CRAN
  content task.

## 12. Cross-Product Coverage

The reusable pattern is a visual-plus-searchable reader surface: one compact
diagram for orientation, paired with exact functions, runnable syntax, and
links to the authoritative capability boundary. It can be reused in sibling
method packages without borrowing drmTMB's claims or terminology. It does NOT cover REML, penalty, missing-data, aggregation, new engine support, Julia
parity, formula-grammar expansion, or any provider-specific inference claim.

## Next Actions

1. Review this focused documentation branch and, if accepted, merge it before
   the final page-by-page content sweep.
2. Re-run `pkgdown::build_site()` with CRAN hostname access, then inspect the
   deployed page through the normal docs path.
3. Resolve the separate Gamma wording blocker before the platform matrix.
