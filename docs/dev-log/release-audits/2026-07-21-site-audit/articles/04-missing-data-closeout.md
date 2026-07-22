# Missing-data audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/missing-data.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The article’s wide capability, boundary, and predictor-family tables could widen the 390 px reader surface. | Repaired with a page-scoped mobile table containment rule. |
| P2 | The mobile article title hyphenated inside words (“miss-ing”). | Repaired with a small-screen heading rule that wraps only between words. |
| Claim audit | The article’s missing-response routes are explicitly bounded by family, predictor completeness, and fixed-effect/ordinary-random-intercept evidence where applicable. No stale `rho12` certification or tier-promoting claim was found. | No claim edit required. |

## Render and focused checks

- `pkgdown::build_article("missing-data", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21, executing the
  article’s supported-route examples.
- Fresh full-page captures: `renders/missing-data-desktop-1440x1000.png` and
  `renders/missing-data-mobile-390x844.png`.
- The 390 x 844 viewport was inspected after repair: body prose is readable,
  the title wraps as “Handling / missing data,” and wide tables are bounded
  scroll regions rather than widening the page.
- `git diff --check` passed.

## What this repair does not establish

It does not widen missing-response or missing-predictor support, certify a
missingness mechanism, add multiple imputation, add structured predictor
models beyond the documented routes, or change the missing-data likelihood.
