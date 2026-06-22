# After Task: Ayumi Phylo Balance 100-Slice Closeout

## 1. Goal

Close the local 100-slice Ayumi phylogenetic balance research arc while keeping
the next public Ayumi action behind explicit approval.

## 2. Implemented

A001-A098 and A100 are banked in
`docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`. A099 is blocked
because no Ayumi issue reply or draft is allowed in this lane without explicit
maintainer approval.

The arc added route vocabulary, tracker evidence, native ML balance evidence,
native REML asymmetry documentation, Julia bridge readiness rows, q4 truth
rows, Ayumi data-readiness notes, inference and boundary ledgers, literature
and docs synchronization, and a non-postable reply-readiness gate.

## 3a. Decisions and Rejected Alternatives

The main decision is to answer "balanced" as a matrix, not a slogan: native TMB
ML, native TMB REML, R-via-Julia, and direct DRM.jl can differ by model cell,
estimator, target, and inference status.

I rejected a public or private Ayumi reply draft because the handover boundary
forbids one. I also rejected any wording that would turn direct-ready targets,
bootstrap plumbing, or direct DRM.jl source availability into calibrated
Ayumi-scale interval support.

## 4. Files Touched

Major new closeout artifacts:

- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/dashboard/ayumi-phylo-balance-vocabulary.tsv`
- `docs/dev-log/dashboard/ayumi-phylo-balance-trackers.tsv`
- `docs/dev-log/dashboard/ayumi-inference-coverage-ledger.tsv`
- `docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv`
- `docs/design/197-ayumi-phylo-balance-research-100-slices.md`
- `docs/design/198-ayumi-native-ml-balance-summary.md`
- `docs/design/199-native-reml-phylo-asymmetry-gap.md`
- `docs/design/200-ayumi-julia-bridge-balance-readiness.md`
- `docs/design/201-ayumi-bivariate-q4-truth.md`
- `docs/design/202-ayumi-data-readiness-summary.md`
- `docs/design/203-ayumi-inference-gap-ledger.md`
- `docs/design/204-ayumi-literature-docs-summary.md`
- `docs/design/205-ayumi-reply-readiness-gate.md`

Synchronized surfaces include `README.md`,
`docs/design/01-formula-grammar.md`,
`docs/dev-log/known-limitations.md`,
`docs/dev-log/check-log.md`, dashboard JSON, dashboard README, and
`tools/validate-mission-control.py`.

Wave-level after-task reports under `docs/dev-log/after-task/` record the
A001-A099 details.

## 5. Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/drm-status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/drm-sweep.json
tools/validate-mission-control.py
git diff --check
/Users/z3437171/.juliaup/bin/julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot -e 'using DRM; names_to_check = (:fit_q4_sparse_tmb, :profile_sigma_a, :bootstrap_sigma_a, :confint, :drm); for n in names_to_check println(string(n), "=", isdefined(DRM, n)) end'
```

Earlier waves also ran focused R tests for phylogenetic Gaussian ML, native REML
asymmetry, scale-phylo diagnostics, and Julia bridge gates. Full
`devtools::test()` was not rerun for this docs-heavy closeout.

## 6. Tests of the Tests

The new dashboard validator rows check required inference and boundary ledger
IDs, status vocabularies, evidence links, slice ordering, dependencies, and
banked-row evidence. A missing required row or nonexistent evidence path fails
`tools/validate-mission-control.py`.

## 7a. Issue Ledger

No GitHub issue was touched. The external Ayumi issue URL remained unreadable
from this session. Internal tracker rows record the relevant local blockers:
drmTMB#555, drmTMB#570, DRM.jl#291, and DRM.jl#293.

## 8. Consistency Audit

The arc keeps these boundaries consistent:

- REML / AI-REML wording remains exact-Gaussian only.
- q4 Patterson-Thompson REML is not HSquared AI-REML.
- Native TMB q4 REML remains unsupported.
- R bridge promotion remains blocked without native R, direct DRM.jl, and
  R-via-Julia parity.
- Profile target readiness, bootstrap plumbing, and coverage are separate.
- Direct DRM.jl q4 profile/bootstrap machinery is direct Julia evidence only.
- No 10,440-tip sigma-phylo interval claim was added.

## 9. What Did Not Go Smoothly

The tricky part was A091-A099. The planned slice names sounded like reply
drafting, but the active boundary forbids reply drafts. The result is a
readiness gate, with A099 blocked, rather than a hidden draft.

The other useful surprise was direct DRM.jl: q4 profile/bootstrap entry points
are present in the active worktree, but prior direct evidence already records
scale-axis bootstrap undercoverage. That makes the evidence stronger and more
cautious at the same time.

## 10. Known Residuals

Native balanced phylogenetic REML is not implemented. q4 native ML remains
diagnostic. Direct DRM.jl q4 inference is not R bridge support. Coverage is
mostly not evaluated. The raw Ayumi `/tmp` bundle was absent in this session.
No Ayumi reply exists.

## 11. Team Learning

For Ayumi-style balance questions, report by route and target: native ML, native
REML, direct Julia, R-via-Julia, point fit, Wald, profile, bootstrap, coverage,
and applied data design. A single yes/no answer loses the part of the truth the
user most needs.
