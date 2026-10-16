# Comment intended for https://github.com/itchyshin/DRModels.jl/issues/1097
# Twin: https://github.com/itchyshin/DRModels.jl/issues/938
# Fix PR (not executed): https://github.com/itchyshin/DRModels.jl/pull/1096

GitHub write from this cloud task returned 403. Paste this if posting by hand. Refs #1097, Refs #938. Do not re-file.

t7 log-2 offset-shift sweep at DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` / Julia 1.12.6 vs drmTMB `ca3ddef` / R 4.6.1.

Pass bar: add log(2) to the offset; intercept drops by log(2) exactly; other estimates and logLik unchanged.

Simulated n=200, 20 groups. Seed `202610167L` (campaign `20261016700+` overflows R integers). CSVs in `sweep-oct16/t7/data_offset_*.csv`.

**New family: Gamma.** FE and `(1|g)` both FAIL. `mu` block is 3 coefficients (intercept, x, **offset as a free slope**). Gamma FE offset coef = 1.154, so the intercept moves `1.154 * log(2) = 0.800` vs required 0.693. Same silent-estimate mechanism as NB2.

**NB2** FE/RE mu `offset()`: FAIL. FE offset coef = 0.974, intercept moves 0.675 vs 0.693.

**Poisson FE mu `offset()`:** PASS (delta 3.9e-14). Matches drmTMB logLik to 1e-12.

**Poisson `(1|g)` + `offset(off)`** on `~ 1 + x` and on `~ 1 + x*z`: REFUSED with the intended message (only supported on FE). The Owls `Food*Sex` route in the original report is the one that skipped the guard; the simple `(1|g)` path does fire it at this pin.

**`offset=` keyword:** MethodError, unsupported keyword. Loud refuse.

**sigma formula `offset()`:** NB2/Gamma estimate it as a free coefficient, no warning. Poisson `sigma ~ offset` is swallowed as a missing dpar (#1027); intercept unmoved.

**drmTMB native TMB** on the same tables: Poisson/NB2/Gamma mu `offset()`, FE and `(1|g)`, all PASS at |delta − log(2)| ≤ 1.7e-12. sigma offset refused. `offset=` unused-argument refused.

```julia
using DRModels
# d from data_offset_gamma.csv
drm(bf(@formula(y ~ 1 + x + offset(off)), @formula(sigma ~ 1)), Gamma(); data=d)
# blocks :mu => 1:3  (third mean coef is the estimated offset)
```
