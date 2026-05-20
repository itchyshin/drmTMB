# Slices 1139-1238: Visual, Reference, Convergence, And Integration Plan

Date: 2026-05-20

Open integration target: PR #263, "Consolidate Ayumi stress evidence and Phase 18 staging".

## Role Map

Ada coordinates the lane and keeps the slice ledger tied to PR #263. Florence
owns the rendered-figure standard, but Fisher, Pat, Rose, Grace, Boole,
Noether, Curie, Darwin, Gauss, and Emmy share the gate because poor figures or
unclear uncertainty are usually a system failure, not a single-person failure.
These are role perspectives, not spawned agents.

## Slice Sets

| Slices | Lane | Closure Target | Current Status |
| --- | --- | --- | --- |
| 1139-1148 | Rendered figure inventory | Inventory every figure in the figure gallery and simulation grammar, including visual data grain, interval source, missing-cell display, and reader risk. | Partly closed by the 2026-05-20 raindrop and coverage figure rescue; keep as the next checklist when new figures enter pkgdown. |
| 1149-1158 | Figure repair and re-render | Repair poor panels, re-render changed articles, inspect rendered images one by one, and save PNG evidence. | Partly closed for coefficient raindrops, correlation raindrops, gallery coverage, and simulation coverage/power. |
| 1159-1168 | Reference and formula discoverability | Rebuild pkgdown locally and audit exported functions plus formula-only syntax such as `sd(group)`, `rho12`, `phylo()`, `spatial()`, `meta_V(V = V)`, planned `animal()`, and planned `relmat()`. | Planned; use `pkgdown::check_pkgdown()` and rendered reference-index searches. |
| 1169-1178 | Forgotten-promise ledger | Cross-check README, ROADMAP, NEWS, known limitations, design docs, after-task notes, and issue/PR text for promises about shape models, animal/relmat, profile/bootstrap CIs, convergence diagnostics, simulations, and examples. | Planned; should produce a done/partial/planned/blocked status table. |
| 1178a | Structural-dependence parity and article split | Make the "same as phylo" target explicit for animal, spatial, and `relmat()`, and record that the future structural-dependence article should split into animal, phylo, spatial, phylo+spatial, and `relmat()` pages. | In progress; the structural-dependence article and forgotten-promises table now name this parity target while preserving fitted-versus-planned status. |
| 1179-1188 | Missing covariance combination | Test and document bivariate models with two independent same-response `mu`/`sigma` blocks plus residual `rho12`, for example `mu1`/`sigma1` label `p` and `mu2`/`sigma2` label `q`. | Closed locally: code, tests, `check_drm()`, `corpairs()`, `profile_targets()`, README, ROADMAP, NEWS, grammar docs, and known limitations now describe the two-block path. |
| 1189-1198 | Convergence diagnostics | Re-test hard Ayumi-style bivariate location-scale fits with current diagnostics, including gradient labels, tiny SDs, boundary correlations, optimizer budgets, and `pdHess` separation from point-estimate usability. | Planned; use at most 10 cores and keep q4 boundary cases separate from locphylo fallback successes. |
| 1199-1208 | Profile interval hardening | Audit direct versus derived profile targets for residual `rho12`, ordinary q=2 correlations, phylogenetic q=2 correlations, same-response mean-scale blocks, q4 derived rows, and response-scale `sigma` or `nu` rows. | Planned; direct profile readiness does not guarantee every hard fit profiles successfully. |
| 1209-1218 | Bootstrap interval design | Keep bootstrap as the fallback for useful point-estimate fits with weak Hessians, add worker-count provenance, and avoid nested multicore layers beyond 10 workers. | Partly closed by private Phase 18 bootstrap helpers; public API, documentation, and broader convergence evidence remain planned. |
| 1219-1228 | Phase 18 simulation integration | Admit only implemented and tested surfaces to simulation grids; attach replicate-level or replicate-block artifacts before plotting bias, coverage, power, RMSE, convergence, runtime, and failures. | Partly closed for first-wave and interval-heavy smoke runners; larger grids and visual reports remain staged. |
| 1229-1238 | Package-down and PR integration | Re-run source and rendered-site stale-wording scans, run checks, update after-task notes, and keep all work on PR #263 rather than opening a duplicate PR. | In progress; this plan and the covariance-combination closeout are part of the PR #263 integration pass. |

## Non-Negotiable Gates

- Do not call a figure done from source inspection alone; inspect the rendered
  image and save evidence for meaningful visual tasks.
- Do not advertise a fitted model surface unless implementation, tests,
  diagnostics or extractors, docs, examples, and after-task notes agree.
- Do not flatten `pdHess = FALSE` into total failure when point estimates are
  useful; separate point-estimate fit, Wald uncertainty, profile uncertainty,
  and bootstrap uncertainty.
- Do not use more than 10 cores for simulation, bootstrap, profile, or render
  work in this lane.
- Keep residual `rho12`, ordinary group-level correlations, phylogenetic
  correlations, spatial correlations, animal/relmat planned correlations, and
  same-response mean-scale correlations as separate layers.
