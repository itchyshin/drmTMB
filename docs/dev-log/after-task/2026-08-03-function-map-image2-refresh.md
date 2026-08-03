# After task: function-map Image 2.0 refresh

## 1. Goal

Repair the public function-map page so its visual hierarchy matches the actual
`drmTMB` workflow and gives an applied reader a correct next step. Use Image
2.0 for the visual design and require rendered-page review from Florence, Pat,
and Rose.

## 2. Implemented

Replaced the old circular six-step PNG with a task map whose primary route is
Specify model → Fit → Check fit health. Interpretation, prediction/assessment,
and uncertainty/simulation are unnumbered conditional branches. Structured
effects now live inside model specification rather than appearing after
inference.

The page now introduces the visual as navigation rather than capability proof,
centres it at a readable desktop width, links directly to the full-size image
on small screens, and keeps the exact route table searchable. The route table
is horizontally scrollable and keyboard-focusable on narrow viewports.

The site navbar now restores a two-item **Get started** menu, following the
gllvmTMB reader pattern: **Get started with drmTMB** opens the guided first-fit
tutorial, while **Function map and cheat sheet** opens the task lookup page.
The articles index uses the same introductory-guide-first order.

The introductory guide now uses the same family-specific definition of
location as the function map. The route table describes `check_drm()` as a
numerical-health check rather than a decision that inference is valid, and it
names the frozen-margin association route as latent-normal association for an
admitted paired-outcome class.

## 3a. Decisions and Rejected Alternatives

The graphic shows only functions that can sensibly begin from an ordinary
`drmTMB` fit. `rho12()` replaces `association()` because `association()`
requires a `drm_pair_association` object created by `biv_associate()`; that
advanced route remains in the table. `profile_targets()` moved from fit health
to uncertainty because it inventories target availability rather than
diagnosing a fit.

The map labels `bf()` as the formula route, `gaussian()` and `nbinom2()` as
family examples, and `phylo()`/`spatial()`/`relmat()` as structured terms whose
support varies. Rejected: sequential numbering of the three post-check
branches, a circular workflow, a generic `family()` call, and an engine/Julia
footnote inside the graphic.

## 4. Files Touched

- `vignettes/function-map-cheatsheet.Rmd`
- `vignettes/function-map-cheatsheet.png`
- `vignettes/drmTMB.Rmd`
- `_pkgdown.yml`
- `docs/dev-log/figure-audits/2026-08-03-function-map/audit.md`
- `docs/dev-log/figure-audits/2026-08-03-function-map/image2-base.png`
- `docs/dev-log/figure-audits/2026-08-03-function-map/function-map-final-overlay.svg`
- `docs/dev-log/figure-audits/2026-08-03-function-map/rendered-desktop.png`
- `docs/dev-log/figure-audits/2026-08-03-function-map/rendered-mobile-390x844.png`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

- `pkgdown::build_article("function-map-cheatsheet", lazy = FALSE)`: PASS; the
  Gaussian location-scale example executed.
- `pkgdown::check_pkgdown()`: PASS, no problems.
- Focused builds of `drmTMB` and `function-map-cheatsheet`: PASS; the rendered
  navbar contains both Get started destinations and both generated article
  files exist. The generated articles index lists them in the same order.
- Full source-installed `pkgdown::build_site(lazy = TRUE, install = TRUE)`:
  PASS, including the association article and both Get started destinations.
- Desktop Chromium render at 1440 px: inspected directly.
- Mobile Chromium render at 390 × 844: inspected directly.
- Displayed-function audit against `NAMESPACE`: PASS for exports and registered
  `drmTMB` S3 methods.
- SVG-to-PNG rasterization at 1536 × 1024: PASS.
- `git diff --check`: PASS.
- Florence: PASS. Pat: PASS. Rose: PASS. Fisher's two initial claim-boundary
  blockers were repaired; final source and rendered-page re-review: PASS.

## 6. Tests of the Tests

The focused article build executes the model, `check_drm()`, coefficient
extraction, and `predict_parameters()` route; a stale or invalid example would
fail the render. `pkgdown::check_pkgdown()` independently verifies article and
reference-index synchronization. The visual labels were checked against
exports/method registrations rather than accepted from OCR or the generation
prompt. Desktop and mobile screenshots were refreshed only after the final
asset and CSS changes.

## 8. Consistency Audit

The navbar, image, alt text, explanatory prose, and route table agree on:

- `profile_targets()` as an uncertainty route;
- `check_drm()` and `summary()` as fit-health functions;
- `rho12()` and `corpairs()` on the ordinary interpretation route;
- `biv_associate()` → `association()` only in the paired-outcome table row;
- structured terms as model specification;
- family-specific location rather than a universal expected response;
- numerical fit health as a prerequisite rather than proof of interpretable
  inference;
- admitted latent-normal paired-outcome association rather than an arbitrary
  paired-family claim;
- fixed-effect distributional scope for the Predict & assess branch;
- Julia fitting as future/deferred, with current methods limited to legacy
  object compatibility.

The first navbar destination is the guided first-fit tutorial; the second is
the task lookup page. Neither is duplicated under a misleading single-link
Get started label.

## 7a. Issue Ledger

No issue or pull request was changed. This was a bounded reader-path repair in
an isolated Codex branch because the shared checkout had an active foreign
Claude lane.

## 9. What Did Not Go Smoothly

The first Image 2.0 edit exposed that the inherited `family()` label was not a
family-construction route. A corrected Image 2.0 base was generated, but later
edit and clean-regeneration requests repeatedly failed with network errors.
The successful Image 2.0 artwork was preserved, and a deterministic SVG
overlay applied only the reviewer-required labels and badge removals. This
kept the visual design while making the public API text exact and reproducible.

The first mobile render also showed the route table collapsing into one-word
lines. A labelled scroll region with a minimum table width fixed that reader
friction.

An initial full-site build used `install = FALSE` and therefore picked up an
older installed package; it stopped when `cross-family.Rmd` called the newer
Arc 6 `vcov()` method. This was an invalid build configuration for the current
source, not evidence that the public association route is unavailable. The
final site build was rerun from a fresh source installation and passed.

## 11. Team Learning

Florence required readable labels and conditional, not sequential, branch
semantics. Pat required an explicit failed-fit route and a usable mobile lookup
table. Rose caught four semantic classes that visual polish alone would not:
target inventory versus fit diagnosis, fitted-object transitions, family-
specific location meaning, and current versus future backend wording.

The reusable lesson is to validate every function label against its accepted
object and scientific task, not merely its export status.

## 10. Known Residuals

The inline mobile image is necessarily small; the immediately adjacent
full-size link is the supported zoom route, while the prose and table carry the
same information without relying on the image. This map does not establish
family-by-component support or calibrated inference. Those claims remain in
the model and capability guides.

## 12. Cross-Product Coverage

The gllvmTMB page supplied the useful task-first precedent, but the drmTMB map
uses its own public functions and distributional-regression workflow. No
gllvmTMB capability or syntax was copied into drmTMB. The pattern—primary fit
route followed by conditional scientific tasks, paired with searchable HTML—
can be reused in sibling packages after package-specific API review.
This documentation repair does NOT cover REML, penalties, engine
implementation, missing-data algorithms, aggregation, family support,
structured-effect admission, interval calibration, or any promotion in the
capability ledger.

## Next actions

Review the isolated branch diff and, if accepted, land it through the normal
small-PR process. After deployment, verify the live article and full-size image
URL rather than inferring success from the local render.
