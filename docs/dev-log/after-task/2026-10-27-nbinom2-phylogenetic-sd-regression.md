# After Task: NB2 phylogenetic-intercept SD regression

## Goal

Allow a complete-data NB2 model to regress the SD of one phylogenetic location intercept on a species-level predictor.

## Implemented

The NB2 builder now recognizes the canonical `sd(species, level = "phylogenetic")` target and routes it through the existing structured SD design. The admitted model has one q1 phylogenetic `mu` intercept, fixed `sigma`, no other random or structured terms, and no zero-inflation formula. The TMB likelihood already handled this scalar structured SD route; no likelihood code changed.

## Mathematical Contract

For species `g`, the latent effect is `a_g = s_g u_g`, where `u ~ Normal(0, A)` and `log(s_g) = W_g alpha`. The predictor `W_g` must be constant within species. `sigma` continues to describe NB2 observation overdispersion. This adds a multiplier to the existing phylogenetic covariance and does not normalize `A`.

## Files Changed

- `R/drmTMB.R` admits phylogenetic SD targets for the existing q1 NB2 structured route and updates the matching error messages.
- `tests/testthat/test-nbinom2-phylo-sd-regression.R` adds a deterministic synthetic fit, SD output check, and constant-SD equivalence check.
- `vignettes/predictor-dependent-random-sd.Rmd` adds a runnable synthetic example.
- `NEWS.md`, `README.md`, `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, `docs/design/59-structural-slope-and-non-gaussian-map.md`, `vignettes/formula-grammar.Rmd`, and `vignettes/model-map.Rmd` record the exact support boundary.
- `docs/dev-log/check-log.md` records the focused checks.

## Checks Run

- Before the builder change, the new test failed at the NB2 unsupported-parameter gate for `sd_phylo(species)`. This confirmed that the test reached the intended route.
- `Rscript -e 'devtools::test(filter = "nbinom2-phylo-sd-regression", reporter = "summary")'` passed. The test checks SD-slope recovery, finite group-level SD predictions, and constant-SD likelihood equivalence.
- `Rscript -e 'devtools::test(filter = "phase18-nbinom2-phylo-q1", reporter = "summary")'` passed.
- `Rscript -e 'devtools::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", quiet = TRUE)'` completed. Pandoc emitted its existing MathJax deprecation warning.
- `git diff --check` on the changed files reported no whitespace errors.
- The brain prose checker reported zero findings. The repository after-task compiler could not run because `tools/check-after-task.R` is absent from this checkout.
- The efficiency gate requested a fresh task. Recovery checkpoint: `docs/dev-log/recovery-checkpoints/2026-10-27-212746-codex-checkpoint.md`.
- A full package test, full site build, and interval calibration were not run.

## Tests Of The Tests

The first run failed with the exact unsupported NB2 structured target message. After the builder admitted the route, all focused expectations passed. The synthetic DGP uses an ultrametric tree, a group-level SD predictor, and a nonzero log-SD slope. The constant-SD fit is compared with the existing NB2 phylogenetic intercept model.

## Consistency Audit

The source, formula, TMB scaling, test DGP, and vignette agree on `a_g = s_g u_g` with `u ~ Normal(0, A)`. The status inventory search used:

```sh
rg -n -i "NB2.*(animal|structured).*SD|NB2.*structured.*SD|animal.*NB2.*direct-SD|NB2.*phylogen.*SD|NB2.*direct-SD" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml
```

The README, NEWS, formula grammar, family likelihood notes, capability map, and both affected vignettes now name this exact route. Historical dated notes were left intact. The formula grammar did not change, so pkgdown navigation did not change.

## GitHub Issue Maintenance

`gh issue list --state open --search "NB2 phylogenetic random-effect SD" --limit 10` returned unrelated test-sweep issues only. No matching open issue was found, and no issue was changed.

## What Did Not Go Smoothly

An initial patch matched a nearby family builder instead of the NB2 definition; the focused test caught the undefined target flag before fitting. The first vignette render loaded a different installed drmTMB checkout and stopped on an old formula restriction. Loading this worktree with `devtools::load_all()` fixed the render source and the complete vignette then rendered.

## Team Learning

When many family builders share similar target-detection code, anchor edits on the named function and verify its local variable definitions before running a fit. Rendered vignettes should explicitly load the active worktree when several drmTMB checkouts are installed.

## Known Limitations

This is one native TMB point-recovery route. It does not establish interval calibration, Julia parity, other structured providers, multiple structured terms, random slopes, ordinary-plus-structured combinations, random `sigma`, missing-response support, or zero-inflated NB2 support.

## Next Actions

Continue from the frozen capability universe. The current read-only family audit identifies lognormal ordinary correlated q2 SD regression as a candidate implementation gap; recheck its exact path ownership and current source before editing.
