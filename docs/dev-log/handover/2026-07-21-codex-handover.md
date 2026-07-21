# Session Handoff: drmTMB 0.6.0 — Phase-20 CRAN RC landed; **your job is the pre-CRAN code + content review**

**From:** Claude Code (lane `drmTMB_final`, Phase-20 CRAN release-candidate gate)
**To:** **Codex** — you are picking this up in a fresh session and have never seen the authoring chat.
**Date:** 2026-07-21 · **Repo:** `drmTMB` · **`origin/main` = `78b89d3f`**

---

## Critical Context (read this first)

drmTMB **0.6.0 is merged to `main` at the TARBALL-CLEAN + local-clang-UBSAN rung.** That is a
deliberately narrow claim. It is **NOT** "CRAN-ready", NOT platform-clean, NOT submitted.

**Why the narrowness matters (the headline).** drmTMB **0.5.0 was green on 3 OS but was NEVER
accepted** — it was blocked at R-hub valgrind/rchk on a real NaN→int UBSAN cast defect plus a ~23-min
Windows check, on a **false "SUBMIT" verdict produced by a `NOT_CRAN=true` lane that excluded incoming
checks.** 0.5.0 was then ditched. **Therefore 0.6.0 is a FIRST / NEW CRAN submission**, and every
surface must say so. This whole lane exists to avoid repeating that false-green.

**What you are being handed:** the packaging is audited to death; **the code and the science are not.**
Across this entire lane the diff touched **no executable code**: `src/` 0 files, `tests/` 0 files, and
the only `R/` changes were **77 roxygen `#'` comment lines** (added `\examples` / `@seealso`). Four D-43
panel rounds and a 6-lens adversarial review all audited *release-surface honesty* — hashes, inventories,
claims, pointers. **Nobody has read `R/` or `src/` for correctness, and nobody has re-checked the
statistical claims scientifically.** That is your review.

---

## Goals / mission

- **Immediate (yours):** an independent **code + content review** of drmTMB 0.6.0 *before* any CRAN
  submission. Fresh eyes, different tool, live toolchain.
- **Then (also likely yours):** the **platform-clean** gate — win-builder (R-release + R-devel), R-hub v2
  (UBSAN / valgrind / rchk), the 3-OS GitHub matrix, and Windows vignette timing.
