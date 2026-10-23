# After Task: C Meuwissen-Luo inbreeding for pedigree F

Date: 2026-09-26
Lane: Cursor, `cursor/meuwissen-cpp-20260926`
Worktree: `~/local-scratch/lanes/drmTMB-meuwissen-cpp-20260926` off `origin/main` @ `671116531`
Active lenses: Ada, Shannon, Rose (perspectives; no spawned subagents)
Current lane: R (drmTMB)

Reader: anyone fitting `animal(1 | id, pedigree = ped)` after #1424, and anyone auditing whether the R heap walk still sits on the construct path.

## Goal

#1424 moved F off dense `A`, but the R Meuwissen-Luo walk was slower than dense F at mid n (same-build construct at n=6000: dense-F 22.546 s, R walk 41.032 s). This slice puts the same published walk in compiled C and keeps the R walk as a private reference.

## Implemented

`drm_pedigree_inbreeding_meuwissen_luo()` still takes a topologically ordered pedigree and still returns a named numeric F. After load it calls `.Call("drm_meuwissen_luo_inbreeding", sire, dam, PACKAGE = "drmTMB")`. Parent matching and the ancestors-before-descendants abort stay in R. `src/init.c` now registers that Call entry and leaves `R_useDynamicSymbols(dll, TRUE)` so TMB can still find MakeADFun symbols.

`drm_pedigree_inbreeding_meuwissen_luo_r()` is the previous R walk, used by the new identity test and the A/B bench. It is not the fit path.

A first C++ draft with `std::vector` failed to compile: R's `length()` macro collides with libc++. The shipped file is `src/meuwissen_luo.c`.

## Mathematical Contract

Unchanged from #1424. Meuwissen and Luo (1992):

```
d_j = 0.5 - 0.25 (F_sire(j) + F_dam(j)),   F_0 = -1
F_i = A_ii - 1,   A_ii = sum_j L_ij^2 d_j
```

One unknown parent forces `F_i = 0`. The heap pops the largest live row index first. Quaas assembly is untouched.

## Files Changed

- `src/meuwissen_luo.c`: compiled walk
- `src/init.c`: `R_CallMethodDef` for `drm_meuwissen_luo_inbreeding`
- `R/phylo-utils.R`: public function calls `.Call`; private R reference kept
- `inst/COPYRIGHTS`: C walk + private R reference; HSquared.jl still not vendored
- `tests/testthat/test-pedigree-sparse-ainv.R`: C symbol loaded; C vs R vs dense F on n=400
- `tools/meuwissen-cpp-ab.R`: same-build C vs R F and construct
- `docs/dev-log/2026-09-26-meuwissen-cpp-ab.csv`
- `docs/dev-log/check-log.d/2026-09-26-meuwissen-cpp.md`

NEWS, README, and pkgdown were left alone. `devtools::document()` rewrote many `man/*.Rd` files; those diffs were reverted.

## Checks Run

```
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'devtools::document(); devtools::load_all(); testthat::test_file("tests/testthat/test-pedigree-sparse-ainv.R")'
# FAIL 0 / WARN 0 / SKIP 0 / PASS 22
```

Same-build A/B (`tools/meuwissen-cpp-ab.R`, seed `20260926 + n`, BLAS threads = 1):

| n | F C (s) | F R (s) | construct C (s) | construct R (s) | max\|dF\| | max\|dAinv\| |
|---:|---:|---:|---:|---:|---:|---:|
| 1500 | 0.012 | 2.984 | 0.029 | 0.693 | 0 | 0 |
| 3000 | 0.113 | 6.433 | 0.123 | 6.461 | 0 | 0 |
| 6000 | 0.806 | 44.706 | 0.837 | 45.396 | 4.44e-16 | 1.78e-15 |

Receipt: `docs/dev-log/2026-09-26-meuwissen-cpp-ab.csv`.

n=1500 F R includes first bytecode compile of the R walk. Construct R at that n is the warmed number. n=3000 and n=6000 match F and construct to a few tenths of a second.

#1424 official construct at n=6000 was 41.793 s (R walk, construction inside fit). This C construct is 0.837 s on the same machine class. That is the measured construct wall, not a NEWS claim.

`devtools::check()` was not re-run in this session.

## Tests Of The Tests

Existing blocks still compare F to `diag(A) - 1`, one-unknown-parent, selfing, sire/dam swap, and the small animal fit vs the dense-F Quaas route. The new block requires the registered Call symbol, then checks C vs the private R walk at 1e-12 and C vs dense F at 1e-8 on n=400, and that names follow animal id.

## Consistency Audit

```
rg "meuwissen_luo|drm_meuwissen_luo_inbreeding|eee5f7aa" \
  src/meuwissen_luo.c src/init.c R/phylo-utils.R inst/COPYRIGHTS \
  tests/testthat/test-pedigree-sparse-ainv.R
rg "times faster|speedup|speed multiplier" NEWS.md README.md
```

Fit-path F is the C walk after load. The R walk remains only as `_r`. NEWS and README have no speed line.

## GitHub Issue Maintenance

#1424 is already closed. No open Meuwissen / C++ F issue. This PR does not use `closes`. #740, #914, and #1148 stay closed or deferred.

## What Did Not Go Smoothly

The first file was `src/meuwissen_luo.cpp` with `std::vector`. libc++'s `length()` method collided with `Rinternals.h`'s `length` macro. Plain C plus `R_alloc` compiled.

n=1500 F R vs construct R do not match (2.984 s vs 0.693 s) because F R is the first call of the R walk in that process.

## Team Learning

R's `length` macro and C++ STL do not mix unless the STL headers come first. For a two-integer `.Call`, C is enough.

gllvmTMB still forms dense tabular F. There is no Meuwissen-Luo hot path to twin.

## Design-doc / pkgdown updates

None. Public `animal()` syntax is unchanged.

## Rose claim fence

Measured on this Mac, this DGP, this CSV: C construct is 0.123 s at n=3000 and 0.837 s at n=6000 against the private R walk at 6.461 s and 45.396 s. Do not write a NEWS or README multiplier. Do not flip a covered row. Do not cite the n=1500 F R 2.984 s figure as the warmed R cost.

## Known Limitations

- Claim is the Gaussian `animal(1 | id, pedigree = )` construct path. Non-Gaussian families, repeated records, and `relmat()` are untested here.
- Quaas assembly stays in R.
- gllvmTMB twin N/A: that package still uses `diag(A) - 1`.
- `devtools::check()` not run in this session.

## Next Actions

1. Open the PR from `cursor/meuwissen-cpp-20260926`. No `closes`.
2. Merge-when-green after every check settles.
3. Leave gllvmTMB alone unless that package later grows a Meuwissen F walk.
