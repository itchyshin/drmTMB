# Session Handover: the 0.7.0 CRAN ladder — holds decidable, REML arm measured

Meta: 2026-08-15 (evening) · from Claude · target **Claude** (fresh session) ·
lane `claude/07-cran-ladder` @ `966039f17`, 10 commits ahead of `origin/main` (`9f1ea65ba`),
pushed · PR **#1039** open.

You are Claude, picking up the drmTMB 0.7.0 release lane. This handover supersedes
`2026-08-15-070-cran-ladder-claude-handover.md` (this morning's, fully executed). Trust the repo
over any narrative, including this one.

## Critical Context

**The rung is `tarball-clean` and did not move.** `cran_release_gate.py` on
`docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json` returned READY after every
one of this session's commits; the ledger JSON and everything under
`docs/dev-log/release/0.7.0-cran-gate/` are zero-diff against `main`. Run the gate yourself before
believing this.

**Everything that gates the release now is an OWNER DECISION, not engineering.**

- **D-93** — the packet is written and current:
  [`docs/dev-log/release-audits/2026-08-15-d93-decision-packet.md`](../release-audits/2026-08-15-d93-decision-packet.md).
  It ends in one unanswered question (nominal-exact bar vs the `g`-tapered floor). Adversarially
  reviewed (CLEARED after one numeric fix); its two load-bearing claims were independently
  confirmed. **Do not answer the question for him. Do not soften the undercoverage framing.**
- **D-117** — all four discharge conditions are MET. Condition 1 was *already satisfied on `main`*
  (`8.3%-15.8%` in `NEWS.md:186`, `R/profile.R:217`, `man/confint.drmTMB.Rd:271`,
  `vignettes/first-week-intervals.Rmd:122`) — a session slice that "added" it was reverted as a
  duplicate. Nothing engineering remains; discharge is Shinichi's judgement.
- **The re-freeze is deferred by his decision** (2026-08-15):
  [`…070-refreeze-timing-decision.md`](../release-audits/2026-08-15-070-refreeze-timing-decision.md)
  lists five preconditions for the next freeze. `main` now reads `Version: 0.7.0.9000` so it no
  longer masquerades as the frozen candidate (`a75c3c901` / `2176e4b8…cda9` — hash re-verified
  this session).

**The REML arm was RUN on Totoro at his instruction** — the one lever the packet named as
implemented-but-unmeasured. Result, pre-registered before results existed and scored by a
falsifier-first scorer:
[`docs/dev-log/simulation-artifacts/2026-08-15-d117-reml-arm/VERDICT.md`](../simulation-artifacts/2026-08-15-d117-reml-arm/VERDICT.md).
**NARROWS BUT DOES NOT CLOSE**: pooled profile coverage 0.924800 → **0.946325** (exact CI
[0.9456, 0.9470], excludes 0.95), SD bias −10.92% → −4.60%, miss asymmetry 5.72:1 → 2.03:1. The
ML control arm reproduced the banked 100k gate to **five decimals in all eight comparisons**, so
the harness is proven. 400,000 paired replicates, 17m19s at 150 cores. Raw CSVs (~220 MB) are on
Totoro at `~/d117_reml/results/` with SHA-256s in the VERDICT; `SUMMARY.csv` and the score output
are committed. **Caveat the VERDICT states: it ran on the 0.6.0 campaign library** (so the control
could reproduce the banked gate), not on `0.7.0.9000`.

## What Was Accomplished (this session, all landed)

1. Morning arc: rehydrated the prior handover, corrected its D-117-conflict claim (both sources
   agree: NOT DECIDED), closed superseded PRs #959/#955 — rescuing commit `8245449f2` from #959
   before closing — and recorded the no-re-freeze decision.
2. **D-93 decision packet** written (Fisher/Opus), adversarially reviewed (Rose lens), one numeric
   fix applied at all three occurrences (miss ratio 5.5:1–5.9:1).
3. **Gate 1 closed**: 9-row component ledger rebuilt; the never-performed rights review of the
   2026-08-09 gllvmTMB borrowing (`drm_log_pnorm()`) is **CLEAR** — verified against a sibling
   gllvmTMB checkout, licence GPL-3 exactly, all three upstream commits match `inst/COPYRIGHTS`
   line-for-line.
4. **Version bump** `0.7.0` → `0.7.0.9000` on the lane (the only non-docs change; sole literal pin
   was `DESCRIPTION` itself).
5. **Bootstrap boundary flag re-landed** as PR **#1041** (branch `claude/bootstrap-boundary-reland`,
   `206f0547a`): `bootstrap_at_boundary` + `drmTMB_bootstrap_boundary_warning`, smoke-proven at the
   original commit's demonstrated case (estimate 0.1936), 16/16 new tests, 983/983 profile-target
   tests.
