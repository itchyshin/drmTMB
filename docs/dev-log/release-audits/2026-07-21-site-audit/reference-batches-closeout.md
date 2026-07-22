# Reference-documentation batches: audit closeout

All 68 Rd topics (covering 51 exports) were regenerated and rendered during
the completed `pkgdown::build_site()` run. Every topic also passed
`tools::checkRd()`. The authoritative sources are roxygen blocks in `R/`; no
generated Rd file was edited directly.

| Batch | Topics | Disposition |
|---|---:|---|
| Package | 1 | Audited; status vocabulary is consistent with reader-surface boundaries. |
| Model specification | 17 | Audited; family, formula, meta-covariance, and missing-predictor documentation rendered. |
| Structured-effect markers | 7 | Audited; deprecated markers, `rho12`, `corpair()`, and narrow REML boundaries are explicit. |
| Deprecated markers | 2 | Audited; compatibility-only status remains explicit. |
| Fit and post-fit tools | 29 | Audited; interval/provenance terminology scanned; the main `drmTMB()` Julia wording was repaired. |
| Distributional outputs | 5 | Audited; no stale certification or engine claim found. |
| Julia compatibility | 4 | Repaired; all topics are legacy-object inspection only, not current fitting/inference. |
| Visualization | 3 | Audited; finite intervals require provenance/status and do not imply coverage. |

The rendered reference index contains 98 generated reference routes including
the index; it labels the retained Julia group “Future Julia support.” The
global render and `pkgdown::check_pkgdown()` are recorded in
`global-render-closeout.md`.

This batch closure does not certify interval coverage, add an export, alter an
estimator, or modify the owner-held `bivariate-coscale` page.
