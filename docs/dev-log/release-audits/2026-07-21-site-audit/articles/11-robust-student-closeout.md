# Robust-student audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/robust-student.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | Reader tables and the title needed a protected narrow-screen layout. | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim/figure audit | The page accurately limits Student-t random/structured extensions to recovery or diagnostic grade and says they are not coverage-validated. Its worked figure distinguishes raw growth observations from fitted means and expressly draws no interval bars. | No claim edit required. |

## Render and focused checks

- `pkgdown::build_article("robust-student", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/robust-student-desktop-1440x1000.png` and
  `renders/robust-student-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  layout.
- `git diff --check` passed.

## What this repair does not establish

It does not promote Student-t random or structured effects, validate their
intervals or coverage, add known-covariance/bivariate Student-t support, or
change the Student-t likelihood.
