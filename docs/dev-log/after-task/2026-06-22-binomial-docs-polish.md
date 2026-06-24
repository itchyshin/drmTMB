# After-Task Report: Binomial Docs Polish

## Task

Bank slice S042 by tightening public binomial wording after the binomial bridge
map.

## Changes

- Updated the README "Event indicators or successes out of known trials" bullet
  to name native TMB fixed-effect binomial logit support, the supported
  response encodings, the `beta_binomial()` escape hatch for extra-binomial
  variation, and the unsupported binomial neighbours.
- Updated the NEWS binomial entry with the same native TMB and unsupported
  non-phylogenetic Julia bridge boundary.
- Added `docs/design/195-binomial-docs-polish.md`.

## Checks

```sh
tools/validate-mission-control.py
git diff --check
```

## Result

The public prose now matches the S041 binomial bridge map without promoting
ordinary binomial Julia bridge support.

## Claim Boundary

S042 changes prose only. It does not add R-via-Julia binomial fitting, relax
bridge gates, add binomial random effects, change formula grammar, claim
non-Gaussian REML, expose public `engine_control`, or touch Ayumi-facing text.
