# Twin/Sister Exchange Log

This log closes the first #437 exchange protocol. Its purpose is to let
`drmTMB` learn from `DRM.jl`, `gllvmTMB`, `GLLVM.jl`, and benchmark sidecars
without turning sister-package speed, coverage, convergence, or implementation
claims into `drmTMB` evidence.

## Protocol

Each scout card should record:

- source repo and local path;
- branch and short commit;
- observed pattern or problem;
- applicability to `drmTMB`;
- proposed `drmTMB` action;
- provenance or licensing risk;
- comment status: none, comment needed, comment left, reply received,
  accepted, declined, or deferred.

The exchange is a design and coordination loop. It is not a substitute for
local `drmTMB` tests, likelihood comparisons, simulation artifacts, rendered
docs, or GitHub Actions checks. Do not copy code from sibling repositories
without provenance review and an `inst/COPYRIGHTS` update. Keep
higher-dimensional multivariate lessons in `gllvmTMB` unless a one-response or
two-response `drmTMB` issue explicitly admits the design.

## Closeout Decision

The first #437 loop is complete as a protocol and evidence ledger. It produced
three accepted planning lessons:

1. Keep random-slope support rows separated by evidence tier: source-tested,
   artifact-ready, diagnostic-only, recovery-ready, coverage-ready, and
   power-ready are different states.
2. Keep core tests, heavy simulation gates, benchmarks, and coverage claims in
   separate lanes with denominators for attempted fits, converged fits, usable
   intervals, and Monte Carlo uncertainty.
3. Keep reader docs paired with status maps and next-action guidance so users
   see the nearest fitted alternative when a planned route is rejected.

These lessons informed the Phase 6c random-slope closeouts and the #446
simulation plan. They did not add a likelihood, formula grammar, parser route,
simulation grid, benchmark result, missing-data behavior, or external-code
copy.

## Scout Cards

| Date | Sources | Lesson | `drmTMB` disposition | Provenance and comment status |
| --- | --- | --- | --- | --- |
| 2026-05-30 | `DRM.jl`, `GLLVM.jl`, `gllvmTMB`, an older local `GLLVM.jl` checkout path, and `gllvmTMB-julia-bench` | Add compact lesson cards before coding and make cross-repo corrections visible. | Accepted for process. The log now requires source handles, applicability, action, and provenance risk before a lesson affects the roadmap. | Comments/issues were mirrored to `DRM.jl` issue 1 and `GLLVM.jl` issue 14. No `gllvmTMB-julia-bench` issue was left because the local checkout had no configured Git remote. |
| 2026-05-31 | `DRM.jl` branch `gaussian-animal-phylo`, commit `5cf13f6`; `GLLVM.jl` branch `article-pitfalls`, commit `583d1ea` | Separate `(0 + x | g)` recovery evidence from correlated `(1 + x | g)` planned or rejected evidence; separate ordinary gates from heavy simulation and coverage grids. | Accepted for planning only. This became status-discipline for #438, #441, #442, and #446. | No code copied. No `DRM.jl` or `GLLVM.jl` speed, coverage, or recovery result was treated as `drmTMB` evidence. |
| 2026-05-31 | `DRM.jl` branch `gaussian-multi-re`, commit `2edd781`, dirty; `GLLVM.jl` branch `fix-vitepress-deploy-path`, commit `281fe07`, clean; `gllvmTMB` `main`, commit `9dcac03`, clean but behind origin | Keep simulation/readability ledgers connected: DGP, estimand, fit route, recovery, coverage, power, and planned neighbours should be visible together. Promote the smallest failing simulation cell to a narrative regression test before broad coverage grids. | Accepted for planning only. This reinforced the #446 run order and the #444 reader-path closeout. | No code copied. No sibling-package speed, coverage, or recovery result was treated as `drmTMB` evidence. |

## Corrections Locked In

- Use `GLLVM.jl` for the Julia sister package. `gllvmTMB.jl` is not a separate
  package name; any such wording refers only to an older local checkout path.
- Use `meta_V(V = V)` as the current known-sampling-covariance spelling.
  `meta_known_V(V = V)` is a deprecated compatibility alias, not the preferred
  route.
- `gllvmTMB` remains the higher-dimensional multivariate package. `drmTMB`
  stays scoped to one-response and two-response models.

## Next Use

#437 can close with this ledger. #436 remains the sprint parent until its own
closeout confirms that the child issues, roadmap, tests, docs, pkgdown checks,
and remaining follow-up issues agree. Future exchange notes should be appended
only when they produce a concrete `drmTMB` action, issue comment, or explicit
defer decision.
