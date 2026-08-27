# ARCS — S6 A7 lognormal `has_mi`

| ID | Slice | Status | Note |
|---|---|---|---|
| A7-Γ | Gamma × Bernoulli `mp-gamma-bernoulli` | done | #1088 `6e5538797` |
| A7.L0 | G0 lock (lognormal, not student / nbinom2×Gaussian) | done | `A7-g0-lognormal.md` |
| A7.L1 | C++ lognormal leaf + `has_mi` in `model_type == 4` | DOING | not a whitelist edit |
| A7.L2 | R spec + gate (`drm_build_lognormal_ls_spec`, families list) | DOING | after C++ |
| A7.L3 | Tests: logLik identity, MCAR, MAR smoke, fail-loud | TODO | |
| A7.L4 | Ledger `mp-lognormal-bernoulli` + evidence row | TODO | append only |
| A7.L5 | Push + PR to itchyshin/drmTMB | TODO | |
| A7.L6 | drmSEM consumer lift (A7c-3) | DEFERRED | after engine on main |

Next family after merge: **beta_binomial** (`A7-post-lognormal-queue.md`).
Student waits (`nu`).