6. **REML arm**: pre-registration → campaign → falsifier-first scoring → VERDICT; D-93 packet
   updated in place (its "never measured" claims are superseded by boxed notes; its
   recommendation's own condition is recorded satisfied; **the closing question remains
   unanswered**).
7. Closeout: after-task ×2 (both pass `closeout.py check`), plan-vs-actual reconciliation,
   mechanical verify (8/8 PASS).

## Current Working State

- **Working**: everything above. **In-progress**: nothing. **Blocked**: the ladder itself, on
  D-93/D-117 (Shinichi).
- 12+ lanes live; foreign codex direct-to-main activity. This lane touched only: its own docs,
  `DESCRIPTION` (Version line), `AGENTS.md` (CRAN-lane block + ▶ Latest pointer), and PR #1041's
  separate branch.

## Key Decisions & Rationale (this session)

- **No re-freeze yet** (Shinichi): D-93/D-117 hold regardless; the platform matrix runs once,
  against shipping bytes.
- **Revert the duplicate 8–16% disclosure** rather than ship two roundings of one measurement.
- **Close #959/#955, rescue `8245449f2`** on its own branch instead of reviving an abandoned
  candidate lineage.
- **Run the ML arm as a paired control** inside the REML campaign — which is what makes the REML
  number trustworthy.
- **REML recommendation updated but decision left open**: Reading B with REML's measured position
  stated; the counter-argument (documented ≠ fixed; he declined that trade once) is preserved.

## Files Created / Modified (session diff vs `origin/main`, all committed + pushed)

