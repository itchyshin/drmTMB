# Phylogenetic tree-height documentation correction

## 1. Goal

Resolve the discrepancy reported by Ayumi in
[LS_ecogeographical-rules issue 49](https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/49)
without changing drmTMB's fitted model.

## 2. Implemented

Corrected `phylo()` help and NEWS to describe the existing normalization:
the Brownian covariance is divided by tree height. For an ultrametric tree,
the latent Brownian field therefore has unit variance at each tip. Multiplying
all branch lengths by the same positive constant leaves this covariance
unchanged. The supplied tree object is not modified.

Added regression tests for covariance, precision and log-determinant
invariance, and updated the help-text test that previously required the
incorrect claim. No executable R code, likelihood or default changed.

## 3a. Decisions and Rejected Alternatives

Preserved the normalized covariance convention. Switching to raw branch-length
units would change the meaning of the phylogenetic SD and would not be a
documentation correction. Under raw covariance, the equivalent SD is
`s_raw = s_normalized / sqrt(tree_height)`.

Did not attribute Ayumi's wide intervals to absolute tree height. The local
branch-rescaling diagnostic does not support that explanation; her empirical
fits and root-age provenance still require separate investigation.

## 4. Files Touched

- `R/formula-markers.R`: corrected roxygen prose and aligned existing capability wording with the generated help.
- `man/phylo.Rd`: regenerated the affected help page.
- `NEWS.md`: corrected the historical claim and documented this repair.
- `tests/testthat/test-dinnage-audit-wave1.R`: corrected the help-text contract.
- `tests/testthat/test-phylo-utils.R`: added branch-unit invariance tests.
- `docs/dev-log/check-log.md`: recorded bounded verification.
- This report.

All work is in managed worktree `tree-height-docs`, on
`codex/phylo-height-docs`, based on `0eb0467851cc2902556764bdca5441b7bc053be6`.
The original checkout and its unrelated inbox files were not edited.

## 5. Checks Run

The final focused run used the installed 0.7.1 engine with local tests and help:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /usr/local/bin/Rscript -e 'r <- testthat::test_local(load_package="installed", filter="dinnage-audit-wave1|phylo-utils", reporter="summary"); d <- as.data.frame(r); cat("COUNTS tests", nrow(d), "passed", sum(d$passed), "failed", sum(d$failed), "errors", sum(d$error), "skipped", sum(d$skipped), "\n")'
```

Result: 29 tests, 220 passed expectations, zero failures, errors or skips.
The installed covariance helpers and public builder had been checked against
the source used for this repair. This is not a full package test run.

`git diff --check`, `tools::checkRd("man/phylo.Rd")` and
`pkgdown::check_pkgdown()` passed. Parsing the changed R file and its baseline
with `keep.source = FALSE` produced identical expressions, confirming that
the R change contains only comments.

Built the `phylo` reference page with examples disabled and inspected its HTML
text. It contains the normalized-covariance wording and no longer contains the
false silent-rescaling claim. The generated page is local:
`/private/tmp/drm-phylo-height-site-20261004/reference/phylo.html`.
No screenshot or live-site deployment check was performed.

The preceding diagnostic fitted the same 32-tip simulated example twice,
scaling every branch by 100 in the second fit. Maximum coefficient difference
was 2.98e-14 and maximum interval-endpoint difference was 1.493e-10; both fits
had positive-definite Hessians. This supports unit-rescaling invariance, not
the validity of Ayumi's empirical models.

## 6. Tests of the Tests

Before the prose correction, the revised help contract failed at its three
intended assertions. After correction it passed. The covariance invariance
test already passed before the documentation edit, as expected.

The raw-covariance control (`correlation = FALSE`) changes by a factor of 100
when branch lengths change by that factor. Thus the added test distinguishes
normalization from simply ignoring branch lengths. It also checks the recorded
tree height changes by 100 while default precision and log determinant do not.

## 7a. Issue Ledger

| Issue | Status | Evidence |
| --- | --- | --- |
| Help and NEWS falsely claimed absolute branch-scale preservation | Fixed locally | Source, regenerated help and HTML content agree |
| Help regression test enforced that false claim | Fixed locally | Intended red test, then green |
| Default branch-unit invariance lacked an explicit regression test | Fixed locally | Covariance, precision, log determinant and raw-covariance control |
| Cause of Ayumi's broad SD intervals | Open | No empirical fit or cloud refit performed |
| Root-age provenance | Open | Outside this documentation repair |

## 8. Consistency Audit

Checked neighboring R, Rd, vignette, README, design and limitation surfaces
for the obsolete absolute-scale wording. Only the deliberate negative-test
string remains. No likelihood or formula grammar changed, so their design
documents require no parameterization update.

Self-assessment of this exact report, Codex, 4 October 2026: perceived AI-like
style 2/10, medium confidence. The sentence "The supplied tree object is not
modified" distinguishes data mutation from model normalization.
Scientific gate: passed for the bounded normalization claim. Factual gate:
passed against source and checks recorded above. Reference gate: passed
for the linked issue; no paper-derived claims are made. This assessment does
not establish Shinichi's voice or authorship.

## 9. What Did Not Go Smoothly

Targeted roxygen generation initially removed 97 unrelated generated help
pages because its cleanup behavior was not disabled. This occurred only in
the isolated, initially clean worktree. All 97 pages were restored exactly
from the original revision before final testing. The intervening run with a
missing help-page skip was discarded; the final run has zero skips.

Targeted generation also initially omitted Markdown processing. Regeneration
with Markdown enabled and `is_first = TRUE` produced the narrow intended diff.
The initial full-generation attempt failed at a sandbox write before changing
an unrelated page. The final reference build required the installed Pandoc
path and normal Sass-cache permission. Pandoc emitted deprecation warnings,
but the reference build and content checks passed.

The report scaffold tool resolved a relative path against the brain hub
instead of this worktree. Its newly created scaffold was moved to the exact
task path without overwriting an existing file, then replaced with this report.
The accidental hub file is no longer present. No pre-existing hub files were
modified.

## 10. Known Residuals

No full `R CMD check`, all-package suite, cross-platform checks, release,
deployment, empirical refit or cloud pooling audit was performed. The repair
is local, not merged or published. Ayumi has not been sent a comment by this
task. Broader tree-shape or topology changes can affect a fit and are not
covered by uniform branch rescaling.

## 11. Team Learning

Memory receipt: the drmTMB routing manifest and applicable package, test,
verification and after-task instructions were loaded before implementation.
The source remained technical truth; the documentation claim was not used
to change the numerical convention. Scoped lane ownership and an isolated
checkout protected the other active checkout.

Golden Set: not run. This is a comments-only repair with focused regression
tests, not a new numerical method or a package-wide readiness claim.

For one-page roxygen generation, enable Markdown explicitly, disable unrelated
cleanup, and inspect the full diff before testing. Use an absolute report path
with the hub closeout tool.

## 12. Cross-Product Coverage

Covers: drmTMB `phylo()` help, NEWS and bounded branch-unit regression tests.

This does NOT cover: DRM.jl, gllvmTMB, other covariance families, full release
readiness, Ayumi's root ages, empirical interval robustness or cloud pooling.
