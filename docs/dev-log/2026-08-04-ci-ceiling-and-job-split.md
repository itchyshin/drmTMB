# The CI ceiling, and why the job should be split

**Date:** 2026-08-04 · **Lane:** Claude, drmTMB Prong B stack + CI ceiling.
**Status:** the ceiling raise has landed on `claude/prong-b-tier1` (`c1da21b7a`,
45 → 120). This note records the measurement behind it and recommends the
follow-on restructure. **The split itself is NOT done here** — it is a workflow
change and deserves its own arc.

## 1. The 45-minute cap was a repo-wide latent failure

The handover and the fix commit both reason from *"main's last green run took
36m12s, and this arc adds slow `se = TRUE` profile tests."* That cites the
**fastest** recent run. Measuring every recent `ubuntu-latest (release)` **job** —
the unit `timeout-minutes` actually governs — tells a different story.

| Run | Branch | Conclusion | Job minutes |
|---|---|---|---|
| 30861623528 | main | success | 36.0 |
| 30838218952 | main | success | 42.3 |
| 30830639007 | main | success | 37.3 |
| 30860828768 | prong-b-handover | success | 42.3 |
| 30856587505 | arc7b-truth-gate | success | 44.4 |
| 30844803774 | parity-triage | success | 42.6 |
| 30840533710 | arc6-gaussian-nine | success | 43.2 |
| 30839836967 | b4-ci-mc0207 | success | **44.9** |
| 30826334006 | handover-2026-08-03 | success | 44.6 |
| 30835207017 | arc5-final-three | success | 37.8 |
| **30847977891** | **main** | **cancelled** | **45.1 → TIMEOUT** |

Two findings:

1. **The cap had about six seconds of headroom.** Worst passing job 44.9 min
   against a 45-minute limit; four of ten successes ≥ 44.4. Those greens were
   luck, not margin.
2. **`main` had already timed out**, before this arc existed — run `30847977891`,
   the post-merge push check at `95b8ea34e` (merge of PR #911, 2026-08-03), killed
   at 45.1 min.

**Why it was misfiled.** GitHub records a timeout kill as
`conclusion: cancelled` — the same string as a concurrency cancel. Because this
repo genuinely does suffer ref-scoped concurrency cancels
(`group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: true`),
every `cancelled` was being read as concurrency. Distinguishing them requires
comparing **job duration** against the limit, not reading the conclusion string.

**Practical rule:** a `cancelled` job whose duration is within a few seconds of
`timeout-minutes` is a timeout, not a cancel. Concurrency cancels land at
arbitrary durations (observed here: 9.6, 18.3, 28.6, 34.8, 37.8 min).

### The first completed measurement — and it sharpens the story

With the ceiling at 120, run `30916793237` on `claude/prong-b-tier1` **completed
in 43m35s** (14:01:55 → 14:45:30) and passed.

That is **under** the old 45-minute cap — and it is the most useful number here,
because it means the arc did **not** push the suite decisively past 45. It pushed
it to **straddle** 45. The same branch died twice at 45m06s and 45m27s, then
passed at 43m35s. A spread of roughly ±1.5 min around a ~44–45 min mean, against
a 45-minute limit, makes every run a coin flip.

So the honest framing is *"the suite sits at 43–46 minutes against a 45-minute
cap"*, not *"this arc added ten minutes."* Either framing justifies raising the
ceiling, but only the first explains why `main` itself died on a commit that had
nothing to do with this arc.

**Consequence for tightening:** do not set the new ceiling from a single run. The
suite's own run-to-run spread is larger than the margin that was killing it.

## 2. Sibling instance

`drmSEM/.github/workflows/R-CMD-check.yaml:22` carries the identical
`timeout-minutes: 45`. Its suite is smaller today, so it has not bitten yet — but
it is the same fault waiting on the same growth curve. Worth a look when
convenient; not in this lane's scope. (gllvmTMB's 120/60 values are on simulation
workflows, which D-50 says should not be on Actions at all — a separate issue.)

## 3. Why `timeout-minutes: 120` is the right interim value

`timeout-minutes` is a **ceiling, not a reservation.** Actions bills consumed
minutes, so a generous ceiling costs nothing when jobs finish early; its only cost
is that a genuinely hung job burns longer before being killed — bounded, and on
the 1× Ubuntu runner.

Tightening *before* the merges would have set the number from
`claude/prong-b-tier1`, the lightest branch in the stack, while
`claude/mc0653-fixture` raises its fixture from 16 to 64 pairs (~4× the rows in
its own tests) and **has never once completed a CI run**. Measure against the top
of the stack, then tighten once.

When tightening, do **not** hug the measured number: the observed spread on
identical work is 36.0–44.9 min, about 25%. Leave headroom proportional to that.

## 4. Recommended restructure: split the fast guards from the slow check

The job currently runs, in order: setup → a Python/ledger guard block → an R
truth-manifest check → a capability-runtime check → a profile-fence guard → then
`check-r-package`. Their costs are wildly different:

| Step | Loads package? | Fits models? | Cost |
|---|---|---|---|
| `capability_ledger.py --check` + six `tools/tests/*.py` | no | no | **seconds** — TSV reads plus `git rev-parse`/`hash-object` |
| `check-evidence-citations.R` | **no** | no | **milliseconds** — `read.delim` + `readLines` + `grepl` only |
| `emit-profile-truth-manifest.R --check` | **yes** | no | **expensive by accident** — pays the full TMB compile of the 182 KB `src/drmTMB.cpp` via `load_all`, then only re-evaluates fixture builders and byte-diffs a TSV |
| `check-capability-runtime.R` | yes | yes (≤6 fits) | compile (warm) + fits |
| `check-profile-fence-integrity.R` | yes | **yes — 24 routes, all `se = TRUE`** | most expensive guard |
| `check-r-package` | — | — | **the 40-minute one** |

**The recommendation.** Move the two genuinely package-free steps — the Python
ledger/unittest block and `check-evidence-citations.R` — into their own fast job
that runs in parallel with the slow one. A broken citation or a failed ledger
assertion would then report in **seconds** instead of dying 40 minutes later
alongside `R CMD check`. That is exactly the failure this stack already hit once:
PR #915 went red on a C17/C14 binding assertion that reproduces locally in 0.6 s.

**Caveat that shapes the design.** Only those two steps are free of the compiled
package. Moving `emit-profile-truth-manifest.R`, `check-capability-runtime.R`, or
the fence guard into a separate job would make that job pay a **second TMB
compile**, unless `src/*.so` is cached between jobs. The existing step ordering
already exploits this — the fence guard sits after `check-capability-runtime.R`
specifically so the shared object is warm. Split on the compile boundary, not on
the conceptual one.

**Secondary win worth noting.** `emit-profile-truth-manifest.R --check` pays a
full TMB compile to do work that fits nothing. If it could resolve its fixture
builders without `load_all`, it would move into the fast job and take several
minutes off the critical path. Worth investigating in the same arc.

## 5. What this arc did NOT do

- Did not tighten the ceiling — that waits for three completed runs.
- Did not split the workflow — recommended above, own arc.
- Did not touch `drmSEM`.
- Did not reduce test cost (`NOT_CRAN: true` means `skip_on_cran()` does not skip;
  100 occurrences across 48 test files all run). That is a lever, but cutting
  coverage to fit a timeout is the wrong trade unless the coverage is redundant.