On `claude/07-cran-ladder` (PR #1039):
- `AGENTS.md` — CRAN-lane re-freeze block + ▶ Latest pointer (this handover)
- `DESCRIPTION` — Version → `0.7.0.9000`
- `docs/dev-log/after-task/2026-08-15-070-cran-ladder-rehydration.md` · `…-070-cran-ladder-arc.md`
- `docs/dev-log/plan-actual/2026-08-15-070-cran-ladder-arc.md`
- `docs/dev-log/release-audits/2026-08-15-070-refreeze-timing-decision.md` ·
  `…-d93-decision-packet.md` · `…-gate1-component-ledger-and-rights-review.md` ·
  `…-gate1-recon-inventory.md` · `…-mechanical-verify.md`
- `docs/dev-log/simulation-artifacts/2026-08-15-d117-reml-arm/` — `PREREGISTRATION.md`,
  `VERDICT.md`, `d117_reml_arm.R`, `score_reml_arm.R`, `a1_profile_common.R` (copy),
  `SCORE-OUTPUT.txt`, `campaign.log`, `results/SUMMARY.csv`
- `docs/dev-log/handover/2026-08-15-070-cran-ladder-close-claude-handover.md` (this file)

On `claude/bootstrap-boundary-reland` (PR #1041): `R/profile.R`, `R/check.R`,
`man/confint.drmTMB.Rd`, `NEWS.md`, `tests/testthat/test-boundary-surfacing.R`.

## Landing State

| Item | State |
| --- | --- |
| `claude/07-cran-ladder` @ `966039f17` (10 commits) | **LANDED to origin; PR #1039 OPEN** — merge is Shinichi's/reviewer's call, do not auto-merge |
| `claude/bootstrap-boundary-reland` @ `206f0547a` | **LANDED to origin; PR #1041 OPEN** — same |
| Raw REML CSVs (~220 MB) | **CARRIED-OVER on Totoro** `~/d117_reml/results/`, SHA-256 in VERDICT §Cost; regenerate command in VERDICT; deliberately not committed |
| `~17` foreign branches with unpushed commits (codex/*, claude/wf-*, hopper/*, shannon-install) | **PROTECTED FOREIGN** — `handoff_gate.sh` flags them; not this lane's to land |
| Stale `.git/index.lock` (0 bytes, 2026-08-14 18:43) | **REPORT, DO NOT REMOVE** — harness blocks `.git` deletions; Shinichi clears it |
| PRs #1033/#1038/#1032/#1040/#858 | **PROTECTED** — other lanes |

## Next Immediate Steps — OWED only

1. Lane preflight; fetch/prune; reconcile this document against live git. Classify every item
   `OWED / DONE / RETRACTED / PROTECTED` before editing anything.
2. **Nothing on this lane is buildable until Shinichi answers the D-93 packet's closing question**
   (and separately D-117). If he has answered: record the decision in the brain's `DECISIONS.md`
   **only with his approval** (D-37), mirror it in a repo release-audit note, and proceed per the
   refreeze-timing decision's five preconditions.
3. If PR #1039 / #1041 have review feedback, address it on their branches.
4. **If (and only if) Reading B is chosen and REML is to be surfaced**: a scope decision is needed
   on whether `confint()`/docs should recommend REML for small-`g` random-effect SDs. That is API
   wording + possibly a default — treat it as its own slice with its own review; the VERDICT's
   single-cell scope caveat applies.
5. Optional, cheap, not blocking: re-run the REML arm's cell 4 (~5 min, 150 cores) against current
   `main` (`0.7.0.9000`) to close the VERDICT's "0.6.0 library" caveat before the packet is decided.
   Command is in VERDICT §Cost; change `--repo`/`R_LIBS` to a current-main build.

**Do not**: submit to CRAN · advance `status_claim` · re-freeze · run the platform matrix ·
answer the D-93 question yourself · touch the missing-data lane (#1033) · remove the index.lock.

## Blockers / Open Questions

- D-93: awaiting Shinichi (the packet's §7 question).
- D-117: awaiting Shinichi (all conditions met).
- Two Gate 1 follow-ups (non-blocking): logo SVGs + `function-map-cheatsheet.png` have
  undocumented generation provenance.

## Gotchas / Failed Approaches (do not repeat)

- **The banked per-cell ML values are listed alphabetically in SUMMARY.csv**, not in cell-index
  order — pairing them positionally mislabels three of four cells. The scorer reads them by name.
- **A negative grep is not evidence of absence**: the 8–16% disclosure exists as `8.3%-15.8%`;
  searching "8-16" missed it and cost a slice.
- **Check tool grants, not just model tier**: `documentation_writer` has no Bash and cannot run
  `devtools::document()`.
- **Reusing one `MakeADFun` across estimator arms warm-starts the inner optimisation** (documented
  false-pass mechanism); the REML runner fits each arm through its own `drmTMB()` call.
- The timing probe ran on the fastest cell; the campaign overran its estimate by 44%.

## How to Resume

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
bash ~/shinichi-brain/tools/lane_preflight.sh .
git fetch --prune origin
# Work in .worktrees/cran-07 (branch claude/07-cran-ladder) or a fresh worktree off origin/main.
# NEVER work in the primary checkout (stale branch, ~1020 commits behind, dirty).
python3 ~/shinichi-brain/tools/cran_release_gate.py \
  docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json   # expect READY, tarball-clean
```

R runs as `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the repo `.Rprofile` segfaults
R 4.6). Totoro: socket `~/.ssh/cm-snakagaw@totoro…` (standing authority), cap 150 cores (D-143),
`OPENBLAS_NUM_THREADS=1`. DRAC only for replicated grids/GPU, via `sbatch` with
`--time`/`--account`, never login-node compute (D-64 Duo rules apply). No campaign is authorised
by this handover.

**Paste-ready prompt:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-15-070-cran-ladder-close-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
