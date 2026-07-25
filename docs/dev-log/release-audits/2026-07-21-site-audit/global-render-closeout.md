# Global pkgdown render closeout

- **Base:** `83d48549e8925a97aa2c156941a97a9bf9b785c4`
- **Date:** 2026-07-21

`pkgdown::build_site(pkg = ".")` completed successfully after rebuilding the
home page, 98 generated reference routes (including the index), 36 article
routes (including the article index), news, sitemap, redirects, and search
index. The full run passed URL, favicon, Open Graph, article-metadata, and
reference-metadata checks; the follow-up `pkgdown::check_pkgdown()` also
passed. All 68 Rd files pass `tools::checkRd()`.

The completed render confirms that current Julia reader surfaces consistently
state halted/deferred future support after one final wording repair in
`julia-engine`. Historical NEWS entries are retained as historical changelog
records, not rewritten as current availability claims.

At the first-pass render this record identified an owner-held false
certification in `bivariate-coscale`. Ownership subsequently transferred to
Codex, and the second pass repaired the source: constant and predictor-dependent
`rho12` intervals are computed/reportable but not coverage-certified. The final
disposition is recorded in `owner-held-findings.md` and
`second-pass-closeout.md`.
