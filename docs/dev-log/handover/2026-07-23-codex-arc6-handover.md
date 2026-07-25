# Handover — Arc 6.1–6.2 closed; Arc 6.3 planning decision → Codex

**From:** Codex · **To:** Codex · **Date:** 2026-07-23 · **Landing:**
PR #817 merged to `main` as `85cff6fa`

> **Status update — landed 2026-07-23.** The complete Arc 6.1–6.2 branch,
> including this handover, was pushed and merged through PR #817. The local
> feature branch is retained as provenance; the next task starts from `main`.

## Critical context

Arc 6.1 and Arc 6.2 are complete, bounded development slices of the
post-0.6 bivariate programme. They add no `biv_*` family and do not extend
Gaussian `rho12`: `associate_pairs()` freezes independently fitted margins and
reports only a conditional latent-normal point association `eta`.

The next question is **not** "implement Arc 6.3". It is whether a
demand-led lognormal × lognormal slice should open at all, and, if it does,
whether it belongs in the same frozen-margin architecture or needs a distinct
exact-special-family contract. Start with research and an Ultra Plan; do not
write Arc 6.3 package code, run a smoke/campaign, change capability tiers, or
reopen `meta_V`, Julia, or CRAN without owner approval.

## What was accomplished

- `d9dc3116` implemented the first fixed-effect Gaussian × literal-Bernoulli
  frozen-margin association slice.
- `0e512b22` extends `associate_pairs()` to one standard Gaussian and one
  ordinary NB2 margin, in either order. NB2 is
  `Var(Y) = mu + sigma^2 * mu^2`, with `size = 1 / sigma^2`.
- The NB2 likelihood is the exact conditional Gaussian density times a
  latent-normal probability over the NB2 CDF jump. It treats `F(-1) = 0`
  analytically, uses log-CDF/log-survival tail choices and a stable log
  difference, and withholds `eta` on unresolved intervals.
- Both fitted margins remain frozen. `eta` is neither `rho12`, an observed
  correlation, nor a joint-MLE or uncertainty claim.
- Third-party NotebookLM research was completed before implementation; the
  report keeps the discrete-continuous copula literature and comparator
  boundary explicit.
- Gauss, Noether, Fisher, and Rose passed the final mathematical,
  implementation, tail, and public-surface reviews.

## Current working state

- **Working:** Arc 6.1 Gaussian × Bernoulli and Arc 6.2 Gaussian × ordinary
  NB2 are committed. The source worktree is clean.
- **Verified:** focused NB2 tests: 32 pass. Gaussian × Bernoulli regression:
  26 pass, 0 failure/warning, 2 expected CRAN skips. Final-tree Arc 6.1 and
  Arc 6.2 smoke ledgers were regenerated and matched byte-for-byte.
- **Not claimed:** a broad `devtools::check()` did not return a terminal result
  in the originating session. Do not convert the focused evidence into a
  package-check, recovery, interval, coverage, or capability claim.
- **Planning status:** Arc 6.3 is a queued demand-review decision, not an
  authorized implementation.

## Key decisions and rationale

1. Preserve the fitted margins exactly, then estimate association second. This
   avoids silently changing the marginal estimands when adding mixed-family
   association.
2. Use a Gaussian-copula latent association only as `eta`; do not recycle the
   Gaussian residual `rho12` API for non-Gaussian or mixed margins.
3. The count implementation is ordinary NB2 only. Zero-inflated, hurdle and
   truncated NB2, weights, offsets, missingness, `mi()`, random/structured
   effects, REML, association slopes, `meta_V`, profiles, `vcov()`, and
   `confint()` remain rejected or unavailable.
4. Keep Arc 6.3 separate: lognormal × lognormal could have a precise
   log-response-scale association interpretation, but it needs a new
   demand/prior-art/API decision rather than an automatic next implementation.

## Files created or modified

The Arc 6.1–6.2 implementation diff relative to `origin/main` includes:

- `R/associate-pairs.R`, `NAMESPACE`, `man/associate_pairs.Rd`,
  `man/association.Rd`, and `man/latent_normal.Rd`.
- `tests/testthat/test-associate-pairs-gaussian-bernoulli.R`,
  `tests/testthat/test-associate-pairs-gaussian-nb2.R`, and
  `tests/testthat/_snaps/associate-pairs-gaussian-bernoulli.md`.
- `tools/run-arc6-association-smokes.R` and all retained 2026-07-23 smoke
  reports/ledgers under `docs/dev-log/smoke/`.
- `docs/design/229-arc6-composable-bivariate-pairs.md`,
  `docs/design/230-arc6-bivariate-series-overview.md`,
  `docs/design/231-arc6-1-gaussian-bernoulli-contract.md`, and
  `docs/design/232-arc6-2-gaussian-nbinom2-contract.md`.
