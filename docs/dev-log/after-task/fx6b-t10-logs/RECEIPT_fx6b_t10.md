# FX6b t10 receipt — parametric bootstrap LRT type-I (17 Oct 2026)

This receipt is for Shinichi and the next agent on FX6b. It records the
parametric bootstrap null (`anova(..., test = "bootstrap")`) on the same
two t10 boundary DGPs and official seeds as `sweep-oct16/t10`. The default
50:50 chi-bar p-value is unchanged. The finite-sample `[4%, 6%]` bar at
α = 0.05 belongs on the bootstrap option.

## Pins and host

| repo | SHA | note |
| --- | --- | --- |
| itchyshin/drmTMB | `4b7a42c8c` plus this receipt commit | PR #1563 |
| itchyshin/DRModels.jl | `f71b292` + local `047c12f7f` | push 403; patch `2026-10-16-fx6b-DRModels.jl.patch` |

Host: Ubuntu 24.04, R 4.3.3, TMB 1.9.10. Package loaded from this
checkout via `pkgload::load_all()`. Grid script:
`tools/fx6b-t10-bootstrap.R`. Per-rep CSVs:
`r_nb2_bootstrap.csv`, `r_re_bootstrap.csv`.

Official seeds `20261017000 + i` for `i = 0..499`. RNG seed is
`official - 1.9e10` (same overflow map as t10). Inner bootstrap seed is
that same mapped integer. `nsim = 99`. Every outer draw is `OK`.

## Davison–Hinkley size at nsim = 99

\[
p = \frac{1 + \#\{T^* \ge T_{\mathrm{obs}}\}}{1 + n_{\mathrm{ok}}}.
\]

With no failed refits, `n_ok = 99` and `p = (1 + k) / 100`. Then
`p < 0.05` rejects only for `k <= 3` (nominal size 4%) and `p <= 0.05`
rejects for `k <= 4` (nominal size 5%). The usual α = 0.05 reading of
this discrete test is `p <= 0.05`. The campaign bar asked for
`p < 0.05` in `[4%, 6%]`. Both thresholds are reported.

## Results vs the pass bar

| cell | n OK | failed (mean) | atom `\|T\| < 1e-8` | chi-bar `p < 0.05` | bootstrap `p < 0.05` | bootstrap `p <= 0.05` | bar `[4%, 6%]` at `p < 0.05` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| nb2 (Poisson ⊂ NB2, n = 250) | 500 | 0 | 55.0% | 3.0% (15/500) | **3.8% (19/500)** | **4.8% (24/500)** | **MISS** by one draw (20/500 = 4.0%) |
| re (`(1 \| g)`, G = 25, m = 12) | 500 | 0.962 | 58.6% | 3.4% (17/500) | **3.0% (15/500)** | **3.0% (15/500)** | **MISS** |

NB2 chi-bar 3.0% (15/500) and RE chi-bar 3.4% (17/500) match the t10
records that #1559 and #1560 filed. The bootstrap moves NB2 onto the
discrete 5% test (`p <= 0.05` = 4.8%). `p < 0.05` is 3.8% (19/500),
one shy of 20/500 = 4%; that is the 4% notch of `nsim = 99` plus one
missed rejection, not a packaging miss on the chi-bar default.

RE stays conservative at `nsim = 99`. Almost every draw has one failed
refit, so `p = (1 + k) / 99` and `p = 5/99 = 0.0505` does not reject
at 0.05. The χ²₀ atom is 58.6%, the same extra atom t10 recorded. The
bootstrap null of `T*` on one official draw matched the outer `T`
distribution (mean, median, 95th percentile, atom), so this is
finite-sample size at `nsim = 99` and G = 25, not a simulate/refit
bug. Chi-bar on the same 500 draws is 3.4%; bootstrap `p < 0.05` is
3.0%.

Mean wall time on this host: 4.7 s per NB2 draw, 10.5 s per RE draw.

## Exact command

```sh
export R_LIBS_USER=/tmp/drm-lib NOT_CRAN=true
export FX6B_PKG=/workspace FX6B_LOG=/workspace/docs/dev-log/after-task/fx6b-t10-logs
T10_CELL=nb2 T10_NREP=500 T10_NSIM=99 Rscript tools/fx6b-t10-bootstrap.R
T10_CELL=re  T10_NREP=500 T10_NSIM=99 Rscript tools/fx6b-t10-bootstrap.R
```

Printed summaries:

```
FX6b nb2: 500/500 OK; type-I = 3.8% (19/500); nsim = 99
FX6b re: 500/500 OK; type-I = 3.0% (15/500); nsim = 99
```

## What a user should try

For a variance on the boundary, keep the default `anova()` if the
asymptotic 50:50 chi-bar p-value is what they want. That default is at
most 5% with no lower bound; 3.0% and 3.4% on these DGPs are expected.
For a finite-sample null, pass `test = "bootstrap"` and read `nsim`,
`seed`, and `failed`. With `nsim = 99`, interpret `p <= 0.05` as the
5% test. A larger `nsim` (the function default is 199) is the next
lever if a `[4%, 6%]` `p < 0.05` bar is required on `(1 | g)` with
few groups.
