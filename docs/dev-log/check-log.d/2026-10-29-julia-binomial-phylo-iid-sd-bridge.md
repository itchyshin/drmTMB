# Julia Binomial phylogenetic plus IID SD bridge

- Date: 2026-10-29
- Source worktree: `general-sd-regression`; paired DRM.jl worktree: `general-sd-julia`.
- `NOT_CRAN=true Rscript -e 'pkgload::load_all("."); testthat::test_file("tests/testthat/test-julia-binomial-phylo-iid-sd-bridge.R", reporter = "summary")'`: pure bridge tests passed (12 expectations); live test skipped because DRM.jl path was not set.
- With Julia 1.10.0, `JULIA_NUM_THREADS=4`, `OPENBLAS_NUM_THREADS=1`, `DRMTMB_JULIA_TESTS=true`, and `DRM_JL_PATH` set to the paired worktree, the same focused test passed including live probit/cloglog fits, SD prediction comparisons, log-likelihood comparison and marginal simulation.
- Adjacent live animal-plus-IID Binomial probit/cloglog bridge test: passed.
- Linked candidate probit/cloglog Julia rows with the retained receipt and source manifest; the evidence reconciler passed at 20,350 candidate rows, 224 evidence records, 201 linked rows, and 20,149 unlinked rows. No capability rows were promoted.
- `git diff --check -- R/julia-bridge.R`: passed; repository-wide diff check reports an unrelated existing trailing blank line in `tests/testthat/test-binomial-sd-integration.R`.
- No full package checks or interval-coverage validation were run. See `docs/dev-log/after-task/2026-10-29-julia-binomial-phylo-iid-sd-bridge.md` for scope and residuals.
