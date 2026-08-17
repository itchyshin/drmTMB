# mc-0717 Totoro smoke brief (predeclared; launched 2026-08-16)

**Date:** 2026-08-16  
**Readers:** the next compute owner, plus Fisher / Noether on the Wave 1 merge-path.  
**Lane:** `cursor/ng-correlated-slope-impl` (draft PR #1059; worktree `.worktrees/ng-corr-w1`).  
**Cell:** `mc-0717`, `ordinary_correlated_q2`, ceiling `point_fit_recovery`.  
**Machine answer:** Totoro, not DRAC, not the laptop, never GitHub Actions (D-50).  
**Launch status:** **launched and finished 2026-08-16 20:44 UTC** after Shinichi's named GO. Results: `docs/dev-log/simulation-artifacts/2026-08-16-mc0717-totoro-smoke/` and after-task `docs/dev-log/after-task/2026-08-16-mc0717-totoro-smoke.md`. This note remains the pre-run contract.

This smoke cannot promote `mc-0717` above `point_fit_recovery`. It cannot open Wave 2, REML, AGHQ, intervals, coverage, or `supported`. It is not `mc-0061`.

## Fisher / Noether merge-path verdict

**PASS** for the Design 257 alignment table against a live fitted object, and for the claim ceiling. **Merge blocked by quiesce.** Do not request merge.

Noether read the alignment table against one complete-data binomial logit ML-Laplace fit of

```r
drmTMB(
  bf(cbind(success, failure) ~ x + (1 + x | id)),
  family = binomial(),
  data = dat
)
```

on the frozen local fixture (`n_group = 56`, `n_each = 14`, seed `20260811`, truth `sd0 = 0.65`, `sd1 = 0.42`, `rho_re = 0.45`). The object was `class = drmTMB`, `family = binomial`, `link = logit`, `estimator = ML`, `REML = FALSE`, `opt$convergence = 0`, `sdr$pdHess = TRUE`.

| Symbol | Design 257 extractor | Fitted value | Truth | \|error\| | 0.30 gate |
| --- | --- | ---: | ---: | ---: | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` | 0.599448 | 0.65 | 0.050552 | PASS |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` | 0.414522 | 0.42 | 0.005478 | PASS |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` | 0.308915 | 0.45 | 0.141085 | PASS |

`rho_re` equals `tanh(eta_cor_mu)` at `opt$par` (`eta_cor_mu = 0.319346`). `obj$report()` still carries `eta_cor_mu`, `rho_mu_re`, and `logsech_mu_re`. The log-sech Cholesky reconstructs `Σ_g`:

```text
L = [[0.599448, 0       ],
     [0.128052, 0.394248]]
Σ = L L'  →  diag(0.359338, 0.171829), off-diag 0.076761
off-diag = sd0 * sd1 * rho_re = 0.076761
```

Group-level correlation is `rho_re`, never residual `rho12`. Fixed effects are nuisance (`fixef(fit)$mu` intercept −0.178, slope 0.657 against DGP −0.25 + 0.70 `x`). `ranef()` exposes `$mu` only.

Fisher: one-seed local recovery inside the existing 0.30 absolute gates supports **`point_fit_recovery` only**. It does not support intervals, coverage, or `supported`. `REML = TRUE` still aborts (`Correlated q = 2 binomial random effects are not implemented with REML`). Ledger, NEWS, grammar, and known-limitations keep that ceiling. `mc-0060` / `mc-0061` / `mc-0062` were not reused.

The generic profile engine marks all five `profile_targets()` rows `profile_ready = TRUE`, and `confint(fit, method = "wald")` returns five rows while emitting `NaNs produced` from `sqrt(diag(cov))`. That is inherited S3 surface, not a Wave 1 interval claim. Do not treat `profile_ready = TRUE` as authorization. A later interval arc needs its own ADEMP and a separate owner goal.

### Residuals (HOLD, not alignment failures)

1. **Constant-within-group `x` is still unidentified and still fits.** Design 257 said a slope with no within-group variation in `x` is a rejection test, not a recovery cell. The auditor residual is confirmed: setting `x` to the group index produced `convergence = 0`, `pdHess = FALSE`, `sd1 ≈ 0`, `rho_re ≈ 0.997`. Wave 1 has no test for this. Add the rejection (or an honest unidentified diagnostic) before treating the smoke as clean, but do not hold the alignment verdict for it.
2. **Stale parser hint.** `validate_binomial_mu_random_terms()` still says `experimental q = 2` (`R/drmTMB.R` around the unsupported-term `i` hint). Grammar and the ledger already name `mc-0717` as `point_fit_recovery`. A one-line honesty edit previously tripped the C14 current-source receipt; leave `R/drmTMB.R` alone until that receipt is refreshed on purpose.

## ADEMP (frozen before any host command)

**Aim.** Recover `sd0`, `sd1`, and `rho_re` for one binomial correlated block under ML-Laplace on three information rungs, with an iid control and one external oracle on the same draws. Classify every exception. Do not drop failed fits from the denominator.

**Data-generating process.** Reuse `mspl_q2_data()` from `tests/testthat/test-binomial-correlated-re-mspl-prereq.R`:

```text
logit(p_ij) = -0.25 + 0.70 x_ij + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
sd0 = 0.65, sd1 = 0.42, rho_re = 0.45
n_ij ~ Poisson(16) + 8
x_ij ~ Normal(0, 1)  # must vary within group
n_group = 56
n_each ∈ {4, 8, 14}
```

Keep the same six recovered symbols as the local fixture. Do not change the truth constants. Do not use seed `20260811` (already spent on the laptop cite) or seeds `20260808`–`20260813` (already spent in tests).

**Estimand.** `sd0`, `sd1`, `rho_re` only. Fixed effects are nuisance. Do not profile. Do not score Wald or profile coverage.

**Methods (all three on every draw).**

1. **Claim fit:** `drmTMB(bf(cbind(success, failure) ~ x + (1 + x | id)), family = binomial(), data = dat)` — ML-Laplace, `REML = FALSE`.
2. **Iid control:** `drmTMB(bf(cbind(success, failure) ~ x + (1 | id) + (0 + x | id)), family = binomial(), data = dat)`. This is the `mc-0061` neighbour, not the claim. Record its two SDs; it has no `rho_re`.
3. **External oracle:** `glmmTMB::glmmTMB(cbind(success, failure) ~ x + (1 + x | id), family = binomial(), data = dat)`. Extract the unstructured `id` SDs and correlation from `VarCorr()`. If `glmmTMB` is missing on Totoro, stop and install it; do not silently switch to `lme4::glmer` after the first draw. `glmer` is the named fallback only when the host check *before launch* shows `glmmTMB` absent.

**Performance.**

| Gate | Rule |
| --- | --- |
| Convergence | `opt$convergence == 0` for drmTMB; `opt$convergence == 0` for glmmTMB |
| Finite extractors | `sd0`, `sd1`, `rho_re` finite on the claim fit |
| `pdHess` | Record; not a hard kill at `n_each = 4` |
| Absolute recovery | start at 0.30 on `sd0` / `sd1` / `rho_re` for the claim fit; do not tighten on this smoke |
| Exceptions | retain gradient / optimizer / Hessian exceptions in the denominator and classify them |
| Claim | `point_fit_recovery` only; no interval, coverage, REML, or `supported` sentence in the write-up |

**Rejection matrix (must stay red on the same host session).** `REML = TRUE`; missing-response + q2; labelled `(1 + x | p | id)`; mixed `(1 | id) + (1 + x | id)`; Poisson `(1 + x | id)`. One draw per neighbour is enough.

## Predeclared draws

27 fits = 9 draws × 3 methods. Seeds are disjoint from the local test suite.

| `n_each` | seeds | draws | fits |
| ---: | --- | ---: | ---: |
| 4 | 871401, 871402, 871403 | 3 | 9 |
| 8 | 871801, 871802, 871803 | 3 | 9 |
| 14 | 871141, 871142, 871143 | 3 | 9 |

Laptop seed `20260811` is a Noether cite only. It is not in this denominator.

## Host plan (Totoro)

**Totoro or DRAC?** Totoro. This is a 27-fit CPU smoke, well under the 150-core cap (D-143). DRAC job arrays are for a later certification (N≈200–400) after this smoke is honest. GitHub Actions is forbidden for the campaign and for storing its output (D-50).

**Connectivity already measured (2026-08-16 20:02 UTC):**

```sh
ssh -o BatchMode=yes -o ConnectTimeout=15 totoro 'hostname'
# totoro
```

A quick home-path probe found no `~/drmTMB` checkout. The launcher must clone or fetch `cursor/ng-correlated-slope-impl` under `~/hsq_work/drmTMB-mc0717` (or an existing Totoro drmTMB clone) and record `git rev-parse HEAD` before the first fit.

**Core budget.** Default 8 workers, hard cap 16, never above 150. Pin `OPENBLAS_NUM_THREADS=1` and `OMP_NUM_THREADS=1`. Copy this guard, do not re-derive `nproc`:

```sh
readonly TOTORO_CORE_CAP=150
NWORKERS=${NWORKERS:-8}
(( NWORKERS <= 16 && NWORKERS <= TOTORO_CORE_CAP && NWORKERS <= $(nproc) - 4 )) || exit 2
```

**R invocation.** `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the laptop `.Rprofile` R-4.5 lib is not the Totoro story, but keep the habit).

