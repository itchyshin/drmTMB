# FX6b t10 receipt: parametric bootstrap LRT type-I (17 Oct 2026; nsim = 199 rerun 18 Oct 2026)

This receipt is for Shinichi and the next agent on FX6b. It records the
parametric bootstrap null (`anova(..., test = "bootstrap")`) on the same
two t10 boundary DGPs and official seeds as `sweep-oct16/t10`. The default
50:50 chi-bar p-value is unchanged. The finite-sample `[4%, 6%]` bar at
α = 0.05 belongs on the bootstrap option.

## nsim = 199 rerun (18 Oct 2026): both cells inside [4%, 6%]

The 18 Oct rerun keeps the two DGPs, the 500 official seeds, the seed
map, and the inner bootstrap seed from the nsim = 99 run below. Only
`nsim` changed, to 199, the default of `anova()` and `drm_lrtest()`. The
method was not changed. Every outer draw is `OK`.

| cell | n OK | failed refits per draw | atom `\|T\| < 1e-8` | chi-bar `p < 0.05` | bootstrap `p < 0.05` [95% CI] | bootstrap `p <= 0.05` | bar `[4%, 6%]` at `p < 0.05` |
| --- | ---: | --- | ---: | ---: | ---: | ---: | --- |
| nb2 (Poisson ⊂ NB2, n = 250) | 500 | 0 on all 500 draws | 55.0% | 3.0% (15/500) | **4.2% (21/500)** [2.6%, 6.3%] | 4.4% (22/500) | **PASS** |
| re (`(1 \| g)`, G = 25, m = 12) | 500 | 1 on 481 draws, 0 on 19 (mean 0.962) | 58.6% | 3.4% (17/500) | **4.2% (21/500)** [2.6%, 6.3%] | 4.2% (21/500) | **PASS** |

The intervals are exact Clopper–Pearson (`binom.test`).

**Discrete size at nsim = 199.** With no failed refit, `n_ok = 199` and
`p = (1 + k) / 200`. Then `p < 0.05` rejects for `k <= 8` (nominal 4.5%)
and `p <= 0.05` rejects for `k <= 9` (nominal 5.0%). With one failed
refit, `n_ok = 198` and `p = (1 + k) / 199`, so both thresholds reject
for `k <= 8` (nominal 4.52%). That is why RE gives the same count at both
thresholds. The 4% notch that cost NB2 one rejection at nsim = 99 is
gone.

**Same draws, finer null.** The outer statistics match the nsim = 99
CSVs draw for draw: max `|ΔT|` is 7.6e-11 (NB2) and 3.4e-11 (RE), and
max `|Δ chi-bar p|` is 6.3e-10 and 2.4e-08. Rejections at `p < 0.05`,
nsim = 99 versus nsim = 199:

| cell | both reject | only nsim = 199 | only nsim = 99 | neither |
| --- | ---: | ---: | ---: | ---: |
| nb2 | 19 | 2 | 0 | 479 |
| re | 14 | 7 | 1 | 478 |

So the change comes from the bootstrap reference distribution, not from
different data.

**How far this goes.** Both cells now sit inside `[4%, 6%]` at
`p < 0.05`. With 500 draws the Monte Carlo standard error at 5% is about
1.0 percentage point, and each 95% interval, [2.6%, 6.3%], also covers
3% and 6%. The grid shows the bootstrap is no longer visibly
conservative at nsim = 199. It cannot tell 4.2% from 5%, and it says
nothing about other DGPs, smaller n, or fewer groups.

**Host and timing.** Apple M1 Ultra, macOS 26.7.1, R 4.6.0, TMB 1.9.21.
Package loaded from the PR #1563 checkout (head `75a2a870a`) via
`pkgload::load_all()`. The only script change is optional seed-block
sharding (`T10_FIRST`, `T10_CSV`). Before the grid, the first two
nsim = 99 NB2 draws on this host gave p = 0.59 and 0.75, the same as the
Ubuntu rows. Six single-threaded workers ran on a shared machine (load
average 35 to 41 on 20 cores) for 1 h 29 min (18:01 to 19:30 MDT). Mean
time per draw was 15.9 s for NB2 and 45.3 s for RE.

Per-rep CSVs: `r_nb2_bootstrap_nsim199.csv`,
`r_re_bootstrap_nsim199.csv`. Each holds 500 `OK` rows, one per seed
`20261017000` to `20261017499`, sorted by seed.

```sh
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 NOT_CRAN=true
export FX6B_PKG=$PWD FX6B_LOG=/tmp/fx6b-n199
# 20 blocks of 50 seeds (re first, then nb2), 6 at a time
for c in re nb2; do for f in 0 50 100 150 200 250 300 350 400 450; do echo "$c $f"; done; done |
  xargs -P 6 -L 1 sh -c 'T10_CELL=$0 T10_NREP=50 T10_NSIM=199 T10_FIRST=$1 \
    T10_CSV=/tmp/fx6b-n199/${0}_${1}.csv Rscript tools/fx6b-t10-bootstrap.R'
# then concatenate the 10 shards per cell, sort by seed, and write
# r_<cell>_bootstrap_nsim199.csv
```

Summary over the merged CSVs, in the script's print format:

```
FX6b nb2: 500/500 OK; type-I = 4.2% (21/500); nsim = 199
FX6b re: 500/500 OK; type-I = 4.2% (21/500); nsim = 199
```

The sections below are the original nsim = 99 run (17 Oct 2026),
unchanged except for the last paragraph.

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
5% test. Keep the function default `nsim = 199` rather than lowering it:
the 18 Oct rerun above put `p < 0.05` at 4.2% on both cells at 199,
against 3.8% and 3.0% at 99.
