# After Task: Meta-V Hessian Limitation Note

## Goal

Add a user-facing limitation note for issue #417 without changing likelihoods,
formula grammar, or tests.

## Implemented

The meta-analysis vignette, meta-analysis design note, known-limitations log,
and README status table now state that issue #417 reports `pdHess = FALSE` for
`meta_V(V = vi)` combined with `sigma ~ moderator`. The note tells users to
treat Hessian-based standard errors and Wald intervals from that combination as
diagnostic rather than final inference until the issue is resolved.

The vignette also states that `offset()` is unsupported in the `sigma` formula
and that known sampling variance should be supplied through `meta_V(V = V)`.
The `meta_V()` reference example now uses a constant-`sigma` model so the
reference page does not present the issue #417 surface as the first copy-run
example.

## Mathematical Contract

No mathematical implementation changed. The supported model remains Gaussian
meta-analysis with known sampling variance or covariance supplied by
`meta_V(V = V)` and residual heterogeneity modelled by `sigma ~ ...`.

## Files Changed

- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `R/formula-markers.R`
- `man/meta_V.Rd`
- `docs/design/08-meta-analysis.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/48-phase-18-meta-v-ademp.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/meta-analysis.Rmd`
- `vignettes/model-map.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-meta-v-hessian-limitation-note.md`

## Checks Run

```sh
air format README.md NEWS.md ROADMAP.md R/formula-markers.R docs/design/08-meta-analysis.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/48-phase-18-meta-v-ademp.md docs/dev-log/known-limitations.md vignettes/meta-analysis.Rmd vignettes/model-map.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-meta-v-hessian-limitation-note.md
Rscript --vanilla -e "devtools::document()"
git diff --check
Rscript --vanilla -e 'pkgload::load_all(".", export_all = FALSE, helpers = FALSE, attach_testthat = FALSE); pkgdown::build_article("meta-analysis", pkg = ".", lazy = FALSE, new_process = FALSE, quiet = FALSE); pkgdown::build_article("model-map", pkg = ".", lazy = FALSE, new_process = FALSE, quiet = FALSE)'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
rg -n 'meta_V\((V = vi|V = V)\)|pdHess = FALSE|offset\(0\.5 \* log\(vi\)|issue #417|Issue #417|Hessian-based|Wald intervals|sigma ~ moderator|sigma ~ habitat|sigma ~ offset|meta_gaussian|tau ~|constant-`sigma`|predictor-dependent `sigma`' README.md NEWS.md ROADMAP.md R/formula-markers.R man/meta_V.Rd vignettes/meta-analysis.Rmd vignettes/model-map.Rmd docs/design/08-meta-analysis.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/48-phase-18-meta-v-ademp.md docs/dev-log/known-limitations.md
```

Results:

- `air format` and `git diff --check` passed.
- `devtools::document()` passed and regenerated `man/meta_V.Rd`. It also
  recompiled the package and emitted local compiler warnings from `xcrun` and
  Eigen, but exited successfully. Unrelated generated changes were restored.
- `pkgdown::build_article()` rendered the `meta-analysis` and `model-map`
  articles.
- `pkgdown::check_pkgdown()` passed with `No problems found.`
- The stale-wording scan found the intended caveats, design-boundary
  `meta_gaussian()` / `tau ~` mentions, and unrelated historical Hessian/Wald
  entries, but no new runnable `meta_gaussian()` or `tau ~` route.

## Tests Of The Tests

This was a documentation-only slice. It did not reproduce issue #417 or add a
regression test. The rendered article check is intended to catch broken vignette
syntax and documentation rendering failures.

## Consistency Audit

The wording keeps `meta_V(V = V)` as the known sampling covariance route and
does not introduce `meta_gaussian()` or `tau ~` syntax. It describes the
`pdHess = FALSE` pattern as an open issue report, not as a reproduced result in
this slice. The Phase 18 readiness docs now say that constant-`sigma`
known-`V` evidence should not be borrowed for the predictor-dependent `sigma`
surface in issue #417.

## GitHub Issue Maintenance

Issue #417 should remain open. This slice documents the current inference
caveat but does not fix the Hessian behavior or decide whether any optimizer,
parameterization, `sdreport()`, or Wald-interval status change is needed.

## What Did Not Go Smoothly

The first repository search for `meta_V`, `pdHess`, and `sigma` was too broad
because it matched historical recovery checkpoints. The final edit used the
current public surfaces instead: README, NEWS, ROADMAP, the reference example,
the meta-analysis and model-map vignettes, the design notes, and known
limitations. `devtools::document()` also produced unrelated generated-file
changes; those were restored so the only generated documentation change is
`man/meta_V.Rd`.

## Team Learning

Pat's reader test is the right standard here: an applied meta-analysis user
needs to know whether intervals can be trusted and what to try next. Rose's
audit standard kept this as a limitation note rather than a claimed fix.

## Known Limitations

This slice does not diagnose why `pdHess = FALSE` occurs, compare drmTMB and
glmmTMB likelihoods, add starts, add profile or bootstrap workarounds, or
support `offset()` in `sigma`. It also does not add code-level `pdHess` gating
for Wald interval status.

## Next Actions

Reproduce issue #417 in a focused test or diagnostic script, then decide
whether the fix belongs in starts, scaling, Hessian reporting, parameterization,
or interval fallback guidance.
