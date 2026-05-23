# After Task: Rendered Figure QA Slices 51-60

## Goal

Continue the rendered-figure QA sequence through slice 60 by merging the
previous figure PR, then improving the `convergence` article with diagnostic
figures that separate clean optimization, skipped uncertainty, and unfinished
optimization.

## Implemented

Merged PR #308 after its Ubuntu, macOS, and Windows checks were green, then
started `codex/rendered-figure-qa-51-60` from updated `origin/main`.

The `convergence` article now has:

- a rendered `check_drm()` status map from three tiny fitted examples;
- a rendered optimizer-budget versus maximum fixed-gradient diagnostic panel;
- captions and alt text that identify the figures as diagnostic status
  displays, not uncertainty intervals; and
- article-level setup for white-background rendered figures.

The rendered article checklist now records two active `convergence` figures.
The visualization grammar now includes `check_drm()` diagnostic summaries in
the case-by-case display table.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
the rendered figures; Fisher checked data grain and uncertainty provenance;
Pat and Darwin checked reader interpretation; Noether checked that axes and
status labels matched diagnostic quantities; Curie checked that the tiny fits
exercise the intended diagnostic states; Grace checked rendering, alt text,
tests, and pkgdown; Rose checked the ledger and repeated one-rule-fits-all
drift.

## Mathematical Contract

No likelihood, formula grammar, optimizer, diagnostic, extractor, interval
method, or exported plotting helper changed. The fitted examples use existing
`drmTMB()`, `drm_control()`, and `check_drm()` behaviour.

The new figures are diagnostic displays:

- tile colours show `check_drm()` statuses such as `ok`, `note`, and
  `warning`;
- the gradient/budget panel shows optimizer counts and maximum fixed-gradient
  size; and
- the dotted threshold is the `check_drm()` fixed-gradient warning threshold.

They are not Confidence Eyes, confidence intervals, posterior probabilities,
or model-estimate uncertainty displays.

## Files Changed

