# After-task report: phylogenetic Confidence Eye and capability refresh

## 1. Goal

Replace the phylogenetic article's flat SD interval display with Confidence
Eyes, link readers to the location-scale-scale tutorial, and verify that the
"What `phylo()` fits today" table reflects the current capability ledger.

## 2. Implemented

The Gaussian SD figure now draws two pale Confidence Eyes from the exact
name-matched 95% Wald endpoints and retains hollow markers for the raw fitted
SDs. Visible prose distinguishes a frequentist compatibility display from a
posterior density. The capability table was rewritten from the current ledger,
including Gaussian location and scale routes, count-family routes, the bounded
Beta phylogenetic direct-SD cell, and bivariate routes. A direct link now sends
readers to Part II for predictor-dependent random-effect SD models. The dense
table scrolls horizontally on narrow screens.

## 3. Mathematical Contract

The figure reports the response-scale residual SD and phylogenetic location SD
with the default finite 95% Wald intervals returned by `confint()`. Eye width is
constructed on the log-SD scale and back-transformed. For Beta, the refreshed
table keeps family scale distinct from the latent phylogenetic SD:
`phi = sigma^(-2)` while `sd(spp_id, level = "phylogenetic") ~ x` models the
random-effect SD.

## 3a. Decisions and Rejected Alternatives

The previous flat intervals were rejected because uncertainty is the figure's
primary message and the project visual standard therefore calls for Confidence
Eyes. The raw estimates remain separate hollow points rather than being moved
to the eye peaks: drmTMB's default small-sample correction can shift an
interval's centre. The table was not shortened by dropping evidence tiers;
horizontal scrolling preserves precise boundaries on mobile.

## 4. Files Touched

- `vignettes/phylogenetic-models.Rmd`
- `docs/dev-log/figure-audits/2026-07-21-phylogenetic-confidence-eyes/`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

- Fresh `git fetch origin main`: the branch base and `origin/main` both resolve
  to merge commit `50e56b1a` before this change.
- `python3 tools/capability_ledger.py --check`: PASS; 30 generated outputs are
  synchronized.
- `pkgdown::build_article("phylogenetic-models", new_process = FALSE)`: PASS.
- Desktop and 390-pixel headless-browser inspection: PASS for the Confidence
  Eye; the table reports a 366-pixel viewport and 760-pixel scroll width.
- `devtools::test(filter = "phylo-gaussian", stop_on_failure = TRUE)`: 385
  passes, 0 failures, and 19 expected legacy `sd_phylo*()` deprecation
  warnings.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- `check-after-task.R`: PASS.
- `git diff --check`: PASS.

## 6. Tests of the Tests

The render-time checks require both exact interval names, finite positive
endpoints, and a raw estimate inside each paired interval. These checks retain
the direct guard against the original row-mismatch failure. The browser check
also measures `clientWidth`, `scrollWidth`, and table width, so the responsive
claim is based on rendered geometry rather than source inspection alone.

## 7a. Issue Ledger

| Issue | Severity | Resolution |
|---|---|---|
| flat bars missed the Confidence Eye hard gate | P1 | replaced with labelled frequentist Confidence Eyes |
| old capability summary was too coarse and omitted the validated Beta direct-SD cell | P1 | regenerated the reader summary from current ledger cells |
| Part II was not linked at the direct-SD transition | P1 | added a contextual link to `location-scale-scale.html` |
| expanded table became unreadable at 390 pixels | P1 | added scoped horizontal overflow and a 760-pixel table floor |

## 8. Consistency Audit

The equation, parameter extraction, interval source, plot, caption, alt text,
and explanatory prose all distinguish family `sigma` from a phylogenetic
random-effect SD. Capability wording uses the ledger tiers rather than treating
"fitted" as an inference claim. The Part II link appears precisely where the
article moves from a constant phylogenetic SD to an SD regression.

## 9. What Did Not Go Smoothly

The first browser run was sandbox-blocked by macOS Mach-port permissions and
was rerun with approved local-only access. The first mobile render showed the
expanded table compressing three dense columns and breaking technical words;
the responsive scroll container was added and rechecked.

## 10. Known Residuals

The Confidence Eyes summarize one illustrative fit, not a coverage study. The
capability table intentionally compresses many ledger cells into reader-level
rows, so it links to the model map for the complete matrix and preserves caveat
language rather than enumerating every cell identifier.

## 11. Team Learning

A minimal Tufte display is not automatically the correct project display. The
figure skill's uncertainty gate must be checked before optimizing visual ink.
Capability summaries should be refreshed from the ledger whenever nearby
implementation arcs have recently changed the supported surface.

## 12. Cross-Product Coverage

This is a drmTMB documentation and figure correction. It does NOT cover new
likelihoods, parser grammar, C++, interval estimators, coverage promotion,
DRM.jl, gllvmTMB, or Mission Control.

## 13. Handoff

After merge, wait for the pkgdown workflow and verify the live figure, the Beta
row, and the Part II link. Any future capability change should update the
ledger first and then refresh this reader summary from that source.
