# Codex handover: Arc 1b-S2R exact relmat q2 REML

## Goal and state

Arc 1b-S2R implements the exact native-TMB bivariate-Gaussian REML model with
matching labelled `relmat(1 | p | id, K = K)` location intercepts in `mu1` and
`mu2`. The claim ceiling is `point_fit_recovery`. It does not admit `Q`, slopes,
q4+, scale-side terms, additional random effects, incomplete/weighted pairs,
non-Gaussian families, intervals, or coverage.

Execution base: `d210439187f2a49922de8bcf8c183d164d7bd0dc` (merged PR #783).
Branch: `codex/arc1b-s2r-relmat-q2-reml`.

Implementation commit: `1f563a17fc2082745ea90820f576702e05b29021`.
Evidence-provenance commit: `4e3fb76b83a037fcf02302f3a33135c24186b8a3`.
Focused PR: [#784](https://github.com/itchyshin/drmTMB/pull/784), ready for
review and intentionally unmerged. Exact-head GitHub run
[29431954827](https://github.com/itchyshin/drmTMB/actions/runs/29431954827)
passed `os-matrix` and `ubuntu-latest (release)` at the provenance head; the
Ubuntu job completed in 26m46s. This receipt is a docs-only successor, so read
the successor's exact-head rerun live before closeout.

## Verified evidence

- Independent dense restricted-likelihood oracle matches the TMB objective at
  the optimum and two displaced parameter vectors; the wrong
  precision/orientation sentinel fails materially.
- Extractors align fixed effects, both structured SDs, the structured
  correlation, both residual SDs, and `rho12`.
- Totoro retained 2,400/2,400 unique attempts over the six predeclared cells.
  All fits converged with `pdHess = TRUE`; every bias, RMSE, MCSE, denominator,
  and provenance gate passed.
- Ledger truth is 675 model rows: 305 implemented, 330 rejected, 40 not
  implemented, and 163 with recovery evidence. Only the exact supplied-`K`
  endpoint cells are `point_fit_recovery`.
- Full tests, documentation, genuine `--as-cran` (0/0/0), pkgdown check/build,
  ledger tests/generation, runtime oracle, Mission Control, stale wording,
  `git diff --check`, and all evidence hashes passed.

## Future sd() boundary — planned only

Do not widen this relmat-K REML arc. Keep the two scale axes explicit:
`sigma` is the distribution/family variability submodel; `sd(target, ...)` is
the SD submodel for a named latent/random-effect target. Current `sd()` RHS
support is fixed-effect-only, with predictors constant inside the target group.

The approved sequence is:

1. finish and separately merge this REML arc;
2. open a new Beta phylogenetic LSS lane and ultra-plan the queued two-PR goal
   in `docs/dev-log/2026-07-15-next-beta-phylo-lss-candidate-goal.md`;
3. after explicit plan approval, land its constant-SD q1 `mu` prerequisite PR
   and then its bounded location-scale-scale PR;
4. only after that, open a separate hierarchical-`sd()` subarc with symbolic
   alignment, nesting
   checks, recovery, and rejection tests.

For that future first implementation, admit an RHS random term only at a
genuinely higher/coarser grouping level with multiple target groups nested in
each higher group. `sd(individual) ~ habitat + (1 | population)` is a candidate
only with multiple individuals per population. Same-level
`sd(individual) ~ (1 | individual)` remains rejected. If the target is already
the highest level, the RHS remains fixed-effect-only unless a separately
justified parent group such as genus or family has adequate species
replication. This is a conservative first-admission and identifiability rule,
not a universal mathematical theorem.

## Resume and guards

Read the after-task report and campaign README first. Confirm the branch/head,
PR exact head, and CI live rather than relying on this note. Do not merge the PR
without separate authorization. PR #781 and unrelated dirty work remain out of
scope. R/TMB is authoritative and Julia remains optional; do not transfer this
evidence to DRM.jl.
