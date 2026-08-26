# Independent two-`mi()` alignment (S6 Phase 1)

Consumer contract: drmSEM `LOOP/notes/A1-engine-contract.md` (option b).
Sister prior art left alone: `impute_joint` (`LOOP/notes/A3-joint-mi-verdict.md`).

| Symbol | User surface | TMB | Recovery |
|---|---|---|---|
| \(\beta_{m1},\beta_{m2},\beta_x\) | `y ~ mi(m1)+mi(m2)+x` | `beta_mu` at `mi_col`, `mi_col2` | response coefficients |
| \(\alpha_1\) | `impute = list(m1 = impute_model(m1 ~ x))` | `beta_mi`, `X_mi` | first imputation slopes |
| \(\alpha_2\) | `impute = list(m2 = impute_model(m2 ~ x))` | `beta_mi2`, `X_mi2` | second imputation slopes |
| \(\sigma_{m1},\sigma_{m2}\) | Gaussian predictor models | `log_sigma_mi`, `log_sigma_mi2` | predictor scales |
| missingness | `NA` in `m1`/`m2` | `x_miss`, `x_miss2` | row accounting; placeholders at missing rows do not enter nll |

No \(\rho(m_1,m_2)\). Within-node Hessian only.
