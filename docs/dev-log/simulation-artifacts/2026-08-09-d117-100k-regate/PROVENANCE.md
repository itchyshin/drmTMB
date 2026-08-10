# Provenance and environment fingerprint — D-117 100k re-gate

Written 2026-08-09 in response to the D-43 panel's **Grace (reproducibility) seat**, which returned
**NOT-DONE** on three reproducibility findings. This file answers findings #1 and #2 with measured
evidence; finding #3 (the regeneration command) is fixed in `VERDICT-100K.md §9`.

Grace's objections were about the **evidence chain**, not the statistics. She independently
re-verified and confirmed: the four raw-CSV SHA-256s, the byte-identical scorer, the prefix-check
PASS (re-run by her, not taken on trust), git hygiene, and the new test (9/9).

## Finding #1 — no environment fingerprint was recorded

Correct, and it was a real gap: nothing committed said what R, TMB, Matrix or BLAS produced these
numbers, and the harness writes no `sessionInfo()`. Captured now, from the machine and library that
actually ran the campaign:

| component | value |
| --- | --- |
| R | **4.5.3 (2026-03-11)** |
| platform | `x86_64-pc-linux-gnu` |
| kernel | `Linux 6.8.0-110-generic x86_64` |
| drmTMB | 0.6.0 (built from source, see below) |
| TMB | **1.9.21** |
| Matrix | 1.7.5 |
| RcppEigen | 0.3.4.0.2 |
| BLAS | `/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0` (reference) |
| LAPACK | `/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0` (reference) |
| library path | `~/d117_100k/lib` (campaign-scoped, not the shared `~/R/lib`) |
| threading | `OPENBLAS_NUM_THREADS=OMP_NUM_THREADS=MKL_NUM_THREADS=1`, set by the runner |
| gcc / g++ / gfortran | **13.3.0** (Ubuntu 13.3.0-6ubuntu2~24.04.1) |
| `R CMD config CXX` | `g++ -std=gnu++17` |
| `RNGkind()` | `Mersenne-Twister | Inversion | Rejection` (R default) |
| `LC_COLLATE` / `LC_NUMERIC` | `en_US.UTF-8` / `C` |

*(The compiler row was added after a D-43 seat pointed out that the compiler producing the TMB
`.so` affects floating-point results in compiled likelihoods — precisely the risk class this file
exists to manage.)*

### Cross-platform reproducibility is NOT achievable — measured, not assumed

The earlier text said cross-R-version reproducibility was "not demonstrated". It is now **measured,
and the answer is negative.** Identical seed, identical `RNGkind`:

```
set.seed(20660728); u <- rnorm(10, 0, 0.5)
```

| | |
| --- | --- |
| Totoro, x86_64, R 4.5.3 | `u[1] = -4.67188603118640299883e-01` |
| laptop, **arm64**, R 4.6.0 | `u[1] = -4.67188603118640244372e-01` |
| `identical()` | **FALSE** — 4 of 10 values differ |
| max relative difference | **2.77e-16** ≈ 1 ULP (`.Machine$double.eps` = 2.22e-16) |

*(Confound, stated: this experiment varies **architecture and R version simultaneously**, so the
cause is not isolated to `libm`. Either way the conclusion — no bit-exact cross-platform
regeneration — is conservative.)*

The DGP itself differs at the last bit between the two environments (most likely platform `libm` in
normal inversion),
so **regenerating this campaign on a different platform cannot reproduce it bit-exactly**, and
individual coverage indicators can flip. Two consequences:

1. The **Totoro↔Totoro prefix check remains fully valid** — same platform, and it was bit-exact.
2. **`VERDICT-100K.md` §3's "environment parity" claim is narrower than it read.** The S0 smoke
   agreed at *printed* precision (7 s.f.), not bit-level. That is still a meaningful robustness
   result — the fit and both interval endpoints agreed to 7 s.f. *despite* ULP-different input data
   — but it is not identity, and it was originally worded as though it were.


