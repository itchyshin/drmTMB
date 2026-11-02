# Native Binomial structured-pair SD evidence

The native TMB Binomial q1 phylogenetic-tree plus coordinate-spatial intercept pair was tested under logit, probit, and cloglog links. The q1 animal plus relatedness-covariance pair was tested under logit. The q1 animal plus coordinate-spatial pair was tested under logit with animal A covariance, equivalent A-inverse precision, and pedigree inputs. Each recovery fixture generated binary outcomes from independent latent fields with separate predictor-dependent SDs.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-spatial-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 60 focused expectations passed with no failures or warnings. Tests check optimizer convergence, recovery bounds for both SD slopes, target names and profile-index separation, group-SD predictions, the animal covariance/precision likelihood and prediction equivalence, and pedigree-input recovery. The animal plus spatial covariance fixture uses 72 sites after a 36-site pilot drove its spatial SD slope to a boundary; the recovery bounds were not relaxed. The retained console output is `focused-tests.log`.

This is one-seed point-recovery and output evidence for these exact complete-data q1 provider pairs and animal inputs. It is not interval-coverage evidence, Julia parity, evidence for other provider pairs, or broad Bernoulli support. The source hashes are in `source-manifest.json`.


Current-source rerun (2026-10-27): exit 0; 60 expectations passed with no failures or warnings. Console: `current-source-rerun.log`. Source hashes in the refreshed manifest bind the exact R builder, TMB objective, and test file exercised. The two previously mislabeled ledger rows were corrected to their actual probit and cloglog links.
