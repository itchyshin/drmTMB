# After Task: AI-REML Post-Gate Exact-Gaussian Slices

## Goal

Run the next ten local slices after the HSquared transfer gate while keeping the
claim boundary exact-Gaussian-only and preserving the parked Ayumi drafts.

## Implemented

In the clean DRM.jl worktree, added a finite-difference REML optimizer
diagnostic, selected-inverse posterior-variance diagnostic, validation/status
tuple, bridge payload draft tuple, and micro scaling smoke for the location-only
Gaussian phylogenetic mean cell.

In drmTMB, added a local issue-comment draft for `DRM.jl#291` / `drmTMB#555`,
added a q4-specific note explaining why q4 Patterson-Thompson is not HSquared
AI-REML, refreshed the transfer note, and updated the dashboard/check-log.

## Mathematical Contract

The implemented code still targets only the exact Gaussian location-only
phylogenetic mean model. The optimizer experiment minimizes the restricted
objective using finite-difference gradients and explicitly reports
`ai_reml_ready = false`. The q4 note keeps Patterson-Thompson q4 language
separate from HSquared average-information language.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/issue-drafts/2026-06-21-drmjl291-drmtmb555-ai-reml-postgate.md`
- `docs/dev-log/after-task/2026-06-21-ai-reml-postgate-slices.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
tools/start-mission-control.sh --background
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-postgate-slices.md docs/dev-log/issue-drafts/2026-06-21-drmjl291-drmtmb555-ai-reml-postgate.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 88/88 assertions in 6.2 seconds.

## Tests Of The Tests

The PEV diagnostic is checked against a dense inverse on the tiny Gaussian
fixture. The optimizer test must improve or match a supplied finite objective
while preserving the negative claim that no AI-REML implementation exists. The
schema/status test guards the future bridge vocabulary before any R field is
introduced.

## Consistency Audit

The public-facing boundary stays unchanged: q4, Laplace, and non-Gaussian routes
keep observed-information/profile/bootstrap or method-specific language. The
dashboard row is still `partial`, and no release, interval, bridge, or Ayumi
claim is promoted.

## GitHub Issue Maintenance

No GitHub issue was posted or edited. A local draft is saved under
`docs/dev-log/issue-drafts/` for maintainer review.

## What Did Not Go Smoothly

The requested ten slices cross the DRM.jl engine worktree and the drmTMB
mission-control docs. Keeping the code evidence, bridge vocabulary, q4 boundary,
and issue draft aligned required a second after-task report instead of extending
the earlier transfer-gate report in place.

## Team Learning

The most useful bridge artifact is a small schema with negative status fields.
`ai_reml_ready = false` is as important as the finite optimizer result.

## Known Limitations

No full DRM.jl suite or drmTMB R package suite was run. No external package
comparator was added beyond the dense GLS same-estimand oracle. The R bridge
schema is not wired into a fitted drmTMB object.

## Next Actions

Decide whether to turn the finite-difference optimizer experiment into an
analytic-score optimizer, a true average-information update, or a deliberately
non-public diagnostic helper.
