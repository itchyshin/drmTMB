# Arc 8 — finite dense known-`V` direct-SD intervals

```text
GOAL
PLATFORM: Codex.
Deliver a local-only, source-pinned feasibility gate for the two dense Gaussian
known-V LSS direct-SD coefficients `sd(study):(Intercept)` and
`sd(study):z_study`. HEADLINE: each coefficient must independently obtain a
finite full `TMB::tmbprofile` likelihood-ratio interval and adequate bootstrap
refit completion before any recovery or coverage proposal. IN PARALLEL: inspect
the existing profile/bootstrap adapters and preserve the all-attempt artefact
contract. DEFER: DRAC/Totoro campaigns, coverage, capability promotion, a new
estimator, endpoint-engine support for fixed effects, DH, eta, bivariate work,
and reader-facing claims. DISCIPLINE: retain the dense K=12 failure control,
use the Gaussian oracle unchanged, keep target-wise denominators, and obtain
fresh Fisher/Rose review before a separate compute request.
```

## What the repository already knows

Arc 7B was merged at `988b2b38`. Its dense LSS K=12 control converged with a
positive-definite Hessian, but both `sd(study)` coefficient profiles were
non-finite. That is retained negative evidence, not an optimizer defect to
hide. Sparse LSS controls had finite profiles, so the open question is whether
the dense route has an interior domain where both targets have a complete
profile procedure.

The existing `confint()` API exposes a scalar endpoint engine, a full
`TMB::tmbprofile` engine, and bootstrap intervals. The endpoint engine supports
scale, random-effect-SD, and correlation targets only; the two Arc 8 targets
are fixed-effect direct-SD coefficients. Arc 8 therefore uses full
`TMB::tmbprofile` as its sole profile-LR route. It does not claim or construct
an endpoint comparison.

## Prior-work sweep receipt

| Surface | Evidence run | Finding | Call forced |
| --- | --- | --- | --- |
| Repository | `git fetch origin main`; `git worktree list`; `git stash list`; `branch_drift_check.sh /private/tmp/drmtmb-arc7b-ci` | Arc 7B is merged; B0 has no unmerged commits; old meta-V branches are stale. The primary checkout is a foreign dirty eta/bivariate lane. | Start a fresh worktree from `988b2b38`; do not resume or edit another lane. |
| Arc 7B source | `docs/design/241-arc7b-meta-v-heterogeneity-ladder-contract.md`; local-sentinel evidence; `inst/sim/run/sim_run_meta_v_lss_smoke.R` | Both dense direct-SD targets are distinct and both failed at K=12; all-attempt reducer already keys by target. | Keep both targets and denominators separate; retain K=12 as a failure control. |
| Sister `DRM.jl` | `git log --all -- src/gaussian_meta.jl` | Gaussian meta-analysis and profile machinery exist, but no matching dense direct-SD feasibility evidence. | No code co-option. |
| Brain | `basic-memory tool search-notes "drmTMB next arc after Arc 7B meta V eta bivariate queue" --hybrid` failed because the local tool could not chmod its config directory; raw `MEMORY.md` meta-V gate was read instead. | The reader/article gate requires end-to-end evidence, not parser/smoke success. | Keep reader-facing work deferred. |

**Verdict:** build only the missing target-wise dense interval-feasibility and
bootstrap-completion evidence. This is not an API, likelihood, or bivariate
arc.

## Decisions locked

- Estimator: existing Gaussian ML `meta_V(V = V)` LSS route only.
- Targets: `sd(study):(Intercept)` and `sd(study):z_study`, assessed
  independently in every cell and summary.
- Profile procedure: explicit full `TMB::tmbprofile`; a finite interval has
  `conf.status == "profile"`, finite ordered endpoints, and contains the
  fitted estimate.
- Bootstrap sidecar: `R = 199` target-wise refits; a feasibility cell needs at
  least 95% finite, successful target draws. This is completion engineering,
  not a replacement interval method or calibration evidence.
- Design: retain dense K=12 as a negative control and add a predeclared dense
  K ladder. The direct Gaussian oracle remains a fit-level gate.
- Compute: local toy/sentinel fits only. No Totoro or DRAC is authorized; a
  later DRAC request needs both target gates plus Fisher/Rose review.

## Slice table

| Slice | Member | Model / effort / dispatch | Output | Depends on |
| --- | --- | --- | --- | --- |
| S0 recon | Ada | Luna low, tiered-cli/enforced | source and target inventory | complete |
| S1 contract | Ada + Noether | Terra high, native/explicit | target-wise feasibility schema and tests | S0 |
| S2 profile adapter | Gauss | Terra high, native/explicit | explicit tmbprofile records and finite-endpoint checks | S1 |
| S3 bootstrap adapter | Curie | Terra medium, native/explicit | target-wise refit-completion diagnostics | S1 |
| S4 local sentinel | Ada | Codex local serial | source-pinned K ladder receipt | S2, S3 |
| S5 plan review | Fisher + Rose | Terra high, native/explicit | target-wise GO/NO-GO verdict | S4 |
| S6 mechanical verify | Ada | Luna low, tiered-cli/enforced | tests, artefact and provenance check | S2--S5 |
| S7 reconcile | Melissa | Terra medium, native/explicit | plan-versus-actual record | S6 |

Luna suitability is yes for the bounded source/artefact inventory and final
mechanical verification. No ultra effort is authorized. The initial execution
budget is at most four producer/review agents; the local sentinel is serial and
not a remote campaign.

## Gates and stop rules

1. The K=12 dense control must remain retained, even if incomplete.
2. Each target must independently have a finite full-profile interval in its
predeclared interior dense cell. A one-target pass is not an LSS pass.
3. Every requested bootstrap draw, fit status, target availability, and
finite-draw status is retained. Fewer than 95% finite successful draws for
either target is a local NO-GO.
4. The source-pinned sentinel receipt records clean SHA, command, host/OS,
R/drmTMB/TMB versions, seed map, DGP cells, both profile results/messages, and
bootstrap results.
5. No coverage/recovery denominator, capability label, public documentation,
or remote job may begin unless Fisher and Rose independently recommend a
separate compute approval.

## Explicit exclusions

This plan does not alter the likelihood, formula grammar, `meta_V()` public
API, DH sensitivity route, eta association work, bivariate models, B0/PR #828,
or reader-facing capability language. A finite local result is feasibility
evidence only and does not establish calibrated intervals or coverage.
