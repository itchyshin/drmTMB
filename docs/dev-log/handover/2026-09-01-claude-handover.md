# Session Handoff: Ayumi Julia-bridge parity repair

Meta: 2026-09-01 · from Codex · target Claude / Fable · working directory
`/private/tmp/drmtmb-control-audit`

## Critical Context

Shinichi paused the wider Julia–R parity programme to resolve Ayumi's two
public issue comments before drafting replies. Do not send a reply or make a
public performance claim. The immediate objective is evidence for
[`Ayumi-495/LS_ecogeographical-rules#28`](https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/28#issuecomment-5472354858)
and [#29](https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/29),
then draft replies for Shinichi to review.

The programme objective remains: make every implemented native-R workflow
available in direct Julia and through `engine = "julia"`, with retained parity,
inference, performance, and documentation evidence. The approved plan is
evidence-gated: functional parity before performance claims; matched warm
workflows; no generic ``5,000 species'' limit; no long campaign without an
estimate, pre-run, and approval. Continue with `ultra-plan` and `unlazy` at
programme scale, but keep the next implementation slice narrow.

## What Was Accomplished

1. Repaired a q4 bridge blocker in the carried-over diff: bivariate parameter
   aliases such as `sigma1`, `sigma2`, and `rho12` were mistakenly demanded as
   columns in `data` when users wrote the fully explicit native syntax
   `sigma1 = sigma1 ~ ...`. The needed-column collector now takes response
   columns only from `mu`, `mu1`, and `mu2`; non-mean formula left-hand sides
   are parameter labels.
2. Added a regression test that failed before the repair with the exact error
   `could not find model variables "sigma1", "sigma2", and "rho12" in data` and
   passes after it.
3. Prior landed bridge work on this branch (`bbe33d23e`) maps generic
   `optimizer$g_tol` to q4's real `q4_g_tol` and rejects the non-equivalent
   `optimizer$algorithm` setting clearly. It does **not** make the TMB robust
   preset equivalent to the Julia q4 solver.
4. Prior landed DRM.jl work on `codex/julia-bridge-route-diagnostic`, PR #573,
   scales q4 phylogenetic initial values by mean tree depth. A deep raw-tree
   fixture no longer begins at non-finite NLL/gradient. A q4 bootstrap repair
   also now discards nonconverged refits instead of including them in percentile
   endpoints.
5. Established bounded evidence already available:
   - a synthetic nonbinary ultrametric q4 `engine = "julia"` fit succeeded;
     a counterpart with spaces in labels also succeeded;
   - ordinary `Rscript` is allowed unless a real R-CMD-check marker is present,
     and an unopted synthetic q4 script succeeded;
   - q4 profile calls run only when all q4 SD targets are requested together;
     a raw 343-tip diagnostic profile completed but had unbounded upper ends,
     so it is execution evidence only, not profile parity or a speed claim;
   - bridge diagnostics are exposed in `fit$bridge$diagnostic`, but their scale
     is not raw-TMB-gradient comparable.

## Current Working State

- **Working:** the focused needed-column regression test passes.
- **In progress:** a deterministic native TMB-versus-Julia q4 REML fixture
  check, `/private/tmp/q4-fixture-bridge-parity.R`, was restarted after the
  alias repair. It initialized Julia but emitted no final comparison line. It
  was deliberately stopped; its temporary log is
  `/private/tmp/q4-fixture-bridge-parity.log`. This is **inconclusive**, not a
  parity pass or failure.
- **Blocked only for exact Ayumi reproduction:** her repository contains the
  full 10,440-row / 10,970-tip data but no committed recipe for the specific
  343-tip validation subset. Do not substitute a random subset and call it her
  validation. Ask for or locate her exact script/reproducer if same-fixture
  evidence is required.
- **Protected:** do not mass-clean worktrees, stashes, or unrelated unpushed
  branches. The handoff gate listed numerous unrelated unpushed branches; they
  are outside this lane.

## Key Decisions and Rationale

- Treat any run without a final retained result as inconclusive.
- Preserve the optional-backend contract: Julia remains optional through
  `engine = "julia"`; do not imply it is required for drmTMB or CRAN.
- Do not claim all controls, profile results, bootstrap uncertainty, or
  polytomy behaviour are equivalent from a point-fit success.
- Keep genuine Julia q4 controls explicit. A clear refusal is better than
  silently accepting a TMB-only control.
- Polytomies are supported only subject to the current ultrametric and
  positive-branch validation contract; the observed synthetic success does not
  establish all native-tree cases.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `drmTMB` `codex/rebase-julia-optimizer-controls` (this repair and this handover) | yes after this handover commit | yes after push | [#1112](https://github.com/itchyshin/drmTMB/pull/1112) | LANDED |
| DRM.jl `codex/julia-bridge-route-diagnostic` `04e3e5d1` | yes | yes | [#573](https://github.com/itchyshin/DRM.jl/pull/573) | LANDED, separate repo/lane |
| `/private/tmp/q4-fixture-bridge-parity.R` and `.log` | no | no | none | CARRIED-OVER: disposable diagnostic outside the repository; resume with the command below, not by staging it |

FINDINGS-OF-RECORD: none. The explicit bivariate non-mean-alias finding is
retained in this repository handover and regression test; no personal-vault
memory update was authorized in this session.

## Next Immediate Steps

1. Rehydrate, run lane preflight, inspect the current branch and this document,
   and classify all items `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`.
2. Confirm the pushed repair with:
   ```sh
   Rscript -e 'devtools::load_all("/private/tmp/drmtmb-control-audit", quiet=TRUE); testthat::test_file("/private/tmp/drmtmb-control-audit/tests/testthat/test-julia-bridge.R", reporter="summary")'
   ```
3. Diagnose the fixture script before retrying: add durable result capture or
   execute each native TMB and Julia step separately so an early R/Julia exit
   cannot hide the final comparator. Estimate the run first; it is expected to
   be below 10 minutes, but stop and report if it exceeds that.
4. Compare a matched control contract. The fixture currently requests TMB
   `optimizer_preset = "robust"`, for which Julia deliberately has no equivalent;
   measure a shared baseline separately before interpreting deltas.
5. Run a small convergent q4 bootstrap/profile check only after point parity is
   established. Profile/bootstrapping are Ayumi's stated concern. Do not launch
   a campaign over 30 minutes without Shinichi's approved pre-run gate.
6. Obtain/locate Ayumi's exact 343-tip recipe before claiming her same-data
   validation is resolved. Then prepare, but do not post, reply drafts covering
   each issue bullet with links to retained evidence and residual boundaries.

## Plans / Roadmap Beyond This Slice

The approved first pass retains these gates: G0 scope/owners; G1 recovery; G2
functional parity; G3 numerical/inference; G4 parallel correctness; G5 matched
warm-workflow performance; G6 documentation; G7 integration; G8 Melissa
reconciliation. Current work is within G2/G3 for the R bridge. The original
programme estimate was 157–297 active agent-hours (80–150 working elapsed
hours), plus an 8–20 hour bounded optimization reserve. This must be
re-estimated from the frozen manifest, not represented as a delivery promise.

## Blockers / Open Questions

- Is the absent q4 fixture result a JuliaCall process-lifecycle problem,
  an error hidden by the call, or simply output capture? It has not been
  diagnosed.
- CI status for #1112 must be checked live; do not infer it from old screenshots.
- The exact 343-tip Ayumi validation sampler is absent from the checked
  repository history searched so far.
- q4 profile and bootstrap parity remain unverified. Point-estimate success
  does not settle them.

## Gotchas & Failed Approaches

- Calling `confint()` for q4 with a single target is invalid: request all q4 SD
  targets from `profile_targets(fit)$parm`.
- A raw random 343-tip subset is a diagnostic only; it cannot stand in for
  Ayumi's named validation set.
- A previous attempt used `Pkg.test(test_args=...)`, which did not filter as
  intended and began the full suite. Use direct focused test-file inclusion for
  Julia tests when appropriate.
- The R `optimizer_preset = "robust"` is an nlminb/progressive-ladder policy,
  not a Julia q4 solver setting.

## How to Resume

Claude is best placed to plan, refactor, write the evidence ledger, and conduct
the independent review. Codex should take any remaining live R/TMB/Julia fit,
compiled test, or benchmark that Claude cannot execute locally.

```sh
cd /private/tmp/drmtmb-control-audit && claude "Read AGENTS.md and docs/dev-log/handover/2026-09-01-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps. Use Fable and ultra-plan/unlazy for the wider programme, but keep the current Ayumi bridge repair narrow."
```

Paste-ready instruction for an already-open Claude session:

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-01-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
