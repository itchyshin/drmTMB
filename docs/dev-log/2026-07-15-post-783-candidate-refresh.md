# Post-PR #783 candidate refresh

## Gate result

**PASS — continue with Arc 1b-S2R, supplied-`K` `relmat()` q2 bivariate
REML only.**

This refresh was run after PR #783 merged. The exact execution base is
`d210439187f2a49922de8bcf8c183d164d7bd0dc`; the implementation branch
`codex/arc1b-s2r-relmat-q2-reml` was created from that `origin/main` commit.

## Live read-back

- PR #783 merged at `d2104391` after its exact head `e2c22893` passed the
  `os-matrix` and `ubuntu-latest (release)` checks.
- PR #781 is the only open pull request. It is an unrelated meta-analysis
  trust dossier and is outside this branch.
- `mc-0151` and `mc-0152` remain the two ML endpoint projections of the
  bivariate `relmat()` q2 location-intercept block. Both are implemented,
  verified, and `point_fit_recovery`.
- `mc-0201` remains the broad bivariate relmat REML rejection row:
  `rejected_by_design`, deferred, and evidence tier `none`.
- A local exact-formula probe on `d2104391` reached
  `drm_validate_reml_spec_biv()` and failed with the intended spatial-only
  REML message. The target is therefore still absent, and the future
  admission test has genuine pre-fix failure evidence.
- DRM.jl has related known-covariance kernels but no matching bivariate
  relmat-REML public route. No Julia code or evidence transfers into this arc.

## Candidate comparison

| Rank | Candidate | Decision |
| ---: | --- | --- |
| 1 | Supplied-`K` relmat q2 location-intercept REML | Execute: existing ML comparator, exact dense-`K` REML oracle, narrow fail-closed gate |
| 2 | Animal q2 location-intercept REML | Separate successor: pedigree/`A`/`Ainv` construction and normalization broaden the boundary |
| 3 | Beta phylogenetic q1 `mu` | Next prerequisite toward the banked `sd()` product arc |
| 4 | Spatial q2 interval pilot | Later: repeated profiles, boundary skew, and wider inference claim |
| 5 | Combined Beta location-scale-scale `sd()` | Do not bundle; split after the Beta phylogenetic `mu` prerequisite |

Fisher independently re-read the post-merge base and returned PASS. The claim
ceiling remains `point_fit_recovery`.

## Stop conditions

Stop rather than substitute or broaden if any of these becomes true:

- the exact target already fits under REML on the execution base;
- the two ML comparator rows no longer have their recorded evidence;
- the implementation cannot distinguish supplied covariance `K` from supplied
  precision `Q` without relaxing another route;
- the symbolic, parser, TMB, extractor, and oracle orderings do not agree; or
- PR #781 or another unrelated branch would need to be absorbed.
