# Beta ordinary SD small-group recovery smoke

`test-beta-sd-regression.R` passed all 26 expectations with `NOT_CRAN=true`, including new independent 36-group intercept and 40-group slope SD recovery fits. The existing Beta intercept and slope integration files also passed on the current loaded source; they cover public predictions, save/reload, constant-SD equivalence, and independent slope quadrature with a reversed-map control. The adapter map now says Beta supports an ordinary intercept and one independent numeric slope. This is native point-recovery evidence only. Julia parity and interval calibration remain open.

Exact command for the new focused file:

```sh
NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-beta-sd-regression.R", reporter = "summary")'
```

Exact command for the existing integration files:

```sh
NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-beta-sd-integration.R", reporter = "summary"); testthat::test_file("tests/testthat/test-beta-sd-slope-integration.R", reporter = "summary")'
```
