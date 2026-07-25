# After Task: pkgdown reader-surface formal closeout

## 1. Goal

Close the formal assurance phase of the merged reader-surface audit at
`1a972b8e` without reopening completed article repairs or expanding the
package's public capability surface.

## 2. Implemented

Added the promised explicit eight-batch Rd ledger, a canonical-versus-alias
route receipt, plan-versus-actual reconciliation, and final D-43 record.
Reconciled the initially owner-held `bivariate-coscale` P1 with its completed
second-pass repair. Removed trailing whitespace from the original audit records
and corrected stale provenance that incorrectly left that P1 open.

## 3a. Decisions and Rejected Alternatives

The closure repaired audit evidence rather than restarting the 32 article
audits, changing a vignette, or changing R code. The 98-reference-page claim is
retained but now defined precisely as 69 canonical routes plus 29 pkgdown alias
redirects. No capability, coverage, Julia, or CRAN claim was broadened.

## 4. Files Touched

The touched files are audit records under
`docs/dev-log/release-audits/2026-07-21-site-audit/`, the two related prior
after-task records, this report, the plan-versus-actual record, and the
handoff. No `R/`, `man/`, `vignettes/`, `_pkgdown.yml`, `NAMESPACE`, or package
test source changed.

## 5. Checks Run

In clean worktree `/private/tmp/drmtmb-pkgdown-formal-closeout`, pinned at
`1a972b8e`: `tools::checkRd()` passed for 68 topics; `pkgdown::check_pkgdown()`
reported no problems before and after the full render; `pkgdown::build_site()`
completed; `git diff --check` passed. Read-back found 35 `.Rmd` sources, 36
article HTML routes, 68 `.Rd` topics, 69 canonical reference URLs, 98 generated
reference HTML files, 51 NAMESPACE exports, plus sitemap and search index.

## 6. Tests of the Tests

The first D-43 round found real evidence defects: a false historical
`git diff --check` claim, stale owner-held P1 wording, and unexplained route
counts. The final commands and three independent reviews would have retained a
NOT READY verdict had those defects remained.

## 7a. Issue Ledger

No GitHub issue was opened. The resolved P2s are recorded in
`2026-07-22-pkgdown-reader-surface-d43.md`: audit-trail whitespace, stale
`bivariate-coscale` disposition, incomplete reference-batch provenance, and
ambiguous 98-route accounting.

## 8. Consistency Audit

Fisher checked the manifest, capability ledger, reader sources, `rho12`, Julia,
and cross-family claims. Rose checked stale records, counts, and formatting. A
fresh verifier independently checked inventories, aliases, and retained build
evidence. The routed repository manifest, `r-package-engineer`,
`validation-harness`, and `prose-style-review` instructions shaped the
documentation-only boundary. `/ask-brain` was attempted through its local CLI
fallback but its user configuration was not writable in the sandbox; the repo
and frozen audit records supplied technical truth. No known-mistake Golden Set
applied because this task changed neither model code nor evidence tiers.

## 9. What Did Not Go Smoothly

The first sandboxed full render could not resolve the CRAN sidebar hostname or
write the user R sass cache. The permitted rerun completed. The first review
round correctly stopped closeout for P2 evidence defects; those records, not
reader pages, required repair.

## 10. Known Residuals

The reader assurance record is complete at the frozen revision. Its evidence is
local and does not prove a deployed site, CRAN acceptance, cross-platform
rendering, or any new statistical property. `rho12` intervals remain
reportable but not coverage-certified.

## 11. Team Learning

For pkgdown closeout, retain both canonical sitemap counts and physical alias
redirect counts. Historical findings need an explicit later disposition when a
second pass repairs them; otherwise accurate reader sources can coexist with a
misleading closure record.

## 12. Cross-Product Coverage

This work covers the drmTMB reader-surface audit trail, local rendering, Rd
parsing, and claim consistency. It does NOT cover package implementation,
likelihood correctness, family support, coverage calibration, Julia parity,
simulation evidence, deployment, CRAN, or platform-specific validation.