- **Finally (maintainer's call):** the CRAN submission itself.
- **Sequence matters:** do the review **BEFORE** the platform matrix. If the review changes shipped bytes,
  a platform matrix run on the old artifact is wasted.

---

## What Was Accomplished (this lane)

- `R CMD check --as-cran --run-donttest` on the **real** lane (`NOT_CRAN` unset, no `force_suggests`):
  **0 errors / 0 warnings / 1 NOTE** (new-submission) + installed-size INFO (27.8 Mb).
- **CRAN-lane test count `FAIL 0 | WARN 52 | SKIP 122 | PASS 12011`**, reproduced identically across all
  four builds; heavy `phase18` / `structured-re-conversion` suites correctly skip-gated on CRAN.
- **Local clang-UBSAN: 0 runtime errors** on the six `(int)asDouble()` casts (`src/drmTMB.cpp`
  1197/1301/1648/3241/3784/3856) — the exact defect class that blocked 0.5.0.
- ONE frozen, hash-identified tarball + inventory + forbidden-path scan + temp-lib install smoke.
- Reader surface repaired and made honest: known limitations published on the **shipped** surface
  (`vignettes/capability-and-limits.Rmd`), version story reconciled, clean first-submission
  `cran-comments.md`.
- Release ledger green: `python3 ~/shinichi-brain/tools/cran_release_gate.py <ledger>` = **READY FOR
  CLAIMED RUNG**.
- PRs merged: **#804** (RC) → **#805** (honesty sweep) → **#807** (post-review consolidation).
- Issue hygiene closed out: **#61** Phase-20 status posted (stays OPEN), **#59** aligned to D-50, **#710**
  records 5/6 findings fixed (only #710.2 open), **#806** filed with a 5-item doc checklist,
  `phase18-simulation-grid.yaml` converted to a disabled stub (D-50).

### The four D-43 panel rounds — what each caught (read this; it is the trust calibration)
| Round | Artifact | Verdict | What it caught |
|---|---|---|---|
| 1 | `afd4600a` | 3× NOT-READY | install-smoke log ended `SMOKE_EXIT=1` but was recorded "PASSED"; ROADMAP recommended v0.5.0; `cross-family.Rmd` over-promised the Julia xfam extractors |
| 2 | `e818e165` | 2 READY / 1 NOT-READY | Pat, correctly: the round-1 fix patched only the extractor *table cell* and left two prose passages still promising fitted values. **The rung was NOT taken on the 2-1 vote.** |
| 3 | `9ca4d07c` | 3× READY — **but invalid** | Only Pat was a *fresh* agent; Grace/Rose were orchestrator-verified deltas. Its Rose verdict contained a **false claim** about an evidence pointer. |
| **4** | **`323d820f`** | **3× READY, 0 blockers** | Three genuinely fresh agents. Grace additionally root-caused a stray UBSAN log marker (see Gotchas). |

A separate **6-lens adversarial review** of merged `main` then found four more defects — including that
the *declared candidate had gone stale* — all fixed in #807. **Every defect in this lane was found by a
reviewer outside the authoring context, none by the author.** Weigh that when deciding how hard to look.

---

## Current Working State

**Working / landed:** everything above is on `origin/main` @ `78b89d3f`. **0 open PRs.**

**The current frozen candidate artifact:**
```
~/worktrees/drmTMB-rc-frozen/323d820f0a0ca444/
  drmTMB_0.6.0.tar.gz
    sha256 323d820f0a0ca444659b3ec3c20bf162ff22e80916b47b05494fa0fd817e0fcb
    size   6981105 bytes        built from c3b9ad49 (tree ≡ main for all tarball-relevant files)
  tarball-inventory.txt (825 entries, forbidden scan clean)
  local-as-cran-check.log · cran-lane-testthat.Rout · laneproof-invert-devmode.log
  install-smoke.log (+ install-smoke-tarball.R) · local-ubsan.log · FREEZE-NOTES.md
```
Superseded rounds `afd4600a86830451/`, `e818e1651dc188f9/`, `9ca4d07ca403b6c2/` each carry a
`SUPERSEDED.txt`. **Use only `323d820f0a0ca444`.**

> ⚠ **`R CMD build` is NOT bit-reproducible** — built vignettes carry timestamps, so every rebuild yields
> a new sha256. Do not treat a hash change after a rebuild as a defect; but any artifact you *declare*
> must carry **its own** check/smoke logs, not inherited ones. (Round 3 got this wrong; see Gotchas.)

**Blocked / not started:** the remote platform matrix and the CRAN submission. Both are deliberate
next gates, not oversights.

---

## Key Decisions & Rationale

- **Rung discipline (D-49):** default NOT READY; always report the *exact* rung. Never say "ready".
- **The manifest is the TRUTH CEILING:** `docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`.
  Nothing may claim beyond it. **Any capability/claim change is Shinichi's decision, not a reviewer's.**
- **Honesty over vote math:** in round 2 a single correct dissent withheld the rung even though the
  2-of-3 threshold was not met. Keep that bar.
- **Zero-one-beta (`mc-0575`) is CLOSED:** it ships as a **fenced, generator-qualified**
  `inference_ready_with_caveats` claim (2-1 promotion, Noether withheld). A strictly-interior rerun was
  specified, reviewed, and **decided against** — no faithful strictly-interior sampler exists for the
  intended DGP (manifest §2a). **Do not reopen it, and do not run compute on it.**
- **#710.5 is FIXED** (PR #722, `ace97fc0`) and is a git-verified ancestor of every certified profile-CI
  cell. The only open #710 item is **#710.2** (sigma-slope start; reverted once for a Windows-BLAS
  spatial-q4 regression).
- **D-50:** simulation/coverage/power campaigns run on **Totoro/DRAC**, outputs stay **local**; GitHub
  Actions is **checks + docs only** and campaign outputs are never Actions artifacts (hard ~2 GB/month cap).

---

## Landing State (git ledger)

`~/shinichi-brain/tools/handoff_gate.sh` was run before writing this doc.

| Item | State |
|---|---|
| All lane work (#804, #805, #807) | ✅ **LANDED** on `origin/main` @ `78b89d3f`; 0 open PRs |
| `scratchpad/xfam-extractor-issue-draft.md` | ✅ **LANDED in this handover commit** (gate flagged it untracked; `.gitignore` only excludes scratchpad `*.log`/`*.rds`, and it is `.Rbuildignore`'d so it never ships). Its content is filed as **#806**. |
| This handover doc + `AGENTS.md` pointer | ✅ committed on `handover/2026-07-21-codex`, **pushed**, PR opened — **NOT merged** (maintainer merges) |
| Frozen artifacts | Live **outside** the repo at `~/worktrees/drmTMB-rc-frozen/` — *local only, not on origin.* If you work on a different machine you must rebuild; the identity above lets you verify. |

---

## Files Created / Modified (this lane, `919a0b3a...78b89d3f`)

**Docs / release state:** `AGENTS.md` · `README.md` · `ROADMAP.md` · `NEWS.md` · `DESCRIPTION` ·
`_pkgdown.yml` · `cran-comments.md` · `CRAN-SUBMISSION` (deleted — stale 0.5.0 marker) ·
`docs/cran-readiness-checklist.md`
**Vignettes:** `capability-and-limits.Rmd` · `cross-family.Rmd` · `distributional-outputs-and-adequacy.Rmd` · `drmTMB.Rmd`
**Roxygen only (77 `#'` lines, no executable code):** `R/methods.R` · `R/missing-data.R` · `R/penalty.R` · `R/profile.R`
**Generated Rd:** `man/confint.drmTMB.Rd` · `man/summary.drmTMB.Rd` · `man/imputed.Rd` ·
`man/drm_phylo_penalty.Rd` · `man/drm_phylo_penalty_sweep.Rd`
**Evidence:** `docs/dev-log/release-audits/2026-07-20-0.6.0-cran-rc-ledger.json` ·
`…-0.6.0-release-scope-manifest.md` · `…-cran-policy-consult.md` ·
`docs/dev-log/after-task/2026-07-20-cran-rc-s8-s9-refreeze.md` ·
`docs/dev-log/plan-actual/2026-07-20-0.6.0-cran-rc.md` ·
`docs/dev-log/figure-audits/2026-07-20-0.6.0-rc/rc-inspection-report.md` ·
`docs/dev-log/handover/2026-07-20-cran-rc-s3-to-g3-handover.md`
**CI:** `.github/workflows/phase18-simulation-grid.yaml` (→ disabled stub)
**This handover:** `docs/dev-log/handover/2026-07-21-codex-handover.md` + the `AGENTS.md` snapshot bullet
+ `scratchpad/xfam-extractor-issue-draft.md` (landed).

---

## Next Immediate Steps — YOUR REVIEW (scope + fences)

### The fence (important — this lane re-froze the tarball 4× chasing doc fixes)
> **A finding is a BLOCKER only if it is (a) a correctness defect in code, or (b) a false claim on a
> shipped surface. Everything else is a LOGGED FOLLOW-UP ISSUE — do not fix it inline.**
> Any change to a *capability claim* reopens the frozen manifest = **Shinichi's decision, STOP and ask.**
> **Do NOT re-verify the tarball-clean rung** — it has had 4 panel rounds + a 6-lens review + 3 fresh
> agents. Reproduce it only if you suspect it.

### 1. CODE review (never done in this lane — highest value)
- **`src/drmTMB.cpp`** — the TMB likelihood/template code. Only ever *probed* by a local UBSAN run,
  never *read*. Start with the six `(int)asDouble()` casts (1197/1301/1648/3241/3784/3856) and the
  `:1648` bad-alloc path. UBSAN was clean, but clean-under-one-workload ≠ correct.
- **`coef.drmTMB()`** (`R/methods.R:2260`) returns a **named list keyed by dpar** when `dpar = NULL`, not
  a flat numeric vector. This broke a smoke test in round 1 (`round(coef(fit)[1], 3)` → error). Is that
  the API you want for a CRAN package where `lm`/`glm` users expect a vector? It is also **undocumented**
  (no Rd for `coef.drmTMB`).
- **Julia bridge** (`R/julia-bridge.R` ~4150-4235) — `new_drmTMB_julia_xfam()` never sets `$vcov` /
  `$fitted` / `$residuals` / `$coef_vector` / `$aic` / `$bic` / `$df`, so five extractors silently return
  `NULL`. Root cause + checklist in **#806**.
- Compiler warnings: ~10 unused-variable `sigma_i` dead stores in `drmTMB.cpp` plus RcppEigen header
  warnings. Pre-existing, not check-forced — but noisy output can draw CRAN attention.

### 2. CONTENT / science review (never done)
- Do the manifest's inference claims actually hold? Specifically the **coverage numbers and certified
  floors** in §1b (skew-normal / Tweedie / zero-one-beta M≥16; binomial M≥32; cumulative-logit M≥80 via
  AGHQ-25 + Cox-Reid), and the negative space ("no Wald, no point-bias claim").
- Is the **zero-one-beta generator-qualified fence** (manifest §2a) scientifically the right terminal
  characterization? It was adjudicated as such — you may confirm or challenge, but changing it is
  Shinichi's call.
- Is `capability-and-limits.Rmd` a fair description of what the package actually does?

### 3. THEN the platform-clean gate (after the review, on the final artifact)
win-builder (R-release + R-devel) · R-hub v2 (UBSAN / valgrind / rchk — the 0.5.0 blocker) · 3-OS GitHub
matrix · **Windows vignette timing** (heavy: `phylogenetic-spatial` 21 fits, `missing-data` 21,
`location-scale` 22, `which-scale` 14). Treat proximity to the ~10-min incoming limit as a blocker even
at NOTE. `rhub.yaml` is `workflow_dispatch`-only — dispatch it deliberately.

---

## Blockers / Open Questions

- **Nothing blocks the tarball-clean rung.** It is met and merged.
- **#61 stays OPEN** — its DoD includes platform-clean, CRAN submission, and paper-prep/comparator (#60).
- **#710.2** (sigma-slope start) is the one accepted open numerical item.
- **#806** — Julia xfam extractors + 4 doc sub-items.
- **Frozen artifacts are local-only.** They are not on origin. On a different machine, rebuild.

---

## Gotchas & Failed Approaches (learn from these — they cost this lane real time)

1. **The `NOT_CRAN` trap.** `NOT_CRAN=true` appears **644×** in this repo's logs. It is the mechanism
   behind the 0.5.0 false-green. Run any claim-bearing check with **`NOT_CRAN` unset** (`env -u NOT_CRAN`).
2. **`devtools::test()` forces `NOT_CRAN=true`.** So its count (`PASS 13476`) legitimately **exceeds** the
   CRAN lane (`PASS 12011`) because `skip_on_cran()` tests run. These two numbers are **not** meant to
   match. An earlier handover implied they did — that was wrong.
3. **Fix ALL instances of a defect class, not the first one.** The "v0.5.0 treated as a real milestone"
   defect recurred **four times** (ROADMAP ×2, `NEWS.md`, `cross-family.Rmd`) across three separate
   "exhaustive" sweeps. Each sweep fixed what it found and declared completeness. Grep the whole surface.
4. **If `main` moves past your frozen artifact, RE-FREEZE.** Round 3 merged shipped-file fixes without
   re-freezing, leaving the declared candidate carrying defects `main` had already fixed.
5. **A "3× READY" panel that isn't 3 *fresh* agents is not a D-43 panel.** Round 3's shortcut is exactly
   how a false claim survived into the ledger.
6. **The stray `E` in `local-ubsan.log` is explained, not a defect.** It is
   `test-beta-binomial.R:218:3 — could not find function "beta_binomial_proportion_variance"`: that
   function exists (`R/methods.R:5013`) but is **not exported**, and the ad-hoc UBSAN probe used
   `library(drmTMB)` + `test_dir(load_package="none")`, which does not expose internals the way
   `devtools::test()` does. Zero errors under `load_all()`; the test passes `FAIL 0` in both real lanes.
   No sanitizer runtime-error text appears anywhere in the log.
7. **Read the LOG, not the exit code.** And prove the loaded namespace matches the checkout before calling
   any failure a package bug.

---

## How to Resume (Codex recipe)

`AGENTS.md` is native to you — read it first (its "▶ Latest — start here" bullet now points at this doc).
Then read this doc, then the doc set below. Team mirror lives in `.codex/agents/*.toml`; **the Rose audit
is mandatory before any public claim.**

**Live-toolchain env (you run the real thing; Claude could not):**
```bash
cd <repo root>                 # the drmTMB checkout
env -u NOT_CRAN R CMD build .  # NEVER set NOT_CRAN for a claim-bearing run
env -u NOT_CRAN R CMD check --as-cran --run-donttest drmTMB_0.6.0.tar.gz
# release gate (brain path, not repo):
python3 ~/shinichi-brain/tools/cran_release_gate.py \
  docs/dev-log/release-audits/2026-07-20-0.6.0-cran-rc-ledger.json
# repo-local validators:
python3 tools/capability_ledger.py --check ; Rscript tools/check-capability-runtime.R
```

**Doc set to read:** this doc → `docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`
(truth ceiling) → `…-0.6.0-cran-rc-ledger.json` (evidence + all 4 panel rounds) →
`docs/dev-log/after-task/2026-07-20-cran-rc-s8-s9-refreeze.md` → `vignettes/capability-and-limits.Rmd`
(the shipped honesty surface). Capability + deferred-work index (outside the repo):
`~/shinichi-brain/docs/release/drmTMB-0.6.0-future-work-register.md`.

### One-command resume (paste into Codex at the repo root)
```
Rehydrate from docs/dev-log/handover/2026-07-21-codex-handover.md + the AGENTS.md snapshot, then
continue with the Next Immediate Steps: the pre-CRAN CODE + CONTENT review (src/drmTMB.cpp, the
coef.drmTMB list-return API, the Julia bridge behind #806, and whether the manifest's coverage claims
hold). Respect the fence: a finding is a blocker only if it is a correctness defect or a false claim on
a shipped surface; everything else is a logged follow-up. Do NOT re-verify the tarball-clean rung. Any
capability/claim change is Shinichi's decision — stop and ask.
```

---

## Mission control

| Repo | Branch / main | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| **drmTMB** | `main` @ `78b89d3f`; 0 open PRs | R-CMD-check green on #804/#805/#807; `phase18` + `rhub` are `workflow_dispatch`-only and did not fire | **0.6.0 at the tarball-clean + local-UBSAN rung.** `--as-cran` 0/0/1 + size INFO; CRAN-lane `PASS 12011`; UBSAN 0 errors; frozen `323d820f`; ledger gate READY FOR CLAIMED RUNG; D-43 round-4 3× READY | **1.** Code + content review (this handover) · **2.** Platform-clean (win-builder / R-hub UBSAN·valgrind·rchk / 3-OS) · **3.** CRAN submission (maintainer) · **4.** #806, #710.2, #802, #60 |

---

## Claude ↔ Codex routing

**Yours (Codex, live toolchain):** real fits, `R CMD check`, the UBSAN/valgrind probes, vignette
rendering and timing, the remote platform matrix, and any code fix the review forces.
**Claude's (if it picks up after you):** planning, refactor design, prose/doc rewriting, and pure-logic
checks — it may not have a live compiler in every environment.

**Do not run Claude and Codex on drmTMB concurrently** — one lane per repo, sequential.
