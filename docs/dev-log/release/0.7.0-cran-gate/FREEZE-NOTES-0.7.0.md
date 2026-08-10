# drmTMB 0.7.0 — the first 0.7.0 candidate freeze

Frozen 2026-08-10. **This is the first drmTMB 0.7.0 artifact that has ever existed.** Every prior
freeze and every platform log on file describes a `0.6.0` predecessor.

## Artifact identity

- **Freeze source commit:** `9490576466bfce4cb2bb952bd15993f6aff48d4b`
  (branch `claude/07-candidate-freeze`, off `main` @ `c91d62b21`)
- **Clean tracked worktree at build:** yes (`git status --porcelain` empty, verified before build)
- **Tarball:** `drmTMB_0.7.0.tar.gz`
- **SHA-256:** `d1c7b4f0ef819512a6c9470958f9168579404cbf72f5edbe173cc95cdb06bc2b`
- **Size:** 9,873,999 bytes
- **Inventory:** 929 paths
- **Forbidden-path scan:** **0 entries** — no `docs/dev-log`, `tools`, `scratchpad`, `.codex`,
  `.claude`, `.github`, `AGENTS.md`, `CLAUDE.md`, or `.worktrees` path is present. Proven from the
  built tarball, not from `.Rbuildignore`, per the protocol's Gate 1 requirement.
- **Installed size:** 31 MB — `libs` 14 MB, `doc` 11 MB, `R` 3.0 MB, `sim` 1.9 MB

## Real CRAN-lane check

`R CMD check --as-cran --run-donttest --no-manual` with `_R_CHECK_CRAN_INCOMING_=true`, run against
the frozen tarball (not the source tree, and not `devtools::check()`).

**`Status: 1 NOTE` — 0 ERROR, 0 WARNING.** The sole NOTE is `New submission`, which is unavoidable
for a first CRAN submission.

| phase | time |
| --- | --- |
| checking CRAN incoming feasibility | `[4s/24s]` NOTE |
| checking R code for possible problems | `[28s/30s]` OK |
| checking examples | `[11s/12s]` OK |
| **checking tests** | **`[193s/221s]`** OK |
| checking re-building of vignette outputs | `[78s/90s]` OK |

## Check-time budget — what changed and what did not

The predecessor freeze recorded `checking tests ... [9m/10m]` locally and **29 min** (R-release) /
**30 min** (R-devel) on win-builder, against CRAN's roughly ten-minute guidance for the *whole* check.
PR #990 trimmed the CRAN lane via `tests/testthat.R`'s existing filter; this freeze measures the
result at **`[193s/221s]`**, a **2.7x** reduction on the same harness.

**Projection to Windows, computed like-for-like.** The correct factor comes from comparing the same
phase in the same harness: predecessor local `R CMD check` tests `10m` vs win-builder `29m`, i.e.
**≈2.9x**. Applying that: `3.7 min × 2.9 ≈ 10.7 min` of `checking tests` on Windows.

> **A superseded figure, recorded so it is not reused.** An earlier estimate used a **1.50x** factor.
> That was wrong: it compared a `testthat::test_local()` profiling run (19.3 min) against
> win-builder's `R CMD check` (29 min) — two different harnesses. It happened to yield a similar
> answer (~10.8 min); the agreement is coincidence, not corroboration.

**This freeze does not claim the check clears CRAN's guidance.** Estimated Windows total is roughly
**15 min** (tests ~10.7 + vignettes ~2 + examples/install ~2), down from about 35 min. That is a large
improvement and still probably above ten minutes.

## Rung

**No rung claim is written here.** Advancing `status_claim` is the owner's decision under D-49, and
`FREEZE-NOTES.md` for the predecessor already records that the next rung requires explicit
authorisation before any ledger write.

What this freeze establishes as *evidence*: an identified artifact with a clean real-CRAN-lane local
check, a clean-worktree build, a proven-empty forbidden-path scan, and a recorded inventory.

What it does **not** establish: any platform evidence. Every 3-OS, sanitizer, rchk and win-builder log
on file belongs to `744b9fbe` or `25e38cc74` — predecessors of this commit — and **valgrind has never
produced a verdict at any commit** (job `92921626041` was cancelled at GitHub's 6-hour ceiling, so
Actions structurally cannot host it; it must run locally or on Totoro).

## Gate 1 — rights and product contract

Completed before this freeze: SHIP 4 · EXCLUDE 0 · UNRESOLVED 2. No undocumented borrowing, no
consent gap, no undocumented data provenance. `License: GPL (>= 3)` linking TMB (`GPL-2`) follows the
precedent of `glmmTMB` (`AGPL-3`, `LinkingTo: TMB`), which is on CRAN.

> An earlier draft of the Gate 1 report listed a third unresolved item — `inst/COPYRIGHTS` citing a
> "phantom" `R/crs.R`. **That was a misreading and is withdrawn.** The citation names the *upstream
> gllvmTMB* source baseline "at that exact commit"; gllvmTMB has both `R/mesh.R` and `R/crs.R`.
> The record is correct as written and must not be "fixed".

## Reproduce

```sh
git checkout 9490576466bfce4cb2bb952bd15993f6aff48d4b
R CMD build --no-manual .
shasum -a 256 drmTMB_0.7.0.tar.gz     # d1c7b4f0...bc2b
_R_CHECK_CRAN_INCOMING_=true R CMD check --as-cran --run-donttest --no-manual drmTMB_0.7.0.tar.gz
```

`R CMD build` embeds timestamps, so a rebuild will not reproduce these bytes. Content equivalence is
established by the source commit, not by re-deriving the hash.
