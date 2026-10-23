# Current CRAN policy application — candidate `6b45164b…`

Accessed: 2026-08-18

Authoritative sources:

- <https://cran.r-project.org/web/packages/policies.html>, revision 6875;
- <https://cran.r-project.org/web/packages/submission_checklist.html>;
- <https://cran.r-project.org/web/packages/URL_checks.html>.

## Application to the candidate

- The file is an `R CMD build` source archive named `drmTMB_0.7.0.tar.gz`.
- The exact bytes completed local `R CMD check --as-cran` and win-builder
  R-devel, R-release, and R-oldrelease checks. Each has only the expected first
  submission NOTE; any submission comment must explain it.
- The exact source commit passed package checks on Windows, macOS, and Ubuntu.
- The tarball is 4,367,799 bytes, below CRAN's preferred 10 MB source size.
- Installed documentation is 4,939,776 bytes, below the general 5 MB
  documentation guideline. The whole installed package is 25,927,680 bytes,
  principally compiled code and help/database material; its installed-size
  check is `OK` on all three win-builder arms.
- The local CRAN-lane test stage was 203 seconds elapsed (239 seconds total
  reported by `R CMD check`). win-builder reported 14 minutes for tests on
  R-release/R-devel and 560 seconds on R-oldrelease. CRAN policy gives no fixed
  ten-minute limit, but requires checks to use as little CPU time as possible.
  Grace must adjudicate this measured risk before `submission-ready`; it is not
  hidden behind a green platform result.
- Examples and substantive checks are `OK` on all three win-builder arms.
- The R-hub run remains visibly red because rchk reports installed-TMB-header
  findings. Three independent sanitizer jobs passed, and no rchk protection
  finding cites `drmTMB.cpp`.
- Two DOI redirects previously returned automated 403 responses while their
  Crossref registrations resolved. If the URLs remain flagged at submission,
  the submission comment must explain that evidence rather than call the URL
  checker clean.

This application supports evaluation of the platform packet. It does not
authorize upload or assert `submission-ready`.

