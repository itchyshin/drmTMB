# Convergence-guide audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/convergence.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The diagnostic table required a stable narrow-screen reading surface. | Repaired with page-scoped heading rules and a 720 px horizontally scrollable table surface. |
| Claim/figure audit | The guide correctly separates optimizer status, Hessian curvature, finite standard errors, boundary warnings, and target-specific profiling. It explicitly says a clean Hessian is necessary but insufficient and does not treat convergence as validation. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("convergence", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/convergence-desktop-1440x1000.png` and
  `renders/convergence-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and a
  horizontally contained diagnostic table.
- Original-resolution inspection of the check-status map confirmed that colours
  encode diagnostic statuses—not uncertainty or posterior probabilities—and
  that notes for skipped standard-error work remain distinct from warnings.
- `git diff --check` passed.

## What this repair does not establish

It does not make optimizer convergence a model-validation certificate,
validate Wald intervals where Hessian diagnostics fail, promote diagnostic
profiles into reporting intervals, or resolve weak identification by itself.
