# Current CRAN policy receipt — candidate `1d6445db…`

Authoritative pages refreshed on 2026-08-18 (America/Edmonton):

- CRAN Repository Policy: <https://cran.r-project.org/web/packages/policies.html>, revision 6875
- Checklist for CRAN submissions: <https://cran.r-project.org/web/packages/submission_checklist.html>
- CRAN URL checks: <https://cran.r-project.org/web/packages/URL_checks.html>
- win-builder procedure: <https://win-builder.r-project.org/>

## Applicable release profile

This is a first submission of a package with compiled C/C++ code, many vignettes, optional external Julia integration, no CRAN reverse dependencies, and no required network service at install/load/check time. Applicable conditional gates are native registration/compiled diagnostics, offline-safe optional integration, package/timing budgets, and independent Windows checks.

## Candidate observations

- The immutable source archive is 4,368,396 bytes, below CRAN's preferred 10 MB source-tarball guideline.
- Installed documentation occupies 4,824 KiB on disk (4,939,776 bytes), below but close to the general 5 MB documentation guideline. This is non-blocking with limited growth headroom.
- The exact local `--as-cran --run-donttest` check has 0 errors, 0 warnings, and one expected `New submission` NOTE. Tests complete in 45 seconds elapsed / 54 seconds reported; vignette rebuilding completes in 66 seconds elapsed / 75 seconds reported.
- Local spelling test output is clean. Incoming Windows spelling findings, if any, must be read and explained rather than inferred from this local dictionary.
- The exact source passes reader-surface and pkgdown checks. URLs reported `OK` during the local CRAN check and `pkgdown::check_pkgdown()`.
- Exact-source sanitizer/rchk and 3-OS results are complete. The three exact-byte win-builder result packets are complete, with short selected-test timings and no errors or warnings. The evidence supports `platform-clean`; no submission-ready claim is made before the final gate and panel.

## Policy interpretation

CRAN policy asks packages to minimize check CPU time and retain checks that exercise all features; it does not state a fixed ten-minute limit. This project uses approximately ten Windows minutes as a conservative first-submission margin based on observed incoming behaviour. The new CRAN allowlist retains representative compiled, family, formula, extractor, error-path, and release-identity coverage while the full `NOT_CRAN=true` repository suite remains much broader.

CRAN accepts explanatory comments for unavoidable or spurious notes. Therefore any incoming DESCRIPTION spelling terms and the independently adjudicated rchk result must be described precisely in `cran-comments.md` before a submission-ready vote.

No submission was performed.
