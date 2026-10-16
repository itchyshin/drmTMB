Target: https://github.com/itchyshin/drmTMB/issues/1554
Status: NOT POSTED (GitHub write 403). Do not re-file. Julia-side optimum miss is a separate new issue draft: `sweep-oct16/t8/issues/NEW_DRModels_GasolineYield.md`.

---

**sweep-oct16 t8 real-data neighbour (16 Oct 2026).** `betareg::GasolineYield` Beta loc-scale, `yield ~ temp + batch`, `sigma ~ batch`, n = 32, 10 batches with 2–4 rows. Weakly identified interior, not an exact alias (so not #1470).

| engine | logLik | `is_converged` | SEs |
|---|---|---|---|
| drmTMB `ca3ddef` | 92.0596218477018 | FALSE (degenerate Hessian; opt message "relative convergence (4)") | refused (`sdreport` not PD) |
| glmmTMB 1.1.15.2 | 92.0596218474146 (Δ vs drmTMB 2.9e-10) | TRUE | finite |
| DRModels.jl `f71b292` | 92.04282636918045 (Δ vs drmTMB **0.0168**) | FALSE | finite, printed |

Two pieces for this contract:

1. drmTMB and glmmTMB sit at the same optimum; drmTMB says FALSE because the Hessian is not PD, glmmTMB says TRUE. That is question 3 of this issue ("interior MLE that exists but is weakly identified") on real data rather than the t4 grid.
2. Unlike the 182 t4 fits where the twins share an optimum and only the flag differs, Julia is 0.017 nats short **and** still emits SEs. That is not this issue's "same optimum, different flag" census; it is drafted as a new DRModels.jl issue (write API 403 on this run).

**Source / prep / repro.** `betareg::GasolineYield` 3.2-6. Full CSV, prep, and scripts: `sweep-oct16/t8/issues/NEW_DRModels_GasolineYield.md` and `sweep-oct16/t8/data/GasolineYield.csv`. Pins: drmTMB `ca3ddef`, DRModels.jl `f71b292`. R 4.3.3, Julia 1.11.6.
