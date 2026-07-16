# Codex handover: Beta phylogenetic q1 pilot abort

## Current state

The approved two-PR Beta phylogenetic LSS goal stopped at PR 1's recovery gate.
No PR was opened, PR 2 was not started, and no capability ledger row changed.
The active branch is `codex/beta-phylo-q1-constant-sd`; its pushed head before
banking this closeout was `ad1ebe9bdd73fc009668af81cd4f5e806f3b983e`.

## Read first

1. `docs/dev-log/after-task/2026-07-16-beta-phylo-q1-pilot-abort.md`
2. `docs/dev-log/2026-07-16-beta-phylo-q1-pr1-two-hold-disposition.md`
3. `docs/dev-log/2026-07-16-beta-phylo-q1-pr1-disjoint-seed-repair-plan.md`
4. `docs/dev-log/simulation-artifacts/2026-07-16-beta-phylo-q1-pr1-disjoint-repair-pilot-aborted/README.md`
5. `docs/dev-log/2026-07-16-beta-phylo-q1-pr1-symbolic-alignment.md`

## Exact evidence

The original `m = 2` 1,200-attempt campaign is HOLD at `g = 256` mean
log-`tau` bias `-0.5203`. The earlier valid within-block `m = 4` 1,200-attempt
campaign is HOLD at `-0.2470`; it was not independent of the `m = 2` campaign
because 1,197 numeric seeds overlapped.

The repaired seed table contains 1,200 unique seeds with zero overlap against
both earlier designs, smoke, or pilot. Clean runner commit
`39acd66a191d2c6fb6d768e6423f3a91241f9c51`, SHA-256
`777f7de6da2ae003624122e11c035fc096449af85971bd6ac3e0dff4a1d9f2a4`,
authenticates the pinned `R/` and `src/` trees, all earlier artifacts, frozen
design, and complete-DGP RNG before fitting.

Local and Totoro smoke runs were mechanically clean. The disjoint Totoro pilot
retained 30/30 fits, all with convergence code zero and `pdHess = TRUE`, no
warnings, and no boundaries. Its `g = 256` mean log-`tau` bias was `-0.2214`
(MCSE `0.0861`), while `g = 1024` passed at `-0.0771` (MCSE `0.0489`). All
fixed-slope and RMSE gates passed.

Noether, Fisher, and Rose returned STOP. Under the frozen equal-size pooled
rule, the new certification block would need `g = 256` bias at least
`+0.046998` to offset the earlier `-0.246998` and achieve pooled absolute bias
at most `0.10`. The disjoint pilot and all prior moderate-tree results are
negative. The 1,200-attempt certification was therefore not launched.

## Hard guards

- Do not open PR 1 or begin PR 2 from this state.
- Do not run certification under the current goal.
- Do not replace mean log-`tau` with raw `tau`, relax the threshold, omit
  `g = 256`, or treat the pilot as certification evidence.
- Keep family `sigma` (`phi = sigma^(-2)`) distinct from latent phylogenetic
  location-effect SD.
- Continue to defer REML, q2/q4, phylogenetic family-`sigma`, slopes, labels,
  hierarchical `sd()` RHS effects, `zero_one_beta()`, missing/external data,
  intervals, and coverage.

## Decision required from Shinichi

Choose a new goal before further work:

1. abandon/revert the branch-only admission while retaining the negative
   evidence in a documentation-only closeout; or
2. approve a separately predeclared high-information or estimator-method
   redesign with its own claim boundary and two-PR decision.

Until that choice, preserve the pushed branch and stop.
