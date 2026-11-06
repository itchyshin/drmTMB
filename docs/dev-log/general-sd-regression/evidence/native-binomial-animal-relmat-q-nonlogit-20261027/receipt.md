# Native Binomial animal plus related-matrix Q non-logit equivalence

A fixed-seed synthetic dataset is generated under probit and complementary-log-log links. For each link, animal `A` and relmat `K` covariance fits are compared with an otherwise identical fit using `Q = solve(K)` precision. Both fits use the same response, fixed effects, latent draws, and predictor-dependent SD formulas. The test checks convergence, likelihood, both SD coefficient vectors, and animal/population SD predictions aligned by labels.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-q-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 16 focused expectations passed across probit and cloglog. The `K` and `Q` fits agree within the stated numerical tolerances. Data are synthetic and independent of collaborator examples.

This is input-equivalence and fit/output evidence for the native Binomial q1 animal `A_covariance` plus relmat `Q_precision` route under the two tested links. It does not establish interval coverage, Julia parity, or support for other provider combinations and families.
