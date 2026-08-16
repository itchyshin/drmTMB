# After Task: Non-Gaussian ordinary correlated-slope design (docs only)

## Goal

Start the #1 post-quiesce fruit as a docs-only design and symbolic-alignment
note: ordinary non-Gaussian `(1 + x | g)`, binomial wedge first. No C++/API,
no merge of shipped files, no CRAN, no missing-data, no MSPL.

## Implemented

A design contract and the fruit inventory that ranked this slice first. The
binomial experimental point-fit path is named as Wave 1; other families stay
rejected until that cell is an honest `point_fit_recovery` row. Claim ceiling
is `point_fit_recovery` first; `supported` is withheld for the whole first arc.

## Mathematical Contract

Binomial logit location with one unlabelled intercept–slope block. Group-level
correlation is `rho_re`, not residual `rho12`. The compiled map to reuse is the
existing log-sech Cholesky (`eta_cor_mu` / `logsech_mu_re`), not a rewrite of
design 17’s Gaussian `√(1-ρ²)` form. Alignment table is in design 257.

## Files Changed

- `docs/design/257-nongaussian-ordinary-correlated-slope.md` (new)
- `docs/dev-log/research/2026-08-16-nongaussian-re-remaining-fruit.md` (new on this branch; copied from the cran-07 worktree inventory)
- `docs/dev-log/after-task/2026-08-16-nongaussian-correlated-slope-design.md` (this file)

Check-log and `coordination-board.md` were left untouched: both are multi-lane
hot files (360+ and 3 foreign refs). The operator pointer goes to Mission
Control `next_safe_action` instead.

## Checks Run

| Check | Result |
| --- | --- |
| Lane preflight | 14 live lanes; this session took `cursor/ng-correlated-slope-design` only |
| Read fruit inventory + binomial q2 tests + `validate_binomial_mu_random_terms()` + `drm_validate_binomial_q2_context()` + design 17 / 01 / 224 | Done before writing |
| Package tests / `devtools::check()` | Not run — no executable change |
| `--as-cran` / pkgdown / CRAN | Not run |

## Tests Of The Tests

None added. Wave 1 must keep `test-binomial-correlated-re-mspl-prereq.R` as
the local regression and add a rejection-matrix neighbour, not replace it.

## Consistency Audit

- Design 256 is not used; the MSPL-boundary lane already claims it.
- `mc-0061` is not reused; it is the independent binomial slope.
- Formula grammar’s experimental binomial q2 row is cited, not rewritten.
- MSPL and missing-data fences in `drm_validate_binomial_q2_context()` stay closed.

## GitHub Issue Maintenance

No issue opened. This is a pre-implementation contract, not a user-facing
defect. A draft PR is the review surface.

## What Did Not Go Smoothly

The fruit note lived only as an untracked file on `.worktrees/cran-07`
(`cursor/070-winbuilder-collect`). Extending that win-builder lane would have
mixed CRAN collection with this design, so the inventory was copied onto a
fresh branch from `origin/main` instead.

## Team Learning

A second Cursor lane is still a live lane. Name the subject
(`ng-correlated-slope-design`) and keep it off the win-builder worktree even
when that worktree already holds the inventory.

## Known Limitations

The note is not a gate flip. Binomial correlated remains experimental
point-fit until Wave 1 lands after quiesce. Noether / Fisher have not signed
the alignment table yet; that review belongs on the later code PR.

## Next Actions

1. Draft-PR this docs branch, labeled design-only / no ship until quiesce.
2. After win-builder unlock: Wave 1 implementation from design 257, Totoro
   smoke, then owner approval before any DRAC campaign.
3. Do not start Wave 2 (Poisson / NB2) in the same PR.
