# Exact-source pkgdown inspection — candidate `1d6445db…`

- Package: `drmTMB` 0.7.0
- Public-site source commit: `6170fbeeea65f22444d7b0934f4e808c40744d22`
- Frozen installed-artifact SHA-256: `1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`
- Source checkout: disposable `git archive` of the exact commit
- Installed package used by pkgdown: the frozen tarball above in a disposable library
- Environment: `R_PROFILE_USER=/dev/null`, `NOT_CRAN=true`
- Build result: `pkgdown::check_pkgdown()` reported no problems; `pkgdown::build_site(new_process = FALSE, install = FALSE)` completed successfully.
- Deployment post-processing: favicon MIME repair, reference-alt repair, and internal-page stripping all completed. `AGENTS.html` and `CLAUDE.html` were absent after stripping; 18 internal search-index entries were removed.

## Reader-surface inspection

Desktop-width screenshots were captured from a localhost-only server after all deployment post-processing:

- `rendered-site/home.png`
- `rendered-site/news.png`
- `rendered-site/capability.png`

The home page, changelog, and capability/limits article rendered without overlapping main content, missing assets, or broken navigation. The compact navbar version marker wraps `0.7.0 pre-CRAN` onto multiple short lines; it remains readable and is treated as non-blocking polish rather than a release-identity defect.

Visible release identity is consistent:

- the navbar says `0.7.0 pre-CRAN`;
- the home page says the package has not yet been submitted to or accepted by CRAN;
- the changelog says this is the first CRAN-targeted release candidate and is not yet submitted or accepted;
- the introductory article labels installation as pre-CRAN and makes `install.packages("drmTMB")` conditional on future CRAN acceptance.

A recursive HTML search found no `0.6.0 experimental`, `v0.5.0`, or unconditional `drmTMB is on CRAN` wording. The sanitized site contains 574 files and occupies 26 MB locally.

The Browser plugin could not initialize because its bundled runtime attempted a disallowed `node:process` import. Visual QA therefore used local headless Chrome screenshots. This tooling failure did not alter the source, installed tarball, or rendered site.

## Claim boundary

This receipt proves a successful build and inspection of the public-site source at `6170fbeee…`. It does not prove deployment to GitHub Pages, CRAN acceptance, or server-side identity of any external package check.
