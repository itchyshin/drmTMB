# Julia article execution — bounded evidence

The current `vignettes/julia-engine.Rmd` model expressions were executed by
`tools/check-julia-engine-article.R` against an isolated R install built from this
worktree. Technical files `R/`, `src/`, `DESCRIPTION` and `NAMESPACE` match frozen
source `b35642b4560072cadba7e595e66e00209ebdeb40`; subsequent changes are documentation
and verification tools. The build and final execution logs are retained beside this note.

The final receipt `article-execution-004.json` binds the article hash, installed R
namespace hash, compiled DLL hash, exact loaded Julia module path, Julia revision,
all Julia source-file digests, version1.10.0 and actual Julia/BLAS thread counts1/1.
The R namespace hash is `98c372a1de766aae75058fc5ec36bc9f8c6b27c50aa616445e691dfa7c6d2907`.
It differs from the pre-existing installed0.7.0 package; that installation was not replaced.

Verified: all five fits converge, have finite likelihoods and coefficients with the
expected dimensions, and retain the requested ML/REML labels. Ordinary predictions
are finite with120rows, predicted sigma is positive, the ordinary covariance is
finite4×4, and Wald/profile bounds are finite and ordered for the requested targets.
The ordinary ML R/Julia absolute log-likelihood difference is6.500613380922005e-10,
below the predeclared1e-6 bound. These data and all other observed outputs are retained.

The first checker attempt used `knitr::purl`, which omitted every `eval=FALSE`
example. It correctly failed for missing fits; the original receipt is retained as
`article-execution-001-missing-chunks.json`. The corrected runner extracts literal
R code fences. Deliberately collapsed, missing and failed-status intervals are
negative controls and must fail before example execution proceeds.

Reproduce from the repository root with prepared isolated dependencies:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript tools/check-julia-engine-article.R \
  /private/tmp/drm-parity-20260830/R-lib \
  /private/tmp/drm-parity-20260830/DRM.jl \
  /private/tmp/drm-parity-20260830/article-execution-new.json
```

`SETUP_PROVIDED` means packages and checkout were supplied; it is not a clean-machine
installation test. This evidence does NOT cover full cross-engine coefficient/SE parity,
REML interval correctness, interval coverage, performance comparisons, large trees,
whole-site rendering or public deployment. It closes only the bounded example-execution
check; the full programme and documentation gates remain open.
