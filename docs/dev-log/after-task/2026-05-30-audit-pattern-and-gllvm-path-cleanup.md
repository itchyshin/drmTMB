# After Task: Audit Pattern and GLLVM Path Cleanup

## Goal

Remove two small terminology hazards from current developer-facing docs before
they caused future Phase 6c agents to repeat stale wording.

## Implemented

- `docs/design/10-after-task-protocol.md` now flags
  `meta_known_V(V = V)` only when docs call it current, preferred, stable, or
  default.
- `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md` now states that
  `gllvmTMB.jl` is an older local checkout directory for `GLLVM.jl`, not a
  separate package name.

## Mathematical Contract

No model syntax, likelihood, formula grammar, simulation status, or fitted
capability changed.

## Files Changed

- `docs/design/10-after-task-protocol.md`
- `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`. The checks scanned for
the updated audit pattern, the new GLLVM path note, the absence of the old
false-positive compatibility-alias scan, and whitespace hygiene.

## Tests Of The Tests

No R tests were run because this was a developer-documentation cleanup with no
package behavior change.

## Consistency Audit

The cleanup keeps `meta_V(V = V)` as the preferred known-covariance syntax,
`meta_known_V(V = V)` as deprecated compatibility wording, and `GLLVM.jl` as the
sister-package name.

## GitHub Issue Maintenance

No new issue was opened. This is a small follow-up to the Phase 6c twin/sister
exchange and meta-syntax cleanup already tracked in the sprint branch.

## What Did Not Go Smoothly

Older local path names can still be useful provenance, but they need an
explicit sentence when the path looks like a package name.

## Team Learning

Audit patterns should catch stale preferred/default language, not correct
compatibility-alias language.

## Known Limitations

Historical notes may still quote old paths or names when that was the evidence
available at the time. Those should not be mechanically rewritten unless they
are current guidance.

## Next Actions

Keep using `meta_V(V = V)` in new user-facing prose and `GLLVM.jl` for the
Julia sister package name.
