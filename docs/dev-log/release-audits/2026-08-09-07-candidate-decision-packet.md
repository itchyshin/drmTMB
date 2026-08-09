# drmTMB 0.7.0 — candidate decision packet

**Date:** 2026-08-09 · **For:** Shinichi · **Lane:** Claude task 1, Stage B (closing)
**Branch:** `claude/07-release-slice` @ `771b2a3d6` · **Draft PR:** [#959](https://github.com/itchyshin/drmTMB/pull/959)

## Verdict

**Highest proven rung: `tarball-clean`**, for hash `da9b2d76…` only.
**Next unproven rung: `platform-clean`** — runs dispatched, rung **not** claimed.

There is now, for the first time, an exact 0.7.0 candidate that exists, is frozen, and has
passed a full CRAN-lane check on its own bytes.

## The candidate

| Property | Value |
| --- | --- |
| **SHA-256** | `da9b2d76badcdd48e7200d134f6a314d765071884e7e094da330ba85163df04a` |
| **Size** | 9,853,648 bytes · **924 entries** · **0 forbidden paths** |
| **Source** | `14bc8ce89`; artifact proved identical to clean commit `771b2a3d6` over every build-included path |
| **Base** | `origin/main@8d441a32d` (PR #956, separation **DEFER**) |
| **Immutable copy** | `scratchpad/frozen-da9b2d76badc/`, write-protected |
| **Local CRAN check** | **Status: 1 NOTE** — `New submission`, and nothing else |
| **Fail-closed ledger** | `READY FOR CLAIMED RUNG` at `tarball-clean` |

Check ran with CRAN incoming **enabled**, vignettes **built**, manual built,
`_R_CHECK_FORCE_SUGGESTS_` **not** disabled. Both predecessor incoming items — DESCRIPTION
spelling and the invalid file URI — are **cleared**, the URI verified inside the artifact
rather than in source.

## The one thing that should decide the submission

**`inst/doc` is 11.11 MB against CRAN's stated 5MB documentation maximum — 2.2×.**

Today's policy read, verbatim:

> As a general rule, neither data nor documentation should exceed 5MB … **authors will be
> asked to trim their documentation to a maximum of 5MB.**

`R CMD check` reports this only as an `INFO` line. Not a NOTE. It is invisible to every gate
except a policy read, which is exactly why the protocol demands one.

Driven by self-contained vignette HTML with base64 figures: `figure-gallery.html` 2.90 MB,
`function-map-cheatsheet.html` 1.52 MB, `simulation-plot-grammar.html` 0.73 MB. **The top
five files alone exceed the entire allowance.**

Options, in rough order of cost — **none taken, because which vignettes ship is your call:**

1. Move `figure-gallery` and `function-map-cheatsheet` to pkgdown-only articles (they are
   arguably website artifacts). Removes ~4.4 MB → `doc` ≈ 6.7 MB. Still over.
2. Reduce figure resolution or switch to vector output in the heaviest vignettes.
3. `build_vignettes = FALSE` for the heaviest few — source ships, built HTML does not.
4. Justify in `cran-comments.md` and submit as-is. Weakest given the wording, but legitimate.

`libs` at 13.6 MB is **not** covered by this rule — compiled TMB object code, same pattern
as CRAN's own `glmmTMB`.

## What Stage B changed

- Merged the offset arc ([#958](https://github.com/itchyshin/drmTMB/pull/958)) and the B1
  dispatch fix ([#957](https://github.com/itchyshin/drmTMB/pull/957)).
- `DESCRIPTION` **0.6.0 → 0.7.0** (D-86 — inside the release slice).
- Spelling and file-URI fixes; version-consistency repairs in `NEWS.md` and `README.md` that
  the bump itself had falsified.
- README Install section no longer directs new users to the unsupported `v0.5.0` tag.
- C17 model-15 compatibility evidence **re-measured** on the new source.

## Two failures worth carrying forward

**1. I verified the wrong artifact.** CI failed with `mc-0568: current model-15 fingerprint
differs`. The capability ledger fingerprints named source anchors, and the offset arc edited
two of them. I had run `capability_ledger.py --check` (passes) and confirmed the census
(unchanged) — but the fingerprint guard lives in `tools/tests/`, which CI runs and I did
not. Fixed by re-measurement, not by re-pinning: 3 cells × 4 attempts, all PASS, tau
relative errors 0.099 / 0.166 / 0.061 against a 0.40 threshold.

**2. Reading source is not reading the reader surface.** Candidate `d35c0b9e` passed the
identical check and was frozen — then building the pkgdown site and reading the *rendered
homepage* showed the README still telling users to install `v0.5.0`. `README.md` ships, so
the fix invalidated that candidate and forced the rebuild to `da9b2d76`. The defect had been
reported HIGH by the pre-release reader review; I had fixed the neighbouring line and missed
the command itself.

Both were caught by *running* the thing rather than reading it. Both are recorded in
[`FREEZE-NOTES-0.7.0.md`](../release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md).

## Platform matrix

Dispatched at the final source `771b2a3d6`:

- 3-OS `R-CMD-check` — [31328481090](https://github.com/itchyshin/drmTMB/actions/runs/31328481090)
- `R-hub` sanitizers — [31328482134](https://github.com/itchyshin/drmTMB/actions/runs/31328482134)

⚠ **Earlier dispatches are void for this candidate** — runs `31327046167` and `31327047576`
launched at `7fccac0b9`, before both fixes.

Reading them: **a timeout kill logs as `conclusion: cancelled`**, identical to a concurrency
cancel. Compare job duration against the 75-min ceiling; never trust the conclusion string.

**win-builder was not submitted.** It is the only real measurement of the Windows vignette
timing, and it is an upload to a third party — say the word and it goes.

## Decisions still yours

| Item | State |
| --- | --- |
| **`inst/doc` 11.11 MB vs the 5MB maximum** | **open — the likely submission blocker** |
| `platform-clean` rung | runs dispatched; the **rung** needs your explicit word |
| win-builder submission | not sent |
| D-43 panel | deferred by you until platform evidence exists |
| Merge #957 / #958 to `main` | open, not merged |
| Merge #959 (release slice) | **draft — merging it is the release action** |
| `DESCRIPTION:19` "Skewness … staged for later phases" | stale understatement; `skew_normal()` is fitted. No CRAN risk; your copy |
| Final `cran-comments.md`, author-consent line, tag, upload | not started, as instructed |

**D-93 was discharged by you today** on the grounds that its premise — a fixable drmTMB
defect — was answered by measurement. **D-117's PASS remains withheld** and is untouched.

## Stopped here, as instructed

No D-43. No `platform-clean` write. No final `cran-comments.md`. No tag. No GitHub release.
No CRAN upload.
