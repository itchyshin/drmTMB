# After Task: Arc 6 programme closure audit

## Goal

Audit the completed Arc 6.1--6.8 programme against its stated boundaries:
source/adapters, retained failed evidence, cross-pair integration, live branch
state, CI, and reader articles.

## Requirement-by-Requirement Evidence

| Requirement | Current evidence | Verdict |
| --- | --- | --- |
| Arc 6.1 Gaussian x Bernoulli adapter and audit | Source `d9dc3116`, contracts 231/232, after-task reports, and merged PR #817 | Complete, bounded |
| Arc 6.2 Gaussian x NB2 adapter and audit | Source `0e512b22`, contract 232, independent conditional-normal interval tests, merged PR #817 | Complete, bounded |
| Arc 6.3 exact bivariate lognormal | Contract 233, after-task report, merged PR #819 | Complete, source-tested only |
| Arc 6.4 exact bivariate Student-t | Contract 234, after-task report, merged PR #820 | Complete, source-tested only |
| Arc 6.5 source and failed all-attempt evidence | Contract 235, PR #821, and retained 220-attempt Totoro receipt; one interior 9/10 cell fails | Complete as HOLD; no recovery/capability claim |
| Arc 6.6 Bernoulli x NB2 adapter | Contract 236, independent rectangle oracle/simulator/fail-closed tests, merged PR #822 | Complete, point-estimate-only |
| Arc 6.7 NB2 x NB2 adapter | Contract 237, independent rectangle oracle/simulator/fail-closed tests, merged PR #823 | Complete, point-estimate-only |
| Arc 6.8 integration after all five pair classes | Contract 238, integration matrix, merged PR #824 | Complete, source integration only |
| Public articles | PR #825 and current main `fa6d1519` have successful pkgdown/deploy checks; both article URLs resolve | Complete for the landed baseline |

## Live GitHub Evidence

At audit time, PRs #817 and #819--#825 were merged to `main`. Their
R-CMD-check rollups were successful. Current `main` was `fa6d1519`, with
successful macOS/Windows matrix, Ubuntu release check, pkgdown, and deployment
jobs. This is live-state evidence, not an inference or coverage result.

## Arc 6.5 HOLD

`docs/dev-log/simulation-artifacts/2026-07-24-arc6-5-bernoulli-recovery/`
retains all 220 attempts: 180 interior and 40 predeclared rare/near-boundary
HOLD rows. The asymmetric-prevalence, `n = 120`, true-`eta = 0.5` interior
cell contains one `boundary_unresolved` replicate, hence 9/10 returned
estimates. The nonzero runner exit, raw ledger, and receipt preserve that
failure. It must not be promoted, rescored, or converted into a capability
claim.

## Boundaries Preserved

No Arc result provides standard errors, intervals, profiles, coverage, random
effects, generic discrete pairs, Julia, CRAN, or a general mixed-family
`rho12`. The exact-special direct models retain their own `rho12` semantics;
the post-fit adapters retain frozen-margin latent-normal `eta` semantics.

## Reader-Facing Follow-up

The landed baseline articles are reachable. A separate local-only reader-first
revision adds a clearer two-stage explanation and a narrowly bounded beta
Bernoulli x NB2 association gradient. It is committed locally as `afbc008c`
for user review and has not been pushed, merged, or represented as part of the
completed Arc 6 programme.

## Closure Verdict

Arc 6.1--6.8 is closed honestly at its stated source/CI/documentation boundary.
The retained Arc 6.5 recovery result remains HOLD. The local reader-first beta
follow-up needs explicit user approval before any upload or new PR.
