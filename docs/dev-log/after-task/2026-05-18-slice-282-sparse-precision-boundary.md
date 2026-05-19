# After Task: Slice 282 Sparse Precision Boundary

## Goal

Clarify dense covariance versus sparse precision routes for future
phylogenetic, animal-model, and `relmat()` work without adding a new fitted
likelihood. Readers should see that dense `A` or `K` matrices are small-example
or parity inputs, while scalable animal/relatedness claims require sparse
precision or inverse-relatedness routes such as `Ainv` or `Q`.

## Standing Perspectives

- Ada kept the slice to documentation and roadmap alignment.
- Jason checked the ASReml lesson: sparse inverse relationship matrices are the
  speed-relevant representation.
- Darwin checked that the biological animal-model surface stays visible.
- Pat checked that user docs distinguish `A`/`K`, `Ainv`/`Q`, and `meta_V(V =
  V)`.
- Grace checked article rendering, pkgdown, and whitespace.
- Rose checked stale claims about fitted `animal()`/`relmat()` or large-matrix
  speed.

No spawned subagents were used.

## Implemented

`docs/design/42-asreml-efficiency-lessons.md` now includes a representation
boundary table for `animal()`, `relmat()`, and `meta_V()`. The structural
article now explains that `A` and `K` are dense VCV-style covariance inputs,
while `Ainv` and `Q` are the future sparse precision or inverse-relatedness
routes. The model map now uses `meta_V(V = V)` for known sampling covariance
and states that dense `K`/`A` examples are small-to-moderate, while scalable
claims require sparse `Q`/`Ainv` evidence.

## Mathematical Contract

No model code changed. Dense covariance inputs (`A`, `K`) represent covariance
or relatedness matrices for latent random effects. Precision inputs (`Ainv`,
`Q`) represent inverse covariance or precision matrices. `meta_V(V = V)` is a
different layer: known sampling covariance among observations or effect-size
estimates. None of these planned `animal()` or `relmat()` inputs are fitted in
this slice.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/42-asreml-efficiency-lessons.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-205304-codex-checkpoint.md`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/42-asreml-efficiency-lessons.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd`
- `Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/phylogenetic-spatial.Rmd", output_dir = tempfile("phylo-spatial-render-"), quiet = FALSE); rmarkdown::render("vignettes/model-map.Rmd", output_dir = tempfile("model-map-render-"), quiet = FALSE)'`
- `rg -n 'Slice 282|dense covariance inputs|sparse precision inputs|dense VCV|Ainv|Q\\)|large-pedigree|large-matrix|sparse-precision|representation boundary|meta_V\\(V = V\\).*sampling covariance' NEWS.md ROADMAP.md docs/design/42-asreml-efficiency-lessons.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd`
- `rg -n 'large-pedigree.*implemented|large-matrix.*implemented|ASReml-like.*speed|dense `?K`?.*large|dense `?A`?.*large|Ainv.*fitted|relmat\\(.*Q.*fitted|meta_V\\(V = V\\).*relatedness|V.*Ainv|weights.*Ainv|sampling covariance.*relmat' README.md NEWS.md ROADMAP.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript tools/codex-checkpoint.R --goal "Slice 282 sparse precision boundary" --next "stage, commit, push, and open draft PR"`

Both touched articles rendered, `pkgdown::check_pkgdown()` reported no
problems, and `git diff --check` reported no whitespace errors. The stale scan
returned planned-boundary and negative-status wording, not a current claim that
`animal()`, `relmat(Q)`, or large-pedigree sparse precision paths are fitted.

## Tests Of The Tests

This was a documentation-only slice, so no unit test was added. The relevant
validation is rendered article output plus stale-claim scanning. Existing
parser and unsupported-boundary tests still cover the planned `animal()` and
`relmat()` grammar.

## Consistency Audit

NEWS and the roadmap mark Slice 282 as documentation hardening. The ASReml
lessons, model map, and structural-dependence article now agree that dense VCV
inputs are not the scalability route and that `meta_V(V = V)` is observation
sampling covariance, not latent relatedness.

## What Did Not Go Smoothly

Most of the conceptual material already existed, so the useful work was
compression: a small representation table in the design note and one matching
reader paragraph in the article. I also corrected the model-map known-covariance
row to use the preferred `meta_V(V = V)` spelling while touching the table.

## Team Learning

Jason's standing question for these slices should be "which matrix is this?"
Before implementation, every example should say whether a symbol is dense
covariance, sparse precision, inverse relatedness, or known sampling covariance.

## Known Limitations

No sparse precision likelihood, dense `A`/`K` animal or `relmat()` fit,
`Ainv`/`Q` route, sparse known sampling covariance, or benchmark was added.
Large-pedigree and large-matrix claims remain blocked until implementation,
diagnostics, recovery tests, and scaling evidence exist.

## Next Actions

Stage, commit, push, and open the Slice 282 draft PR against Slice 281, then
move to Slice 283 for the non-Gaussian family and parameter-map audit unless
the 5 AM report cutoff arrives first.
