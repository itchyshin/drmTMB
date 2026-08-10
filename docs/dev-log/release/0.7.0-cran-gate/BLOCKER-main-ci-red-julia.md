# BLOCKER — `main` CI is RED, and it is not a release-lane problem

**Found 2026-08-10 during the overnight 0.7.0 readiness run. Reported, not fixed — the fix belongs to
the Julia lane or to CI, not to this lane.**

> ## ⚠ CORRECTION (2026-08-10, later session) — the cause below is WRONG
>
> **The `Suppressor` `LoadError` is not the ERROR. It is Julia teardown noise printed *after*
> `Execution halted`.** Every Julia test in run `31350747542` **skipped correctly** (they carry a
> second `skip_if_not(...)` after `skip_if_not_installed("JuliaCall")`; the log records
> `DRM.jl engine path not available (9)` and siblings, 305 skips total).
>
> **The real ERROR is three failing assertions**, all in one test:
>
> ```
> ── Failure ('test-missing-predictor-beta-binomial.R:152:3'): beta-binomial mi() predictor model
>    reports a route-conditional std_error when sdreport is available ──
> Expected `all(is.finite(imp$std_error))` to be TRUE.   actual: FALSE
> Expected `all(imp$std_error > 0)` to be TRUE.          actual: <NA>
> Expected `imp$uncertainty_status` to equal `rep("ok", 5)`.
>     actual: "sdreport_non_pd_hessian" ×5
> [ FAIL 3 | WARN 75 | SKIP 305 | PASS 20023 ]
> ```
>
> This **confirms the timeline in the table below and corrects its attribution**: the test was added by
> `afb917213` inside PR #972 — the very merge at which `main` went red.
>
> **It is a borderline-conditioned fixture, not a platform bug.** Reproduced at `64149c465` on macOS
> (`pkgload::load_all`, `NOT_CRAN=true`): the test **passes**, but the fit reaches
> `false convergence (8)` on *both* platforms and its `sdreport` covariance is only marginally positive
> definite — `min eigenvalue 8.81e-06`, **condition number 3.63e+07**. Whether the smallest eigenvalue
> lands just above or just below zero is a BLAS/LAPACK coin-flip; macOS says `pdHess = TRUE`, the ubuntu
> runner says non-PD. The adjacent test in the same file already carries a BLAS/LAPACK-sensitivity
> comment, and `0f612e648` already had to `skip_on_cran()` other blocks in this file for fragility.
>
> **Consequence for the plan: neither Julia fix below would turn `main` green.** They address at most
> the `checking for detritus in the temp directory` **NOTE** (`jl_*` temp dirs), not the ERROR. The
> remaining fix belongs to the **missing-data lane**, and the choice between hardening the fixture,
> widening the assertion, or treating the near-singular Hessian as a real finding is **not the release
> lane's to make**. Sections "The cause", "Why the skip guard does not save it", and "Two candidate
> fixes" are **SUPERSEDED**; the "state" table and "Why this matters" remain accurate once the cause is
> substituted.
>
> **Verified on all three runs** — `main` `31350747542`, PR #978 `31350952083`, PR #976 `31383639291` —
> each `Status: 1 ERROR, 1 NOTE` with the *identical* three failures and **zero** Julia-caused failures.
> So "PR #978 failed for this reason and nothing else" below is still true of the *shape* of the
> failure; the reason is the beta-binomial fixture, not Julia.

## The state

`main` is **failing** `R CMD check`. It is not a flake and it is not caused by tonight's merges.

| commit | run | result |
| --- | --- | --- |
| `a2695a788` | 31346… | **success** (2026-08-09 21:15) |
| `fddb82105` — PR **#972**, missing-data merge | 31349… | **FAILURE** (2026-08-10 01:53) ← went red here |
| `744a2d4f3` — PR #974 (D-117) | 31350726346 | cancelled (concurrency, by the next push) |
| `64149c465` — PR #975 (D-117 figures) | 31350747542 | **FAILURE** (same cause) |

**Main went red at `fddb82105`, before either D-117 merge.** Both D-117 PRs are docs, roxygen, `man/`,
`NEWS.md` and one vignette; neither touches Julia, `src/`, or test infrastructure.

## The cause

```
Status: 1 ERROR, 1 NOTE
❯ checking tests ...
  LoadError("/home/runner/work/_temp/Library/JuliaCall/julia/setup.jl", 16,
    ArgumentError("Package Suppressor not found in current path.
      - Run `import Pkg; Pkg.add(\"Suppressor\")` to install the Suppressor package."))
```

The **Julia** package `Suppressor` is not present in the CI runner's Julia depot.

## Why the skip guard does not save it

`.github/workflows/R-CMD-check.yaml` contains **no Julia setup step at all** (`grep -i julia` →
nothing). The live Workflow-G test states in its own header that it is *"Skip-safe when JuliaCall /
DRM.jl / the fixture tree is unavailable"* — but the guard is:

```r
skip_if_not_installed("JuliaCall")
```

**`JuliaCall` the R package IS installed in CI** — `r-lib/actions/setup-r-dependencies` installs
Suggests. So the skip never fires. Execution proceeds to Julia initialisation, which then dies on the
missing Julia-side `Suppressor`.

**The guard tests the wrong thing:** the presence of the R binding, not whether the Julia runtime is
usable. `skip_if_not_installed()` cannot detect a broken Julia depot.

## Two candidate fixes — the owner or the Julia lane should choose

1. **Make the guard genuinely skip-safe** (test-side). Wrap Julia initialisation in `tryCatch()` and
   `skip()` on any failure, rather than inferring usability from `JuliaCall`'s presence. This keeps CI
   independent of a Julia toolchain, which matches the workflow's current design (no Julia step).
2. **Install Julia and its packages in CI** (workflow-side). Add a `julia-actions/setup-julia` step
   plus `Pkg.add("Suppressor")` and DRM.jl. This makes the gate genuinely live in CI — closer to
   #499's intent — but adds Julia to every routine run.

(1) is the smaller change and restores green immediately. (2) is what you want if the Workflow-G gate
is meant to be enforced on every push rather than run opportunistically.

## Why this matters for 0.7.0

A red `main` is a hard readiness blocker regardless of the release candidate's own state, and it will
contaminate every subsequent PR's checks — **PR #978 failed for exactly this reason and nothing else**
(its own local `R CMD check --as-cran` returns `Status: 1 NOTE`).

**Note the asymmetry:** the release slice `claude/07-release-slice` is **unaffected** — the 3-OS matrix
dispatched there tonight (run 31350779116, at `bce9cfb6f`) passed on all three platforms, because that
branch predates the live-Julia test. So this blocks `main`, not the candidate.

## What this does not change

Highest proven rung remains `tarball-clean`; next unproven remains `platform-clean`. No rung claim is
made here. `DESCRIPTION` remains 0.6.0.
