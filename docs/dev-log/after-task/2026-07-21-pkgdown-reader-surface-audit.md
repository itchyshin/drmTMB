# After Task: pkgdown reader-surface audit and repair

## 1. Goal

Audit and repair the current-main drmTMB reader surface: homepage, Codex-owned
articles, generated reference documentation, legacy routes, navigation, and
rendered pkgdown outputs. `bivariate-coscale` remained Shinichi-owned.

## 2. Implemented

The audit repaired stale public status language across articles, README,
navbar/reference groups, roxygen help, and legacy routes. The native TMB engine
is now the sole current fitting workflow; the Julia bridge and cross-family
route are consistently halted/deferred future work, with Julia methods retained
only for inspecting legacy objects. The model map labels `meta_V(V = V)`
implemented/source-tested without inventing a ledger tier. Stale GitHub Actions
simulation wording was removed, and several mobile-wide tables now scroll.

## 3. Mathematical Contract

No likelihood, parser, family, estimator, or capability tier changed. The
repairs retain these boundaries: `rho12` is residual correlation, not latent
`corpair()` dependence; computed/profile intervals do not imply coverage;
`meta_V(V = V)` is known sampling covariance; and deprecated
`meta_known_V(V = V)` remains a compatibility alias.

## 3a. Decisions and Rejected Alternatives

The audit repaired ordinary documentation defects as they were verified rather
than deferring them. It did not alter code to disable Julia, fabricate a
capability-ledger row, rewrite historical NEWS, or edit the owner-held
`bivariate-coscale` page.

## 4. Files Touched

Changed public sources include `README.md`, `_pkgdown.yml`, selected vignettes,
`R/drmTMB.R`, `R/julia-bridge.R`, regenerated `man/*.Rd`, and
`docs/design/226-reader-learning-path.md`. The audit evidence lives under
`docs/dev-log/release-audits/2026-07-21-site-audit/`.

## 5. Checks Run

- `devtools::document()` regenerated the five affected Rd topics and compiled
  the package; only existing compiler warnings appeared.
- All 68 Rd topics passed `tools::checkRd()`.
- `pkgdown::build_site(pkg = ".")` completed: homepage, 98 reference routes
  including the index, 36 article routes including the index, news, sitemap,
  redirects, and search index.
- `pkgdown::check_pkgdown(pkg = ".")` passed after the full render.
- All focused article rebuilds and `git diff --check` gates passed.

## 6. Tests of the Tests

This was a documentation-only task. The build checks exercised evaluated
vignette chunks, generated Rd parsing, link/metadata validation, and the full
route generator. The audit also caught real prior defects: stale Julia calls,
a false Student-t boundary, an obsolete simulation-execution claim, and the
unregistered `meta_V()` maturity label.

## 7a. Issue Ledger

No matching open Julia/pkgdown/rho12-certification issue was found in the
read-only search. No issue action was taken; the owner-held P1 is recorded in
the local audit ledger.

## 8. Consistency Audit

Exact scans covered `meta_gaussian`, `tau ~`, `rho ~`, malformed
`meta_known_V`, `rho12`, `sigma1`, `sigma2`, `sd(`, stale Julia labels,
simulation-artifact wording, and certification language across README,
ROADMAP, NEWS, design docs, vignettes, R sources, tests, Rd, and generated
pkgdown. Remaining old Julia language is historical NEWS/development record;
remaining `meta_gaussian`/`tau ~` matches are intentional rejection guardrails.

## 9. What Did Not Go Smoothly

The initial homepage build could not resolve the CRAN sidebar hostname in the
sandbox. The permitted rerun completed. A first full-site terminal stream
detached during rendering; a second session was monitored to successful exit.

## 10. Known Residuals

At the initial audit closeout, `vignettes/bivariate-coscale.Rmd:425` still
called a constant `rho12` profile interval certified. Ownership subsequently
transferred to Codex and the second pass repaired that P1: both constant and
predictor-dependent intervals remain computed/reportable but are not
coverage-certified. See `owner-held-findings.md` and `second-pass-closeout.md`.
No deployment, push, merge, CRAN check, or simulation campaign was performed by
the initial repair pass.

## 11. Team Learning

Public status terms can remain stale in navigation, alt text, generated Rd, and
legacy pages after the main article is repaired. A full-site render plus a
targeted status scan must therefore be the final documentation gate.

## 12. Cross-Product Coverage

This work covers the current drmTMB reader surface only. It does not cover a
Julia implementation decision, capability expansion, cross-platform release
validation, or coverage certification for the bivariate tutorial's intervals.

## 13. Next Actions

1. Completed later in the second pass: the transferred `bivariate-coscale` P1
   was repaired and rebuilt.
2. Run a fresh independent D-43 reader-claim verdict and a final clean-worktree
   documentation gate before claiming the whole site is complete.
