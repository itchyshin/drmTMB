# Handover → Claude — drmTMB true-parity lane, 2026-09-02 (checkpoint 1 closed)

**You are Claude, picking up drmTMB's half of the R<->Julia true-parity programme.** You inherit no
chat context. This document, `AGENTS.md`, the decision map and the current git state are
authoritative. The earlier `2026-09-02-claude-handover.md` (reverse-parity) is superseded by this
one for everything it listed as OWED; its facts stand.

**Nothing is merged. D-164 still holds CRAN.** All work is on `claude/rev-parity-*` branches,
all on origin. One DRAFT PR (#1114) exists and says it lands after #1112.

## FIRST ACTIONS

1. `~/shinichi-brain/tools/lane_preflight.sh .` — name the lane you take. This lane =
   `claude/rev-parity-*`. Four sibling lanes were live today, all Claude sessions (DRM.jl,
   gllvmTMB, GLLVM.jl); no Codex/Cursor lane. DRM.jl is read-only for you.
2. Read `docs/dev-log/2026-09-02-true-parity-decision-map.md` (branch `claude/rev-parity-handover`)
   and the after-task `docs/dev-log/after-task/2026-09-02-true-parity-arc.md`.
3. `gh pr view 1112 --json state` — its merge state decides your first slice (below).
4. Do not work in the main checkout (`feat/bridge-lss-reml-row12`, 45 behind). Worktrees only;
   create them serially (Dropbox, ~19k files).
5. Ledger: `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root . --status --scope true-parity`
   (`.unlazy/` is git-excluded run state; `--status` is a claim, `--reverify --cwd <worktree>` is evidence).

## Mission control

| item | state |
|---|---|
| draft PR | #1114 from `claude/rev-parity-integration-all` @ 14035812f — "lands after #1112" |
| head that should replace it once #1112 merges | `claude/rev-parity-integration-post1112` @ 89bfd210a (+ guard: `start`/`multi_start` rejected under `engine="julia"`) |
| label contract (ARC C2) | `claude/rev-parity-c2-label-producer` @ f0b7c4da9 — design 258 §7, R half, repaired after Rose |
| q4 SE receipt | `claude/rev-parity-q4-se-receipt` @ 996870366 — TMB SEs finite; Julia SE axis is the fixture fence (`wald_unavailable`, DRM.jl #495) |
| A4/A5 cross-engine wrapper + #575 receipt | `claude/rev-parity-a4-objective-at-bridge` @ 1291772bc — internal `drm_julia_reml_objective_at()`, DRM.jl pinned `dc3ce190` (five private names, one block); receipt re-runnable, refuses any other ref |
| handoff to DRM.jl lane | `claude/rev-parity-drmjl-findings` @ b0b5577a6 — five items |
| decisions | D-202 (vault) + `docs/dev-log/2026-09-02-rev-parity-owner-decisions.md`; relayed D-203 recorded as relayed |
| shared page | vault `memory/TWIN-PARITY-SHARED-PAGE.md`, sent to all three sibling lanes, none disagreed |
| DRM.jl fence | HEAD `f4778964`, working tree untouched |

## Key decisions (do not re-ask)

Push all 18 (done) · #1112 first · `cov.fixed` conditioning and unpenalized `objective_at()`
confirmed · base-R naming authority · promotion = Rose-scanned draft PR + owner merge (relayed) ·
Julia half of the label contract is the Claude DRM.jl lane's (relayed) · this arc is R→Julia; the
standing "both ways for user-facing" rule is recorded by analogy from gllvmTMB and needs one sentence
from Shinichi for drmTMB.

## Gotchas learned today

- **Six green gates measured the producer's own tests, not the claim.** Rose refuted the label
  producer seven ways after all its gates passed (a `(1 | g)` term reached `model.matrix()` and
  fabricated `1 | gTRUE`; the map path never cross-checked the engine's names; vacuity on
  unlabelled blocks). Always run the adversarial child before calling a slice done.
- **"Dead code" needs a caller census, not a comment.** The predict-time `gsub` had live structured-
  route callers; removing it broke `predict()` there. It is back, scoped as the legacy path.
- **Peers relay decisions; they are leads.** Record them as relayed, act on them where reversible,
  and let Shinichi confirm in your own session before anything public (issues, promotions).
- **Oracles can be wrong before the code is**: two gate CHECKs were corrected after seeing output
  (branch count; bare formula and shell-mangled regex). Record every correction in the leaf.
- The checker resolves ledgers against `--root` (main checkout), runs against `--cwd` (worktree).

## Next immediate steps (OWED)

1. **If #1112 is MERGED:** rebase `claude/rev-parity-integration-post1112` onto `origin/main`,
   merge `c2-label-producer` and `q4-se-receipt` into it, re-run leaf-s2/s3/s4 gates, point PR
   #1114 at it; then S6 promotion wave 1 exactly per
   `docs/dev-log/plan/2026-09-01-bridge-promotion-wave1.md` (on #1112's branch) — 4 rows
   `experimental → partial`, Rose forbidden-claim scan, draft PR; q4 stays out (SE axis fenced).
   A4/A5 are DONE on `claude/rev-parity-a4-objective-at-bridge` (off the post-#1112 branch): merge that
   branch into the integration head too. Re-pin the DRM.jl ref when that lane folds
   `feat/575-objective-at` into a merging ref (one env-var + one comment line).
2. **If #1112 is still OPEN:** nothing merges; do the two owner-independent items: project the
   `Non-Gaussian phylogenetic location-scale` row onto `docs/design/capability-status.md` as
   scope-limited (nbinom2, zero_one_beta implemented; ten families rejected by design — measured in
   the decision map), and prepare (do not file) the reverse-gap issue list split user-facing vs
   engine-internal.
3. Ask Shinichi, once, in one message: (a) one-way vs both-ways for drmTMB; (b) keep or revert the
   scoped legacy `gsub`; (c) file the reverse-gap issues?
4. `objective_at()` does not reach `rho12` or the q4 phylo covariance block by label (found by A5);
   widening the start/label vocabulary is an A2/A3 follow-up.
5. Extending `coef_labels` to the structured/joint/xfam payload builders (design 258 §7.4) is the
   next C-arc slice; it retires the legacy predict path.
5. Do not re-run the full suite (~45 min) or `--as-cran` unless R/ code outside today's hunks changes.

## Compute (Shinichi, 2026-09-02: "make good use of DRAC + Totoro")

Propose the target WITH the estimate, do not wait to be asked: P2 pilots and the P4 warm grid on
Totoro (≤150 cores, BLAS pinned; the P4 pre-run is <10 min and under the line); multi-seed campaigns
on DRAC job arrays (nibi or trillium, `--time` from `seff`); never GitHub Actions (D-50). Fleet facts:
vault `projects/SLURM-AND-THE-FLEET.md`.

## How to resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-02-claude-true-parity-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
