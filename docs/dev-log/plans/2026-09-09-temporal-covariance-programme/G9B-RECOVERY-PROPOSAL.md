# G9b proposal — paired phylogenetic-stable plus independent OU recovery

**Status:** draft for user approval. This document changes no gate, seed,
threshold, artifact, or supported claim unless the user explicitly approves it.

## Why G9 cannot be reinterpreted

The frozen G9 denominator remains failed. It retains 24 selected fits and 48
starts, with all SD and decay criteria passing but aggregate mean fixed-effect
MAE above 0.15. Its coefficient-specific results identify the mechanism:

| Denominator | Intercept MAE | Between-species contrast MAE | Within-species contrast MAE |
| --- | ---: | ---: | ---: |
| v4, 50 species | 0.339 | 0.131 | 0.077 |
| v6 diagnostic, 80 species | 0.336 | 0.104 | 0.055 |

A sampled tree-correlated stable intercept is a single realised population
shift. Its distributional mean is zero, but a finite realised tip average is
not constrained to zero. The treatment contrasts answer the intended fixed
mean-effect question. The original aggregate metric conflates those two
quantities. G9 remains a retained failure rather than becoming a pass by
reinterpretation.

## Proposed G9b contract

G9b would be a new gate with new, predeclared fixtures and a separate two-part
assessment. It would retain every selected fit, both decay starts, warning, and
failure. The current v4/v6 artifacts would remain immutable historical
counterexamples.

### G9b-A: reportable treatment contrasts

Generate 24 new balanced/unbalanced fixtures with the same model, parameter
grid, raw-time rules, and independently permuted between/within predictors as
G9. Freeze a new seed manifest before execution. The primary estimands are
`between` and `within`; the intercept is reported but not pooled into their
recovery metric.

- At least 22 finite selected fits and exactly 48 retained starts.
- Mean absolute error at most 0.15 for each contrast separately.
- Median absolute log-SD error at most 0.25 across stable phylogenetic,
  temporal, and residual SDs.
- Median absolute log-decay error at most 0.35.
- Report signed error, MAE, median absolute error, warnings, and results by
  balanced/unbalanced layout and phylogenetic SD.

### G9b-B: ensemble population-mean intercept diagnostic

Use a separate tree-and-response replicate study, not a single-tree error
threshold. For each of the three phylogenetic SD values, generate 100
independent trees and responses with a centred fixed design and the G9 timing
layouts. Estimate the intercept in every finite fit. Report signed ensemble
bias, empirical SD, MAE, median absolute error, convergence, and variance/decay
recovery. The primary diagnostic is whether the signed ensemble intercept bias
is small relative to its empirical sampling SD; the proposed prespecified bound
is `abs(mean(error)) / sd(error) <= 0.10` per phylogenetic-SD cell.

This part distinguishes an estimator bias from the expected uncertainty of one
realised tree. It does not create a single-data-set intercept-accuracy claim.

## Compute and decision gates

Before a full G9b run, a five-seed local pilot must measure elapsed time,
memory, denominator completeness, and both metric families. The expected
full ensemble study is likely longer than 30 minutes, so it requires a measured
resource plan and explicit campaign approval after the pilot. No campaign,
remote run, or G9b fixture generation is authorized by this draft.

## Consequences of approval

Approval would authorize adding G9b to the P1 ledger, freezing its seed
manifest and runner, then running only its bounded local pilot. A successful
G9b-A and G9b-B would repair point-recovery evidence only. It would not qualify
fixed-effect interval coverage, variance/decay intervals, forecasting,
`newdata`, the separable phylogeny-by-OU field, or P2 Toeplitz.
