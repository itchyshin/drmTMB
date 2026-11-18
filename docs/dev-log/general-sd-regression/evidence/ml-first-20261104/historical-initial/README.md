# ML-first SD article and first repair-wave evidence

This receipt retains the bounded prediction checks, numerical probes and Gamma article candidate measured on 4 November 2026. It does not close the wider SD programme, interval calibration or the deferred REML policy.

## Source and artifact identity

`source-snapshot.json` records R base `094706b5f93d9f08bcf34b76e0328eb2293fdee5` and Julia source `f4fa3aed451636b6ffa442ce2632515513d23b1f`, source-file SHA-256 values and the reused native DLL hash. The R base has uncommitted bridge, test and documentation changes. The snapshot was captured during receipt assembly. It identifies current bytes, rather than proving that every earlier log exercised the final source. Final source-freeze revalidation and its receipt remain separate.

`artifact-manifest.json` binds the copied scripts, logs, public synthetic data, source snapshot and the sibling gap ledger. Copies preserve original bytes. `external-attempts.json` points to retained earlier setup failures and intermediate runs by absolute path, byte count and SHA-256. Those attempts are historical records, not passing checks. No fitted-object RDS or rendered HTML is committed here.

## Stored-row prediction checks

`s2-red.log` shows the original public `predict()` refusal for seven structured family/link cases. `s2-pure.log` retains the repaired payload checks and the neighbouring ordinary Gaussian suites. The additional link-specific fresh-row regression has its own red and green logs. `s2-b34-final-live.log` reports 26 live tests executed, including independently assembled conditional contributions, shuffled row/group order, non-unit covariance diagonals and selected q2 oracle checks. It retains one `NA/NaN function evaluation` warning for the Gamma relmat slope fit and the unlabeled-A warning; neither is omitted from the accounting.

These tests qualify their named stored-row R bridge output paths. They do not add conditional predictions for fresh data, new groups, standard errors or every structured provider. Direct Julia `fitted()` has its separate population-level contract.

## Numerical probes

The sibling `gap-reproduction-20261104.tsv` has 18 records, including all eight NB2 fit attempts over four retained seeds and their four paired objective comparisons. The two nonconverged plain NB2 fits returned `converged=false`; the explicit constant-SD counterparts returned true and lower negative log likelihoods. This is a reproduced optimization limitation, not a false-positive convergence finding or an estimated failure rate. All eight stored/current objective differences are zero at the stored parameters in this probe. The reported gradients are unavailable in the returned objects.

The ZeroOneBeta outcomes are mixed. Seed 20261409, minimum interior response about `2.58e-56`, returned coefficients, convergence code zero and a stored log likelihood. Its standard-error quality and gradient were not independently verified. Seed 20261412, minimum interior response about `1.55e-311`, threw `matrix contains Infs or NaNs` in the standard-error Hessian. No current point-convergence claim is made for that failed public call. Both draws retain their unchanged responses; neither was clipped. The older report that both seeds failed is historical evidence and does not replace these current outcomes.

The Binomial scalar-q1 locator at seed 20261017 returns an SD intercept near -0.442 and slope near 0.573. It is not bound to the inherited -26.9 report, whose original testset, seed and log remain missing. The clamp-versus-exponential source finding remains a known limitation and has no repair grant here. Review existing Julia PR 1223 where relevant before starting overlapping numerical work.

The stored-log-likelihood fix `8646e8d14bbb8f19e003851a3d624ed4e4030920` is already merged. The full existing `test_stored_loglik_at_optimum.jl` regression is pending in this receipt, rather than an unfixed implementation ticket. Zero deltas from the NB2 probes do not replace that suite.

## Gamma article example

`article-gamma.R` and `article-gamma-results.tsv` retain the continuous-predictor, raw non-unit-K example at seed 20261104. Native TMB and R/Julia fits each passed an independent dense Laplace objective comparison at their own coefficients, with the predeclared absolute tolerance `1e-5`. The estimated one-unit SD multiplier ratios are about 1.073, versus a generating value about 1.492. This is one checked draw, not a recovery study. `gamma-sd-data.tsv`, `gamma-sd-K.tsv` and the K-label file retain the public synthetic data for the matched direct-Julia example.

The initial Julia attempt copied native `control(se=FALSE)` and was refused by the bridge before fitting. Its script, log and result table remain here with the passing default-control run. That refusal is an API boundary, not a numerical failure. The R script saves fitted objects externally for rendering; those large runtime objects are not required for this byte-integrity receipt.

## Reproduction and remaining checks

The copied scripts are the exact executed script artifacts. The examples below are reproduction command templates, not a reconstruction of missing shell-history bytes. Select the recorded roots, a writable output directory and the same dependencies before running them. The NB2 scripts require StableRNGs in the selected Julia load path. The first attempt without that dependency is retained externally; installing or selecting a test dependency must not change the statistical fixture.

```sh
# Pure payload and neighbour checks, with the recorded native DLL available.
Rscript -e 'pkgload::load_all(compile=FALSE, quiet=TRUE); testthat::test_file("tests/testthat/test-julia-structured-stored-prediction.R", reporter="summary", stop_on_failure=TRUE)'
# Full stored-output live file. Run serially on Mac with the selected Julia bin.
NOT_CRAN=true DRMTMB_JULIA_TESTS=true OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'pkgload::load_all(compile=FALSE, quiet=TRUE); testthat::test_file("tests/testthat/test-julia-b34-structured-fitted-bridge.R", reporter="summary", stop_on_failure=TRUE)'
# Direct Julia probes; DRM_JL_PATH and JULIA_PROJECT select the recorded clone.
# Run the first seed as the timing probe before continuing the other three.
julia --project="$DRM_JL_PATH" s3-nb2-binomial.jl 20261022
julia --project="$DRM_JL_PATH" s3-nb2-binomial.jl 20261023 20261024 20261025
julia --project="$DRM_JL_PATH" s3-binomial-locator.jl
```

Set `JULIA_HOME` to the selected Julia bin directory for R/Julia calls. `s3-zeroonebeta.R` uses relative repository test paths and its retained external output path; run from the R root or copy it to a writable scratch location before adapting the output destination. `article-gamma.R` takes `ARTICLE_R_ROOT` and `ARTICLE_OUT`. Estimate runtime before rerunning any fit. The integrity check below performs no fits:

```sh
python3 docs/dev-log/general-sd-regression/evidence/ml-first-20261104/check_artifacts.py
```

This receipt makes no calibrated-interval, REML, broad-family or whole-programme completion claim.
