# Check log: Julia Binomial phylogenetic SD output names

- Date: 2026-10-29
- Source: drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`.
- Command: `JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0; filtered test file passed; three live Julia bridge tests ran.
- Repair: corrected test expectations for the established distinction between tip names from `predict()` and target-qualified names in stored `sdpars`; values are compared separately.
- Evidence registration: linked three rows in `direct-sd-evidence.tsv` for the tree provider under logit, probit, and cloglog. `tools/general-sd-regression/reconcile_evidence.py` passed with 196 receipt records, 176 linked rows, and 20,174 unlinked rows of 20,350.
- Receipt: `docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-sd-bridge-live-20261029/receipt.md`.
- Boundary: focused fit/output evidence only. No interval-coverage, broad parity, full-suite, or release claim.
- Detailed report: `docs/dev-log/after-task/2026-10-29-julia-binomial-phylo-sd-output-names.md`.
