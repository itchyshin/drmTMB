# Likelihood-testing guide audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/testing-likelihoods.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The guide framed test completion too closely to implementation completion and did not make evidence boundaries visible near its core contract. | Repaired with a contributor-facing evidence matrix that separates code-path, comparator, small-recovery, and coverage claims. |
| P2 | The article lacked standard narrow-screen treatment for its test matrix/table. | Repaired with page-scoped heading rules and a 720 px horizontally scrollable table surface. |
| API clarity | `drm_formula()` remains exported and canonical; `bf()` is its short alias. | Documented that relationship rather than incorrectly replacing valid examples. |

## Render and visual evidence

- `pkgdown::build_article("testing-likelihoods", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/testing-likelihoods-desktop-1440x1000.png`
  and `renders/testing-likelihoods-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  evidence-table layout.
- The article contains no generated scientific figure; formulas, comparator
  snippets, and the evidence matrix are the primary visual aids.
- `git diff --check` passed.

## What this repair does not establish

It does not convert a unit/comparator/recovery test into interval coverage,
promote a neighbouring formula, or replace the release manifest and ledger as
the public claim ceiling.
