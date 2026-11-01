# Native Binomial ordinary plus animal SD input equivalence

A fixed-seed synthetic Binomial logit dataset was fit three times with an ordinary iid group intercept and an animal SD regression: supplied additive relationship covariance `A`, its inverse precision `Ainv = solve(A)`, and pedigree input that reconstructs the same additive relationship matrix. The test checks optimizer convergence, same-data log likelihood, both SD coefficient vectors, and animal SD predictions aligned by animal labels.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-animal-kernel-equivalence-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 11 focused expectations passed. A-inverse precision and pedigree fits match the A covariance fit within the test tolerances for likelihood, coefficients, and named predictions. The synthetic data are independent of collaborator data.

This is input-equivalence and fit/output evidence for native Binomial logit with an ordinary iid intercept plus an animal SD regression. It does not establish interval coverage, Julia parity, or support for other families, links, providers, or effect structures.
