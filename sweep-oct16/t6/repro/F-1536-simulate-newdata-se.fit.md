# Comment draft for drmTMB #1536

GitHub write was 403 at run time. Post this comment; do not open a new issue.

---

## sweep-oct16 t6: confirmed on a fitted Gaussian (not code-read only)

Lane t6 (`predict()` / `simulate()`) on pin `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`. Both halves of this issue still happen on a real fit.

**Expected:** `simulate(fit, newdata = nd)` draws for `nd`, or errors naming the unused argument. `predict(..., se.fit = TRUE)` either returns SEs or refuses the unused name (as `drmTMB()` does after #1486).

**Actual:** `simulate(newdata = nd)` returns one row per training observation and ignores `nd`. `predict(se.fit = TRUE)` returns a numeric vector and never mentions `se.fit`. `predict_parameters(..., conf.int = TRUE)` *does* return `std.error` — that is the offered SE surface.

Twin note (do not re-file): DRModels.jl `f71b292` `simulate(fit; nsim, rng)` also has no `newdata`. Its `predict(fit, nd; se = true)` *does* return SEs.

### Source
Simulated data, not a package dataset. Nominal seed `20261016600` (R `set.seed(20261016600 %% 2^31)` = `933663768`), `RNGkind("Mersenne-Twister", "Inversion", "Rejection")`. drmTMB 0.7.1 at `ca3ddefa5`.

### Preparation
`n = 80`, `x ~ N(0,1)`, `f ∈ {a,b,c}` recycled. Full generator: `sweep-oct16/t6/t6_gen_data.R`.

### Minimal repro

```r
library(drmTMB)
dat <- read.csv("sweep-oct16/t6/data/gaussian_fe.csv", stringsAsFactors = FALSE)
dat$f <- factor(dat$f, levels = c("a", "b", "c"))
fit <- drmTMB(bf(y ~ x + f, sigma ~ 1), family = gaussian(), data = dat)
nd <- data.frame(x = c(0, 1), f = factor(c("a", "b"), levels = levels(dat$f)))
s <- simulate(fit, nsim = 1, seed = 1, newdata = nd)
nrow(s)                 # 80 (training), not 2
inherited <- predict(fit, newdata = nd, se.fit = TRUE)
is.list(inherited)      # FALSE
pp <- predict_parameters(fit, newdata = nd, dpar = "mu", conf.int = TRUE)
"std.error" %in% names(pp)  # TRUE
```

Observed on this CSV: `nrow(simulate(..., newdata = nd2)) = 80` with `nrow(nd2) = 2`; `predict(se.fit = TRUE)` status `ignored`.

<details><summary>Prepared data (first 8 rows of gaussian_fe.csv)</summary>

```r
structure(list(
  y = c(1.49335373660745, 0.909822071695177, -0.201915536918276,
        0.802397494094681, 1.12999735070209, -1.41318456543635,
        1.26884070056195, 1.24232919830674),
  x = c(0.259091355159942, 0.433206244432816, 0.0864026850714217,
        0.500275264128215, -0.365106819080982, 0.0403827396169908,
        2.89649633962484, 0.766600265710733),
  f = c("a", "b", "c", "a", "b", "c", "a", "b"),
  g = c("g01", "g01", "g01", "g01", "g01", "g01", "g01", "g01"),
  trials = c(12L, 12L, 12L, 12L, 12L, 12L, 12L, 12L)
), class = "data.frame", row.names = c(NA, 8L))
```

</details>

<details><summary>sessionInfo / versioninfo</summary>

```
drmTMB 0.7.1  SHA ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
DRModels.jl 0.7.2 SHA f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
R 4.6.1 (2026-06-24) x86_64-pc-linux-gnu Ubuntu 24.04.5 LTS
TMB 1.9.25  Matrix 1.7-6
Julia 1.11.6
```

</details>

Refs #1536. Not closing.
