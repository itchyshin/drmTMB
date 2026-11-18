# Check log: inst/CITATION fallback version (#1752)

**Date:** 2026-11-17
**Branch:** `cursor/citation-fallback-version-89d9`

## Goal

Stop `inst/CITATION` from naming the stale fallback version `0.1.4`. The
package version in `DESCRIPTION` is `0.8.2`. A normal `citation("drmTMB")`
call already passes `meta$Version` from the installed DESCRIPTION, but a
reader of the file, or a call without `meta`, still saw `0.1.4`.

## Change

`inst/CITATION` still prefers `meta$Version` when `citation()` supplies it.
When `meta` is missing, it now reads `utils::packageDescription("drmTMB",
fields = "Version")` instead of a hard-coded string. No R, test, tolerance,
or timeout files were edited.

## Verification

R 4.3.3. Installed with `R CMD INSTALL --fake --no-R --no-libs --no-test-load
--no-help` into a throwaway library so `citation("drmTMB")` could run without
compiling TMB or installing Imports.

```sh
R CMD INSTALL --fake --no-R --no-libs --no-test-load --no-help --library="$CITE_LIB" .
R_LIBS="$CITE_LIB" Rscript --vanilla -e 'print(citation("drmTMB"))'
Rscript --vanilla -e 'print(utils::readCitationFile("inst/CITATION", meta = list(Version = "0.8.2")))'
```

| Check | Result |
| --- | --- |
| `citation("drmTMB")` after install | note is `R package version 0.8.2` |
| `readCitationFile(..., meta = list(Version = "0.8.2"))` | same note |
| Fallback without `meta$Version`, package installed | `packageDescription()` returns `0.8.2` |
| `rg '0\\.1\\.4' inst/CITATION` | no matches |

## Claim boundary

This is a citation-file version string only. It does not change likelihoods,
formula grammar, tests, or CRAN readiness.
