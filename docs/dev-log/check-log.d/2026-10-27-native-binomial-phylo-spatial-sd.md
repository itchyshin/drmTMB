# Native Binomial phylogenetic plus spatial SD regression

- Focused command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-spatial-sd|binomial-phylo-sd-regression|binomial-spatial-sd-regression|binomial-phylo-sd-simulation", reporter = "summary", stop_on_failure = TRUE)'`.
- Result: PASS; the four selected suites completed with no failures. Console transcript: `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-spatial-sd-20261027/focused-tests.log`.
- The new fixture fits one logit Binomial model with crossed phylogenetic and coordinate-spatial q1 intercepts, each with its own SD regression. It checks point recovery, group SD predictions, direct profile-target identity and coefficient indexing, combined conditional prediction, simulation, structured-effect extraction, and save/reload. Per-group SD values remain derived profile targets; no interval endpoints or coverage were tested.
- Documentation updated in `vignettes/predictor-dependent-random-sd.Rmd`, `docs/design/18-random-effect-scale-models.md`, and `docs/design/06-distribution-roadmap.md`.
- Julia parity, other links, other structured-provider pairs, intervals, and the full package suite were not tested in this slice.
