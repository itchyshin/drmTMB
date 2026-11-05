# Native Binomial non-logit mesh SD check log (2026-10-27)

Source: branch `codex/general-sd-regression`, HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.

- `OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-mesh-sd-regression")'` — PASS, 22 assertions, 0 failures, 0 warnings, 0 skips; 10.8 seconds.
- Source manifests before and after are byte-identical for `R/drmTMB.R`, `src/drmTMB.cpp`, `R/methods.R`, `R/random-effect-scale-formulas.R`, and `tests/testthat/test-binomial-mesh-sd-regression.R`.
- `python3 tools/general-sd-regression/reconcile_evidence.py` — PASS; 19,230 candidate rows, 84 linked, 19,146 unlinked, 104 evidence records.
- Receipts and hashes: `docs/dev-log/general-sd-regression/evidence/native-binomial-nonlogit-mesh-sd-20261027/`.
- The linked probit/cloglog evidence is a single seeded point-recovery and workflow check per link. It is not interval-coverage evidence or Julia parity.
