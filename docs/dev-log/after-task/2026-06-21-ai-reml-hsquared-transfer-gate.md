# AI-REML HSquared Transfer Gate

## 1. Goal

Bank the HSquared AI-REML scout findings in `drmTMB` without widening any q4,
Laplace, non-Gaussian, or Ayumi-facing claim.

## 2. Implemented

Added `docs/design/178-ai-reml-hsquared-transfer-gate.md`, a contributor-facing
gate note that separates transferable sparse Gaussian mixed-model machinery from
non-transferable q4/non-Gaussian AI-REML wording. Updated the R-Julia finish
matrix so the AI-REML-inspired row points to the new note. Added a check-log
entry recording the read-only scout and the dirty DRM.jl Ayumi checkout
boundary.

Created a clean DRM.jl implementation worktree at
`/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot` and completed the
Gaussian sparse-MME source map there. The first pilot target is now explicit:
the location-only Gaussian phylogenetic mean cell in `DRM.jl/src/location_only.jl`.
The two-structured Gaussian sparse path in `DRM.jl/src/gaussian_structured.jl`
is the second candidate, not the first.

In that clean DRM.jl worktree, added the next two engine slices: an internal
supplied-variance REML objective for the location-only Gaussian phylogenetic mean
cell, a Takahashi selected-inverse trace diagnostic, an AI-vs-observed
information diagnostic, and boundary fixtures with dense-oracle tests.

## 3a. Decisions and Rejected Alternatives

The note treats `hsquared` / `HSquared.jl` as a design analogue for exact
Gaussian MME cells only. It rejects calling bivariate q4, Laplace, or
non-Gaussian routes "AI-REML" until the actual objective has a derivation,
implementation, and validation ladder. It also rejects using the dirty
`DRM.jl` `shannon/ayumi-integration` checkout as an implementation surface,
because that checkout contains parked Ayumi drafts that must be preserved.

## 4. Files Touched

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-21-ai-reml-hsquared-transfer-gate.md`

## 5. Checks Run

Initial orientation and source-map checks:

```sh
sed -n '1,260p' /Users/z3437171/shinichi-brain/AGENTS.md
sed -n '1,260p' /Users/z3437171/shinichi-brain/memory/00-INDEX.md
rg -n "drmTMB|DRM\\.jl|HSquared|hsquared|AI-REML|REML|TMB|Julia" /Users/z3437171/shinichi-brain/memory/PROJECTS.md /Users/z3437171/shinichi-brain/memory/LESSONS.md /Users/z3437171/shinichi-brain/memory/DECISIONS.md
sed -n '1,220p' /Users/z3437171/Dropbox/Github\ Local/DRM.jl/AGENTS.md
git status --short --branch
git log --oneline --decorate -5
git -C /Users/z3437171/Dropbox/Github\ Local/DRM.jl fetch --all --prune
git -C /Users/z3437171/Dropbox/Github\ Local/DRM.jl worktree add -b codex/ai-reml-gaussian-mme-pilot /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot origin/main
git -C /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot status --short --branch
git -C /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot log --oneline -1
sed -n '1,220p' /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/HANDOVER.md
sed -n '1,160p' /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/ROADMAP.md
nl -ba /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/src/location_only.jl | sed -n '1,470p'
nl -ba /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/src/gaussian_structured.jl | sed -n '250,620p'
nl -ba /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/test/test_two_structured_gaussian_sparse.jl | sed -n '1,290p'
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-hsquared-transfer-gate.md docs/design/168-r-julia-finish-capability-matrix.md
```

These checks showed `drmTMB` clean on `main` before branch creation and showed
that the sibling DRM.jl checkout has parked Ayumi drafts on
`shannon/ayumi-integration`. The new DRM.jl worktree is clean on
`codex/ai-reml-gaussian-mme-pilot` at `f46035d`.

Follow-up checks for the final edited state are recorded below and in the final
task summary.

The focused DRM.jl test passed: 36/36 assertions in 5.2 seconds after the
AI-information and boundary fixture additions. `git diff --check` passed in both
worktrees. The claim-boundary scan hit
only expected negative-boundary wording in the new transfer note plus historical
guardrail entries in `docs/dev-log/check-log.md`; no Ayumi reply text was
changed.

Dashboard validation also passed after the final sync:

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8765/status.json | jq '{updated, metrics, active_work: .active_work[0].text, hsquared: (.finish_board[] | select(.id=="HSquared-validation-status-lesson") | {status, engine_julia, docs, evidence_url})}'
```

Mission-control reported `25/68 banked_or_verified`, `1 active`, `17 matrix
rows`, `11 finish rows`, `15 Julia gate rows`, and `9 Julia capability rows`.
The served dashboard reported `updated = "2026-06-21 15:21 MDT"` and the
HSquared row remained `partial`, with `engine_julia = "partial"` and the
transfer note as evidence.

## 6. Tests of the Tests

The DRM.jl worktree now includes `test/test_location_only_reml_mme.jl`, a focused
executable dense-oracle test. The oracle constructs the dense leaf covariance,
profiles `beta` by dense GLS, evaluates the dense ML objective, adds the same
`0.5 logdet(X'V^{-1}X)` restricted penalty, and compares the sparse helper at
1e-8 tolerance. The trace checks compare Takahashi selected-inverse traces
against an explicit dense inverse of `M`. The AI-information diagnostic compares
a candidate Gaussian average-information quadratic with a finite-difference
observed Hessian and records relative disagreement; it does not assert identity.
Boundary fixtures cover weak/zero phylogenetic signal, near-singular tree
precision, and singular fixed-effect information.

## 7a. Issue Ledger

No GitHub issue was changed in this slice. The note names the relevant open
engine blockers for follow-up synchronization: `drmTMB#570`, `DRM.jl#293`,
`drmTMB#555`, and `DRM.jl#291`.

## 8. Consistency Audit

The new wording preserves the existing finish-matrix claim guard that AI-REML
wording belongs only to exact Gaussian REML/MME derivations. It also matches the
Ayumi parked-thread rule: no reply was drafted or sent, and no file under the
dirty DRM.jl `report/finish-audit/` area was touched.

## 9. What Did Not Go Smoothly

The user asked for the "next 10 slices", but the programme crosses two repos
and the active DRM.jl checkout is intentionally dirty with parked Ayumi drafts.
That forced the first slice to be a transfer gate and worktree boundary rather
than direct DRM.jl engine edits.

## 10. Known Residuals

The original ten-slice gate is now complete locally. The next residuals are a
same-estimand external comparator, selected-inverse diagonal/PEV diagnostics, a
real optimizer experiment, validation-status rows, and any bridge schema work
that the maintainer decides to expose.

## 11. Team Learning

HSquared's useful contribution is not permission to use a larger label. It is a
worked example of how to earn a narrow estimator claim: exact Gaussian target,
dense oracle, sparse parity, information check, boundary tests, external or
simulation evidence, and honest status rows.
