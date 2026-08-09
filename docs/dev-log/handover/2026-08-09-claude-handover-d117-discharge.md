# Session handoff — drmTMB: 0.7.0 candidate frozen; next arc is the D-117 discharge question

Meta: 2026-08-09 · from Claude to Claude · **fresh lane required** (the authoring session ran the
whole candidate cycle)

You are Claude, picking up drmTMB. **The committed repository is authoritative; the authoring chat
is gone.** Read this, reconcile against git, then **plan the next arc in your lane** — it is scoped
below but deliberately not decomposed here, at Shinichi's instruction.

## Where 0.7.0 stands

**A clean candidate exists.** `drmTMB_0.7.0.tar.gz`, SHA-256 `a8f7c47905b03a95c30c413d2ae351c589a3884a0bbf2e1d9a31ce4bc9ffcad5`,
4,190,882 bytes, 904 entries, built at `cc4f5baee`.
`R CMD check --as-cran --run-donttest` → **Status: 1 NOTE** (`New submission` only), 0 errors,
0 warnings. Gate: selftest 14/14 fail closed, then **READY FOR CLAIMED RUNG** at `tarball-clean`.

**Highest rung PROVEN: `tarball-clean`. Next unproven: `platform-clean`.**

Full packet: [`../release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md`](../release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md).
Decision packet: [`../release-audits/2026-08-09-07-decision-packet.md`](../release-audits/2026-08-09-07-decision-packet.md).

**The 11.11 MB documentation blocker is resolved** — `inst/doc` **11.105 → 4.605 MB** — by moving
the five heaviest vignettes to `vignettes/articles/` (pkgdown-only). This is the **fourth**
candidate; three were deliberately invalidated under D-49, the last after it had already passed the
identical check.

## The one thing that actually blocks publication

**Not packaging. D-117.** It holds 0.7.0 until a 10-group random-effect-SD coverage gate passes on
the *profile* interval. The gate ran 2026-08-04 (Totoro), but a D-43 panel returned **2 of 3
NOT-DONE** and the PASS is **withheld**. D-89 separately records that submission is far away by
choice, and the CRAN portal was noted offline until ~2026-08-19.

**D-117's one documentary open item was closed on 2026-08-09** — `confint()` now warns and the
boundary regime is documented in `NEWS.md`, `man/confint.drmTMB.Rd`, and the vignettes
(`first-week-intervals`, `model-workflow`). All three surfaces it named are done. What remains is
statistical.

### What the evidence shows — verified this session, from the artifacts

Source: `docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/`
(`VERDICT.md`, `D43-PANEL.md`, `COMPARATOR.md`, `PREREGISTRATION.md`, runners, `results/`).

**1. The worst cell passes only on the MCSE margin.** The pre-registered rule is
`coverage + 2×MCSE ≥ ss_floor(10) = 0.918`.

| cell | n_per | sd | raw coverage | MCSE (n=1000) | score | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `g10_n04_sd05` | 4 | 0.5 | **0.9140** | 0.00887 | 0.9317 | PASS |
| `g10_n04_sd10` | 4 | 1.0 | 0.9290 | — | — | PASS |
| `g10_n10_sd10` | 10 | 1.0 | 0.9310 | — | — | PASS |
| `g10_n10_sd05` | 10 | 0.5 | 0.9370 | — | — | PASS |

Raw 0.9140 is **below** the 0.918 floor; only `+2×MCSE` lifts it over. `VERDICT.md §2.4` calls this
rule anti-conservative in its own words.

**2. The untested consequence.** MCSE shrinks as `1/√n`. At **100,000** replicates the same
coverage scores `0.9140 + 0.0018 = 0.9158` and **fails** the floor. So the recorded PASS may be an
artifact of running only 1,000 replicates.

**3. It is cheap to find out.** 4 cells × 1,000 replicates = 4,000 fits in **~21 seconds** on
Totoro at 90 cores (`results/campaign.log`). A 100× re-run is minutes. **Nobody has paid this
trivial price.**

**4. One NOT-DONE was a dispatch error, not a finding.** `D43-PANEL.md:61-66` records Noether was
dispatched with only Read/Grep/Glob — no Bash, no git — so it could not reach the branch. The panel
calls this "an orchestrator dispatch error, not a finding." That verdict has never been properly
taken.

**5. One open finding may already be fixed.** Panel finding #6 ("no user-facing warning for
`profile.boundary = TRUE`") is carried open, but `warn_profile_boundary()` at `R/profile.R:1888`
already fires `drmTMB_profile_boundary_warning` and cites this very evidence directory.
`VERDICT.md:167`'s "There is no analogous warning" looks **stale — verify before claiming.**

**6. Genuinely open:** findings #1 (gate the boundary sub-population rather than pooling),
#2 (a large significant point-estimate bias went unreported), #3 (a "not materially worse" claim
contradicted at z≈2.5), #4 (D-97 provenance vs this arc's premise).

