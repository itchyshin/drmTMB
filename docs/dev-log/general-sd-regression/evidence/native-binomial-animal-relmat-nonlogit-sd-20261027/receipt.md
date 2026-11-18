# Native Binomial animal plus related-matrix non-logit SD recovery fixture

The fixed-seed fixture generates separate Binomial responses under probit and complementary-log-log links. Each response uses an animal field with additive relationship covariance `A` and a related-matrix field with covariance `K`; both latent terms have predictor-dependent SDs. For each link, the fit is required to converge, report the named SD coefficient targets, recover each generated SD slope within the test's broad predeclared tolerance, and return predictions with the expected group names.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 14 focused expectations passed without warnings across probit and cloglog. This is a one-seed point-recovery fixture with broad slope bounds; it is not precise recovery evidence or interval calibration. Synthetic data are independent of collaborator data.

Scope is native Binomial `mu` with animal `A_covariance` plus relmat `K_covariance` for the two tested links. It does not establish A-inverse, pedigree, Q-precision, other provider combinations, Julia parity, or broader family support.
