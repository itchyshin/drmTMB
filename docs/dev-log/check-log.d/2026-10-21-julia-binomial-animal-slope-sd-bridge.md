# Julia Binomial animal-slope SD bridge

- Added an exact bridge admission for a complete-response Binomial animal slope-only model with one animal SD target.
- Mapped the R target `sd_animal(id)` to Julia’s single `sd` coefficient block and enabled group-level SD prediction/extraction.
- Aligned the synthetic fixture’s factor-level, covariance-label, and predictor order.
- Focused R test: mock route and prediction checks passed. A later live rerun in matched local development checkouts executed the R-to-Julia fit and output assertions with no failed assertions; one Julia dependency-install precompile warning (`LogExpFunctionsInverseFunctionsExt`, `loglogistic` undefined) remained. This is a passing focused run with a warning, not a warning-free package check. The live fit exercised SD-slope recovery, target naming, and group-level prediction.
- Native TMB recovery smoke: log-SD slope 0.684 for truth 0.65; optimizer gradient 2.01e-10. The Hessian diagnostic is not clean, so this is point recovery evidence only.
- Julia bridge syntax parses. An earlier live attempt failed during JuliaCall dependency setup; the later isolated-depot rerun above supersedes that attempt for this focused bridge test only. This is partial evidence, not broad parity.
- The current programme ledger records G2 met and eight gates open; this is partial work, not programme closeout.
- Interval calibration remains deferred.
