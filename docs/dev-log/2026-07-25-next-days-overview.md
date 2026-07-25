# drmTMB: next-days overview after the Arc 7B/8 and Julia-xfam cleanup

## Current landing point

`main` contains the Arc 7B known-`V` heterogeneity-ladder documentation, the
Julia cross-family extractor boundary (PR #833), and the staged eta bootstrap
handoff (PR #831). Arc 8's narrow CI repair remains a separate draft PR until
its required Linux release check completes. PR #828 is explicitly outside this
cleanup and must not be merged. PR #829 stays parked because it is dirty
against `main`; it belongs to the separate bivariate lane.

The repository also has seven confirmed baseline failures in
`test-estimator-surface-conformance.R`: the same stale TSV line-anchor
expectations fail on untouched `origin/main`. They are real hygiene debt, but
they are not caused by the merged Julia extractor work and should not be hidden
inside a method arc.

## Proposed sequence

### Today: finish the already-built work

1. Merge Arc 8 only after its two required checks are green, the PR is clean,
   and no review or comment blocks it. The claim remains local engineering
   feasibility: no recovery, coverage, tier promotion, Totoro, or DRAC
   campaign is authorized by that merge.
2. Leave PR #828 untouched. Leave PR #829 to the owner of the eta/bivariate
   lane rather than resolving its conflict in parallel.
3. Close the Arc 8 repair with its existing after-task record and this
   repository-wide landing note; do not widen it into a new model feature.

### Next working day: restore a trustworthy baseline

Open one small, dedicated hygiene PR that updates the stale estimator-surface
line-anchor fixtures after comparing each expectation with its current source
location. It should change no estimator behaviour. Its acceptance evidence is
the exact seven-test file first, then the full local suite; any mismatch that
is semantic rather than an anchor must become a separate issue.

This is the highest-value short task because a red baseline makes every later
method claim harder to interpret.

### Following days: choose one independent substantive lane

The eta and bivariate implementation stays with its current owner. The clean
independent follow-up for this lane is to design, rather than immediately
implement, the `DRM.jl` counterpart of the Julia cross-family extractor
contract: fitted values and residuals are defined for fixed-only (`u = 0`)
fits, coefficient and variance-covariance extractors remain explicitly
unsupported, and the API refuses accidental covariance or random-effect
claims. That is a cross-repository interface task, so it needs a fresh goal,
an isolated worktree, symbolic/API alignment, and a new pull request.

In parallel, keep the Arc 7B/8 meta-`V` ladder at its stated boundary. The
next computational question is not “run more”: it is whether a pre-registered
calibration/recovery design can justify a Totoro or DRAC campaign. Until that
question has a written design and explicit compute approval, do not use the
available cores for a speculative ladder rerun.

## Decision points for Shinichi

- After baseline hygiene is green, choose between the cross-repository
  `DRM.jl` extractor-parity design and a new, independently scoped method arc.
- If the eta/bivariate lane needs help, hand over a bounded review or test
  slice; do not merge or repair it from this lane by default.
- Approve a compute design before any new meta-`V` recovery or calibration
  campaign. The current Arc 8 fixtures are intentionally not such evidence.

## Guardrails retained

- Never merge PR #828 as part of this work.
- Keep GitHub Actions for package checks and documentation; use Totoro/DRAC
  only for an approved computational campaign.
- Keep `meta_V(V = V)` as the known sampling-covariance contract. Do not add a
  `tau ~` grammar or treat direct-SD engineering feasibility as calibrated
  inference.
