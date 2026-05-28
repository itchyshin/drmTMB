# After-Task Report: Phase 18 Comparator And Support-Boundary Decisions

Date: 2026-05-28

## Goal

Record the next Team A and Team B design decisions without adding a new fitted
surface: Tweedie weights and offsets need a clear comparator boundary, and the
future skew-normal lane needs support/missingness and rank-deficiency rules.

## Implemented

Added
`docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md`.
The note records that weighted Tweedie comparator tests wait for a dedicated
row-weighting target, Tweedie offsets stay outside the first comparator pass,
skew-normal support should be finite continuous responses after model-frame
filtering, and skew-normal rank handling should initially use shared
fixed-effect infrastructure.

## Files Changed

- `docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md`
- `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-comparator-boundary-decisions.md
rg -n "1631|1632|1685|1686|finite continuous|rank-deficiency|Tweedie weights|Tweedie offsets" docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

The positive evidence scan found the new slice IDs and boundary wording.
`pkgdown::check_pkgdown()` reported no problems, and `git diff --check` was
clean.

## Tests Of The Tests

No executable tests were added in this design-only slice. The testable outcome
is a bounded future checklist: weighted Tweedie comparison must name the
weighting target before adding a fixture, and skew-normal implementation must
add density, normal-limit, support, and malformed-input tests before exposing a
constructor.

## Consistency Audit

The source inspection found that Tweedie already receives top-level weights
through shared likelihood infrastructure and rejects `offset()` through the
unsupported-term gate. Formula grammar keeps offsets as implemented count
`mu` exposure syntax. Skew-normal remains design-only.

## Next Actions

Team A can choose either a weighted-row target design or missing-row comparator
documentation. Team B can start source-level density tests only after the
support and rank decisions are accepted.
