# Status And Stale-Claim Audit: Slices 1-10

## Scope

This audit picked up after the crash, closed the already validated rendered
figure QA branch through PR #314, and then checked the next handoff item:
high-risk public status wording. The goal was to make current docs agree on
three boundaries:

- `meta_V(V = V)` is the preferred known sampling covariance spelling, with
  `meta_known_V(V = V)` retained as a compatibility alias.
- Constant spatial, animal-model, and `relmat()` q=4 routes are fitted first
  slices, while richer structured correlations, slopes, direct-SD surfaces, and
  mesh/SPDE or non-Gaussian routes remain planned.
- Ordinary Poisson q=1 phylogenetic `mu` is the only fitted structured
  non-Gaussian slice; it is not broad structured count parity.

No likelihood, formula grammar, optimizer, extractor, or interval method
changed.

## Slice Decisions

| Slice | Surface | Finding | Action |
| --- | --- | --- | --- |
| 1 | crash recovery | The newest recovery checkpoint pointed from rendered figure QA to status and stale-claim audit. | Rehydrated from `git status`, checkpoint, after-task report, PR state, and check-log evidence. |
| 2 | PR overlap | PR #314 was open with checks passing and owned the rendered figure QA branch. | Squash-merged PR #314 and rebased `codex/status-stale-audit-1-10` onto `origin/main`. |
| 3 | known covariance syntax | Several high-traffic docs still led with `meta_known_V(V = V)`. | Moved status prose and examples to `meta_V(V = V)` while retaining the compatibility alias. |
| 4 | extractor and diagnostic wording | `weights()`, `sigma()`, and `check_drm()` wording still pointed users at `meta_known_V()`. | Updated roxygen and regenerated the matching Rd files. |
| 5 | formula grammar | Grammar tables risked hiding the preferred spelling. | Added `meta_V(V = V)` as the preferred implemented row and kept `meta_known_V(V = V)` as the alias row. |
| 6 | structured q4 status | Known-limitations wording still grouped spatial q4 with planned work. | Marked constant coordinate-spatial q4 as fitted first-slice support and kept richer spatial routes planned. |
| 7 | animal and `relmat()` q4 status | Known-limitations wording still stopped at q2 for known-matrix bivariate routes. | Marked constant q4 animal and `relmat()` blocks as fitted first slices, with slope and direct-SD neighbours planned. |
| 8 | Poisson phylo status | Some limitations still said phylogenetic terms were unavailable for Poisson. | Marked ordinary Poisson q=1 phylogenetic `mu` as fitted and kept neighbouring structured count routes planned. |
| 9 | stale scans | The main stale scan now leaves only the intentional proportional-variance roadmap note. | Recorded alias and structural-status scan results for later auditors. |
| 10 | issue and validation | Open issues still track broader covariance, known-relatedness, and tutorial work. | Left issues open and recorded validation rather than closing broad trackers. |

## Remaining Search Hits

The current high-risk scan:

```sh
rg -n 'meta_V\(\.\.\.|once the alias|alias/rename|preferred roadmap spelling|canonical marker is `meta_known|spatial q=4 blocks are still planned|bivariate spatial q=4 blocks|structured non-Gaussian random effects are not implemented' README.md ROADMAP.md NEWS.md R vignettes docs/design docs/dev-log/known-limitations.md -g '!*.html'
```

returned only the intentional roadmap line for the future proportional branch:
`meta_V(..., scale = "proportional")`.

The compatibility-alias scan still finds `meta_known_V(V = V)` in NEWS,
roadmap history, tests-adjacent design notes, source-map inventory, and explicit
alias explanations. Those are not stale by themselves because the alias remains
supported.

The structured-status scan still finds fitted first-slice and planned-neighbour
wording for Poisson q=1 phylogeny, spatial q4, animal q4, `relmat()` q4, and
non-Gaussian structured routes. The current docs now separate narrow fitted
slices from remaining broad planned surfaces.

## Role Review

Ada kept the recovery and branch state explicit. Boole checked formula/API
spelling and alias wording. Fisher checked that interval and profile-status
claims stayed bounded. Pat checked whether users are told what to try next when
syntax remains unsupported. Grace checked roxygen, pkgdown, vignettes, and
whitespace. Rose audited stale status claims and durable handoff evidence. No
spawned subagents were used.
