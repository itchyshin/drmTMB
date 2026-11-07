## Bernoulli correlated-q2 non-logit links

Added synthetic probit and cloglog cases for an ordinary correlated
random-intercept/random-slope block with separate predictor-dependent SDs. Each
fit converged with a positive-definite Hessian and finite SD predictions; its
fitted marginal log likelihood also matched an independent two-dimensional
Gauss-Hermite calculation (`tolerance = 0.5`).

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript --vanilla -e 'devtools::test(filter = "binomial-correlated-sd", reporter = "summary")'`
passed with exit code 0. This is one seeded native R/TMB fixture per link. It
does not establish recovery or interval calibration, nor Julia parity. The
candidate design document still labels the correlated-q2 example as logit;
that wording needs reconciliation after its overlapping references are
reviewed. No issue or PR was changed; GitHub search found no open issue specific
to this q2 link regression.
