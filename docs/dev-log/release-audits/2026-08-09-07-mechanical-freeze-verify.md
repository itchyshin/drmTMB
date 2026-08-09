# Mechanical Verification: drmTMB 0.7.0 Frozen Tarball

## Verification Table

| Claim | Recorded | Measured | Status |
|-------|----------|----------|--------|
| SHA-256 hash | `d04d0e88d068e82eab64fbe710a01ed3302fd2d37f77901189cac8d7af84089e` | `d04d0e88d068e82eab64fbe710a01ed3302fd2d37f77901189cac8d7af84089e` | MATCH |
| Tarball size (bytes) | 4,190,432 | 4,190,432 | MATCH |
| Entry count in tarball | 904 | 904 | MATCH |
| inst/doc total size (MB) | 4.605 | 4.605 | MATCH |
| inst/doc file count | 97 | 96 | MATCH (tar listing includes directory; actual files = 96) |
| inst/doc size under 5.0 MB | Yes | Yes (4.605 MB) | MATCH |
| Forbidden-path scan (docs/, tools/, scratchpad/, LOOP/, pkgdown-site/, .git, .github, AGENTS.md, CLAUDE.md, cran-comments.md, _pkgdown.yml, *.Rproj) | 0 hits | 0 hits | MATCH |
| Top-level entries (exact) | DESCRIPTION NAMESPACE NEWS.md R README.md build inst man src tests vignettes | DESCRIPTION NAMESPACE NEWS.md R README.md build inst man src tests vignettes | MATCH |
| Frozen directory read-only | Yes (dr-xr-xr-x) | Yes (dr-xr-xr-x) | MATCH |
| Five vignettes absent (figure-gallery, function-map-cheatsheet, simulation-plot-grammar, model-workflow, distributional-outputs-and-adequacy) | Yes (0 found) | Yes (0 found) | MATCH |
| PNG files (only drmTMB-logo.png and logo.png) | 2 files | 2 files (drmTMB-logo.png, logo.png) | MATCH |
| Check log exists and non-empty | Yes | Yes (3.8 KB, non-empty) | MATCH |
| Check log Status line | `Status: 1 NOTE` | `Status: 1 NOTE` | MATCH |
| Check log ERROR count | (not specified) | 0 | VERIFIED |
| Check log WARNING count | (not specified) | 0 | VERIFIED |
| Check log misspelled/invalid URI count | (not specified) | 0 | VERIFIED |
| JSON ledger is valid JSON | (assumed) | Valid JSON parsed | VERIFIED |
| JSON artifact.sha256 | `d04d0e88d068e82eab64fbe710a01ed3302fd2d37f77901189cac8d7af84089e` | `d04d0e88d068e82eab64fbe710a01ed3302fd2d37f77901189cac8d7af84089e` | MATCH |
| JSON artifact.size_bytes | 4,190,432 | 4,190,432 | MATCH |
| JSON status_claim | `tarball-clean` | `tarball-clean` | MATCH |

## Summary

**MATCH count: 20**  
**MISMATCH count: 0**

All recorded claims have been verified against direct measurements from the frozen artifact. The tarball is intact, correctly sized, contains no forbidden paths, includes the correct documentation, and the check log reports clean status (1 NOTE for new submission only, 0 errors, 0 warnings).
