# Figure Audit: Simulation Plot Grammar Rendered Pass

## Scope

This pass inspected the active rendered figures in
`pkgdown-site/articles/simulation-plot-grammar.html` during the comprehensive
function, page, and figure audit. The purpose was to verify that the simulation
grammar displays the data grain, uncertainty source, and unsupported cells a
reader needs before treating Phase 18 plots as evidence.

Render command:

```sh
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('simulation-plot-grammar', new_process = FALSE, quiet = TRUE)"
```

Active rendered images:

```sh
rg -n 'simulation-plot-grammar_files/figure-html|<img' pkgdown-site/articles/simulation-plot-grammar.html -S
```

## Rendered Figure Table

| Figure | Source chunk | Visual data grain | Uncertainty source | Missing-cell display | Reader risk found | Fix | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Bias display | `bias-rmse-display` figure 1 | Fixture replicate-error rows plus aggregate mean bias | 95% MCSE interval for mean bias | Fixed during this pass: unsupported rows now say `not targeted` | Unsupported count, proportion, and meta-analysis cells were blank, so a reader could mistake missing support for a plotting omission. | Added an `accuracy_missing` table and grey `not targeted` labels. | Pass for this grammar fixture. |
| RMSE display | `bias-rmse-display` figure 2 | Aggregate RMSE rows by surface and estimand | 95% RMSE MCSE interval | Fixed during this pass: unsupported rows now say `not targeted` | Missing RMSE rows disappeared while coverage/power already labelled missing rows, creating an inconsistent visual contract. | Reused the missing-cell labels in the RMSE panel. | Pass for this grammar fixture. |
| Coverage and power | `coverage-power-display` | Replicate-block proportions plus aggregate proportions | 95% binomial MCSE interval | Already visible as `not targeted` | The panel is dense but interpretable; no source change needed in this pass. | Inspected after render. | Pass. |
| Convergence and runtime | `convergence-runtime-display` | Aggregate fit-status proportions and runtime summaries | None; descriptive diagnostic summary | Not applicable | The legend is large but readable, and the page text makes this a companion diagnostic rather than interval evidence. | Inspected after render. | Pass, with later visual-polish potential. |
| Failure ledger | `failure-ledger-display` | Stacked status counts by surface | None; descriptive failure ledger | Failure classes remain visible | The stacked ledger is honest but not a high-priority redesign compared with missing-cell and uncertainty displays. | Inspected after render; left for later Florence polish. | Watch. |

## Remaining Watch Items

- The article uses fixture data, not a completed Phase 18 operating-characteristic
  grid. The page should keep calling this a display contract.
- The failure ledger is acceptable as a quick evidence ledger, but future
  reports may need a better hierarchy once real warning classes and error
  messages are available.
- The comprehensive audit still needs function/reference table review after the
  highest-risk rendered pages are synchronized.
