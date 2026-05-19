# After Task: Slice 281 Structured User Surface

## Goal

Finalize a clearer user surface for planned `animal()` and `relmat()` syntax
without claiming a fitted animal-model or lower-level relatedness likelihood.
The article should tell applied ecology and evolution readers what syntax is
planned, what fitted sensitivity model to use now, and when a known matrix
belongs to `meta_V(V = V)` instead of a future latent relatedness route.

## Standing Perspectives

- Ada kept this as documentation hardening, not implementation.
- Darwin checked that the examples name ecological and evolutionary questions.
- Pat checked that readers see what they can fit now.
- Jason checked that `animal()`, `phylo()`, `spatial()`, and `relmat()` remain
  separate routes rather than one generic matrix hook.
- Grace checked article rendering, pkgdown, and whitespace.
- Rose checked for stale claims that animal or `relmat()` models are fitted.

No spawned subagents were used.

## Implemented

The structural-dependence article now adds a planned-question table for
`animal()` and `relmat()` use cases. It pairs planned syntax such as
`animal(1 | individual, pedigree = pedigree)`, `animal(1 | individual, A = A)`,
and `relmat(1 | line, K = K)` with fitted actions available now, such as
ordinary repeatability sensitivity models or the already fitted `phylo()` and
coordinate-spatial routes. The model map now adds the same boundary in prose:
known sampling covariance among observations or effect-size estimates belongs
to `meta_V(V = V)`, while `relmat()` is reserved for future latent
random-effect relatedness or precision matrices.

## Mathematical Contract

No likelihood, formula parser, or parameterization changed. `animal()` and
`relmat()` remain parsed and documented planned markers. `meta_V(V = V)` remains
observation-level known sampling covariance. Ordinary `(1 | group)` sensitivity
models remain independent group-level random effects and should be reported as
ignoring pedigree or known-matrix relatedness.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-204717-codex-checkpoint.md`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd`
- `Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/phylogenetic-spatial.Rmd", output_dir = tempfile("phylo-spatial-render-"), quiet = FALSE); rmarkdown::render("vignettes/model-map.Rmd", output_dir = tempfile("model-map-render-"), quiet = FALSE)'`
- `rg -n 'Slice 281|Structural-dependence docs|planned animal|relmat\\(\\).*future latent|Fitted action now|repeatability sensitivity|matrix is sampling covariance|meta_V\\(V = V\\).*relmat|latent relatedness|observation-level known sampling covariance' NEWS.md ROADMAP.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd`
- `rg -n 'animal\\(.*Implemented|relmat\\(.*Implemented|animal\\(.*fitted|relmat\\(.*fitted|relmat\\(.*sampling covariance|meta_V\\(V = V\\).*latent relatedness|V.*relatedness.*relmat|weights.*relatedness' README.md NEWS.md ROADMAP.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript tools/codex-checkpoint.R --goal "Slice 281 structured user surface" --next "stage, commit, push, and open draft PR"`

Both touched articles rendered. The stale-claim scan returned only intended
planned-boundary, design, or negative-status wording; it did not find a current
claim that `animal()` or `relmat()` are fitted likelihoods. `pkgdown` reported
no problems, and `git diff --check` reported no whitespace errors.

## Tests Of The Tests

This was a documentation-only slice, so no package test was added. The rendered
article check is the key validation: it exercises the new table and surrounding
R Markdown in the same article that users read. Existing parser and boundary
tests for `animal()` and `relmat()` remain unchanged.

## Consistency Audit

The roadmap now marks Slice 281 as documentation hardening only. NEWS describes
the clearer user surface without claiming fitted support. The structural article
and model map both keep `animal()` and `relmat()` as planned latent relatedness
routes and direct observation-level known sampling covariance to
`meta_V(V = V)`.

## What Did Not Go Smoothly

The repository already had much of the animal/`relmat()` scaffold, so the main
risk was duplicating text. I kept the patch narrow by adding one action table in
the structural-dependence article and one boundary sentence in the model map.

## Team Learning

Pat's useful standard here is "what do I fit today?" Planned syntax is less
confusing when it sits beside an honest fitted sensitivity model and a sentence
that says what the sensitivity model omits.

## Known Limitations

No animal-model, `A`/`Ainv`, `relmat(K)`, `relmat(Q)`, combined phylogenetic and
spatial, or sparse precision likelihood was added. These routes still need
matrix validation, diagnostics, profile targets, recovery tests, and examples
before they can enter Phase 18 fitted grids.

## Next Actions

Stage, commit, push, and open the Slice 281 draft PR against Slice 280, then
move to Slice 282 for sparse precision and dense-VCV boundary wording unless
the 5 AM report cutoff arrives first.