- `vignettes/convergence.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/audits/2026-05-22-rendered-article-checklist.md`
- `docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-51-60.md`
- `docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-51-60.md`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-prediction-grid.R`

## Checks Run

```sh
gh pr view 308 --json number,title,url,state,isDraft,mergeStateStatus,statusCheckRollup,headRefName,baseRefName
gh api -X PUT repos/itchyshin/drmTMB/pulls/308/merge -f merge_method=squash -f commit_title='Polish animal and relmat figure QA slices (#308)'
git push origin --delete codex/rendered-figure-qa-46-50
git fetch origin --prune
git switch -c codex/rendered-figure-qa-51-60 origin/main
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('convergence', new_process = FALSE, quiet = TRUE)"
Rscript -e "html <- paste(readLines('pkgdown-site/articles/convergence.html', warn = FALSE), collapse = '\n'); m <- gregexpr('<img[^>]+src=\"convergence_files/figure-html/[^\"]+\"[^>]*>', html, perl = TRUE); imgs <- regmatches(html, m)[[1]]; if (identical(imgs, character(0))) imgs <- character(); missing <- imgs[!grepl('alt=\"[^\"]+', imgs)]; cat(length(imgs), 'article images,', length(missing), 'missing alt text\n')"
Rscript tools/fix-pkgdown-reference-alt.R pkgdown-site
air format vignettes/convergence.Rmd docs/design/39-visualization-grammar.md docs/dev-log/audits/2026-05-22-rendered-article-checklist.md docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-51-60.md docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-51-60.md
Rscript -e "devtools::test(filter = 'check-drm|control', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'convergence-check-map|convergence-gradient-budget|diagnostic statuses|skipped uncertainty|failed optimization|fixed-gradient warning threshold' vignettes/convergence.Rmd docs/design/39-visualization-grammar.md docs/dev-log/audits/2026-05-22-rendered-article-checklist.md pkgdown-site/articles/convergence.html
rg -n 'Confidence Eye|posterior|credible' vignettes/convergence.Rmd docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-51-60.md docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-51-60.md pkgdown-site/articles/convergence.html
gh run view 26333207178 --json status,conclusion,displayTitle,headSha,url,jobs
Rscript -e "devtools::test(filter = 'prediction-grid', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'prediction-grid|check-drm|control', reporter = 'summary')"
gh run watch 26333560880 --exit-status
gh api repos/itchyshin/drmTMB/actions/jobs/77523481904/logs
gh api repos/itchyshin/drmTMB/actions/jobs/77523481894/logs
gh api repos/itchyshin/drmTMB/actions/jobs/77523481889/logs
Rscript -e "devtools::build_vignettes()"
```

PR #308 was green on Ubuntu, macOS, and Windows before merge. It was
squash-merged as `2c1108ec559b0bf17f6cf3c121a4c844f5969e92`, and the remote
branch was deleted.

The `convergence` article rebuilt successfully. Article-image alt-text
inspection found 2 referenced article images and 0 missing alt attributes.
The generated-reference alt-text post-processor completed without output.
The focused `check-drm` and `control` test shards passed. `git diff --check`
was clean. `pkgdown::check_pkgdown()` reported no problems.

The rendered/source status scan found the new convergence chunk labels,
diagnostic-status wording, skipped-uncertainty wording, and fixed-gradient
threshold wording in the source and rebuilt article. The negative scan found
only intentional statements that diagnostic figures are not Confidence Eyes,
posterior probabilities, or credible intervals.

The first PR #309 CI run failed before merge. Ubuntu and macOS reached package
checks but treated OS-sensitive `TMB::sdreport()` `NaNs produced` warnings in
`test-prediction-grid.R` as failures; Windows failed earlier in checkout with
`could not read Username for 'https://github.com': terminal prompts disabled`.
The prediction-grid tests check grid construction and point prediction, not
Wald standard errors, so their tiny fixture fits now use
`control = drm_control(se = FALSE)`. The focused prediction-grid shard and the
combined `prediction-grid|check-drm|control` shard passed locally after that
change.

The next PR #309 CI run reached R CMD check on all three platforms and failed
during `convergence.Rmd` vignette rebuilding because the new evaluated figure
chunk called `drmTMB()` without attaching the package in the vignette itself.
The hidden setup chunk now calls `library(drmTMB)`, matching the other
fitted-model vignettes. `devtools::build_vignettes()` passed locally after
that fix, including the `convergence-check-map` and
`convergence-gradient-budget` chunks.

## Tests Of The Tests

This slice changes article plotting recipes and documentation. The diagnostic
figures are built from actual tiny fitted `drmTMB` examples rather than a
hand-written status table, so the rendered chunks exercise `drmTMB()`,
`drm_control(se = FALSE)`, deliberately low optimizer budgets, and
`check_drm()` status output.

The CI-warning fix also tightened an existing test contract: prediction-grid
tests that only need point predictions no longer depend on Hessian standard
error extraction from tiny fixture fits.

The check-like vignette build failed before the setup fix and passed after it,
so the test of the test is direct: the evaluated `convergence` chunks are now
self-contained under vignette rebuilding, not just under pkgdown rendering.

## Consistency Audit

The case-by-case visual rule still holds:

- `check_drm()` status maps show diagnostic state, not uncertainty;
- skipped Hessian and standard-error rows from `se = FALSE` are notes, not
  failed optimization;
- low-budget optimizer and gradient rows are warnings that should be resolved
  before Wald interpretation;
- no raw response points appear on diagnostic status axes; and
- no Confidence Eye geometry was added to diagnostic figures.

## GitHub Issue Maintenance

Opened PR #309:
<https://github.com/itchyshin/drmTMB/pull/309>.

Updated the overlapping visualization-layer issue #58 with the slice summary
and validation evidence:
<https://github.com/itchyshin/drmTMB/issues/58#issuecomment-4525406911>.

## What Did Not Go Smoothly

The first gradient/budget render used bars on a log scale. Florence rejected
that because bar baselines on a transformed axis made the clean-gradient
comparison look more precise than it was. The accepted render uses lollipop
points and a named threshold instead.

After the PR was opened, CI exposed a separate test-fixture problem in
`test-prediction-grid.R`. Grace treated it as part of the PR gate because a red
package check blocks the figure slice even when the visual code itself is
sound.

The second CI run exposed that pkgdown rendering had hidden a vignette
self-containment problem. Evaluated article chunks need the package attached in
the vignette, even when local `pkgdown::build_article()` succeeds.

## Team Learning

Diagnostic figures need the same case-by-case discipline as estimate figures.
A status map can be beautiful and useful without carrying uncertainty
geometry, but the caption must tell readers that the visual object is a
diagnostic state.

## Known Limitations

This slice does not add a public `plot_diagnostics()` helper. The recipe stays
inside the article until the diagnostic-plot data contract is stable and
tested.

## Next Actions

1. Re-run PR #309 CI after the `convergence.Rmd` setup fix.
2. Continue the rendered-figure sweep with slice 61, likely `large-data` or a
   family-specific article.
