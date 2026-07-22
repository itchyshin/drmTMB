# Capability-and-limits audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/capability-and-limits.Rmd` (`16bf769336e2bfa0d878e04711da672b30f504f1` at audit start)  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`  
**Claim authority:** `docs/dev-log/dashboard/capability-ledger/cells.tsv`, including `mc-0181` and `mc-0242`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P1 | The article said `rho12 ~ x` had no interval; supplied `newdata` instead returns row-specific profile or Wald intervals. | Repaired. The article now gives both calls and says that the intervals are computable but lack coverage evidence. |
| P1 | The release-scope manifest called constant `rho12 ~ 1` the only coverage-certified fitted-correlation interval, but `mc-0181` is `interval_feasible` and explicitly records no committed bivariate fixed-effect CI-coverage simulation. | Repaired. No fitted-correlation interval is now called coverage-certified. |
| P1, owner-held | `vignettes/bivariate-coscale.Rmd` calls the constant `rho12 ~ 1` interval a certified reporting target. | Not edited: Shinichi owns this page. Its required correction is to retain the interval example while removing the certification claim. |
| P2 | The at-a-glance table widened the supported ordinary random-effect claim beyond the exact Gaussian `mu` intercept/slope and matching bivariate `mu1`/`mu2` intercept rows. | Repaired. |
| P2 | The fixed-effect table implied a universal `n >= 50` threshold although evidence used the discrete grid `n = 50, 150, 500`. | Repaired. |
| P2 | Gamma `sigma ~ (1 | id)` (`mc-0242`) was absent from the reader route. | Repaired with the exact iid, uncentred, true-SD 0.40, 12-observation/group boundary; reporting floor `M >= 32`, `M = 16` borderline, `M = 8` excluded. |
| P1 render | The three-column at-a-glance table overflowed a 390 px view. | Repaired with a page-local `table-responsive` wrapper; a narrow view now has a controlled horizontal table container. |

## Render and focused checks

- `pkgdown::build_article("capability-and-limits", pkg = ".", lazy = FALSE, new_process = TRUE)` completed successfully on 2026-07-21. Its only warning was a sandbox-denied write to the user-level R sass cache; the rendered article was written successfully.
- Rendered HTML: `pkgdown-site/articles/capability-and-limits.html` (ignored build artifact).
- Desktop capture: `renders/capability-and-limits/desktop-1440x1000.png`.
- Mobile capture: `renders/capability-and-limits/mobile-390x844.png`.
- HTML verification found the revised coscale text, Gamma section, exact-supported-row wording, and `table-responsive` wrapper.
- `git diff --check` passed.

## What this repair does not establish

It does not create a CI-coverage study for either constant or regression `rho12`, promote `mc-0181`, certify any broad random-effect family, expand the Gamma fixture, reconcile the generated missing-response include, or change implementation, likelihood, API, or release scope. The bivariate-coscale correction remains owner-held.
