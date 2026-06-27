# Session Handoff #2: drmTMB q-series structured-RE completion lane

Meta: 2026-06-27 (second session of the day) · from Claude (ultracode) · TARGET =
a fresh Claude or Codex session. Supersedes the state in
`docs/dev-log/handover/2026-06-27-claude-handover.md` (read that first for the
deeper background; this doc records what changed since).

## TL;DR

The apply-list from handover #1 is **done and banked**, plus one extra verified
slice and an advisory memo. The plan is still ~30% to `supported`; the decisive
rungs (coverage / intervals / bridge) remain externally gated to the
maintainer / Codex / upstream. Nothing here breached a guard; no live R was run.

## What this session did

1. **PR #681** (draft, pushed, base = `claude/handover-2026-06-27`) —
   coverage-runner hardening:
   - degenerate-MCSE gate fixed byte-identically in the q2 and q4 coverage runners
     (`n_wald_fin >= 475L && wald_mcse > 0` before `<= 0.01`, else `NA`);
   - SLURM copy-back made fail-safe in all 3 sbatch (`set +e` / `EXIT_CODE=$?` /
     `set -eo pipefail`, keep `|| true`);
   - q4-location blind-safe fixes (D2 finite-interval fractions; D4 `sd_label_in_sdpars`
     now uses the `mu1:provider(...)` key) — **q4 runner stays HELD**;
   - q2-slope lane added to the coverage deploy runbook.
   - Reviewed by Fisher (q2 runner SOUND), Grace (sbatch), Rose (GO to bank).
2. **PR #683** (draft, pushed, base = #681) — **count-`mu` rejection contract**,
   6 source-verified boundary cells (q-series **98 → 104**):
   non-canonical/slope-only, labelled q=2, structured+ordinary, zero-inflated
   Poisson, zero-inflated NB2, simultaneous structured types. Rose-audited
   HONEST/SOUND; each `expected_error_pattern` maps to a real `cli_abort` +
   existing `expect_error`.
3. **Local commit `bfd0e3ad`** (on the #683 branch, **NOT pushed — push was
   declined by the maintainer**): documents the count-`mu` contract in design map
   218 + dashboard README, and adds the **item-5 anchor-robustness decision memo**
   `docs/dev-log/2026-06-27-rejection-contract-anchor-robustness-memo.md`.
   → **First action for the next session: push this commit (or let the maintainer
   review it first), then PR #683 reflects it.**
4. **Comprehensive verification**: a 12-family + refuter consolidation sweep
   verified **all 145 banked structured-RE sidecars are drift-free**; validator
   `mission_control_ok` throughout (now 104 q-series cells, 6 count structured-mu
   rejection rows).

## Current PR stack (all draft; maintainer merges)

`main` ← #675 ← #676 ← #677 ← #678 ← #679 (handover #1) ← **#681** ← **#683**
(+ local `bfd0e3ad` on #683's branch, unpushed).

## Hard guards (UNCHANGED, still in force)

No cluster (Totoro/DRAC) submission without per-run approval; do NOT touch DRM.jl;
do not undraft/merge PRs; no Ayumi reply; no q4/non-Gaussian REML / AI-REML claims;
no broad bridge / public-optimizer promotion; never infer a half-cell; do not
promote `supported` without the full ladder; run R with `--no-init-file`
(`.Rprofile` segfaults R 4.6); keep the validator `mission_control_ok`; **spawn Rose
before status claims, Fisher before trusting any coverage/interval number.**
The `/goal` Stop hook ("finish the plan") will keep firing because the plan is
externally gated — **holding is correct; do NOT fake completion or breach a guard
to clear it** (handover #1 §critical-context-3 already established this).

## Action map — remaining rungs by owner (highest leverage first)

1. **Coverage grids, sigma + q2** → **maintainer**. Run
   `tools/slurm/DEPLOY-sigma-slope-coverage.md` on fir (now covers both lanes).
   Agent is transfer-blocked. After results land, a session does Step 7: compute
   per-target coverage → bank a coverage sidecar → move only the exact cells'
   `coverage_status` off `planned`. **Read the MCSE caveat**: SR475 gives
   MCSE ≈ 0.01 only AT nominal 0.95 coverage; under-coverage inflates it — SR475
   sizes the estimate, not a guaranteed-passable 0.01 gate.
2. **Count recovery shards** → **maintainer** approves one provider-family shard
   (e.g. phylo/poisson, seeds 760001-760080) for the cluster; preserve the full
   retention policy in the run log.
3. **q4-location runner** → **Codex** (live R): confirm `names(fit$sdpars$mu)`
   matches the `mu1:provider(...)` key (D4), and regenerate the stale pilot
   artifact under `…/2026-06-27-q4-location-coverage-pilot/` (D3). Then it can
   leave HELD.
4. **q4 all-four one-slope intervals** → **engine work** (`pdHess=FALSE`,
   sigma-SD at lower bound) — needs explicit authorization.
5. **relmat-Q bridge** → blocked on upstream **DRM.jl #299/#300**.
6. **Item-5 anchor robustness** → **maintainer decision**. The rejection contracts
   anchor on engine message substrings; the worst (`"Structured non-Gaussian
   paths"`) is a hint line at `R/drmTMB.R:6631` load-bearing across ~8 sites.
   Recommendation (memo `bfd0e3ad`): add `class = "drmTMB_structured_rejection"`
   to the structured-rejection `cli_abort` calls (the warning-class precedent
   already exists) and re-anchor tests/sidecars/validator on the class.
   **Do this before banking further rejection tranches** — each new
   message-anchored contract compounds the fragility.

## Lessons banked this session

- **Wide-but-waved fan-out.** A 14-agent all-at-once sweep (~1M subagent tokens in
  ~10 min) tripped the provider rate limit; re-running in waves of ~4-5 succeeded.
  Resume (`Workflow {scriptPath, resumeFromRunId}`) caches completed agents, so a
  rate-limit-killed sweep is cheap to finish.
- **The refuter earns its cost.** The comprehensive sweep's value was not
  re-confirming the clean corpus but *refuting* the operator's "nothing left"
  claim — it found the 6 count-`mu` cells hiding as prose in neighbour cells.
- **Verify before banking a subagent's contract** (the #678 lesson held): each of
  the 6 count-`mu` `expected_error_pattern`s was source-checked against the real
  `cli_abort` + `expect_error` before commit.

## Rehydration recipe (next session)

1. `cd "/Users/z3437171/Dropbox/Github Local/drmTMB"`;
   `git status --short --branch`; `git log --oneline -8`.
2. Read this doc → handover #1 → `docs/design/218-structured-q-series-completion-map.md`
   → `docs/dev-log/2026-06-27-rejection-contract-anchor-robustness-memo.md`
   → `tools/slurm/DEPLOY-sigma-slope-coverage.md`.
3. `python3 tools/validate-mission-control.py` (expect `mission_control_ok`,
   **104** q-series cells, **6** count structured-mu rejection rows).
4. First action: decide whether to push the local `bfd0e3ad` commit.
5. Then: the work is externally gated — route per the action map above. The
   single highest-leverage unblock is the maintainer running the coverage deploy
   on fir.
