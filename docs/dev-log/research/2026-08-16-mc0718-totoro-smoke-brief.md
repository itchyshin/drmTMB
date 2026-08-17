# mc-0718 Totoro smoke brief (predeclared; launched 2026-08-16)

**Date:** 2026-08-16  
**Readers:** the next compute owner, plus Fisher / Noether on the Wave 2 merge-path.  
**Lane:** `cursor/ng-correlated-slope-wave2` (draft PR #1060; worktree `.worktrees/ng-corr-w2`; live checkout `local-scratch/lanes/drmTMB-ng-corr-stack`).  
**Cell:** `mc-0718`, `ordinary_correlated_q2`, ceiling `point_fit_recovery`.  
**Machine answer:** Totoro, not DRAC, not the laptop, never GitHub Actions (D-50).  
**Launch status:** **launched and finished 2026-08-17 11:39 UTC** after Shinichi's named GO. Results: `docs/dev-log/simulation-artifacts/2026-08-16-mc0718-totoro-smoke/` and after-task `docs/dev-log/after-task/2026-08-16-mc0718-totoro-smoke.md`. This note remains the pre-run contract.

This smoke cannot promote `mc-0718` above `point_fit_recovery`. It cannot open Wave 3, NB2, REML, AGHQ, intervals, coverage, or `supported`. It is not `mc-0431` and not `mc-0717`.

## Local alignment already on the branch

The Wave 2 implementation after-task
(`docs/dev-log/after-task/2026-08-16-design-257-wave2-poisson-correlated.md`)
records one complete-data Poisson log ML-Laplace fit of

```r
drmTMB(
  bf(count ~ x + (1 + x | id)),
  family = poisson(link = "log"),
  data = dat
)
```

on the frozen local fixture (`n_group = 56`, `n_each = 14`, seed `20260816`,
truth `sd0 = 0.65`, `sd1 = 0.42`, `rho_re = 0.45`). Extractors are the
design-17 map, not the binomial log-sech factorisation:

| Symbol | Design 257 / design-17 extractor |
| --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `0.999999 tanh(eta_cor_mu)` |

`obj$report()` carries `eta_cor_mu` and `rho_mu_re`. It does **not** carry
`logsech_mu_re`. Group-level correlation is `rho_re`, never residual `rho12`.
Laptop seed `20260816` is a local cite only. It is not in this denominator.

Fisher / Noether: one-seed local recovery inside the existing 0.30 absolute
gates supports **`point_fit_recovery` only**. This smoke does not change that
ceiling. `REML = TRUE` still aborts. Ledger, NEWS, grammar, and
known-limitations keep that ceiling. `mc-0431` / `mc-0432` / `mc-0717` were
not reused.

## ADEMP (frozen before any host command)

**Aim.** Recover `sd0`, `sd1`, and `rho_re` for one ordinary Poisson
correlated block under ML-Laplace on three information rungs, with an iid
control and one external oracle on the same draws. Classify every exception.
Do not drop failed fits from the denominator.

**Data-generating process.** Reuse `poisson_q2_data()` from
`tests/testthat/test-poisson-ordinary-correlated-q2.R`:

```text
y_ij | λ_ij ~ Poisson(λ_ij)
log(λ_ij) = -0.25 + 0.70 x_ij + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
sd0 = 0.65, sd1 = 0.42, rho_re = 0.45
x_ij ~ Normal(0, 1)  # must vary within group
n_group = 56
n_each ∈ {4, 8, 14}
```

Keep the same three recovered symbols as the local fixture. Do not change the
truth constants. Do not use seed `20260816` (already spent on the laptop
cite) or seeds `20260817`–`20260819` (already spent in tests). Do not reuse
the mc-0717 seeds `871401`–`871403`, `871801`–`871803`, `871141`–`871143`.

**Estimand.** `sd0`, `sd1`, `rho_re` only. Fixed effects are nuisance. Do not
profile. Do not score Wald or profile coverage.

**Methods (all three on every draw).**

1. **Claim fit:** `drmTMB(bf(count ~ x + (1 + x | id)), family = poisson(link = "log"), data = dat)` — ML-Laplace, `REML = FALSE`.
2. **Iid control:** `drmTMB(bf(count ~ x + (1 | id) + (0 + x | id)), family = poisson(link = "log"), data = dat)`. This is the `mc-0431` neighbour, not the claim. Record its two SDs; it has no `rho_re`.
3. **External oracle:** `glmmTMB::glmmTMB(count ~ x + (1 + x | id), family = poisson(), data = dat)`. Extract the unstructured `id` SDs and correlation from `VarCorr()`. If `glmmTMB` is missing on Totoro, stop and install it; do not silently switch to `lme4::glmer` after the first draw. `glmer` is the named fallback only when the host check *before launch* shows `glmmTMB` absent.

**Performance.**

| Gate | Rule |
| --- | --- |
| Convergence | `opt$convergence == 0` for drmTMB; `opt$convergence == 0` for glmmTMB |
| Finite extractors | `sd0`, `sd1`, `rho_re` finite on the claim fit |
| `pdHess` | Record; not a hard kill at `n_each = 4` |
| Absolute recovery | start at 0.30 on `sd0` / `sd1` / `rho_re` for the claim fit; do not tighten on this smoke |
| Exceptions | retain gradient / optimizer / Hessian exceptions in the denominator and classify them |
| Claim | `point_fit_recovery` only; no interval, coverage, REML, or `supported` sentence in the write-up |

**Rejection matrix (must stay red on the same host session).** `REML = TRUE`; missing-response + q2; labelled `(1 + x | p | id)`; mixed `(1 | id) + (1 + x | id)`; NB2 `(1 + x | id)`. One draw per neighbour is enough. Poisson is the claim, not a rejection neighbour.

## Predeclared draws

27 fits = 9 draws × 3 methods. Seeds are disjoint from the local test suite
and from the mc-0717 set.

| `n_each` | seeds | draws | fits |
| ---: | --- | ---: | ---: |
| 4 | 881401, 881402, 881403 | 3 | 9 |
| 8 | 881801, 881802, 881803 | 3 | 9 |
| 14 | 881141, 881142, 881143 | 3 | 9 |

Laptop seed `20260816` is a local cite only. It is not in this denominator.
Toy seed `881000` and rejection seed `881999` are plumbing only.

## Host plan (Totoro)

**Totoro or DRAC?** Totoro. This is a 27-fit CPU smoke, well under the
150-core cap (D-143). DRAC job arrays are for a later certification
(N≈200–400) after this smoke is honest. GitHub Actions is forbidden for the
campaign and for storing its output (D-50).

**Connectivity already measured (2026-08-17 00:46 UTC):**

```sh
ssh -o BatchMode=yes -o ConnectTimeout=15 totoro 'hostname'
# totoro
# nproc=384
# glmmTMB present
```

A home-path probe found `~/hsq_work/drmTMB-mc0717` and no `~/hsq_work/drmTMB-mc0718`.
The launcher must clone or fetch `cursor/ng-correlated-slope-wave2` under
`~/hsq_work/drmTMB-mc0718` and record `git rev-parse HEAD` before the first
fit. Expected SHA is the live PR #1060 head `3e8a9aaec9aae3e20a5e3bbd46fb65561304e368`
(rewritten onto the Wave 1 stack after `aef4c860`; same Poisson `mc-0718` admission).

**Core budget.** Default 8 workers, hard cap 16, never above 150. Pin
`OPENBLAS_NUM_THREADS=1` and `OMP_NUM_THREADS=1`. Copy this guard, do not
re-derive `nproc`:

```sh
readonly TOTORO_CORE_CAP=150
NWORKERS=${NWORKERS:-8}
(( NWORKERS <= 16 && NWORKERS <= TOTORO_CORE_CAP && NWORKERS <= $(nproc) - 4 )) || exit 2
```

**R invocation.** `R_PROFILE_USER=/dev/null Rscript --no-init-file`.

**Outputs (local only).** Write under

```text
docs/dev-log/simulation-artifacts/2026-08-16-mc0718-totoro-smoke/
```

on the PR branch after the run, or keep the raw TSV on Totoro and copy it
back. Never attach the TSV as a GitHub Actions artifact. Columns at minimum:
`seed`, `n_each`, `method` (`drmtmb_corr` / `drmtmb_iid` / `glmmtmb_corr`),
`convergence`, `pdHess`, `sd0`, `sd1`, `rho_re`, `abs_err_sd0`,
`abs_err_sd1`, `abs_err_rho`, `exception_class`, `git_sha`.

**STOP if** any claim fit drops an exception from the denominator; extractor
names drift from the design-17 table; a write-up says interval, coverage,
REML, or `supported`; a Wave 3 family is fitted; NB2 is admitted; or the job
is submitted to GitHub Actions.

**Launched from Shinichi's named GO** (2026-08-16 evening America/Denver,
autonomous overnight). Do not relaunch this 27-fit set. A later
certification needs its own ADEMP and a new GO. Standing 2026-08-07 Totoro
permission is not a substitute for a named cell GO.

## Out of scope

MSPL, missing-data / #1033, Ligges / win-builder, binomial phylo / #1049,
Wave 1 merge of #1059, Wave 3 families, NB2 admission, O3 AGHQ, public REML,
DRAC certification, and any merge to `main`.
