# Overnight session — D-117 discharged, 0.7.0 readiness advanced, NOT released

Meta: 2026-08-09 · Claude, autonomous run · **nothing was released.** No tag, no GitHub release, no
CRAN upload, no `DESCRIPTION` bump, PR #959 untouched.

**Read this first, then `../release/0.7.0-cran-gate/PLATFORM-AUTHORISATION-PACKET.md`.**

## What you decided tonight, and where it is recorded

| decision | recorded |
| --- | --- |
| **D-117 DISCHARGED** as recommended, four conditions attached | `~/shinichi-brain/memory/DECISIONS.md` D-117, commit `d6bf6cc` |
| **Platform matrix AUTHORISED** | acted on — see "what ran" below |
| **D-135: probit/cloglog is 0.7.0**, overriding the 0.7.1 scoping | `DECISIONS.md` D-135 |
| Brain writes approved | D-117 entry, D-135, a new atomic note, one `LESSONS` line |

## The correction that matters most

**I was wrong about money, repeatedly, and it drove my recommendation.**

I told you a platform matrix would cost **~481–750 billed GitHub Actions minutes**. It costs **zero**.
`gh repo view` → **PUBLIC**; every runner is standard; `/actions/runs/{id}/timing` returns
`billable.{UBUNTU,WINDOWS,MACOS}.total_ms = 0` on every run checked, **including the exact run my cost
table was built from**. The real axis is wall-clock (~59 min for a 3-OS run), not dollars.

Two more of my claims were false, all leaning the same way — toward the cautious answer I already
preferred:

- **"PR #959 never had CI"** — false. `pull_request` run `31333822332` passed, and the `src` tree is
  byte-identical across `cc4f5baee`→`bce9cfb6f`, compiled and checked on six platform/version
  combinations. The true, narrow claim is only: *no CI ran at the exact candidate head.*
- **"The genuine gap is win-builder"** (singular) — understated. The candidate-era R-hub run tested
  linux/windows/macos R-devel only: **no asan, ubsan, gcc-asan, valgrind or rchk**, for a tree whose
  `src/drmTMB.cpp` genuinely changed.

All three were found by adversarial review, not by me. **The recommendation flipped** from "hold,
win-builder only" to **Option (b) now, with (c) immediately after** — and I have already dispatched
both, since they are free and you authorised them.

## What ran, and what it covers

| run | what | at | status when I left |
| --- | --- | --- | --- |
| `31350779116` | 3-OS `R-CMD-check` (ubuntu/macOS/windows) | `bce9cfb6f` | in progress |
| `31350780323` | R-hub **clang-asan, clang-ubsan, gcc-asan, valgrind, rchk** | `bce9cfb6f` | in progress |

**Gate 6 note:** both ran at `bce9cfb6f`, not at the candidate source `cc4f5baee`. The `src` tree is
**identical** (`a4a3138d`) across both, so this genuinely covers the candidate's compiled code — but
it is content-equivalence, not a literal hash match, and the packet says so.

## What is on `main` now

`main` = `64149c465`. Merged tonight: **#974** (D-117 evidence + recommendation) and **#975**
(corrected user-facing figures). The D-117 verdict is permanently on `main`.

## Open PRs of mine

- **#976** `claude/07-hash-ledger` — the hash ledger (11 hashes, 0 unresolved) + the corrected
  authorisation packet. **Ready to merge.**
- **#978** `claude/07-cran-notes` — CRAN NOTE fixes. **Local check: `Status: 1 NOTE`, "New submission"
  only.**

## ⚠ Three things you should know before any submission

1. **The candidate carries a latent URL NOTE.** `cc4f5baee`'s vignette links to
   `github.com/itchyshin/drmTMB/blob/main/vignettes/articles/function-map-cheatsheet.png`, which
   **404s on both blob and raw** — `vignettes/articles/` does not exist on `main`, only on the
   unmerged slice. CRAN checks URLs. It resolves only *after* the slice merges. #978 uses a pkgdown
   URL verified 200, with no such dependency.
