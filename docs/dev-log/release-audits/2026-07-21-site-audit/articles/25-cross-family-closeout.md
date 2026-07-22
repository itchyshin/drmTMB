# Cross-family development-note audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/cross-family.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The Julia-engine link still described its former contributor-setup material. | Repaired to point to the reduced future-support boundary page. |
| P2 | The page lacked the standard narrow-screen heading/table treatment. | Repaired with page-scoped responsive rules. |
| Claim audit | The note consistently defers cross-family fitting, distinguishes latent `rho_latent` from native residual `rho12`, and makes no 0.6 point-estimate or interval claim. | No further claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("cross-family", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/cross-family-desktop-1440x1000.png` and
  `renders/cross-family-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and an
  unambiguous future-support link.
- The page contains no generated scientific figures or interval display.
- `git diff --check` passed.

## What this repair does not establish

It does not admit cross-family models, expose a `rho12` cross-family formula,
claim latent-correlation recovery or interval evidence, or make Julia a
required/default engine.
