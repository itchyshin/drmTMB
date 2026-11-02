## 1. Goal

Make the first-capture CJS article directly discoverable from the live drmTMB Tutorials menu.

## 2. Implemented

Added a `Capture and recapture histories` link to the `Tutorials` navbar, pointing to `articles/cjs-first-capture.html`, in the existing CMR PR branch.

## 3a. Decisions and Rejected Alternatives

Kept the article under Tutorials, matching the reader-facing location Shinichi asked about. The existing article index and function reference entries remain in place. The link is visible in the PR source but is not yet in the deployed site.

## 4. Files Touched

- `_pkgdown.yml`
- `docs/dev-log/check-log.d/2026-10-23-cmr-tutorial-nav.md`
- `docs/dev-log/after-task/2026-10-23-cmr-tutorial-nav.md`

The navigation change was committed as `3d119a9405e819140cc2f36acf2ada9bdf89fbba` and pushed to PR #1612. This report and its check-log are a docs-only receipt on the same PR branch; they do not change runtime code.

## 5. Checks Run

- `Rscript -e 'pkgdown::check_pkgdown()'`: `No problems found.`
- Totoro R CMD check on candidate `3d119a9405e819140cc2f36acf2ada9bdf89fbba`: testthat reported 3,498 passes, 0 failures, 18 warnings, and 32 skips. The CJS vignette passed in 268 seconds. The overall check exited with one error, three warnings, and two notes.
- The exact PR base `3493b187c91750a6cda810e536ac873e2ef1eaa9` reproduced the same `convergence.Rmd` error (`could not find function "bf"`), so this full-check error predates CMR.
- `git diff --check` passed for the navigation change.

## 6. Tests of the Tests

The R testthat suite exercised the candidate and returned zero failures. The baseline comparison established that the `convergence.Rmd` check error is present on the PR base as well as the candidate. No claim is made about a full clean package check.

## 7a. Issue Ledger

- Fixed: the CMR article was absent from the top-level Tutorials dropdown.
- Open: the exact-head GitHub checks for the current PR head are queued; adding the evidence files will create a new head and require fresh checks.
- Open: PR #1612 is unmerged and the production pkgdown page has not been rebuilt.
- Deferred: repeated-sample interval availability, coverage, and calibration remain Phase B.

## 8. Consistency Audit

The link target matches the CMR vignette slug. The article itself states that intervals are capability/availability outputs only and that repeated-sample calibration is not established. The check log preserves the full-check failure and its exact-base reproduction.

## 9. What Did Not Go Smoothly

GitHub Actions remained queued during this work. The local full check surfaced a pre-existing failure in `convergence.Rmd`; an exact-base run confirmed that it is not introduced by the CMR candidate. The Totoro check also reported environment notes because `pandoc` and `checkbashisms` are absent and the source package was built without a vignette index.

## 10. Known Residuals

The article is not online. The current PR head must pass its exact-head checks, then the PR needs the maintainer-authorized merge step. The pkgdown workflow does not deploy on every main merge, so a production build must also complete before the URL can be reported as live. No repeated-sample interval calibration was run or claimed.

## 11. Team Learning

For a new reader-facing vignette, add a direct navbar link as well as an article-index entry; the article list alone did not make the CMR page discoverable from the Tutorials dropdown.

## 12. Cross-Product Coverage

Covers: R package CMR page navigation and local pkgdown surface checking.

Does not cover: Julia CMR publication, R-to-Julia CMR bridge routes, repeated-sample recovery/interval calibration, merge, production deployment, or live-page verification.
