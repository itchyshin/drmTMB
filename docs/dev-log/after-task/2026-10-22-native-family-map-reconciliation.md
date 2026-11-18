# After Task: Native Family SD Map Reconciliation

## Goal

Correct stale statements in the internal native family map so it reflects
verified ordinary Student-t, zero-inflated NB2, and zero-truncated NB2 slope
routes and points future implementation choices to the still-open capability
inventory.

## Implemented

Updated the map's family summaries, slope evidence, and next-slice guidance.
The change records existing evidence only; it adds no runtime behavior and
does not close a programme gate.

## Mathematical Contract

The map retains the existing model: one selected independent location-slope
coefficient can have a group-level SD whose log is a fixed-effects predictor.
Each family report states its own response-completeness and other-parameter
constraints. No likelihood or covariance parameterization changed.

## Files Changed

- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/check-log.d/2026-10-22-native-family-map-reconciliation.md`
- `docs/dev-log/after-task/2026-10-22-native-family-map-reconciliation.md`

## Checks Run

Read the existing after-task reports for native Student-t slope SD, zero-
inflated NB2 slope SD, zero-truncated NB2 slope SD, and Gamma animal slope SD.
`git diff --no-index --check /dev/null
docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md` returned
exit 1 because the untracked map differs from `/dev/null`; stdout and stderr
were empty, so it reported no whitespace errors. A map-specific stale-wording
search found no remaining intercept-only wording for those updated rows. No
code tests ran because no code changed. The repository instruction names
`tools/check-after-task.R`, but that checker is absent from this checkout, so
the required sections were checked manually.

## Tests Of The Tests

No tests were added. This correction was checked directly against four
existing slice reports, which distinguish native point-recovery evidence from
Julia parity and interval calibration.

## Consistency Audit

The Student-t row now includes its one selected independent numeric slope and
links to the slope report. The zero-inflated and zero-truncated NB2 rows now
name their selected numeric slope support and limitations. The Gamma sentence
distinguishes ordinary intercepts from its q1 animal intercept and slope-only
routes. The next-slice section no longer presents already implemented
ordinary-family rows as future work. The map explicitly states that the
capability inventory defines the remaining denominator; this family-only
source map provides adapter detail for a subset of rows.

## Design And Pkgdown Updates

No formula grammar, model design, user guide, reference page, or pkgdown
navigation changed. This was an internal evidence-map correction.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search 'native family SD
adapter map' --limit 10` returned no matches. No issue was edited; broader
implementation tracking remains in the active general-SD programme ledger.

## What Did Not Go Smoothly

The first lease attempt encountered a busy shared registry lock and could not
write the lease from the restricted process. An escalated retry recorded the
exact documentation paths. Preflight also found 424 refs with work on the
shared `docs/dev-log/check-log.md`; I left that file untouched and recorded
this receipt in its dedicated `check-log.d` fragment. The source tree remained
untouched by this slice.

## Team Learning

Update the family map as each route lands, but select new work from the
reconciled cross-product inventory. A family-only map can otherwise make a
completed ordinary route look like the next task while structured, endpoint,
and Julia rows remain unresolved.

## Known Limitations

The full family/effect/provider/endpoint/engine universe remains incomplete.
This report does not validate model behavior, interval calibration, full Julia
parity, or programme completion. G0, G1, G3, G4, G6, G7, and G8 remain open;
G2 remains limited to its tested Bernoulli slice.

## Next Actions

Continue with the next unimplemented row selected from the reconciled
capability inventory after ownership checks. Preserve the full programme
scope and the approved deferral of coverage calibration.
