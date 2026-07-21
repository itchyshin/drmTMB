# Figure audit: phylogenetic mixed models

## Purpose

The article's interval figure should distinguish the fitted phylogenetic
location SD from the residual SD and show the matching uncertainty interval for
each quantity. It must not turn a transformed log-SD interval into a test of a
zero variance component.

## Audit table

| Figure | Source object | Visual data grain | Uncertainty source | Missing-cell display | Reader risk | Verdict and fix |
|---|---|---|---|---|---|---|
| `gaussian-figure` | `fit$sdpars$mu`, `sigma(fit)`, and `confint(fit, parm = "variance_components")` from one simulated Gaussian fit | two fitted response-scale SD estimates from 16 species with six observations per species | default 95% Wald intervals returned by `confint()` after transformation from the log-SD scale | not applicable; both requested intervals are required and a render-time assertion rejects missing matches | the old recipe attached residual `sigma`'s interval to the phylogenetic point and omitted the residual interval; its caption and alt text then described intervals that were not actually drawn | PASS after exact parameter-name matching, two fit-within-interval assertions, removal of deprecated `geom_errorbarh()`, a zero-based x-axis, shorter direct labels, and corrected caption and alt text |

## Florence and Tufte review

Florence identified the P0 statistical mismatch: row 1 of the rendered
`confint()` table was residual `sigma` (0.232--0.313), but the old positional
code drew it beside the phylogenetic estimate (0.78). Tufte independently
recommended a compact two-row forest plot with quiet grey interval lines, blue
point estimates, no redundant title or legend, and shorter row labels for
mobile rendering. Both reviews rejected suppressing the ggplot2 warning; the
deprecated geometry was removed instead.

The page remains a one-figure article. A new tree or covariance heatmap was
considered, but not added: the immediate scientific promise is the comparison
of two fitted SDs, and an extra display would lengthen the tutorial without
repairing that inference task.

## Cross-figure checks

- Parameter rows are matched by `parm`, never by table position.
- The vignette stops during rendering if either interval is absent or if a
  point estimate falls outside its paired interval.
- The axis begins at zero because zero is meaningful for an SD.
- The caption names the interval source and the known generating values.
- The prose explicitly says that a back-transformed log-SD Wald interval is
  not a test of a zero variance component.
- The source PNG and the 390-pixel mobile rendering were inspected directly;
  both are stored beside this audit.
- The rendered HTML contains no lifecycle warning, translated-aesthetic
  warning, or other figure output leakage.

## Residual limitation

This is one simulated fit, not a recovery or coverage study. The interval
figure illustrates fitted magnitudes and uncertainty only; it does not
establish calibrated frequentist coverage or support a boundary hypothesis
test.
