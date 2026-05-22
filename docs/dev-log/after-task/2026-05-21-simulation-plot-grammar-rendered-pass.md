# After Task: Simulation Plot Grammar Rendered Pass

## Goal

Continue the comprehensive audit by inspecting the rendered
`simulation-plot-grammar` figures, making unsupported simulation cells visible,
and recording the page-level visual evidence.

## Implemented

- Added a shared `accuracy_missing` table for the bias and RMSE displays.
- Added grey `not targeted` labels to unsupported cells in both accuracy
  figures.
- Updated the nearby prose so missing rows are explicitly part of the message.
- Recorded a per-figure audit table under
  `docs/dev-log/figure-audits/2026-05-21-simulation-plot-grammar/`.

## Mathematical Contract

No model, likelihood, or simulation result changed. The article remains a
fixture-based display contract for Phase 18 reports. Bias still uses fixture
replicate-error rows with mean-bias MCSE intervals, RMSE remains an aggregate
root-mean-square summary with its own MCSE interval, and coverage/power still
uses replicate-block proportions plus binomial MCSE intervals.

## Files Changed

- `vignettes/simulation-plot-grammar.Rmd`
- `docs/dev-log/audits/2026-05-21-function-page-figure-audit.md`
- `docs/dev-log/figure-audits/2026-05-21-simulation-plot-grammar/figure-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-simulation-plot-grammar-rendered-pass.md`

## Checks Run

```sh
air format vignettes/simulation-plot-grammar.Rmd docs/dev-log/audits/2026-05-21-function-page-figure-audit.md docs/dev-log/figure-audits/2026-05-21-simulation-plot-grammar/figure-audit.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-simulation-plot-grammar-rendered-pass.md
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('simulation-plot-grammar', new_process = FALSE, quiet = TRUE)"
rg -n 'simulation-plot-grammar_files/figure-html|<img' pkgdown-site/articles/simulation-plot-grammar.html -S
rg -n 'not targeted|replicate-block proportions|unsupported cells stay visible|fixture replicate errors|RMSE and 95% MCSE' vignettes/simulation-plot-grammar.Rmd pkgdown-site/articles/simulation-plot-grammar.html -S
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "simulation plot grammar OR simulation figures OR replicate-level simulation artifacts OR uncertainty displays" --limit 20
```

## Tests Of The Tests

This was a rendered-document and figure-audit slice, not a package code-path
change. The evidence check was direct inspection of all five active rendered
article figures after rebuilding the page.

## Consistency Audit

The active HTML references five article figures:
`bias-rmse-display-1.png`, `bias-rmse-display-2.png`,
`coverage-power-display-1.png`, `convergence-runtime-display-1.png`, and
`failure-ledger-display-1.png`. Bias and RMSE now follow the same missing-cell
contract that coverage/power already used.

## GitHub Issue Maintenance

Issue search found #255 for replicate-level simulation artifacts, #59 for the
comprehensive Phase 18 simulation framework, #58 for visualization, and #61 for
the CRAN/paper gate. This slice contributes to #58 and #255, but no issue was
closed because the broader audit and real simulation-output work remain open.

## What Did Not Go Smoothly

Earlier audit notes had accepted blank RMSE and bias cells as acceptable
negative space. The one-by-one rendered inspection made the inconsistency clear:
coverage/power labelled missing rows, while accuracy panels silently dropped
them.

## Team Learning

Florence and Fisher kept the visual standard tied to evidence: missing support
must be visible whenever the plot is teaching a simulation-reporting grammar.
Rose recorded the repeated pattern so future simulation figures do not confuse
not-fitted cells with absent plotting code.

## Known Limitations

The fixture still does not replace real Phase 18 simulation evidence. The
failure-ledger figure is honest but basic, and it should be revisited when real
warning classes, error messages, seeds, and cell identifiers are available.

## Next Actions

1. Continue the comprehensive audit with the function/reference table.
2. Revisit the failure-ledger design after real Phase 18 outputs carry richer
   warning and error metadata.
3. Keep `profile_precision = "fast"` and direct Wald CI guidance visible in the
   user-facing pages while slower profile/bootstrap routes remain targeted.
