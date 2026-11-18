# Native Tweedie SD marginal-oracle check

- Command: `Rscript -e 'devtools::test(filter="tweedie-sd-marginal-oracle", reporter="summary")'`
- Result: passed; the test fit converged and the fitted marginal log likelihood agreed with the independent groupwise quadrature oracle within the test tolerance. Reversing the group SD map failed the oracle comparison as expected.
- Runtime: about 45 seconds on the local Mac.
- Runtime: R 4.6.0.
- Candidate: `codex/general-sd-regression`, HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- SHA-256: `src/drmTMB.cpp` `dc8fe935e80382939600c559ed287093b67d0ebff82882d5d5e013355d0feb03`; `R/drmTMB.R` `087c53b3c3fc9e8ec0702766efc8723548008b001754b6cef42b353e51be82cf`; `tests/testthat/test-tweedie-sd-marginal-oracle.R` `a245ef393fec9a59072ad71c4fdf11500f82ddc3c573dfc6f0c0fc99a84c64bc`.
- Scope: one native Tweedie SD synthetic design and one independent likelihood oracle; no interval-coverage calibration or Julia parity claim.
