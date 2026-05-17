# After Task: Slice 124 model-workflow emmeans example

## Goal

Add the first reader-facing `emmeans::emmeans()` example now that Slice 122
supports fixed-effect univariate `mu` estimated marginal means.

The reader is an applied ecology or evolution user working through the fitted
model workflow. They have just seen direct prediction tables and empirical
marginal summaries, so the article needs to show when an adjusted mean of `mu`
is a distinct estimand.

## Implemented

The model-workflow article now has an "Estimate marginal means for `mu`" section
after the `prediction_grid()` and `marginal_parameters()` examples. The example
uses the existing fixed-effect Gaussian location-scale fit and conditionally
calls:

```r
emmeans::emmeans(
  fit,
  ~habitat,
  at = list(temperature = 0)
)
```

The prose tells the reader to interpret the table as estimated marginal means of
native `mu` at a supplied temperature. It also sends `sigma`, random-effect,
bivariate, zero-inflated, hurdle, ordinal, contrast, and slope workflows back to
explicit prediction-table paths until their reference-grid algebra and tests
exist.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-124-model-workflow-emmeans-example.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-201508-codex-checkpoint.md`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md vignettes/model-workflow.Rmd`
- `Rscript -e "rmarkdown::render('vignettes/model-workflow.Rmd', output_dir = tempfile('model-workflow-render-'), quiet = FALSE)"`: failed because the direct render used an installed package namespace that did not expose the current development `profile_targets()` function.
- `Rscript -e "pkgload::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_dir = tempfile('model-workflow-render-'), quiet = FALSE)"`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n 'Slice 124|Estimate marginal means for `mu`|emmeans::emmeans\\(|fixed-effect univariate `mu`|native distributional parameter `mu`|at = list\\(temperature = 0\\)|reference-grid algebra and tests' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`
- `rg -n 'sigma.*emmeans.*works|random-effect.*emmeans.*works|bivariate.*emmeans.*works|zero-inflated.*emmeans.*works|hurdle.*emmeans.*works|ordinal.*emmeans.*works|contrast.*emmeans.*implemented|slope.*emmeans.*implemented|all.*emmeans.*targets|fitted response.*emmeans.*works' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md vignettes/model-workflow.Rmd pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`: returned no matches.
- `git diff --check`
- `Rscript tools/codex-checkpoint.R --goal "Slice 124 model-workflow emmeans example" --next "commit Slice 124, then wait for Slice 123 PR #88, merge it, rebase Slice 124, rerun focused checks, push, and open PR"`
- Post-rebase `git diff --check origin/main...HEAD`
- Post-rebase `Rscript -e "pkgload::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_dir = tempfile('model-workflow-render-'), quiet = TRUE)"`

## Consistency Audit

NEWS, the Phase 17 roadmap, `docs/design/39-visualization-grammar.md`, and
`docs/design/40-emmeans-interface-contract.md` all describe the example as the
first reader-facing path for fixed-effect univariate `mu` EMMs. None of the
edited prose claims support for `sigma`, random-effect, bivariate,
zero-inflated, hurdle, ordinal, contrast, or slope workflows.

## Known Limitations

- This is documentation only.
- It does not broaden the Slice 122 `emmeans` method.
- It does not teach contrasts, slopes, weights, or custom `emmeans` reference
  grid options.

## Team Notes

Pat should keep the reader-facing order as direct predictions, empirical
marginal summaries, then EMMs, because the three targets answer different
questions. Fisher should keep the word `mu` next to `emmeans()` examples until
other distributional parameters have tested reference-grid contracts. Rose
should keep stale-claim scans focused on unsupported target wording whenever a
public example is added.