**Outputs (local only).** Write under

```text
docs/dev-log/simulation-artifacts/2026-08-16-mc0717-totoro-smoke/
```

on the PR branch after the run, or keep the raw TSV on Totoro and copy it back. Never attach the TSV as a GitHub Actions artifact. Columns at minimum: `seed`, `n_each`, `method` (`drmtmb_corr` / `drmtmb_iid` / `glmmtmb_corr`), `convergence`, `pdHess`, `sd0`, `sd1`, `rho_re`, `abs_err_sd0`, `abs_err_sd1`, `abs_err_rho`, `exception_class`, `git_sha`.

**STOP if** any claim fit drops an exception from the denominator; extractor names drift from the Design 257 table; a write-up says interval, coverage, REML, or `supported`; a Wave 2 family is fitted; or the job is submitted to GitHub Actions.

**Launched from Shinichi's named GO** (2026-08-16 20:44 UTC). Do not relaunch this 27-fit set. A later certification needs its own ADEMP and a new GO. Standing 2026-08-07 Totoro permission is not a substitute for a named cell GO.

## Out of scope

MSPL, missing-data / #1033, Ligges / win-builder, binomial phylo / #1049, Wave 2 Poisson/NB2, O3 AGHQ, public REML, Bernoulli `y01`, probit / cloglog recovery, DRAC certification, and any merge to `main`.