**Summarised.** The whole campaign — including the 2026-08-04 run it is compared against — executed
on Totoro under R 4.5.3. The local Mac is arm64 under R 4.6.0. So:

- **within-Totoro reproducibility is bit-exact** — the prefix check reproduces the 2026-08-04
  campaign to `max|diff| = 0.000e+00` across 1,000 shared seeds in all four cells. This is the
  control the arc's conclusions actually rest on, and it is same-platform, so it is unaffected by
  the ULP finding above.
- **cross-platform reproducibility is impossible at the bit level** — measured above, ~1 ULP in
  `rnorm()` itself.
- **cross-platform agreement at the fit level is nonetheless close**: the S0 smoke agreed to 7 s.f.
  on `estimate_sd`, both interval endpoints, and boundary counts, *despite* ULP-different inputs.
  That is 50 replicates, not 400,000, and it is a robustness observation — **not** identity, and
  **not** a demonstration that a 400,000-replicate campaign would reproduce cross-platform.

## Finding #2 — package provenance was asserted, not pinned

Also correct as raised. `package_commit` is `NA` in every raw row (the runner only populates it for
an installed build, not a `--repo`/`pkgload` load), and the extracted build tree at
`~/d117_100k/src` has **no `.git` directory**, so nothing inside the campaign artifacts tied the
compiled package to a commit.

**Now established by measurement rather than trust:**

1. **The branch never modified the package.**
   `git diff --name-only a2695a788..HEAD -- R/ src/ DESCRIPTION` returns **empty**. Every commit on
   `claude/d117-discharge` touches only `docs/dev-log/**` and one new file under `tests/testthat/`.
   So the package source on this branch *is* `origin/main @ a2695a788`'s.

2. **The built tree is byte-identical to that source.** Rolled-up SHA-256 over all 41 `R/*.R`,
   `src/*.cpp`, `*.h`, `*.hpp` files, computed content-only and order-independently on both sides:

   ```
   bc1a666e0fb5a1e699bd724e788c0166fd3d8c117adb1af231fe373541248c5f   local worktree  (R/ + src/)
   bc1a666e0fb5a1e699bd724e788c0166fd3d8c117adb1af231fe373541248c5f   Totoro build tree ~/d117_100k/src
   ```

   Same 41 files, same content hash.

Together these pin the compiled package to `a2695a788` without needing a `package_commit` field.

> **A methodological trap worth recording.** The first attempt at this comparison reported
> **MISMATCH**. The cause was not content — it was that macOS and GNU `sort` collate
> `associate-pairs.R` against `associate-pairs-sandwich-*.R` differently, so a hash of
> `find | sort | xargs shasum` rolled the same files up in a different order on each side. Per-file
> hashes were identical throughout. **A cross-platform file-tree hash must sort the hashes, not the
> filenames.** Had this been trusted at face value it would have manufactured a provenance scandal
> out of a locale setting.

## Residual gaps — not closed, stated

- **`package_commit` is still `NA` in the data.** The fix belongs in the harness (bake a
  `git describe`/SHA in at run time), which is out of this arc's scope since it would edit the
  frozen 2026-08-04 runner. Filed here rather than silently left.
- **No `sessionInfo()` is captured by the harness itself.** This file records the environment
  externally; the harness still does not, so a future run will have the same gap unless changed.
- **Totoro's `~/d117_100k/` is not backed up.** If it is cleaned, the raw CSVs (~195 MB, checksums
  in `VERDICT-100K.md §9`) are gone and only regeneration recovers them — under the environment
  above, which is itself mutable shared state.
- **Cross-R-version reproducibility is untested at scale** (see finding #1's caveat).

## Verification commands

```sh
# 1. the branch never touched the package
git diff --name-only a2695a788..HEAD -- R/ src/ DESCRIPTION      # expect: empty

# 2. built tree == worktree source (order-independent, cross-platform safe)
find R src -type f \( -name '*.R' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) \
  -exec shasum -a 256 {} \; | awk '{print $1}' | sort | shasum -a 256
# on Totoro, same with sha256sum; expect bc1a666e0f…48c5f both sides
```
