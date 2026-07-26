# Session Handoff: Arc C closeout, then Arc D plan-only

**Meta:** 2026-07-26 · **from/to:** Codex → fresh Codex session

## Critical context

You are Codex, picking up a narrow numerical-inference lane in `drmTMB`.
PR #846 merged the **private** general latent-normal association sandwich engine;
do not infer any public `vcov()`, interval, profile, full-refit, recovery,
coverage, bootstrap, simulation, or compute authorization from that merge.

The immediate package lane is Arc C / PR #845. Its A5 beta `mi()` clamp-ordering
repair and A7 citation hardening are independent of F5. F5 was attempted and
correctly reverted because the tight residual clamp manufactured a finite,
vacuous K=12 direct-SD profile interval. Arc D is therefore a **plan-only**
decision about the clamp/profile contract, not an implementation queue.

## Goals and roadmap

The local goal is to close Arc C safely, then decide whether a scale clamp can
participate in profile-likelihood inference without laundering false precision.
The broader 0.7 roadmap keeps the interval-grade campaign (177
`point_fit_recovery` cells), A1 marginal simulation, Arc A2 capability work,
and other Arc B findings in their own lanes. Do not collapse those lanes into
Arc D.

## What was accomplished

- Verified and merged PR #846 to `main` as `1834734a`; its public-inference
  boundary remains intact.
- Reviewed Arc C's exact tip `0209351d`, including its C++ likelihood move and
  the explicit A5 test limitation. Local focused test:
  `arc-c-clamp-hardening` = 9 pass, 0 failures/warnings/skips.
- Obtained independent Fisher and Rose plan reviews: both recommend Arc C
  first, Arc D plan-only second, and retain the K=12 negative-control result.
- Wrote and pushed the Arc D ultra-plan and this handover on
  `codex/arc-d-inference-contract-plan`.

## Current working state

- **Working:** Arc C branch `claude/arc-c-hardening` is clean at `0209351d`.
  PR #845 is open against `main` (which includes #846). The lightweight
  `os-matrix` check passed; GitHub's normal `ubuntu-latest (release)` package
  check was in progress when this handover was updated. Refresh live state.
- **Working:** Arc D documentation branch
  `origin/codex/arc-d-inference-contract-plan` at `cb39b977` is committed and
  pushed. It contains no C++/R behaviour change.
- **Blocked:** Arc C may not merge until that exact-tip release check passes
  and review preserves the A5/F5 limitations. Arc D may not implement any
  option until Shinichi selects one at D1.

## Key decisions and rationale

1. **Merge Arc C before Arc D.** Arc C narrowly resolves A5/A7 and does not
   change public inference. Arc D is a separate inferential-contract question.
2. **F5 is not a routine clamp repair.** With `logsigma_clamp = c(-12, 12)`,
   the known dense K=12 meta-V LSS non-identification becomes a finite
   `[-4.1428, 27.7859]` direct-SD profile; widening to `c(-200, 200)` restores
   `profile_failed`. The bound, not data, supplied the endpoint.
3. **A5 evidence is structural, not behavioural.** Its new test exercises the
   beta `mi()` branch and the clamp bound, but it also passes pre-repair. Do
   not describe it as empirical falsification.
4. **Do not change the AGENTS snapshot pointer here.** The repository has
   concurrent A1/Arc C/other lanes; the existing dated snapshot and its linked
   multi-lane handover remain the coordination entrypoint. This handover is an
   additive lane record, not a replacement pointer.

## Mission-control summary

| Lane | Branch / PR | State | Next leverage step |
| --- | --- | --- | --- |
| Private association sandwich | merged #846 `1834734a` | private implementation only | hold all validation/public inference |
| Arc B audit | merged #842 | audit complete | retain findings and separate repair lanes |
| Arc C A5/A7 | `claude/arc-c-hardening`, #845 | CI/review gated | wait for green, review, merge, verify main |
| Arc D F5 contract | `codex/arc-d-inference-contract-plan` `cb39b977` | plan-only | D0 inventory, then D1 owner decision |

## Landing state

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/arc-d-inference-contract-plan` `cb39b977` | yes | yes | none | LANDED planning handover |
| `claude/arc-c-hardening` `0209351d` | yes | yes | #845 open | CARRIED-OVER: awaiting release CI/review |
| `claude/arc-a-external-comparator-evidence` | yes | no | none | CARRIED-OVER, foreign: do not touch |
| `codex/arc6-6-bernoulli-nb2-plan` | yes | no | none | CARRIED-OVER, foreign: do not touch |

`handoff_gate.sh` reports 17 unpushed commits on those pre-existing foreign
branches. They are declared above and are outside this lane; do not clean,
merge, rebase, or push them.

## Files created / modified

- `docs/dev-log/2026-07-26-arc-d-scale-clamp-profile-contract-ultra-plan.md`
- `docs/dev-log/handover/2026-07-26-codex-arc-d-plan-handover.md`

No code, tests, public API, capability ledger, or AGENTS snapshot was modified
on this Arc D planning branch.

## Next immediate steps

1. Refresh #845 with `gh pr checks 845 --repo itchyshin/drmTMB` and confirm the
   green check belongs to tip `0209351d`.
2. Review the PR against the two retained limitations: A5 structural evidence;
   F5 negative-control reversion. Merge only if both are intact.
3. Verify the actual merged-main commit and its CI before calling Arc C closed.
4. Create a fresh worktree from merged `main` for D0, the read-only inventory
   of all nine `sd()` predictor `exp()` sites and their fit/profile/status
   consumers.
5. Stop after D1's three-design comparison until Shinichi selects a contract
   in writing. Only then request approval for D2 implementation.

## Blockers / open questions

- GitHub's `ubuntu-latest (release)` check for #845 was still running at the
  last check. It is a normal package-check step, not a known failure.
- Which D1 design should govern clamp-shaped endpoints: overflow-only guard,
  explicit `clamp_limited` status, or clamp-fit/unclamped-profile? This is an
  owner decision after D0/D1 evidence, not a default.

## Gotchas and failed approaches

- Do not retry “reuse `drm_softclamp_log_sigma()` at the nine sites.” It is
  falsified by the K=12 negative control.
- Do not call a finite interval evidence of identification without checking
  whether the endpoint meets a clamp bound.
- Do not turn the A5 test into a behavioural claim: its pre-repair pass is
  documented and intentional.
- Never run simulation/recovery/coverage/full-refit work on GitHub Actions;
  any approved campaign belongs on Totoro or DRAC.

## How to resume

From a fresh Codex task in the `drmTMB` project, select the worktree branch
`codex/arc-d-inference-contract-plan` and paste:

```text
Read AGENTS.md, then docs/dev-log/handover/2026-07-26-codex-arc-d-plan-handover.md
and docs/dev-log/2026-07-26-arc-d-scale-clamp-profile-contract-ultra-plan.md.
First refresh and safely close PR #845 if its exact-tip CI is green; then begin
D0 read-only only. Do not implement F5 or expose association sandwich inference.
```

For local R work, use `R_PROFILE_USER=/dev/null Rscript --no-init-file` when a
clean R startup is needed. Codex owns live R/TMB fits, package checks, and any
later approved compute; this handover authorizes none of those beyond the
focused local Arc C test already recorded.
