# Session handoff — drmTMB 0.7.0 readiness: D-117 discharged, platform evidence gathered, `main` CI RED

Meta: 2026-08-10 · from Claude to a fresh Claude session · **fresh lane recommended** (the authoring
session ran the whole D-117 arc plus the 0.7.0 readiness arc)

You are Claude, picking up drmTMB. **The committed repository is authoritative; the authoring chat is
gone.** Read `AGENTS.md`, this document, then
[`../release/0.7.0-cran-gate/BLOCKER-main-ci-red-julia.md`](../release/0.7.0-cran-gate/BLOCKER-main-ci-red-julia.md).
Classify every item below as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED` against current git and
GitHub state before acting.

## Goals / mission

Produce drmTMB's **first CRAN release as 0.7.0** (D-86) without broadening its scientific claims,
under the fail-closed rung ladder (D-49): never say "CRAN ready" — always report the **highest proven
rung and the next unproven one**. **D-89 governs the pace: submission is far away by choice.** The
CRAN portal is offline until ~2026-08-19.

## Critical context

**Highest proven rung: `tarball-clean`. Next unproven: `platform-clean`.** `DESCRIPTION` is **0.6.0**
on `main`; the 0.7.0 bump lives only inside PR #959.

**🔴 `main` fails `R CMD check`** and has since `fddb82105` (PR #972, missing-data) — **before** this
session's merges. The Julia package `Suppressor` is missing in CI. The live Workflow-G test calls
itself *"skip-safe"* but guards with `skip_if_not_installed("JuliaCall")`, and **JuliaCall the R
package IS installed** in CI (Suggests are installed by `setup-r-dependencies`), so the skip never
fires; execution reaches Julia initialisation and dies. The workflow has **no Julia setup step at
all**. This blocks `main` and every PR against it — **it is the critical path.**

## What was accomplished

**D-117 DISCHARGED** (owner decision, 2026-08-09), recorded in `~/shinichi-brain/memory/DECISIONS.md`.
The 10-group profile coverage gate was re-run at **100,000 replicates/cell (400,000 attempts)**:
pooled coverage **0.924800** (SE 0.000417), every cell clearing `ss_floor(10) = 0.918` on **raw**
coverage and on the stricter one-sided LCB. My **pre-registered prediction was WRONG** and is recorded
as falsified. Recovery was measured (−15.76/−9.31/−10.26/−8.34%) but was never made scoreable — no
bias criterion was ever pre-registered; the honest reading is **under-specification, not failure**.
All four of the owner's discharge conditions are **verified live on `main`**.

**Platform evidence gathered** (owner authorised the matrix). 3-OS `R CMD check` **success** on
ubuntu/macOS/windows, and **all three memory sanitizers pass** — clang-asan, clang-ubsan, gcc-asan —
at `bce9cfb6f`, whose `src` tree (`a4a3138d`) is **identical to the candidate's**. No such coverage
existed for this candidate at any level before.

**Hash ledger**: 11 hashes, **0 unresolved**, ending an eight-plus-tarball confusion.

**D-135 recorded**: binomial **probit/cloglog is 0.7.0**, overriding a 0.7.1 scoping.

## Current working state

| item | state |
| --- | --- |
| `main` @ `64149c465` | **RED** — Julia blocker (see above) |
| PR **#976** `claude/07-hash-ledger` | OPEN, MERGEABLE, **CI fails on the blocker only** |
| PR **#978** `claude/07-cran-notes` | OPEN, MERGEABLE, **CI fails on the blocker only**; its own local `--as-cran` is `Status: 1 NOTE` |
| PRs #974, #975 | **MERGED** to main |
| R-hub run `31350780323` | valgrind **failure** (container never installed the package — no coverage, not a defect); rchk **failure** (all findings inside TMB's own headers) |

## Key decisions & rationale

- **Discharge rests on under-specification, not on a failed bar.** An earlier draft imported the
  Beta-phylogenetic **0.10** log-scale gate as if binding; a verifier ruled that an **unfair
  transplant** (`g = 256` vs `g = 10`, different family, and a bar `lme4` would fail identically).
  Do not reintroduce it as a criterion.
- **Content-equivalence, not literal hash.** The 3-OS/R-hub runs cover the candidate's *source*, not
  its tarball bytes. `R CMD build` embeds timestamps; no rebuild reproduces them. Stated, never
  claimed as Gate 6 hash compliance.
- **No rung claim was written.** Advancing `status_claim` to `platform-clean` is the owner's (D-49).
- **Nothing merged past red CI**, even though both PRs are docs-only and the failure is unrelated.

## Files created / modified

*On `claude/07-hash-ledger` (PR #976):* `docs/dev-log/release/0.7.0-cran-gate/HASH-LEDGER.md` ·
`PLATFORM-AUTHORISATION-PACKET.md` · `BLOCKER-main-ci-red-julia.md` ·
`platform/2026-08-09-platform-evidence-at-bce9cfb6f.md` ·
`docs/dev-log/handover/2026-08-09-overnight-07-readiness.md` · this file.

*On `claude/07-cran-notes` (PR #978):* `DESCRIPTION` · `inst/WORDLIST` ·
`vignettes/function-map-cheatsheet.Rmd` · `docs/dev-log/release/0.7.0-cran-gate/CRAN-NOTE-FIXES-EVIDENCE.md`.

*Already on `main`:* `R/profile.R` (roxygen) · `man/confint.drmTMB.Rd` · `NEWS.md` ·
`vignettes/first-week-intervals.Rmd` · `tests/testthat/test-d117-boundary-warning.R` ·
`docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/**` ·
`docs/dev-log/after-task/2026-08-09-d117-discharge-100k-regate.md` ·
`docs/dev-log/release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md` · `docs/dev-log/internal-roadmap.md`.

*Brain (local-only, D-37):* `DECISIONS.md` (D-117 discharge, D-135) · `LESSONS.md` (4 entries) ·
`WHAT-WORKS.md` · `memory/The most dangerous error is the one made while fixing an error.md`.

## Next immediate steps

1. **Fix the Julia CI blocker.** Critical path — nothing else can go green. Two options, both written
   up in `BLOCKER-main-ci-red-julia.md`: **(a)** `tryCatch()` around Julia init + `skip()` on failure —
   small, restores green, keeps CI Julia-free, matches the workflow's current design (recommended);
   **(b)** add `julia-actions/setup-julia` + `Pkg.add("Suppressor")` + DRM.jl — makes the gate genuinely
   live. **The choice is the Julia lane's or Shinichi's — do not pick unilaterally.**
2. **Then merge #976 and #978** — both go green once (1) lands.
3. **win-builder** — **owner action**; the agent upload is classifier-blocked. Still the only evidence
   class with **no run at any level** for this candidate.
4. **MSPL needs a PR** — `claude/mspl-binomial-inference-promotion`, **14 commits, no PR**.
5. **#973** (probit/cloglog) is now MERGEABLE and is 0.7.0 work per D-135.

## Blockers / open questions

- **Julia CI** (above) — blocks everything.
- **The candidate carries a latent URL NOTE.** `cc4f5baee`'s vignette links to
  `github.com/itchyshin/drmTMB/blob/main/vignettes/articles/function-map-cheatsheet.png`, which
  **404s** (both blob and raw) because `vignettes/articles/` exists only on the unmerged slice.
- **PR #959's body** still calls the invalidated first candidate `d35c0b9e` "the first exact 0.7.0
  candidate that has ever existed" — three candidates out of date. Outward-facing; owner's call.
- **valgrind coverage does not exist** for this candidate (install failure, not a defect).
- **Stale `.git/index.lock`** in the primary checkout — the harness blocks `.git` deletions.
  **Needs a human `rm`.**

## Gotchas / failed approaches

- **`inst/WORDLIST` is never read by CRAN-incoming spell checking** (zero hits for `"WORDLIST"` across
  the `tools`/`utils` namespaces). It *is* read by the package's own `tests/spelling.R`. Fixing the
  real typo is what cleared the NOTE.
- **`.install_extras` trades one NOTE for another** — installing the PNG into `inst/doc` raises
  `checking installed files from 'inst/doc'`. Reverted; the fix is an external URL, **verified 200
  before use** because CRAN checks URLs.
- **GitHub Actions is FREE here** — the repo is public and `/actions/runs/{id}/timing` returns
  `billable.total_ms = 0`. An earlier "~481–750 billed minutes" figure in this arc was **false**;
  the real axis is wall-clock.
- **A cross-platform file-tree hash must sort the HASHES, not the filenames** — locale collation
  manufactured a false provenance MISMATCH.
- **`conclusion: cancelled` on CI is usually a concurrency cancel** from your own next push.
- Never `git add -A`. Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file`.

## Landing state

| Artifact | Committed | Pushed | State |
| --- | --- | --- | --- |
| `claude/07-hash-ledger` → PR #976 | yes | yes | **ACTIVE** — CI red on the blocker only |
| `claude/07-cran-notes` → PR #978 | yes | yes | **ACTIVE** — same |
| `claude/d117-discharge` / `claude/d117-user-facing-numbers` | yes | yes | **MERGED** (#974/#975) |
| Brain vault | yes | n/a | **LANDED** — local-only by D-37, no remote by design |
| Candidate `a8f7c479` bytes | n/a | n/a | preserved at `~/local-scratch/drmTMB-0.7.0-candidates/`, SHA re-verified |
| **12 foreign branches with unpushed commits** (`codex/lane-b-q1-preflight-admission` **226**, `codex/lane-c-provider-cohort-20260729` **99**, `hopper/bridge-finish-phase15-5`, …) | mixed | **no** | **CARRIED-OVER · PROTECTED FOREIGN.** Pre-existing, not this session's. Do **not** push, clean, or reconcile. Resume: whoever owns each lane |
| `claude/mspl-binomial-inference-promotion` | yes | yes | **CARRIED-OVER** — 14 commits, **no PR** |
| PRs #959, #958, #957, #955, #937, #858, #973 | — | — | **PROTECTED FOREIGN** — untouched |
| Stale `.git/index.lock` | — | — | **REPORT ONLY** — needs a human `rm` |

`tools/handoff_gate.sh` returns **GATE FAIL**, entirely from the pre-existing foreign branches and the
lock above. Declared here per the protocol's "DECLARE it" branch. **This session's own lanes are clean
and fully pushed.**

## Live environment

Worktrees: `/private/tmp/drmTMB-07-ledger` (PR #976) · `/private/tmp/drmTMB-07-notes` (PR #978) ·
`/private/tmp/drmTMB-d117`. **Never work in the primary checkout** — it is on a stale July branch and
is PROTECTED.

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e '...'   # the .Rprofile R-4.5 lib segfaults R 4.6
```

Safe verification (changes nothing):

```sh
cd /private/tmp/drmTMB-07-notes && R CMD build --no-manual . && R CMD check --as-cran --no-manual drmTMB_0.6.0.tar.gz
```

Totoro reachable via its existing ControlMaster (`ls ~/.ssh/cm-*totoro*`); no Duo needed.
**Do not stage:** anything under `scratchpad/` you did not create, or any foreign branch's work.

## How to resume

```sh
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/drmTMB"
cd /private/tmp/drmTMB-07-ledger && git status --short --branch
gh pr checks 976; gh run list --branch main --limit 3
```

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-10-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
