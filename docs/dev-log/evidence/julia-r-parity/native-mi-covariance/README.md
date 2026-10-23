# Native missing-predictor regression covariance

The public blocks `mi_<variable>` were mapped to nonexistent `beta_mi_<variable>` parameters. Native TMB stores the first and second predictor regressions as `beta_mi` and `beta_mi2`. This caused missing public covariance rows, standard errors and unavailable interval targets despite finite fitted covariance.

`R/profile.R` now resolves exact stored variable metadata at all three object-aware callers. Ordinary mappings are unchanged. No likelihood, optimizer, tolerance or frozen fixture changed.

The regression test fits two finite predictor families and two independent Gaussian predictors. It checks the whole selected covariance against native TMB covariance, nonzero response/predictor and between-predictor cross-covariances, finite summary SEs, target ordering and exact raw-normal Wald intervals. It also tests malformed metadata and exact punctuation-sensitive matching. RED retained 16 failures; final gate has 101 passing assertions. `receipt-004.json` stamps the final test and R working-tree source before/after execution; it does not certify a clean committed-head build or warm speed.

Rose independently approved the bounded source repair (`R/profile.R` SHA256 `455310984cf1244a90b7f3ce184e82a1f75fbdf50acde243694b53d181d6b5a5`) and ran pure mapping boundary checks. Root added the suggested persistent cross-covariance and excluded-scale checks.

Still required: positive predictor scales are exported after exp(), and mixture probabilities after plogis(). Their covariance needs both axes transformed by the Jacobian, with separate link-scale profile metadata. They remain unavailable in this bounded repair, rather than incorrectly returning raw-scale covariance. Actual profile/bootstrap workflows and full native/Julia interval-convention reconciliation remain open. Strict finite-state native parity still fails 4e-6; see `../finite-stopping/`.

Run from the R checkout:

```sh
OPENBLAS_NUM_THREADS=1 Rscript -e 'pkgload::load_all(quiet=TRUE,recompile=FALSE); testthat::test_file("tests/testthat/test-missing-predictor-public-covariance.R",stop_on_failure=TRUE)'
```
