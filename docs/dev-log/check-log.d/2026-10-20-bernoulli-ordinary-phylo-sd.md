# 2026-10-20: Bernoulli ordinary plus phylogenetic SD regression

The native binomial builder now admits one ordinary random intercept and one
phylogenetic random intercept in the same location predictor. SD regression may
target either effect or both. A deterministic nested-group DGP test covers
positive-slope recovery for both SD formulas, target-specific prediction,
binary response simulation, save/reload, and equivalence between constant SD
formulas and the constant-SD model.

The focused final rerun passed 18 assertions. The broader command
`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-(sd-integration|sd-profile|sd-simulation|correlated-sd|ordinary-phylo-sd|phylo-sd-regression)")'`
passed 513 assertions in 454.9 seconds, including the candidate's Bernoulli
intercept, slope, correlated-q2, phylogenetic, simulation, and profile tests,
plus beta-binomial SD integration selected by the filename filter. The
predictor-dependent SD vignette rendered after explicitly loading the current
worktree with `devtools::load_all()`. `pkgdown::check_pkgdown()` found no
problems; it printed existing MathML option deprecation warnings.

The focused joint test failed before the builder change with the intended
ordinary-plus-phylogenetic rejection. The base model and constant-SD model now
both fit, with log-likelihood and fixed-effect equivalence checks. A fit-free
Julia bridge suite did not run in these commands; joint Julia parity and
interval calibration remain unverified. The current full capability ledger was
not promoted or altered.
