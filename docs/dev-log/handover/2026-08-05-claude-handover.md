# Session Handoff: the D-117 gate — measured, claim withheld, attribution settled

**Meta:** 2026-08-05 (work dated 2026-08-04 UTC) · from **Claude** (Claude Code) · to a fresh
**Claude** session · context high. **Repo:** `drmTMB`, `origin/main = a7ef0d33c`.

---

## Critical Context

**1. D-117's number exists, but the PASS claim was WITHHELD — and that is the correct
state, not an unfinished one.** A D-43 panel returned 2 of 3 NOT-DONE. Do not "finish the
job" by reinstating a PASS. The measurement is the deliverable; the claim is a separate
question that now hinges on one open item (below).

**2. Exactly ONE item still gates a "D-117 discharged" verdict:** `confint()` warns on
*Wald*-at-boundary and steers users to `method = "profile"` — into a regime this session
measured at **7–25% coverage** — with no warning in `NEWS.md`, `man/`, or the vignettes.
The comparator has since removed the competing hypothesis, so this is now unambiguously
the right fix rather than one of two candidates. **It is a live R/TMB code change**, not a
docs edit.

**3. The census is 182 `interval_feasible` / 60 `point_fit_recovery` and must stay there.**
Nine merges this session moved it zero times. Verify before and after anything you do.

---

## What Was Accomplished

Two arcs, nine merges, `25768833b → a7ef0d33c`.

