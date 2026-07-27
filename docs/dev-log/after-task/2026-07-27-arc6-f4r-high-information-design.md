# After Task: Arc 6 F4R high-information design

## Goal

Turn the F4 failure into a prospective, bounded design for testing a
higher-information alpha-Wald domain without changing public behaviour.

## Implemented

Documented F4R: a fresh 16-cell, 16,000-attempt design at `n = 480` and 960,
with F4's alpha estimand, all-attempt accounting, and pass criteria unchanged.

## Mathematical Contract

The target remains the private link-scale `alpha` Godambe-Wald interval. The
primary denominator is all valid-protocol datasets; unavailable intervals are
non-coverage. Neither eta nor conditional stage-2 curvature is an interval
target.

## Files Changed

- `docs/dev-log/2026-07-27-arc6-f4r-high-information-design.md`
- `docs/dev-log/check-log.md`
- this report

## Checks Run

- Checked the F4 retained summary: all eight `n = 480` cells pass the frozen
  screen, while five lower-information cells fail primary coverage.
- Checked that public `vcov()` and `confint()` still fail closed in
  `R/associate-pairs.R`.
- Ran `git diff --check` after writing this documentation.

## Tests Of The Tests

No code or test changed. The F4R design fixes fresh seed arithmetic, row
counts, denominators, and cell-wise thresholds before any runner or campaign
approval.

## Consistency Audit

The design repeats the existing point-only public boundary and does not call
the failed F4 candidate calibrated. It explicitly corrects the tempting but
unsupported shortcut of promoting an untested `n >= 480` rule from the old
`n = 480` observations.

## GitHub Issue Maintenance

No issue changed. Issue #680 remains a general t-calibration discussion, not
an approved association remediation or F4R implementation issue.

## What Did Not Go Smoothly

The preliminary 8,000-attempt idea would not validate a usable
high-information range. Adding `n = 960` makes the proposed rule prospective
and increases the design to 16,000 attempts.

## Team Learning

A successful endpoint in a failed calibration campaign can motivate a new
design, but cannot become an eligibility rule without fresh evidence.

## Known Limitations

F4R is design-only. Public association uncertainty remains unavailable, and
the F4 failure is unchanged.

## Next Actions

Do not build a runner, connect to DRAC, or begin F5. Seek a separate F4R
compute approval only if the method owner accepts the fresh 16,000-attempt
design.
