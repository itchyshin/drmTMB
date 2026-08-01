# After Task: Reader Path, Function Map, and Location-Scale Part 2

## 1. Goal

Repair the public learning path that remained incomplete after the Arc 6
association interval work: restore a concise Function Map, distinguish it from
the full introduction, reunite the two location-scale articles, add a usable
uncertainty and error-recovery workflow to Part 2, and make the pkgdown
navigation tell the same story.

## 2. Implemented

The Function Map is now a short route chooser for users who already have
`drmTMB` installed. The full `drmTMB` introduction owns installation, the model
components, and the guided first fit; it no longer duplicates the changing
capability ledger.

The article index now puts the Function Map and full introduction together
under Getting Started, Part 1 and Part 2 together under Location and Scale,
and the three bivariate routes together under Bivariate Models and
Association. Duplicate model-workflow, adequacy, and convergence entries were
removed from competing top menus. The deferred Julia compatibility page has a
separate category.

Location-scale-scale Part 2 now checks the worked fit before interpretation,
shows `profile_targets()` for the residual- and group-SD slopes, requests named
Wald intervals with `confint()`, preserves method/status columns, and transforms
only successful log-SD endpoints into SD-ratio intervals. It keeps
repeatability point-only and explains why separate component endpoints cannot
be combined into a repeatability interval. Its early error guidance tells the
reader to repair miscoded group-constant predictors or remove a genuinely
within-group predictor rather than average it to silence the error.

## 3a. Decisions and Rejected Alternatives

The repair uses only exported, user-facing functions. Internal validation
runners, private campaign machinery, provenance-smoke scripts, and developer
helpers were rejected from the applied-user path. Public pages may state the
evidence boundary and expose returned interval status, but they do not teach
the machinery used to validate it.

The Function Map was shortened instead of becoming a second reference manual.
Changing capability counts and exact support cells remain owned by the model
and capability guides. The Tutorials dropdown remains broad but coherent; a
larger information-architecture redesign is deferred to a later whole-site
audit.

## 3b. Mathematical Contract

No model or inferential implementation changed. Part 2 keeps three distinct
quantities: expected response `mu`, within-group residual SD `sigma`, and the
SD of the location random effect `sd(individual)`. The latter two use log-SD
links, so exponentiating a coefficient or successful interval endpoints gives
an SD ratio. Repeatability is a nonlinear function of both variance
components; combining their marginal interval endpoints is not a valid joint
interval for repeatability.

## 4. Files Touched

- `_pkgdown.yml`: repaired article categories and removed duplicate top-menu
  destinations.
- `vignettes/function-map-cheatsheet.Rmd`: concise installed-user route chooser.
- `vignettes/drmTMB.Rmd`: distinct guided introduction and current capability
  pointers.
- `vignettes/location-scale.Rmd`: explicit Part 1 to Part 2 handoff.
- `vignettes/location-scale-scale.Rmd`: diagnostics, interval workflow,
  endpoint transformation, repeatability boundary, and actionable recovery.

## 5. Checks Run

- YAML/article inventory: 36 entries, 36 unique targets, zero missing sources,
  zero unindexed vignettes.
- Knitr extraction and R parsing of all four repaired Rmd files: PASS.
- Source rendering of all four repaired Rmd files: PASS.
- Full `pkgdown::build_site(new_process = FALSE)`: PASS.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- Rendered article and internal-link sweeps: PASS, zero missing targets.
- `git diff --check`: PASS.
- Pat final rendered reader-path review: PASS.
- Rose final navigation and consistency audit: PASS.

## 6. Tests of the Tests

Pat's first rendered review found that the initial deterministic Part 2 sample
produced a `fixed_gradient` warning while the prose proceeded to intervals.
That contradicted the article's own diagnostic rule. A direct refit identified
a deterministic seed with the same scientific design and clean diagnostics;
the rebuilt article now prints 14/14 checks OK, zero warnings, zero errors, a
positive-definite Hessian, finite standard errors, and no SD-boundary warning
before interpreting coefficients or intervals.

The rendered interval chunks execute the public API rather than printing
hand-written output: both named targets are profile-ready, both Wald interval
rows retain method/status metadata, and both transformed SD-ratio rows are
computed from complete successful endpoints.

## 7a. Issue Ledger

This is a follow-up within the existing Arc 6 association public-interval
branch. No duplicate GitHub issue was opened and no issue was closed; public
deployment remains a later PR/merge action.

## 8. Consistency Audit

The navigation audit checked `_pkgdown.yml`, all 36 vignette sources, all
rendered article targets, and source/rendered internal links. Exact prose/code
searches covered `tools/`, `private`, `internal`, `provenance`, `campaign`,
`:::`, `.Call(`, `TMB::`, `MakeADFun`, and `run-arc` in the four repaired
sources. The sole `provenance` occurrence is the public prediction table's
returned interval-source/status metadata; no internal validation code or
campaign path appears.

The Function Map and introduction now point to each other without competing.
Part 1 and Part 2 have reciprocal handoffs. Cross-family association remains
grouped with the bivariate model guides, while `rho12` remains a distinct
residual-correlation estimand rather than being relabelled as staged latent
association.

## 9. What Did Not Go Smoothly

The earlier Arc 6 after-task report overstated the completeness of the reader
path: existence and navigation checks did not establish that Function Map and
Part 2 contained the necessary user workflow. The follow-up therefore audited
article substance and rendered examples, not only targets.

The first sandboxed full-site build failed because CRAN metadata DNS and the
normal R cache were unavailable. The identical build passed with explicit
access. Pat then found the deterministic gradient warning described above;
the example was rerun and rebuilt before final review.

A broad `devtools::test()` run was also started, but it was intentionally
stopped after the already-relevant association contexts had continued to pass;
running the entire model-surface suite was disproportionate for a documentation-
only diff. The rendered examples, prior complete association suite at this
branch head, and documentation-specific checks are the acceptance evidence.

## 10. Known Residuals

The Tutorials menu still has many items in one dropdown. It is now free of the
earlier duplicates and category drift, but a shorter or nested whole-site
information architecture needs a separate audit.

The Part 2 intervals shown are component-wise Wald intervals. They are not a
joint interval for repeatability, a coverage claim for every design, or a new
profile/bootstrap implementation. The live website will not change until the
branch is reviewed, merged, and deployed.

## 11. Team Learning

Pat's user review changed the actual example rather than merely polishing
prose: a tutorial must pass the diagnostic gate it teaches. Rose's systems
review converted four symptoms into one coherent navigation repair. Future
feature work should update the implementation, public reference, worked
article, navigation, and rendered site in the same slice while keeping
internal validation machinery out of the applied-user path.

## 12. Cross-Product Coverage

This slice covers the Getting Started route, Function Map, full introduction,
Location-Scale Parts 1 and 2, and their neighboring pkgdown navigation. This
slice does NOT cover a whole-site content audit, a complete redesign of the long Tutorials
menu, new interval estimators, repeatability uncertainty, new association
family pairs, new compute, or live-site deployment.

## 13. Next Actions

1. Commit this focused documentation repair with the existing Arc 6 eta work.
2. Present the complete branch diff for maintainer review before push or PR.
3. Schedule a later whole-site audit for the remaining long menu and article
   sequencing after this focused reader path is landed.
