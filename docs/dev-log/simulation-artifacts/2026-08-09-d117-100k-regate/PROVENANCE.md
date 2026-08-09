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

**A caveat Grace is right to press.** The whole campaign — including the 2026-08-04 run it is
compared against — executed on Totoro under R 4.5.3. The local Mac runs R 4.6.0. **Cross-R-version
reproducibility is therefore NOT demonstrated by this arc.** What *is* demonstrated is:

- **within-Totoro reproducibility**, bit-exact: the prefix check reproduces the 2026-08-04 campaign
  to `max|diff| = 0.000e+00` across 1,000 shared seeds in all four cells; and
- **cross-machine agreement at the fit level**: the S0 smoke, run on the Mac under R 4.6.0 and on
  Totoro under R 4.5.3 with the same seeds, produced identical `estimate_sd = 0.1919612`,
  `profile_lower = 0`, `profile_upper = 0.6268075` and identical boundary counts.

That second point is evidence *for* cross-version stability but it is 50 replicates, not 400,000.
It should not be over-read, and `VERDICT-100K.md §3`'s "environment parity" wording rests on it.

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
