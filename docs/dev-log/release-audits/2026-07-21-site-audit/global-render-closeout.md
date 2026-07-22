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

The sole remaining current-page false certification is owner-held:
`vignettes/bivariate-coscale.Rmd:425` and its generated route call a constant
`rho12` profile interval “certified.” It is recorded in
`owner-held-findings.md` for Shinichi and is excluded from this Codex lane.
