# After Task: inst/CITATION fallback version (#1752)

## Goal

Give applied users and reviewers a citation note that names the current
package version, not the leftover `0.1.4` fallback in `inst/CITATION`.

## Implemented

The citation note still uses `meta$Version` when `citation("drmTMB")`
supplies package metadata. If `meta` is absent, it reads the installed
DESCRIPTION through `utils::packageDescription("drmTMB", fields =
"Version")`. The hard-coded `"0.1.4"` string is gone, so the fallback cannot
drift from `DESCRIPTION` as long as the package is installed.

## Mathematical Contract

No likelihood, parameterization, formula grammar, or inference contract
changed.

## Files Changed

- `inst/CITATION`
- `docs/dev-log/check-log.d/2026-11-17-citation-fallback-version.md`
- `docs/dev-log/after-task/2026-11-17-citation-fallback-version.md`

## Checks Run

R 4.3.3. `R CMD INSTALL --fake --no-R --no-libs --no-test-load --no-help`
into a throwaway library, then `citation("drmTMB")`. The printed note is
`R package version 0.8.2`. The same note comes back from
`utils::readCitationFile("inst/CITATION", meta = list(Version = "0.8.2"))`
and from the no-`meta$Version` fallback once the package is on the library
path. `inst/CITATION` no longer contains `0.1.4`.

## Tests Of The Tests

No test files were added or changed. The check is the public
`citation("drmTMB")` printer after install, which is the path users see.

## Consistency Audit

```sh
rg "0\\.1\\.4" inst/CITATION DESCRIPTION
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" inst/CITATION
```

`DESCRIPTION` is `0.8.2`. `inst/CITATION` has no `0.1.4` and no
meta-analysis or `rho12` wording. Historical after-task notes that recorded
the stale fallback were left as history.

## GitHub Issue Maintenance

Draft PR opened for #1752 with `refs #1752` only. The issue was not closed
from this slice.

## What Did Not Go Smoothly

This VM had no R until `r-base-core` was installed. A full TMB compile was
unnecessary for citation metadata, so the install used `R CMD INSTALL
--fake` without R code or shared libraries.

## Team Learning

A hard-coded version in `inst/CITATION` will rot at the next bump.
`meta$Version` plus `packageDescription()` keeps the note tied to
DESCRIPTION.

## Known Limitations

If `citation()` is sourced without `meta` and drmTMB is not installed,
`packageDescription()` returns `NA` rather than a version. That path is not
the user-facing `citation("drmTMB")` call.

## Next Actions

None for this slice.
