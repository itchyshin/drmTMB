# Which-scale audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/which-scale.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | Tables can exceed the 390 px reading width. | Repaired with a page-scoped mobile table containment rule. |
| Claim audit | The article consistently distinguishes residual `sigma`, mean-side random-effect SD, scale-side random-effect SD, `sd(group) ~ x`, and known sampling covariance. Its random-effect-SD figure explicitly withholds an interval when none is supported. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("which-scale", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/which-scale-desktop-1440x1000.png` and
  `renders/which-scale-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable prose and a contained
  page layout.
- The two generated figures were inventoried at original resolution. Detailed
  inspection of the group-level-SD figure confirmed its direct warning that no
  supported interval is drawn, avoiding false precision.
- `git diff --check` passed.

## What this repair does not establish

It does not establish an interval for `sd(group) ~ x`, promote any
random-effect-scale surface, add a `meta_V()` ledger tier, or alter any
likelihood or formula grammar.