- `docs/dev-log/2026-07-23-arc6-first-pair-decision-and-design-packet.md`,
  `docs/dev-log/2026-07-23-arc6-latent-normal-research-report.md`,
  `docs/dev-log/2026-07-23-arc6-2-gaussian-nb2-research-report.md`, the Arc
  6.1/6.2 after-task reports, `docs/dev-log/check-log.md`,
  `docs/dev-log/known-limitations.md`, `NEWS.md`, and
  `vignettes/cross-family.Rmd`.

This handover and the dated `AGENTS.md` Latest pointer are the only new
handover changes after `0e512b22`.

## Landing state

The shared handoff gate found two unpushed Arc 6 commits at the start of this
handover. Shinichi then approved the landing: the branch was pushed and merged
through PR #817 as `85cff6fa`. A pre-existing, unrelated unpushed commit `c018908a`
(`docs: close pkgdown reader-surface audit`) is on another branch: do not
stage, push, amend, or otherwise attribute it from the Arc 6 lane.

| Artifact / branch | Committed | Pushed at writing | PR | State |
| --- | --- | --- | --- | --- |
| PR #817 / `main` (`85cff6fa`) | yes | yes | merged | LANDED |
| `codex/arc6-2-gaussian-nb2` (source branch) | yes | yes | #817 merged | LANDED; retained as provenance |
| Other branch `c018908a` | yes | no | none | CARRIED-OVER, foreign lane; do not touch |

## Next immediate steps

1. Begin from current `main`; do not reopen or amend the completed Arc 6.1–6.2
   feature branch.
2. If Shinichi opens Arc 6.3, begin in a **new Codex task/lane** with an
   Ultra Plan, `/ask-brain`, and NotebookLM research. Decide demand, model
   contract, association scale, oracle, comparator, and claim ceiling before
   writing code.
3. Start from the series overview's exact-special-family row. Compare a
   frozen-margin lognormal × lognormal latent-normal density against any
   potential direct joint model; do not assume the latter is automatically
   preferable.
4. Stop after plan review for owner approval. A future implementation lane must
   have its own Rose and Fisher review, distinct smoke, immutable ledger, and
   after-task reconciliation.

## Blockers and open questions

- Owner decision required: whether Arc 6.3 is the demand-led next lane, or
  whether to plan a direct-kernel branch or return to the Q-series.
- If Arc 6.3 proceeds, decide whether the public association is strictly the
  log-residual/latent-normal correlation or whether an additional derived
  raw-scale summary is useful and defensible. Do not decide this from analogy
  to Gaussian `rho12`.

## Gotchas and failed approaches

- Never use a continuous-extension or jittered-PIT shortcut for a discrete
  margin. NB2 association uses the exact CDF jump interval.
- A naive `pnorm()` then `qnbinom()` can round an upper-tail probability to one
  and produce `Inf`; the Arc 6.2 simulator uses matching log-tail quantiles.
- Smoke receipts are construction checks only. They do not establish recovery,
  standard errors, profiles, intervals, coverage, or a capability tier.
- Do not merge or submit the Arc 6 branch merely because the implementation is
  complete. CRAN remains parked.

## Mission control

| Repo | Branch | Evidence | What shipped | Next by leverage |
| --- | --- | --- | --- | --- |
| `drmTMB` | `codex/arc6-2-gaussian-nb2` | 32 NB2 + 26 Bernoulli focused tests; two matched smoke receipts | Fixed-effect frozen-margin Gaussian × Bernoulli and Gaussian × ordinary NB2 | Owner decision and plan-only Arc 6.3 research/design lane |
| `drmTMB` | `claude/handover-freshness-0718` | foreign lane | AGHQ + non-Gaussian REML work | Do not touch from Arc 6 |

Mission Control was updated only to name Arc 6.2 feasibility work; capability
counts and tiers were not changed.

## How to resume

From the repository root, start a fresh Codex task and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-23-codex-arc6-handover.md plus
the AGENTS.md Latest block. Confirm the Arc 6.1–6.2 branch is clean and pushed,
then do not implement Arc 6.3: begin only its demand-led Ultra Plan and
NotebookLM research if the owner has approved planning.
```

Codex should read `AGENTS.md` first, then this handover, the series overview,
the Arc 6.2 contract/research/after-task records, and the current worktree.
For live R work, use the repository's stable invocation:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::load_all(quiet = TRUE)'
```

Codex owns live R/TMB fitting, tests, package checks, simulation, and rendering
when a later approved lane needs them. Planning, prose, and pure-logic review
may be delegated, but Rose is mandatory before a public claim.