2. **`inst/WORDLIST` does nothing for CRAN-incoming spelling.** Zero hits for `"WORDLIST"` across the
   `tools` and `utils` namespaces; only `.aspell/defaults.R` overrides dictionaries. Do not rely on
   it — what actually cleared the NOTE was fixing a genuine typo (`mis-specification` was splitting
   into the flagged fragment `mis`).
3. **A repair I made was itself wrong, and only the check caught it.** `.install_extras` cleared the
   file-URI NOTE by installing the PNG and immediately raised a different NOTE; status stayed at 2.
   Reverted. This is the arc's recurring lesson, now filed as
   `~/shinichi-brain/memory/The most dangerous error is the one made while fixing an error.md`.

## 🔴 THE ONE THING THAT IS NOT READY — `main` CI is RED

Full diagnosis: `../release/0.7.0-cran-gate/BLOCKER-main-ci-red-julia.md`.

`main` fails `R CMD check` and **has since `fddb82105` (PR #972, missing-data) — before either of
tonight's D-117 merges.** Cause: the **Julia** package `Suppressor` is missing from the CI runner's
depot, so `JuliaCall`'s `setup.jl` throws during "checking tests".

The live Workflow-G test says it is *"skip-safe"*, but it guards with
`skip_if_not_installed("JuliaCall")` — and **JuliaCall the R package IS installed** in CI, so the skip
never fires. The guard tests the R binding's presence, not whether the Julia runtime works. The
workflow has **no Julia setup step at all**.

**Two fixes, and the choice is the Julia lane's or yours:** (1) `tryCatch()` around Julia
initialisation and `skip()` on failure — small, restores green immediately, keeps CI Julia-free; or
(2) add `julia-actions/setup-julia` + `Pkg.add("Suppressor")` — makes the gate genuinely live, at the
cost of Julia on every routine run. I did **not** pick for you; it is another lane's test.

**Two things this does not block:** the release slice is unaffected — the 3-OS matrix at `bce9cfb6f`
passed on all three platforms, because that branch predates the live-Julia test. And **PR #978 failed
for this reason alone** — its own local `--as-cran` returns `Status: 1 NOTE`.

## YOUR ACTIONS

1. **`rm -f "/Users/z3437171/Dropbox/Github Local/drmTMB/.git/index.lock"`** — the harness blocks me
   from `.git` deletions.
2. **win-builder submission — blocked for me, needs you.** The FTP upload was denied by the safety
   classifier. The candidate bytes are preserved and hash-verified:
   ```sh
   TB=~/local-scratch/drmTMB-0.7.0-candidates/drmTMB_0.7.0-a8f7c47905b0.tar.gz
   curl -T "$TB" ftp://win-builder.r-project.org/R-release/drmTMB_0.7.0.tar.gz
   curl -T "$TB" ftp://win-builder.r-project.org/R-devel/drmTMB_0.7.0.tar.gz
   ```
   This is the one evidence class with **no run at any level** for this candidate.
3. **Read the platform run results** (links above) and decide whether to advance the rung. **I wrote
   no `platform-clean` claim** — that is yours.

## Foreign lanes — reported, not touched

- **MSPL / penalized likelihood** (`claude/mspl-binomial-inference-promotion`): **14 commits, no PR
  at all.** Substantial work — the estimator, an external oracle for q2 SEs, an equivariance test,
  Fisher/Noether findings applied. It is the least-protected piece of 0.7 work. **It needs a PR.**
- **PR #973** probit/cloglog — now **0.7.0** per D-135, but **CONFLICTING**; needs a rebase.
- **PR #959** — body still calls the invalidated first candidate "the first exact 0.7.0 candidate
  that has ever existed", three candidates out of date. One-line fix, outward-facing, so I left it.
- **Missing data** — already merged to `main`. Nothing owed.

## Rung status

**Highest proven: `tarball-clean`** (for candidate A, on the unmerged slice).
**Next unproven: `platform-clean`** — evidence now being gathered; win-builder still missing.
`DESCRIPTION` remains **0.6.0**. D-89 governs the pace; the CRAN portal is offline until ~2026-08-19.

Working checkpoint with the full queue:
`~/local-scratch/drmTMB-arc-plans/2026-08-09-AUTONOMOUS-07-readiness-checkpoint.md`