**Arc 1 — the Prong B stack + the CI ceiling.** All three stacked branches merged in order
(#915, #916, #917) plus closeout (#918). The headline was not the merges: the 45-minute
`timeout-minutes` was a **repo-wide latent failure**, not this arc's regression. Worst
passing job was 44.9 min against a 45-min cap, and **`main` itself had already been killed
by it** (run `30847977891` at `95b8ea34e`) — misfiled because GitHub logs a timeout kill as
`conclusion: cancelled`, the same string as a concurrency cancel. Ceiling set to **75** from
six measured runs; the longest run since was 48m21s, so that was sized correctly.

**Arc 2 — D-117.** Pre-registration committed *before* any fit (`e9bccb26b`). Four 10-group
cells, 1000 replicates each, Totoro 90 cores, 21 s. Coverage **0.9140 / 0.9290 / 0.9310 /
0.9370**; all clear the pre-registered floor `ss_floor(10) = 0.918`. The reproduction cell
matched the banked 2026-07-26 run on **five** independent statistics.

**Then three things the panel and follow-ups established:**

- **The claim was withheld.** Conditional on `profile.boundary` — a column `confint()`
  *returns to the user* — coverage is 0.8566 / 0.0732 / 0.2540, which by the arc's own gate
  is BORDERLINE/FAIL/FAIL. At `sd_mu = 1.0` that is worse than the 0.829 that disqualified
  the marginal route in D-117's own framing. Also newly reported: RE-SD point bias −16.9% to
  −9.1%, p < 1e-23, the mechanism behind the upper-miss asymmetry.
- **The attribution is NOT drmTMB's.** `lme4` on the same DGP and same seeds (paired,
  `REML = FALSE` to match drmTMB's ML default) agreed on boundary incidence **4000/4000**,
  matched conditional coverage to four decimals, and in the single divergence returned an
  interval **excluding its own MLE**. The finding is a property of profile intervals near a
  variance boundary.
- **D-97's pooled 0.9368 has no committed evidence.** The committed profile campaign is
  **3 cells / 3,000 attempts pooling to 0.9400**. "12 A1 cells" describes the *bootstrap-only*
  campaign; 11,988 = 12 × 999 where **999 is the bootstrap resample count**, not retained
  attempts. The figure traces to an after-task report existing only in the brain vault.

---

## Current Working State

- **Working:** `main` = `a7ef0d33c`. Census 182/60 verified. `capability_ledger.py --check`
  OK. After-task validator passes. CI ceiling 75.
- **In progress:** PR **#922** (`claude/pointer-final`) — a one-file `AGENTS.md` pointer
  refresh, in CI at handover time. **Merge it if green.** Content is docs-only and low risk.
- **Not working / blocked:** nothing of this lane's. The `profile.boundary` warning is
  unstarted by design (it is a code change and was outside the measurement arc).

---

## Key Decisions & Rationale

1. **Merge at ceiling 120, tighten once at the end** (owner-approved, departing from the
   prior handover's "tighten then merge"). `timeout-minutes` is a ceiling, not a reservation
   — it bills nothing when jobs finish early — and tightening first would have sized from the
   lightest branch.
2. **Pre-register before measuring**, scored with the repo's own `tools/gate-inference-ready.R`
   rather than a rule invented for the arc.
3. **Withhold rather than repair quietly.** The D-43 panel fired *late* (caught by
   plan-vs-actual reconciliation, after the PASS was committed and published). That is
   recorded in `D43-PANEL.md`, not papered over.
4. **Do not edit `DECISIONS.md`.** Correcting D-97's provenance is the owner's call
   ([[DECISIONS#D-87|D-87]]); this session recorded evidence only.
5. **Census untouched, DEFER fence held** throughout.

---

## Landing State

`handoff_gate.sh` run. **This lane is fully landed** except the one in-flight PR.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `claude/prong-b-tier1`, `citation-durability`, `mc0653-fixture` | y | y | #915/#916/#917 merged | **LANDED** |
| `claude/ci-ceiling-closeout` | y | y | #918 merged | **LANDED** |
| `claude/d117-10group-gate` | y | y | #919 merged | **LANDED** |
| `claude/d117-pointer-refresh` | y | y | #920 merged | **LANDED** |
| `claude/d117-comparator` | y | y | #921 merged | **LANDED** |
| `claude/pointer-final` `a4730b635` | y | y | **#922 OPEN, CI in progress** | **CARRIED-OVER** — merge when green; no rebase needed, docs-only |
| brain: `Imperfect coverage is the norm…` + `WHAT-WORKS` | y | n/a | n/a | **LANDED** (D-37: local commit is landed state; `976d2ee`) |
| primary checkout `claude/handover-freshness-0718`, 88 uncommitted; ~435 unpushed on ~18 branches | n | n | — | **NOT THIS LANE'S** — pre-existing from earlier sessions. Do not claim, commit, or clean. |
| PR **#858** `codex/lane-b-e0-readiness` (draft, 2026-07-27) | — | — | #858 draft | **FOREIGN LANE (codex).** Verified: no file of this session's nine merges touches it. |

---

## Next Immediate Steps

Run `tools/lane_preflight.sh`, diff against current git state, and classify every item
**OWED / DONE / RETRACTED / PROTECTED** before acting.

1. **Merge PR #922** if CI is green. One file, docs-only.
2. **The `profile.boundary` user warning — the only item gating "D-117 discharged".**
   Mirror the existing Wald-boundary warning at `R/profile.R:1941-1957`: emit a
   `cli::cli_warn()` when a *profile* interval returns `profile.boundary = TRUE`, plus a
   `NEWS.md` bullet and a line in `?confint.drmTMB`. Suggested wording is in `VERDICT.md` §4.
   Ship it with a test. **This is a live R/TMB change** — run the full suite.
3. **Owner decisions — surface, do not assume.** (a) Whether D-117 is discharged once (2)
   lands. (b) Correcting D-97's provenance in `DECISIONS.md`. (c) Whether the gate extends to
   the 14 newly-reachable Prong B routes (count / zero-one-beta) — this measured the A1
   **scalar Gaussian** corner only.
4. **Push `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`)** — release-gating evidence on
   **no remote**, one disk. Foreign-lane branch, so it is the owner's call, but it is the
   second load-bearing artifact found outside git in a day.
5. Smaller: `drmSEM/.github/workflows/R-CMD-check.yaml:22` carries the identical
   `timeout-minutes: 45` (same latent fault, not yet fired); commit a smoke receipt +
   verified package hash for future campaigns.

**DEFER — fenced, do NOT start:** the 135-trace interval campaign (182→196,
`FROZEN_CENSUS` 59→45); the `predict()` scale-axis defect (its gate test **pins** current
behaviour and must fail when `predict()` is fixed — update it then, never relax it); the CI
guard/check job split; the B4-CI `SOURCE_COMMIT` port; mc-0282's runner contract (PROTECTED).

---

## Blockers / Open Questions

- **Is D-117 discharged?** The measurement exists; the conditional finding is adverse.
  Recommend **not** treating it as discharged until step 2 lands. Owner's call (D-93 / CI-17).
- **D-97's provenance** — `D97-PROVENANCE.md` gives the evidence and a suggested disposition.
  **Do not cite 0.9368 again** until settled.
- **Scope of the gate** vs the Prong B routes — unresolved since the previous handover.

---

## Gotchas & Failed Approaches

- **The primary checkout is a trap.** It sits on `claude/handover-freshness-0718`, ~669
  commits behind `main`, with 88 uncommitted files. Its `AGENTS.md` is stale. Read current
  content with `git show <ref>:<path>`, and work in a fresh worktree.
- **A stale pointer bit three times in one session.** The 2026-08-04 handover was unfindable
  because `AGENTS.md`'s pointer was three weeks old and the handover lived only on a feature
  branch. Then the refreshed pointer went stale twice more as findings landed. **If you change
  what is true, update the pointer in the same PR.**
- **`gh pr merge` fails on any PR touching `.github/workflows/`** — the OAuth token lacks the
  `workflow` scope (`admin:public_key, gist, read:org, repo`). Merge those in the web UI, or
  run `gh auth refresh -s workflow`. Pushing directly to `main` is blocked by the permission
  classifier.
- **A timeout kill and a concurrency cancel both log as `cancelled`.** Distinguish them by
  comparing job *duration* to the limit, never by reading the conclusion string.
- **Smoke caught a comparator that would have produced 4,000 silently empty rows** — passing
  `oldNames = FALSE` to lme4's `confint()` renames the row to `sd_(Intercept)|g`, so
  `parm = ".sig01"` matched nothing and every interval came back `NA` **with no error**.
- **A pre-registered sentence is not a true sentence.** "Not materially worse than pooled"
  was frozen in advance and still turned out false (contradicted at z ≈ 2.5). Pre-register the
  *test*; let the prose follow the result.
- **Do not dispatch a reviewer to an agent type that cannot execute the brief.** One D-43
  panellist got `math_consistency_reviewer` (Read/Grep/Glob only) with a brief requiring
  `git show`; it returned NOT-DONE on inaccessibility rather than on a defect.
- **`capability_ledger.py --check` is NOT the ledger verification** — CI runs six
  `tools/tests/*.py` in the same step. Run the whole command.

---

## How to Resume

**Environment.** Work in a clean worktree, not the primary checkout:
`git worktree add ~/local-scratch/worktrees/<name> origin/main`. Avoid `/private/tmp` (a
prior session lost three worktrees there mid-run). Toolchain: `python3` and `Rscript` on PATH;
`NOT_CRAN=true` for the full suite; run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file`
(the `.Rprofile` R-4.5 lib segfaults R 4.6). Totoro is reachable via
`ssh -o BatchMode=yes totoro` (384 cores; ≤100 cap, `OPENBLAS_NUM_THREADS=1`; D-50 — never
GitHub Actions). You do **not** inherit this session's terminal, credentials, or chat.

**Safe verification command** (the exact CI validation step):

```bash
python3 tools/capability_ledger.py --check && for t in test_capability_ledger test_arc1_profile_reconcilers test_b3_q6_target_promotion test_b4_ci_guard test_b4_ci_c1 test_profile_truth_gate; do python3 -m unittest tools/tests/$t.py; done && Rscript --no-init-file tools/emit-profile-truth-manifest.R --check && Rscript --no-init-file tools/check-capability-runtime.R && Rscript --no-init-file tools/check-profile-fence-integrity.R && Rscript --no-init-file tools/check-evidence-citations.R
```

**Do not stage:** the primary checkout's 88 uncommitted files; any `codex/*` branch work;
anything under PR #858's paths (`inst/sim/R/sim_interval_campaign_readiness.R`,
`tools/verify-lane-b-e0-readiness.R`, `docs/dev-log/interval-campaign-bindings/`).

**Read in this order:** this file → `AGENTS.md` (its `Latest` block) →
`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/VERDICT.md` →
`COMPARATOR.md` → `D97-PROVENANCE.md` → `D43-PANEL.md` →
`docs/dev-log/after-task/2026-08-04-d117-10group-profile-gate.md`.

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-05-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
