# A8b neighbour probe -- where the widened readiness rule stops

Measured 2026-09-05 on `wt-a8b` with the A8b change in place and DRM.jl worktree
`claude/parity-a8b-biv-inference-drmjl`. One Julia session, `threads = FALSE`.

The A8b change opens `profile_ready` for a bivariate fit that carries **no**
covariance provider. The obvious way for that to be wrong is a bivariate route
that has real random structure yet stores no provider in the payload. These four
probes look for one.

## (a) bivariate with an ordinary `(1 | g)` random intercept -- REFUSED, so
## the predicate is never consulted

`bf(mu1 = y1 ~ x + (1 | g), mu2 = y2 ~ x + (1 | g), sigma1 = ~1, sigma2 = ~1, rho12 = ~1)`,
`family = biv_gaussian()`, `engine = "julia"`, n = 120, 20 groups. No fit object
is produced; DRM.jl refuses at formula-splitting time:

```
bivariate q=4 structured fits support only `phylo`/`relmat`/`animal`/`spatial(1 | group)`
markers, not ordinary random effects
  [2] _split_bivariate_q4_rhs(...)  src/gaussian_bivariate.jl:426
```

There is therefore no bivariate route today whose fit has random structure but
no provider in the payload. The predicate cannot be reached in that state.

## (b) a REAL bivariate q4 phylogenetic fit -- still not ready

`phylo(1 | species)` on `mu1`, `mu2`, `sigma1`, `sigma2` over a 12-tip tree,
5 observations per tip (n = 60), `engine = "julia"`:

```
payload: tree NULL? FALSE   matrix NULL? TRUE   kwarg NULL? TRUE
rows: 7   ready: 0   note: missing_tmb_parameter
```

All seven fixed-effect rows (`mu1`/`mu2` intercept and slope, `rho12`,
`sigma1`, `sigma2` intercepts) stay `profile_ready = FALSE`. The SPLIT is
verified on a live structured fit, not only on the synthetic payloads in
`tests/testthat/test-julia-biv-inference.R`.

## (c) bivariate `meta_V(V = ...)` -- not reachable through the bridge at all

```
REFUSED: `engine = "julia"` could not find model variable "Vk" in `data`.
```

The bridge's data marshalling column-subsets a `data.frame`, so the per-row
2x2 sampling-covariance ARRAY a bivariate `meta_V()` needs cannot cross. That
route (which takes a different `nll` branch in DRM.jl's
`_fit_bivariate_residual`) is therefore **not** admitted by `engine = "julia"`
today, with or without this leaf's change. It is named as NOT COVERED rather
than left implied.

## (d) partially observed bivariate response -- fits and profiles, but the
## masked cells never reach Julia

Committed fixture with `y1[1:8] <- NA`, `engine = "julia"`, default
`missing = miss_control(response = "drop", predictor = "fail")`:

```
payload: tree NULL? TRUE   matrix NULL? TRUE   kwarg NULL? TRUE
rows: 7   ready: 7   note: ready
profile   fixef:mu1:x  [0.2009762, 0.4651369]  conf.status = profile
bootstrap fixef:mu1:x  [0.1798161, 0.4059881]  20/20 successful refits, 0 failed
```

READ THIS CAREFULLY. `drmTMB_julia_bridge()` drops NA rows on the R side BEFORE
marshalling whenever `missing_control$response == "drop"` (the drmTMB default;
R/julia-bridge.R, the `#694` block). So this fit is a COMPLETE-CASE fit on the
172 surviving rows, and **no missing cell reaches Julia**. What it shows is that
the new targets survive a smaller, differently-shaped design -- not that a
masked bivariate likelihood was profiled.

Consequence for the DRM.jl side: `_bootstrap_keep_unobserved` (which keeps an
unobserved cell unobserved in every bootstrap replicate) is **not exercised
through the R bridge today**. It is Julia-side correctness for direct DRM.jl
callers and for any future bivariate `response = "include"` route, and it is
unit-tested there for both `NaN` and `Union{Missing,Float64}` columns. Claiming
it as R-visible behaviour would be claiming more than was measured.

Also note what this row does NOT settle: for a bivariate model, dropping a row
that is missing only `y1` also discards its observed `y2`. That is drmTMB's
existing default behaviour on this route and is untouched here.
