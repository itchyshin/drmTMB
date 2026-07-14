# Session Handoff: PR #780 merge authorization and post-merge arc routing

Meta: 2026-07-14 · from Codex to a new Codex session · PR #780

You are Codex, picking up a completed PR #780 merge-disposition task. Read
`AGENTS.md` first, then this file and the two linked closeout reports. The
repository and live GitHub state are technical truth; do not infer current
state from older handoffs.

## Critical Context

PR #780's repaired implementation and claim tree is fully green at verified
ancestor `1dd79228c33e67065f9071f3e400940305a7dd1c`. This handoff and the refreshed
`AGENTS.md` pointer are a docs-only successor commit on the same branch, so
resolve the live PR head dynamically and confirm it contains `1dd79228`. The
evidence-backed disposition is **recommend merge**, but the pull request remains
open and unmerged. Do **not** merge it until Shinichi gives a separate explicit
instruction such as `merge PR #780`.

The repaired Q-Series truth is 27/37 non-Gaussian recovery rows plus 10/37
diagnostic-only rows. Diagnostic-only routes establish fit/extractor
feasibility, not point-estimate recovery. Arc 1a remains exact-Gaussian,
univariate, pure-`mu`, `sigma ~ 1`, with no sigma random effect, and only the
documented unlabelled intercept or independent one-slope
`spatial()`/`animal()`/`relmat()` routes over discrete tested domains.

## Goals / Mission

Preserve the verified merge disposition without widening claims. If Shinichi
explicitly authorizes the merge, recheck the exact remote head, green CI, and
mergeability, merge PR #780, synchronize a clean updated `main`, then determine
the next arc from that updated `main`. Any next arc begins with a copy-paste
`GOAL` and ultra-plan and waits for separate plan approval before execution.

## What Was Accomplished

- Repaired structured-effect SD/covariance semantics class-wide:
  coefficient covariance is `s_j^2 K_h`, node marginal SD is
  `s_j sqrt(K_h[ii])`, and slope SD units include the predictor denominator.
- Corrected Q-Series accounting from an overclaimed 37 recovery rows to 27
  recovery plus 10 diagnostic-only rows.
- Corrected both fixed-`zi` Poisson/NB2 spatial-`mu` gates across source,
  generated, rendered, and LLM-facing surfaces.
- Strengthened semantic and R regression guards; all 33 capability semantic
  tests pass.
- Full `devtools::test()`: 0 failures, 0 errors, 62 expected warnings, 24
  expected skips.
