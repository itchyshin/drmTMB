# Native Binomial ordinary plus animal SD non-logit input equivalence

A fixed-seed synthetic dataset was generated separately under probit and complementary-log-log links. For each link, three native R/TMB fits used the same response and design: supplied additive relationship covariance `A`, its inverse precision `Ainv = solve(A)`, and pedigree input reconstructing the same additive relationship matrix. Each model included an ordinary iid group intercept and predictor-dependent SD formulas for both terms. The tests check convergence, same-data log likelihood, both SD coefficient vectors, and animal SD predictions aligned by animal labels.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-animal-kernel-equivalence-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 22 focused expectations passed for probit and cloglog. For both links, A-inverse precision and pedigree fits match the A covariance fit within the test tolerances. The synthetic data are independent of collaborator data.

This is input-equivalence and fit/output evidence for native Binomial probit and cloglog with an ordinary iid intercept plus animal SD regression. It does not establish interval coverage, Julia parity, or support for other families, links, providers, or effect structures.
