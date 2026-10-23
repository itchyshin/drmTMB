# After Task: Paired Website Reader Journey

## 1. Goal

Give a first-time reader one clear route from the `drmTMB` home page to the Gaussian location-scale guide, a reportable residual-variability result, and an explicitly optional DRM.jl companion.

## 2. Implemented

The home page now presents **Fit a Gaussian location-scale model** as its primary action while retaining the capability check and other existing routes. The location-scale guide links to the Julia companion beside its residual-SD and residual-variance interpretation. Compact desktop navigation now keeps the complete menu and search field visible, and mobile display equations scroll within their own block instead of widening the article.

## 3. Mathematical Contract

No likelihood, parameterization, formula grammar, transformation, estimator, or model code changed. The existing interpretation remains: exponentiating a log-`sigma` contrast gives a residual-SD ratio, and exponentiating twice that contrast gives a residual-variance ratio. R remains the default workflow; Julia is an optional companion with distinct fitting and inference routes.

## 3a. Decisions and Rejected Alternatives

The slice uses the existing Gaussian location-scale guide rather than adding a new route or page. It keeps every existing secondary action and navigation item. The redundant compact-width version pill is hidden below 1360 pixels; menu removal, regrouping, route changes, and a claim of R/Julia API parity were rejected.

## 4. Files Touched

- `README.md`
- `vignettes/location-scale.Rmd`
- `pkgdown/extra.css`
- this after-task report
- `docs/dev-log/check-log.d/2026-09-05-paired-website-reader-journey.md`

## 5. Checks Run

- Focused `pkgdown::build_article("location-scale", new_process = FALSE)`: PASS.
- Final `pkgdown::build_site(new_process = FALSE, preview = FALSE)`: PASS.
- Final `pkgdown::check_pkgdown()`: PASS, no problems found.
- Rendered home and guide at 1440, 1280, 1024, and 390 CSS pixels: PASS; no body-level horizontal overflow.
- R navigation at 1024: PASS; the complete menu, search field, and GitHub link remain in view.
- R mobile menu at 390: PASS; opening the menu exposes a fully visible 350-pixel search field.
- Keyboard entry and primary-action tab order: PASS; the visible skip link receives first focus and the primary action is reachable.
- Reciprocal-link and exact-label checks: PASS.
- Independent reviewer: APPROVE, no P0-P2 findings.

## 6. Tests of the Tests

This was a documentation/CSS-only slice, so model tests were not added. The responsive audit did catch two pre-closeout failures: the search field was clipped at 1024 pixels and a display equation widened the mobile guide to 417 pixels. Both checks passed after the scoped CSS repairs.

## 7a. Issue Ledger

No issue, comment, pull request, push, merge, or deployment was created; the approved task required local commits only.

## 8. Consistency Audit

The source diff changes no capability map, status ledger, license text, route, API, generated site, workflow, model code, or test. Existing experimental-software, release-status, R-default, Gaussian/non-Gaussian REML, and GPL wording remains unchanged. The Julia companion wording explicitly avoids claiming identical APIs, fitting implementations, or route-specific evidence.

## 9. What Did Not Go Smoothly

The first 1024-pixel render showed that shrinking the search field alone did not prevent clipping. The final rule also compacts navigation spacing between 992 and 1099 pixels. The first mobile guide audit exposed MathML overflow that was not visible from source inspection. A live HTTP check also caught an unversioned DRM.jl URL returning 404; the corrected `/stable/` URL returns 200. The full build remained below the stated 30-minute estimate.

## 10. Known Residuals

To preserve every navigation item at 1024 pixels, compact desktop navigation uses `0.78rem` text between 992 and 1099 pixels. The independent reviewer judged this legible and non-blocking, but it is intentionally denser than the wide-desktop navigation. No public site was deployed, so these results describe the local rendered candidate.

## 11. Team Learning

Responsive checks should measure the search and action bounding boxes as well as document width. A page can report no body overflow while a clipped navbar element sits outside the viewport.

## 12. Cross-Product Coverage

The paired DRM.jl home and guide changes were reviewed from `/private/tmp/drmjl-paired-website`. The Julia home uses the same primary action label, and each guide links to the other beside the SD/variance-ratio interpretation. The Julia site passed its full strict DocumenterVitePress build and the same four-width rendered audit. The corrected public Julia companion URL and the reciprocal public R guide URL both returned HTTP 200.

This slice does NOT cover any model, estimator, REML, penalty, engine, missing-data, aggregation, API, capability, evidence-tier, route, workflow, or deployment change in either package.

## Next Actions

Review the two local commits together. Push, pull requests, merging, and deployment remain separate explicit actions.
