# Bernoulli SD timing pre-run, current candidate

Date: 2026-10-20

## Commands and result

- `R CMD build --no-manual --no-build-vignettes` built the dirty candidate at HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- The package installed on Totoro in an isolated library. R version: 4.6.1. Installed DLL SHA-256: `22db49e02869f5cca21638ed2d9eb137739f85876157675ebda8d3249ce997ca`.
- `prepare-095.R --timing` created a source-hashed 45-row capsule. `run-095.py` completed all 45 attempts with 16 workers. `summarize-timing-095.R` reported 45 valid 95% profiles, `calibration_claim=false`, and a complete supervisor receipt.
- Independent scalar Laplace-oracle checks passed for all 45 fits. Maximum absolute discrepancy: `7.2211e-8` against tolerance `1e-6`. There were no warnings, errors, or profile boundaries.
- Supervisor elapsed time: 41.63 seconds. Mean per-fit elapsed time: 12.37 seconds. A direct-rate 9,000-fit projection is 138.8 minutes; with 20% added, 166.5 minutes. The estimate is below 175 minutes but close, and does not supersede the slower partial v8 run's 218-minute projection.

## Source comparison and scope

The candidate package differs from first-look v4 in four pinned core files. Three fixed synthetic Bernoulli datasets were fit with both installed libraries. Convergence, Hessian status, gradient, log likelihood, and all reported location and SD coefficients were byte-identical for these three rows. This is limited ordinary-path equivalence evidence, not proof of full source equivalence or uncertainty calibration.

No calibration attempts were added and no look-two run was launched. G2 remains open pending source-bound adapter qualification, review of first-look versus campaign code paths, and a fresh campaign decision. Full hashes and retained outputs are in `docs/dev-log/general-sd-regression/evidence/calibration-20261020/timing-current-source-v1/`.