- Genuine `--as-cran`: normalized 0 errors, 0 warnings, 0 notes.
- `pkgdown::check_pkgdown()`: no problems.
- Final GitHub run
  [29341629495](https://github.com/itchyshin/drmTMB/actions/runs/29341629495)
  is green for `os-matrix`, clean-checkout capability validation, and
  `ubuntu-latest (release)`.
- Fisher, Pat, and Rose returned DONE on the repaired claim tree; Rose then
  returned DONE on final pushed head `1dd79228`.
- PR body and live Mission Control at <http://127.0.0.1:8823/> were refreshed.
- No issue was edited or closed, no external artifact was refreshed, no Totoro
  campaign was rerun, and no merge was performed.

Authoritative detail:

- `docs/dev-log/after-task/2026-07-14-pr780-claim-surface-repair.md`
- `docs/dev-log/handover/2026-07-14-pr780-repair-disposition-handover.md`

## Current Working State

- **Working:** branch `feature/arc1a-gaussian-reml-providers` contains verified
  implementation ancestor `1dd79228` plus this docs-only handoff successor.
- **Working:** before the handoff commit, PR #780 was open, non-draft,
  `mergeStateStatus=CLEAN`, with both checks green. Re-read current head CI after
  the handoff push; a new documentation-only run may be pending.
- **Working:** Mission Control states “recommended to merge, remains unmerged”
  and names explicit merge authorization as the only blocker.
- **In progress:** nothing. This is a decision boundary.
- **Blocked:** merge requires Shinichi's separate explicit authorization.
- **Out of scope:** external `a1bf21a1` mirror, new compute, issue closure,
  and next-arc implementation.

## Key Decisions and Rationale

- The merge recommendation is based on repository evidence, full local checks,
  final-head GitHub CI, and independent review—not the external mirror.
- Diagnostic-only must remain a typed evidence tier; never infer recovery from
  convergence or extractor availability.
- The legacy `basic_distribution_recovery` track ID structurally contains 27
  recovery and 10 diagnostic-only rows; row-level `fit_status` is
  authoritative.
- This arc does **not** cover non-Gaussian REML, bivariate REML, labelled,
  multiple, or slope-only routes, matched `mu+sigma` structured effects,
  sigma random effects, estimated spatial range, broad matrix geometries, or a
  `supported` promotion.
- Issue #147 closes only through an actual merge of PR #780.

## Mission Control

| Repository | Branch / main | CI | What shipped | Plan by leverage |
| --- | --- | --- | --- | --- |
| drmTMB | `feature/arc1a-gaussian-reml-providers`; verified ancestor `1dd79228` plus docs-only handoff commit; PR #780 open | Run 29341629495 green for `1dd79228`; verify handoff-head rerun live | Arc 1a plus repaired claim surfaces and 27/10 evidence split | Await explicit merge authorization |
| drmTMB `main` | Not yet updated with PR #780 | Existing main state | No Arc 1a merge yet | After an authorized merge, sync main and determine next arc from updated main |
| External capability mirror | `a1bf21a1` pending | Not used as evidence | Nothing claimed refreshed | Separate carried-over task only if explicitly requested |

## Landing State

The handoff gate confirms the active branch is committed and pushed but returns
nonzero because 358 unrelated pre-existing local branches contain commits absent
from their configured upstreams. They are protected user state and are
explicitly carried over; do not modify them.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | ---: | ---: | --- | --- |
| `feature/arc1a-gaussian-reml-providers`; verified ancestor `1dd79228` plus handoff commit | yes | yes after the handoff push | #780 open | LANDED on remote; verify current head/CI, then merge awaits explicit authorization |
| External `a1bf21a1` mirror | n/a | no | n/a | CARRIED-OVER; outside this task |
| 358 unrelated local branches | mixed | mixed | mixed | CARRIED-OVER protected user state; do not stage, push, delete, merge, or rewrite |

To reproduce the protected-branch inventory:

```sh
/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/handoff_gate.sh \
  /Users/z3437171/.codex/worktrees/arc1a-gaussian-reml-providers
```

## Files Created / Modified

Complete branch manifest relative to `origin/main`, plus this new handoff:

```text
.gitattributes
AGENTS.md
NEWS.md
R/drmTMB.R
R/julia-bridge.R
README.md
ROADMAP.md
docs/design/01-formula-grammar.md
docs/design/02-family-registry.md
docs/design/03-likelihoods.md
docs/design/04-random-effects.md
docs/design/06-distribution-roadmap.md
docs/design/09-phylogenetic-and-spatial-speed.md
docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md
docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md
docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md
docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md
docs/design/143-phase-18-structured-workflow-registry.md
docs/design/144-phase6c-gaussian-random-slope-ademp.md
docs/design/148-phase6c-random-slope-simulation-plan.md
docs/design/148-phase6c-structured-one-slope-ademp.md
docs/design/151-phase6c-random-slope-tutorial-ledger.md
docs/design/152-phase6c-random-slope-sprint-closeout.md
docs/design/157-capability-completion-worklist.md
docs/design/16-phylo-spatial-common-math.md
docs/design/168-gaussian-reml-first-slice.md
docs/design/168-r-julia-finish-capability-matrix.md
docs/design/181-q4-target-estimator-inventory.md
docs/design/182-univariate-phylo-balance-inventory.md
docs/design/183-phylo-q2-q4-target-map.md
docs/design/197-ayumi-phylo-balance-research-100-slices.md
docs/design/198-ayumi-native-ml-balance-summary.md
docs/design/199-native-reml-phylo-asymmetry-gap.md
docs/design/200-ayumi-julia-bridge-balance-readiness.md
docs/design/201-ayumi-bivariate-q4-truth.md
docs/design/203-ayumi-inference-gap-ledger.md
docs/design/204-ayumi-literature-docs-summary.md
docs/design/205-ayumi-reply-readiness-gate.md
docs/design/206-ayumi-follow-on-implementation-slices.md
docs/design/210-structured-slope-status.md
docs/design/211-structured-reml-status.md
docs/design/218-structured-q-series-completion-map.md
docs/design/25-ordinal-scale-discrimination.md
docs/design/32-phase-6b-tutorial-source-map.md
docs/design/33-phase-6c-core-random-effects.md
docs/design/34-validation-debt-register.md
docs/design/37-worked-example-inventory.md
docs/design/41-phase-18-simulation-programme.md
docs/design/45-cross-dpar-correlation-gate.md
docs/design/46-pre-simulation-readiness-matrix.md
docs/design/51-phase-18-ordinal-fixed-effect-ademp.md
docs/design/57-structural-parity-next-slices.md
docs/design/58-phase-18-animal-relmat-q4-ademp.md
docs/design/59-structural-slope-and-non-gaussian-map.md
docs/design/61-structural-parity-slices-83-140.md
docs/design/64-implementation-map-slices-326-340.md
docs/design/65-implementation-map-slices-341-355.md
docs/design/66-implementation-map-slices-356-405.md
docs/design/67-sdstar-p8-poisson-q1.md
docs/design/70-phase-18-poisson-structured-q1-ademp.md
docs/design/71-nongaussian-structured-issue-ledger.md
docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md
docs/design/79-supported-nongaussian-evidence-goal.md
docs/design/80-four-week-random-slope-digital-twin-sprint.md
docs/dev-log/2026-07-12-0.6.0-candidate-arcs-plan.md
docs/dev-log/2026-07-13-next-arcs-codex-campaign-plan.md
docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-inference-ready.md
docs/dev-log/after-task/2026-07-13-arc1a-gaussian-reml-providers.md
docs/dev-log/after-task/2026-07-14-pr780-claim-surface-repair.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/README.md
docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv
docs/dev-log/dashboard/ayumi-inference-coverage-ledger.tsv
docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv
docs/dev-log/dashboard/ayumi-phylo-balance-trackers.tsv
docs/dev-log/dashboard/ayumi-phylo-balance-vocabulary.tsv
docs/dev-log/dashboard/bridge-parity-smoke-status.tsv
docs/dev-log/dashboard/bridge-payload-schema.tsv
docs/dev-log/dashboard/capability-census/_master.tsv
docs/dev-log/dashboard/capability-census/_widget_data.json
docs/dev-log/dashboard/capability-census/biv_gaussian.tsv
docs/dev-log/dashboard/capability-census/cumulative_logit.tsv
docs/dev-log/dashboard/capability-census/gaussian.tsv
docs/dev-log/dashboard/capability-census/hurdle_nbinom2.tsv
docs/dev-log/dashboard/capability-census/student.tsv
docs/dev-log/dashboard/capability-census/zi_poisson.tsv
docs/dev-log/dashboard/capability-ledger/cells.tsv
docs/dev-log/dashboard/capability-ledger/evidence.tsv
docs/dev-log/dashboard/capability-ledger/transitions.tsv
docs/dev-log/dashboard/capability-surface.html
docs/dev-log/dashboard/capability-surface.md
docs/dev-log/dashboard/estimator-surface-conformance.tsv
docs/dev-log/dashboard/julia-capabilities.tsv
docs/dev-log/dashboard/member-wave-assignments.tsv
docs/dev-log/dashboard/phylo-balance-inventory.tsv
docs/dev-log/dashboard/phylo-q2-q4-target-map.tsv
docs/dev-log/dashboard/q4-target-inventory.tsv
docs/dev-log/dashboard/structured-re-ayumi-closeout-status.tsv
docs/dev-log/dashboard/structured-re-balance-100-slices.tsv
docs/dev-log/dashboard/structured-re-closeout-package.tsv
docs/dev-log/dashboard/structured-re-conversion-200-slices.tsv
docs/dev-log/dashboard/structured-re-executable-evidence.tsv
docs/dev-log/dashboard/structured-re-finish-100-slices.tsv
docs/dev-log/dashboard/structured-re-native-reml-scope-status.tsv
docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv
docs/dev-log/dashboard/structured-re-q-series-inference-evidence-summary.tsv
docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv
docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv
docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv
docs/dev-log/dashboard/structured-re-q2-bridge-boundary.tsv
docs/dev-log/dashboard/structured-re-q2-native-evidence.tsv
docs/dev-log/dashboard/structured-re-q2-payload-contract.tsv
docs/dev-log/dashboard/structured-re-q2-target-contract.tsv
docs/dev-log/dashboard/structured-re-q4-bridge-boundary.tsv
docs/dev-log/dashboard/structured-re-q4-reml-requested-effective-audit.tsv
docs/dev-log/dashboard/structured-re-q4-target-contract.tsv
docs/dev-log/dashboard/structured-re-reml-scope-gate.tsv
docs/dev-log/dashboard/structured-re-scope-gate-status.tsv
docs/dev-log/handover/2026-07-13-arc1a-claude-handover.md
docs/dev-log/handover/2026-07-14-pr780-repair-disposition-handover.md
docs/dev-log/known-limitations.md
docs/dev-log/release-audits/q-series-v1-preflight-report.md
docs/dev-log/release-audits/q-series-v1-release-status.md
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/README.md
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/arc1a-cells.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/arc1a-seed-pool.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-artifact-hashes.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-campaign.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-fit-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-launch.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-raw.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-run-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-seed-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-artifact-hashes.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-campaign.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-fit-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-launch.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-paired-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-raw.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-run-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-seed-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/session-info.txt
docs/dev-log/team-improvements.md
inst/extdata/julia-capabilities.tsv
man/drmTMB.Rd
tests/testthat/test-estimator-surface-conformance.R
tests/testthat/test-reml-scale-structured.R
tests/testthat/test-reml-structured-location.R
tests/testthat/test-structured-re-conversion-contracts.R
tools/capability_ledger.py
tools/qseries_v1_claim_guard.py
tools/qseries_v1_release_check.py
tools/qseries_v1_release_ledger.py
tools/run-arc1a-gaussian-reml-provider-campaign.R
tools/summarize-arc1a-gaussian-reml-provider-campaign.R
tools/tests/test_capability_ledger.py
tools/validate-mission-control.py
vignettes/animal-models.Rmd
vignettes/bivariate-coscale.Rmd
vignettes/capability-and-limits.Rmd
vignettes/count-nbinom2.Rmd
vignettes/distribution-families.Rmd
vignettes/drmTMB.Rmd
vignettes/formula-grammar.Rmd
vignettes/implementation-map.Rmd
vignettes/includes/capability-ledger-family-map.md
vignettes/model-map.Rmd
vignettes/model-workflow.Rmd
vignettes/phylogenetic-models.Rmd
vignettes/phylogenetic-spatial.Rmd
vignettes/proportion-beta-binomial.Rmd
vignettes/relmat-known-matrices.Rmd
vignettes/source-map.Rmd
vignettes/spatial-models.Rmd
vignettes/structural-dependence.Rmd
vignettes/which-scale.Rmd
docs/dev-log/handover/2026-07-14-codex-handover.md
```

## Plans / Roadmap

1. Await explicit merge authorization. Do not treat this handoff request as
   merge authorization.
2. If authorization arrives, verify PR head, CI, and mergeability immediately
   before merging.
3. Merge PR #780, synchronize a clean updated `main`, and confirm issue #147
   closed only as GitHub's merge consequence.
4. Rehydrate again from updated `main`, inspect current open PRs/issues and
   roadmap truth, then propose the next arc with a copy-paste `GOAL` and
   ultra-plan.
5. Wait for explicit plan approval before any next-arc implementation, compute,
   publication, commit, push, or PR.

## Next Immediate Steps

Run these read-only checks first:

```sh
cd /Users/z3437171/.codex/worktrees/arc1a-gaussian-reml-providers
git status --short --branch
git rev-parse HEAD
git rev-parse origin/feature/arc1a-gaussian-reml-providers
gh pr view 780 --json state,isDraft,headRefOid,mergeStateStatus,statusCheckRollup,url
curl -fsS http://127.0.0.1:8823/home.json
```

Expected ancestry: `git merge-base --is-ancestor 1dd79228 HEAD` succeeds, local
HEAD equals the remote PR head, and only this handoff plus the `AGENTS.md`
pointer follow `1dd79228`. Expected PR state: open and mergeable. If the
handoff-only head CI is pending, wait; if it is red, inspect it. Then wait for
Shinichi's instruction.

## Blockers / Open Questions

- **Only blocker:** explicit authorization to merge PR #780.
- Whether and when to refresh external artifact `a1bf21a1` remains a separate
  request.
- The next arc is deliberately undecided until PR #780 is resolved and
  `main` is updated.

## Gotchas and Failed Approaches

- Two earlier final-head runs were red. The substantive clean-checkout failure
  came from a semantic test unconditionally reading ignored local
  `pkgdown-site/llms.txt`. The guard now always checks tracked README/vignette
  sources and additionally checks ignored rendered/LLM surfaces when a local
  pkgdown build exists. Final run 29341629495 proves the clean-checkout path.
- Do not interpret the red historical Actions rows as the current head; verify
  the exact run/head.
- Do not use `pkgdown-site/` as load-bearing tracked evidence; it is ignored.
  The tracked sources and generated capability outputs are authoritative, with
  local rendered read-back as an additional check.
- Do not broaden discrete Arc 1a evidence into continuous-domain support.
- Run R with `R_PROFILE_USER=/dev/null` and `--no-init-file`; the user
  profile can select an incompatible library.
- No heavy simulation is authorized. Any future campaign belongs on
  Totoro/DRAC, never GitHub Actions.

## Codex Live-Toolchain Environment

Codex owns any required live R/TMB verification in the receiving session:

```sh
export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
Rscript --no-init-file -e 'devtools::test()'
Rscript --no-init-file -e 'devtools::check(args = "--as-cran", error_on = "never")'
Rscript --no-init-file -e 'pkgdown::check_pkgdown()'
```

Do not rerun these expensive gates merely to rehydrate; the final evidence is
already green. Rerun only if the tree changes or live state becomes uncertain.
Use `.codex/agents/*.toml`; Rose is mandatory before changing a public claim.

## How to Resume

Start a fresh Codex session in the drmTMB project and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-14-codex-handover.md + the AGENTS.md snapshot. Verify PR #780 remains open, contains verified ancestor 1dd79228, and has green current-head CI; wait if the docs-only handoff run is pending. Then wait for explicit merge authorization. Do not merge or start the next arc without it.
```
