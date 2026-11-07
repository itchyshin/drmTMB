# Native SD regression reruns and methods-review receipt

**Lane:** `codex/general-sd-regression`  
**Source pin:** `425bee81572c625a634b2b083050c5c57c1dc1f1`

## Checks

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-sd-regression|gamma-sd-integration", reporter = "summary")'`: passed, 40 expectations across Gamma SD-regression and integration tests.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-nbinom2-sd-regression", reporter = "summary")'`: passed, 29 expectations.
- Gamma test run estimate stated before execution: 5 to 15 minutes. ZINB2 estimate: under 10 minutes. Both completed within those estimates.
- NotebookLM browser review inspected in the notebook “General latent-SD regression: identifiability and inference (2026-10-17)” under `itchyshin@gmail.com`. Its later evaluation rejects a universal non-identifiability claim for one Bernoulli observation per cluster, distinguishes individual latent-effect recovery from population-parameter identifiability, and says the notebook sources do not establish general identifiability conditions or SD-slope interval calibration.
- `notebooklm auth check --test --json`: token fetch failed with a DNS resolution error in this environment. Browser notebook was accessible; CLI authentication is not verified.
- `Rscript ~/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-20-native-sd-rerun-notebook-review.md`: report structure passed. The global acceptance-ledger check exited 1 because nine Bernoulli/general-SD gates remain open; this evidence-only task does not close the programme.
- `python3 ~/shinichi-brain/tools/slop_check.py '<absolute after-task path>'`: 0 findings; `git diff --check` passed.

These reruns recheck existing code. They do not establish cross-family parity, structured-effect support, predictor-slope recovery, calibrated uncertainty, or full programme completion. The NotebookLM review is a research lead, not a substitute for checking the cited primary sources.
