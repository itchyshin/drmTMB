# After-task — phylogenetic-stable plus independent OU reader workflow

## 1. Goal

Deliver and render a scientifically usable article for the paired phylogenetic-stable plus independent OU model without promoting it beyond its retained evidence.

## 2. Implemented

Added `vignettes/phylogenetic-temporal-effects.Rmd`, a development-marked pkgdown navigation entry, formula and likelihood contracts, a limitation-register entry, G14/G15 runner checks, and public component labels `sd_phylo_stable`, `sd_temporal`, and `decay_temporal`.

## 3a. Decisions and Rejected Alternatives

The article explains the additive stable-phylogenetic plus within-species OU covariance. It does not describe the later separable phylogeny-by-OU field as implemented, and it does not show a reportable confidence-interval workflow because G9 failed its fixed-effect recovery criterion.

## 4. Files Touched

- `R/drmTMB.R`, `R/temporal.R`, and `R/profile.R`
- paired OU methods/profile/gate-runner tests and gate runner
- `vignettes/phylogenetic-temporal-effects.Rmd` and `_pkgdown.yml`
- formula grammar, likelihood design, limitation register, acceptance ledger, check log, this report and the matching plan-versus-actual record

## 5. Checks Run

`Rscript --vanilla tools/phylo-temporal-ou-gates.R G14` and `G15` each returned their expected PASS token. The paired methods, profile, and gate-runner suites passed. G15 rendered the Rmd from the development package into an isolated temporary directory and checked its HTML content.

## 6. Tests of the Tests

The first article fixture exposed formula parsing against the installed package rather than the development namespace; G15 now explicitly loads the local package before rendering. The first label check exposed formula-echo component names, so the paired model now carries stable/temporal/decay names through extraction, fresh simulation, and profile-target construction.

## 7a. Issue Ledger

G14 and G15 pass. G9 remains unmet: 24 retained primary fits passed SD and decay criteria but missed the predeclared mean fixed-effect recovery threshold. The reader article displays that limitation.

## 8. Consistency Audit

The article equation, parser syntax, likelihood documentation, public parameter labels, simulation lookup, profile lookup, limitation register, and pkgdown title all describe the same additive covariance. The workflow preserves genuine elapsed-time gaps and keeps the input tree bound by name.

## 9. What Did Not Go Smoothly

The initial reader chunk queried non-existent simplified metadata fields. This revealed that the public output still used inconsistent formula-derived labels. The correction made the labels meet the scientific contract instead of changing the article to conceal the discrepancy.

## 10. Known Residuals

The paired route remains development-only. No calibration campaign, remote computation, Wald/profile/bootstrapped paired-model inference, variance/decay intervals, forecasting, or `newdata` prediction is qualified.

## 11. Team Learning

A reader example is an extractor test: forcing a concise scientific explanation can expose names that are technically present but too ambiguous for reporting. Component labels should describe the estimand, not repeat the formula.

## 12. Cross-Product Coverage

This work does not cover the separable phylogeny-by-OU field, independent temporal AR1/OU calibration beyond existing evidence, Toeplitz, heterogeneous AR1/Toeplitz, ARMA, seasonal, random-walk, or temporal Matérn structures.
