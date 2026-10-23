# After Task: Public NG REML honesty (4a)

**Date:** 2026-08-16
**Lane:** `cursor/ng-reml-honesty-4a` · worktree `~/local-scratch/lanes/drmTMB-ng-reml-honesty-4a`
**Reader:** applied ecology/evolution user hitting README or `?drmTMB`
**Contract:** Arc Card Public NG REML honesty (4a). Docs only. No gate flip. No O3 export.

## Goal

A Pat-level reader of README and `?drmTMB` can answer “does non-Gaussian REML
work?” without opening the ledger: public NG REML is binomial O2 only
(`mc-0060` RI, `mc-0062` independent slope), both `diagnostic_only`; O3 is
package-private; `mc-0227` stays public ML `point_fit_recovery`; other
non-Gaussian families reject `REML = TRUE`.

## Implemented

Honesty alignment only. Capability guide, NEWS 0.7 REML section, and
known-limitations already carried the contract from PR #953. This slice puts
the same sentence on the two surfaces a new user actually opens.

No `drm_validate_reml_spec` change. No abort-text change. No O3 export. No
cell promotion.

## Mathematical Contract

Unchanged. Public `REML = TRUE` remains the joint-Laplace fold for Gaussian /
bivariate-Gaussian routes and the bounded binomial O2 slice. O3 stays the
nested AGHQ plus Cox-Reid-style profile in `R/aghq-coxreid.R`.

## Files Changed

- `README.md` — binomial family bullet and Current boundaries paragraph
- `R/drmTMB.R` — `REML` roxygen only
- `man/drmTMB.Rd` — matching help text
- `NEWS.md` — 0.7 REML section names cells and README/`?drmTMB`
- `docs/dev-log/known-limitations.md` — cell IDs on the O2/O3 bullets
- `docs/dev-log/check-log.md` — this slice
- this after-task note

## Checks Run

| Check | Result |
| --- | --- |
| `git show origin/main:README.md` L190–205 | already said binomial REML is diagnostic-only |
| Reconciliation table L28–40 | `mc-0060`/`mc-0062` diagnostic; `mc-0227` ML point-fit; O3 internal |
| `git diff -- R/drmTMB.R` | roxygen only; no `cli_abort` / `drm_validate_reml_spec` hunk |
| `NAMESPACE` | no `aghq` / `cox` / `o3` export |
| Ledger / cells.tsv | not touched |
| `rg` leftover overclaims on edited surfaces | no “REML planned” / “public O3” product claim |

`rg` patterns: `REML planned|non-Gaussian REML is|REML is planned|O3.*REML = TRUE|public O3`
on `README.md NEWS.md man/drmTMB.Rd docs/dev-log/known-limitations.md R/drmTMB.R`.

Status inventory: `README.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`,
`?drmTMB`. `ROADMAP.md`, formula-grammar, and `_pkgdown.yml` unchanged (no
grammar or navigation change).

`devtools::document()` was not re-run; `man/drmTMB.Rd` was edited to match the
roxygen so a sparse worktree would not need `src/`.

## Tests Of The Tests

No new tests. Behaviour is unchanged. A reader test is the Done-when: README +
`?drmTMB` now name O2, O3, and the other-family reject.

## Consistency Audit

Capability guide (`vignettes/capability-and-limits.Rmd`) already stated the
same boundary and was left alone. Historical 0.6 NEWS still mentions later
`mc-0227` campaigns; the 0.7 section and README now outrank that for a current
reader.

## GitHub Issue Maintenance

No overlapping open issue asked for this honesty slice. Left the tracker
unchanged. Stayed off #1033 and Ligges/win-builder.

## What Did Not Go Smoothly

The first Dropbox worktree checkout of 18k files failed to write its index.
Relocated to a sparse local-scratch worktree.

## Team Learning

PR #953 already fixed the capability guide. The remaining leak was README /
`?drmTMB`: a reader who never opens the guide could still miss that O3 is
private and that other NG families reject REML.

## Known Limitations

4b (public O2 recovery/coverage) and 4c (named public O3) are not this arc.
Sigma-slope admit and correlated PRs are out of scope.

## Next Actions

Merge this docs PR if the owner wants the landing-page sentence on `main`.
Do not treat merge as a gate flip or as 4b/4c authorization.
