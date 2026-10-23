# Plan versus actual — phylogenetic-stable plus independent OU reader workflow

## Planned

G14 would synchronize a reader article, reference/design documentation, and navigation. G15 would render its runnable irregular-time example and make the inference boundary visible.

## Actual

The new article distinguishes stable tree-correlated baselines, independent within-species OU deviations, and residual noise. It fits an irregular-time simulated example and shows in-sample extractors/simulation. A development notice and the limitation register state that the retained recovery failure prevents a reportable interval workflow. During implementation, the article exposed ambiguous formula-derived output labels; the implementation now reports `sd_phylo_stable`, `sd_temporal`, and `decay_temporal` for the paired route.

## Evidence

`Rscript --vanilla tools/phylo-temporal-ou-gates.R G14` returned `PHYLO_TEMPORAL_OU_G14_PASS`; `G15` returned `PHYLO_TEMPORAL_OU_G15_PASS`. The latter renders the Rmd from the current development package in an isolated temporary directory and verifies its generated HTML. Focused paired methods, profile, and gate-runner suites passed.

## Variance

No claim-bearing recovery or calibration result changed. G9 remains failed and G10--G13/G16--G18 remain open. No remote campaign, push, merge, release, or additional temporal covariance structure was started.