**7. The conditioning is real, and is not a drmTMB defect.** Conditional on `profile.boundary`,
coverage is 0.8566 (49.5% incidence), 0.0732 (4.1%), 0.2540 (6.3%). `lme4` agrees on boundary
incidence **4000/4000** and coverage outcome **3999/4000** on the same DGP and seeds.

### Reproduction

```
Rscript --no-init-file d117_profile_gate.R --cell=<1|4|5|6> --nrep=<n> --cores=90 --outdir=OUT
Rscript --no-init-file score_d117_gate.R      # reads results/*.csv, requires exactly 4
```
in `docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/`.
**Smoke first** (one cell, `--nrep=50`, inspect one fit past its guards) before any scaled run.

### The fence on this arc

Do **not** move the pre-registered floor, drop the worst corner, re-score on raw SD, or otherwise
shift a goalpost to reach a PASS. **"D-117 does not discharge; hold 0.7.0" is a legitimate and
possibly correct outcome.** Record the predicted direction *before* looking at new results.

A fuller draft decomposition sits at `~/.claude/plans/hidden-twirling-curry.md` — treat it as input
to your own planning, not as an approved plan.

## A landmine to defuse first

**`docs/dev-log/internal-roadmap.md:16` is stale and dangerous.** It names *"Current closeout —
Beta phylogenetic LSS PR 1"* as the immediate post-0.7.0 arc. **That arc was aborted 2026-07-16** —
Noether, Fisher and Rose all returned STOP at its recovery gate — and AGENTS.md says do not open
PR 1 or begin PR 2 without Shinichi's explicit new goal. A session following the roadmap walks
straight into it. Fix the roadmap.

## Debt this session created — own it

- **`R CMD check` no longer executes the five relocated vignettes' code.** It builds
  `vignettes/*.Rmd` and not `vignettes/articles/*.Rmd`, so the re-build went from 37 documents to
  32. `figure-gallery.Rmd` alone is ~92 KB of plotting code, now run by nothing in the release
  gate. **And pkgdown builds only on `main` via `workflow_run`, never on a PR** — so there is no CI
  safety net either. Restoring this is real work: build the site on PRs, or add a test that knits
  the five.
- **Rendering since the move is unproved.** pkgdown *discovery* and config are verified
  (`as_pkgdown()` finds all 37; `check_pkgdown()` clean); no site has been built. I did not
  dispatch the pkgdown workflow because its `workflow_dispatch` path **deploys to Pages** and would
  publish this candidate's site over the live one.
- **Installed size 24.7 Mb** is quoted and adjudicated as *still open*: dominated by `libs 13.6Mb`,
  reported as `INFO` not `NOTE` here; CRAN's verdict is not established. `inst/sim` (1.9 Mb) ships.

## Goals / mission (the durable why)

Produce drmTMB's **first CRAN release as `0.7.0`** (D-86) without broadening its scientific claims,
under the fail-closed rung ladder (D-49): never say "CRAN ready", always report the **highest proven
rung and the next unproven one**. **D-89 governs the pace — submission is far away by choice; there
is no clock.** Trust capability by exact cell and evidence tier.

## Plans / roadmap beyond the next steps

