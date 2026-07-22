# Model-workflow audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/model-workflow.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`  
**Claim authority:** `docs/dev-log/dashboard/capability-ledger/cells.tsv`, `mc-0181`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P1 | The interval section stated that constant `rho12 ~ 1` was the certified residual-correlation target, although `mc-0181` is only `interval_feasible` and records no committed bivariate fixed-effect CI-coverage simulation. | Repaired. Both constant and `newdata` regression intervals are now described as computable but not coverage-certified. |
| P2 | Wide tables could widen the 390 px reader surface. | Repaired with a page-scoped mobile table containment rule. |

## Render and visual evidence

- `pkgdown::build_article("model-workflow", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures are `renders/model-workflow-desktop-1440x1000.png`
  and `renders/model-workflow-mobile-390x844.png`.
- The six generated figures were inventoried at original resolution. Detailed
  visual inspection of the profile and fitted-surface figures found that the
  likelihood-ratio distance, response-scale target, estimate, threshold, and
  endpoints are visible, while the surface figure separates `mu` and `sigma`,
  names the 95% Wald bands, and makes the shared-`sigma` habitat rule visible.
- The rendered HTML contains the repaired interval statement and mobile style;
  `git diff --check` passed.

## What this repair does not establish

It does not add a bivariate fixed-effect CI-coverage study, promote `mc-0181`,
validate every profile target, change the fitting API, or change the status of
`meta_V()`.
