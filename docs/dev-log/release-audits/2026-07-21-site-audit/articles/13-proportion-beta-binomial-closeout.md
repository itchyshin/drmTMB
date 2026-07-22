# Proportion and success-rate audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/proportion-beta-binomial.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The article contains comparative tables and a multiword title that need a narrow-screen reading treatment. | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim/figure audit | The decision path correctly distinguishes known-trial binomial data, beta-binomial overdispersion, strict-interior beta data, and boundary-inclusive zero-one beta data. The tray figure labels its bars as fitted tray-level scatter, not confidence intervals. | No claim or figure edit required. |

## Render and visual evidence

- `pkgdown::build_article("proportion-beta-binomial", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/proportion-beta-binomial-desktop-1440x1000.png`
  and `renders/proportion-beta-binomial-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  layout.
- Original-resolution inspection of `beta-binomial-tray-figure-1.png` (1382 x
  844) confirmed that the raw observations, fitted group centres, and fitted
  tray-level-scatter bars remain visually distinct; the subtitle prevents those
  bars from being read as confidence intervals.
- `git diff --check` passed.

## What this repair does not establish

It does not promote random or structured effects for beta-family models, add
coverage evidence for any interval, or change the beta, beta-binomial, or
zero-one-beta likelihoods.
