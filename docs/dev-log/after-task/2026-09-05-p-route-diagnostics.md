# After Task: route-aware diagnostics, the drmTMB consumer side (`p-route-diagnostics`)

**Worktree.** `claude/parity-p-route-diagnostics` at
`~/local-scratch/parity-joint/wt-p-route-diagnostics`, cut from `origin/main`
at `6370f9c5a` and merged up to `f8f11699c`.
**Issues.** [drmTMB#1108](https://github.com/itchyshin/drmTMB/issues/1108) /
[DRM.jl#569](https://github.com/itchyshin/DRM.jl/issues/569). Adjacent:
[DRM.jl#632](https://github.com/itchyshin/DRM.jl/issues/632) (which exposed the
stored gradient across the bridge) and DRM.jl PR
[#656](https://github.com/itchyshin/DRM.jl/pull/656) (which gives the
`grad_source` vocabulary this leaf reuses). Pin: DRM.jl `430ef64cc`.
**Ledger.** `.unlazy/parity/gates/leaf-p-route-diagnostics.md`.

## The problem, stated as a user would meet it

Leaf A9d (merged PR #1181) landed the base consumer: `check_drm()` on an
`engine = "julia"` fit returned two rows, `optimizer_convergence` and a
route-aware `fixed_gradient`. Both rows were correct. The table around them
was not honest enough, in three separate ways, all of the same shape -- a
DRM.jl fit presented as if TMB had produced it.

1. **The table never said which engine ran.** A user diffing
   `check_drm(tmb_fit)` against `check_drm(julia_fit)` saw roughly forty rows
   against two, with nothing anywhere in the second table saying that the
   thirty-eight missing rows were *not run* rather than *found clean*.
2. **A printed gradient did not say who made it.** DRM.jl can produce a
   gradient from an exact analytic location-scale formula, from a stored
   callback, from forward-mode AD, or from a central finite difference good to
   roughly `1e-6` relative -- and can produce none at all, in two
   distinguishable ways. PR #656 gives those six cases names precisely so a
   caller can tell them apart. drmTMB printed a bare number.
3. **The covariance DRM.jl marshalled back was never read.** `new_drmTMB_julia()`
   already classifies it as `ok` / `partial` / `unavailable` and writes its own
   message. Nothing consumed that. Measured on `origin/main`: a bridge fit
   whose covariance came back wholly non-finite returned
   `attr(check_drm(fit), "ok") == TRUE` over two green rows.

## What landed

`check_drm()` on a `drmTMB_julia` fit now returns five rows, in this order.

| row | status register | what it reads |
| --- | --- | --- |
| `engine_route` | always `note` | engine, DRM.jl route, estimator; message names the native checks that did **not** run |
| `optimizer_convergence` | `ok` / `error` | `object$diagnostics$converged` (unchanged from A9d) |
| `fixed_gradient` | `note` / `ok` / `warning` / `error` | route-aware `max|gradient|`, now with `source=` naming the producer |
| `bridge_covariance` | `ok` / `note` / `warning` | `object$uncertainty$status` and its stored message |
| `bridge_standard_errors` | `ok` / `warning` | the SEs implied by `object$vcov`'s diagonal |

`engine_route` is a `note` by deliberate choice: reporting which machinery ran
is not itself a fault, and a `note` does not flip `attr(x, "ok")` -- the same
register `check_fixed_gradient()` already uses for `keep_tmb_object = FALSE`.

### What R can honestly say about the gradient's source

Measured at the pin, `src/bridge.jl:1497`: the payload's `"gradient"` key has
exactly one producer, `if fit.nllgrad !== nothing`, which then calls that
callback. So **a gradient that crossed the bridge is DRM.jl's `:stored` and
nothing else**, and the row may assert that.

When no gradient crossed, R genuinely cannot tell which of the other five
applies. Verified rather than assumed: DRM.jl PR #656 changes `src/inference.jl`,
`test/test_check_drm.jl` and `NEWS.md` **only** (`gh pr diff 656 --name-only`),
so `grad_source` does not cross the bridge at the pin or after #656 merges.
The row therefore reports `source=unknown` -- deliberately **not** one of
DRM.jl's six values, so it can never be mistaken for one -- and names DRM.jl's
own `check_drm(fit)` as where the distinction is actually available. **No gate
in this leaf is blocked on PR #656**; the leaf takes its vocabulary (a naming
contract, readable now) and none of its code.

Two refusals guard that surface for a future bridge that *does* send a source:
an out-of-vocabulary value aborts rather than being echoed, and a value that
contradicts the payload aborts too (a producer named when no gradient crossed,
or `none`/`unavailable` alongside one that did).

## Evidence measured this run

Every number below was produced in this worktree in this run.

### G1 -- the gradient source was previously unnameable

```
main: 0  branch: 3
GATE_G1_RED_CONFIRMED
```
(`git show origin/main:R/julia-diagnostics.R | grep -c 'source='` is `0`.)

### G2 -- the silent covariance, before and after, same fit

`tools-scratch/red-covariance.R` swaps `R/julia-diagnostics.R` to the
`origin/main` blob, measures a mocked fit with `vcov = matrix(NaN, 3, 3)` in a
subprocess, restores, and measures again:

```
BEFORE ok=TRUE rows=2 covrow=0
AFTER ok=FALSE rows=5 covrow=1
RESTORED_IDENTICAL md5=20c1e1c335e97abbaf7a631794d8f4cb
```

The fit's own `uncertainty$status` is `"unavailable"` in both runs; only the
consumer changed.

### G6 -- red control on the provenance claim

Planted `stored` -> `forward` in `drm_julia_gradient_source()` (claiming an AD
gradient where the bridge handed over the fit's own callback). Verbatim, from
`tools-scratch/redctl-g6.txt`; the full file is committed with this report's
run and reproduced by `bash tools-scratch/redctl-g6.sh`.

### Suites

Full counts are in the ledger's `MEASURED` block.

## Defect found and NOT fixed here (out of OWNS)

`$` on an R list partially matches. `new_drmTMB_julia()`
(`R/julia-bridge.R`) reads the raw DRM.jl payload as `result$gradient`. On a
payload that carries a `gradient`-prefixed field but no `gradient` -- exactly
what a future bridge sending `gradient_source` would produce -- `result$gradient`
returns the **provenance string**, and the constructor then aborts on the
`gradient_names`/`coef_names` comparison. Measured:

```r
l <- list(gradient_source = "none", coef_names = "a")
l$gradient          #> [1] "none"
is.null(l[["gradient"]])  #> [1] TRUE
```

This is latent today (no such payload field exists at the pin) and lives in a
file this leaf does not own, so it is reported, not fixed. The consumer added
here uses exact `[[` extraction throughout, and the tests inject a provenance
field *after* construction with a comment naming this hazard. **A separate
change should switch `R/julia-bridge.R`'s raw-payload reads to `[[`.**

## Not this leaf

No DRM.jl change. No new `drm_control()` option. No capability widened or
narrowed, no family registry row touched. `attr(x, "ok")`'s definition is
unchanged -- what changed is that a covariance failure now produces a row that
meets it. Profile and bootstrap result rows keep their own status and are not
touched. No claim that DRM.jl's gradient and TMB's `sdreport()` gradient agree
numerically appears anywhere in the code or the documentation.
