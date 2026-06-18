# After Task: Phase 1 Public Claim Lint

## Goal

Keep the current public claim surfaces tied to the R-Julia finish capability
matrix before any further implementation slices promote capability status.

## Implemented

README, ROADMAP, NEWS, pkgdown navigation, and the mission-control dashboard
README now point to `docs/design/168-r-julia-finish-capability-matrix.md`.
`tools/validate-mission-control.py` now checks those links, scans vignettes and
local Documenter.jl sources when present, and rejects public release-promotion
wording or reserved Julia-control wording outside the release gate. The
mission-control dashboard now records Phase 1 at 4/5 slices verified, with Rose
signoff still active.

## Mathematical Contract

No likelihood, formula grammar, parameterization, estimator, interval method, or
simulation contract changed. This task only changes the repository guard that
decides which public status words are allowed.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `_pkgdown.yml`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tools/validate-mission-control.py`

## Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `sh tools/start-mission-control.sh --background`
- `rg -n 'release-ready|release ready|ready for release|ready to release|CRAN-ready|CRAN ready|engine_control' README.md ROADMAP.md NEWS.md _pkgdown.yml docs/dev-log/dashboard/README.md docs/design/168-r-julia-finish-capability-matrix.md vignettes`

The validator reported:

```text
mission_control_ok: 24/68 banked_or_verified, 2 active, 17 matrix rows, 11 finish rows, 15 Julia gate rows, 9 Julia capability rows
```

## Tests Of The Tests

The first validator run failed on the dashboard README because it used the same
literal release-promotion and reserved-control terms that the lint now rejects.
After rewording that policy note, the validator passed. That failure shows the
new public-claim lint is active on its own documentation path, not only on the
README and ROADMAP.

## Consistency Audit

The README stable-core matrix now calls missing data a bounded current-preview
surface rather than a release-ready surface. The ROADMAP now says "preview
boundary" for the same route. NEWS and pkgdown navigation point readers back to
the finish capability matrix. The dashboard still leaves Rose signoff active,
so this task does not claim that every fitted, planned, missing, or unsupported
row has had final human-style audit.

The stale-wording scan intentionally still reports the protected terms inside
`docs/design/168-r-julia-finish-capability-matrix.md`, where the policy itself
defines the release gate and reserved-control guard. The validator skips that
matrix when applying the public-claim ban.

## GitHub Issue Maintenance

No issue was opened or closed. This governance slice is intended to land through
its PR and then be reflected in the dashboard. If a follow-up issue is needed,
it should target the remaining Rose signoff row rather than duplicate the matrix
linking work.

## What Did Not Go Smoothly

The first wording of the dashboard README used the banned phrase while
describing the ban. The validator caught it immediately, which was useful but
also a reminder that policy prose should be written in the same vocabulary the
public docs are expected to use.

## Team Learning

Rose gets a concrete lint hook for public claim drift. Grace gets a cheap
standard-library validation path that runs before serving the dashboard. Ada
gets a dashboard count that separates completed matrix wiring from the still
active row-audit signoff.

## Known Limitations

This is a narrow current-repo lint. It does not inspect the separate DRM.jl
Documenter site, public GitHub Pages output after deployment, historical
after-task notes, or every possible claim synonym. It also does not prove that
all rows are correct; it only prevents the current public surfaces from drifting
away from the matrix link and two high-risk claim classes.

## Next Actions

Open a PR, run fresh current-main Ubuntu, macOS, and Windows R-CMD-check, and
merge only if CI passes. After merge, refresh the dashboard and continue the
remaining Rose signoff audit for fitted, planned, missing, and unsupported
rows.