1. **This arc** — the D-117 discharge question (above).
2. **Then** — repay the vignette-code-coverage debt below, and decide `platform-clean`.
3. **After that** — the open-issue frontier clusters into five themes: interval construction and
   coverage calibration (#682, #687, #686, #680, #802), variational inference and outer optimization
   (#932–#936, the Gates 0–4 umbrella under #496; **GVA itself was declined 2026-08-03 — AGHQ is the
   route**), structured effects and covariance (#33, #5, #531), recovery validation (#859, #570,
   #555), and performance at scale (#4, #914, #740, #714).
4. **NOT next** — the Beta phylogenetic LSS arc, despite what `internal-roadmap.md` says. See the
   landmine section.

## Files created / modified this session

**15 commits**, `eda38306b..91e2e85da` on `claude/07-release-slice`.

*Package paths (ship):* `NEWS.md` · `R/profile.R` · `R/check.R` · `man/confint.drmTMB.Rd` ·
`tests/testthat/test-boundary-surfacing.R` (all via the PR #961 merge) · five vignettes +
`function-map-cheatsheet.png` moved to `vignettes/articles/` · link rewrites in
`vignettes/{convergence,drmTMB,first-week-intervals,implementation-map,julia-engine,large-data,model-map,model-selection,structural-dependence}.Rmd`.

*Repo-only (do not ship):* `.Rbuildignore` · `_pkgdown.yml` · `tools/tests/test_capability_ledger.py` ·
`AGENTS.md` · `docs/dev-log/release/0.7.0-cran-gate/{FREEZE-NOTES-0.7.0.md,STALE-EVIDENCE-QUARANTINE.md}` ·
`docs/dev-log/release/0.7.0-cran-gate/CANDIDATE-EVIDENCE/{as-cran-a8f7c47905b0.log,inventory-a8f7c47905b0.txt,tarball-a8f7c47905b0.sha256}` ·
`docs/dev-log/release-audits/2026-08-09-07-{cran-release-ledger.json,decision-packet.md,adversarial-freeze-audit.md,mechanical-freeze-verify.md}` ·
`docs/dev-log/after-task/2026-08-09-07-release-slice-third-candidate.md` ·
`docs/dev-log/plan-actual/2026-08-09-07-release-slice.md` · `docs/dev-log/check-log.md` · this handover.

## Live environment the next session needs

```sh
cd /private/tmp/drmTMB-07-release          # or re-create; see How to Resume
R_PROFILE_USER=/dev/null Rscript --no-init-file -e '...'   # the .Rprofile R-4.5 lib segfaults R 4.6
```

Verified on this machine: R 4.6.0, TMB 1.9.21, `pkgbuild::has_build_tools()` TRUE, `pdflatex` present.
Full suite ~45 min · `R CMD check --as-cran` with vignettes ~15 min · candidate build ~9 min.
Totoro reachable via its existing ControlMaster (no Duo needed).

**Safe verification command (changes nothing):**

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'suppressMessages(pkgload::load_all(".")); testthat::test_dir("tests/testthat", filter="^(offset-families|boundary-surfacing)$", reporter="summary")'
```

**Files you must NOT stage:** anything under `scratchpad/` you did not create, and every foreign
branch's work listed below. **Never `git add -A` in this repository.**

## Landing state

`tools/handoff_gate.sh` returns **GATE FAIL — 1 of 1 repo(s) have UNLANDED state.** That failure is
**entirely pre-existing foreign work**, declared here rather than cleaned, per the protocol's
"DECLARE it" branch. **This session's own lane is clean and fully pushed.**

| Artifact | Committed | Pushed | State |
| --- | --- | --- | --- |
| `claude/07-release-slice` @ `91e2e85da` | yes | yes | **ACTIVE, CLEAN** — draft PR **#959**; do not merge, merging it *is* the release action |
| Candidate `a8f7c479` | evidence committed | yes | frozen. **The tarball itself lives in a session-scoped `/private/tmp/claude-503/<uuid>/scratchpad/frozen-a8f7c47905b0/` that will NOT survive.** Durable log/inventory/sha256 are committed under `CANDIDATE-EVIDENCE/`; recovering the exact bytes needs a rebuild, which yields a new hash |
| PR #961 (boundary surfacing) | merged into the slice | yes | DONE |
| CI | — | — | **green at `6dc48cd94`**; platform matrix dispatched at `604016a5d` (runs `31336312020`, `31336313176`) — **deliberately unread** |
| ~24 foreign branches with unpushed commits (`codex/lane-b-q1-preflight-admission` alone has **226**, `codex/lane-c-provider-cohort-20260729` **99**, `codex/aoi2-drac-recovery` **59**) | mixed | **no** | **CARRIED-OVER · PROTECTED FOREIGN.** Reason: pre-existing, not this session's, and not this lane's to land. Resume: whoever owns each lane. Do **not** push, clean, or reconcile |
| `claude/handover-freshness-0718` (primary checkout, 2 unpushed, dirty) | partial | no | **CARRIED-OVER · PROTECTED.** Never work, stage, or clean there |
| repository stashes | n/a | n/a | **PROTECTED** — do not pop or drop |
| PRs #957, #958, #937, #960, #955, #858 | — | — | **PROTECTED FOREIGN** — untouched. See [`../active-lane-split.md`](../active-lane-split.md) for each lane's own authority |

## Owner gates — none crossed, none to cross without Shinichi

No D-43 (panel `NOT_RUN`), no `platform-clean` write, no final `cran-comments.md`, **0** tags, no
GitHub release, no CRAN upload, PR #959 **OPEN/draft**.

**Note for `platform-clean`:** dispatched runs exist (`31332769740` R-CMD-check, `31332770848`
R-hub) but **none ran at this candidate's source `cc4f5baee`**. A run at the final head is required
before any platform claim.

## Gotchas paid for this session

- **A guard result is scoped to the tree it ran on.** I ran the capability-ledger guard *before* the
  vignette move, not after; CI caught three failures I should have. Re-run guards after the *last*
  change, not the risky-looking one.
- **When a change makes a check faster, ask what it stopped checking.** `--as-cran` reported 1 NOTE
  before and after the vignette move while silently dropping five documents from the re-build. No
  passing instrument emits that signal.
- **`capability_ledger.py --check` is NOT the guard** — `tools/tests/test_capability_ledger.py` is,
  and CI runs it. Remedy a C17 fingerprint break by *re-running*
  `tools/run-lane-c-c17c1-c14-model15-compatibility.R`, never by re-pinning.
- **`conclusion: cancelled` is ambiguous** — compare job duration against the 75-minute ceiling.
  Every cancel this session was a concurrency cancel from my own next push.
- Never `git add -A` here. Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file`.

## How to resume

```sh
cd /private/tmp/drmTMB-07-release && git status --short --branch
```

If that worktree is gone:

```sh
git worktree add -b <new> /private/tmp/drmTMB-d117 origin/claude/07-release-slice
```

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-claude-handover-d117-discharge.md. Reconcile
against git, then plan and run the D-117 discharge arc in this lane.
```
