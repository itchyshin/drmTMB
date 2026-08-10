# BLOCKER — `main` CI is RED, and it is not a release-lane problem

**Found 2026-08-10 during the overnight 0.7.0 readiness run. Reported, not fixed — the fix belongs to
the Julia lane or to CI, not to this lane.**

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
