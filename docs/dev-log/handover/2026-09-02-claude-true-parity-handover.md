# Handover → Claude — drmTMB true-parity lane, 2026-09-02 (checkpoint 1 closed)

**You are Claude, picking up drmTMB's half of the R<->Julia true-parity programme.** You inherit no
chat context. This document, `AGENTS.md`, the decision map and the current git state are
authoritative. The earlier `2026-09-02-claude-handover.md` (reverse-parity) is superseded by this
one for everything it listed as OWED; its facts stand.

**ALL FIVE MERGED on Shinichi's word (2026-09-02): #1112 (13ac255a3), #1114 (37ea93c47), #1119
(8fda9b017), #1120 (ce273991b), #1121 (0ceb77eb0 = main; pkgdown reference index for the two new exports). D-164 still holds CRAN.** The reverse-parity lane, the coefficient-name contract,
the A4/A5 wrapper, the q4 SE receipt, and promotion wave 1 are on main.

## FIRST ACTIONS

1. `~/shinichi-brain/tools/lane_preflight.sh .` — name the lane you take. This lane =
   `claude/rev-parity-*`. Four sibling lanes were live today, all Claude sessions (DRM.jl,
   gllvmTMB, GLLVM.jl); no Codex/Cursor lane. DRM.jl is read-only for you.
2. Read `docs/dev-log/2026-09-02-true-parity-decision-map.md` (branch `claude/rev-parity-handover`)
   and the after-task `docs/dev-log/after-task/2026-09-02-true-parity-arc.md`.
3. `gh api repos/itchyshin/drmTMB/pulls/1112 --jq .merged` — its merge state decides your first slice (below).
   As of 2026-09-02 evening it is OPEN with the Ubuntu release check RED: `test-julia-gate-vs-engine.R:258`
   (TSV artifact vs registry drift on rows gaussian_phylo_mean and biv_q4_phylo_reml). The branch
   (`codex/rebase-julia-optimizer-controls`) is currently UNOWNED — the overnight session that drove it
   has closed and the DRM.jl lane never edits drmTMB. Fix = run `tools/write-julia-capability-comparison.R`
   on that branch and push; do it only on Shinichi's word (protected branch, D-87).
4. Do not work in the main checkout (`feat/bridge-lss-reml-row12`, 45 behind). Worktrees only;
   create them serially (Dropbox, ~19k files).
5. Ledger: `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root . --status --scope true-parity`
   (`.unlazy/` is git-excluded run state; `--status` is a claim, `--reverify --cwd <worktree>` is evidence).

## Mission control (evening of 2026-09-02)

| item | state |
|---|---|
| `origin/main` | 13ac255a3 = #1112 merged (its CI fixed at fcc05c5ab: registry ported from the hand-repaired TSVs, one cell reversed) |
| draft PR #1114 | head 28cf21ff5 (353f39f2d + CI-portability fixes + premise guards on the two conditioning edge tests) (integrated tree + C17 re-cert + A4/A5 re-pin to DRM.jl 77513aa0 + phylocov/sd coef_labels + lss-tip-identity receipt) = `claude/rev-parity-integration-v2` (main + reverse-parity lane + guard + label contract + q4 SE receipt + A4/A5); every leaf ledger re-run on this tree; filtered suites 629/0. Owner merge = sign-off |
| draft PR #1119 | `claude/bridge-promotion-wave1` @ e296168ff: four rows experimental → partial on the bridge axis; Rose scan CLEAN; adds `partial` to the r_bridge_status vocabulary (designs 192/168) — the one schema decision named in the PR body |
| A4/A5 | on DRM.jl's supported `drm_bridge_objective_at` (DRM.jl #590), pinned main `77513aa0` (carries #577 and #599), zero private names; receipt at the fixed engine (numbers identical to e4647333) |
| ledger `.unlazy/true-parity/` | eight leaves + node gates; see the after-task for the final count |
| reverse-gap issues | #1115–#1118 filed (D-204) |
| DRM.jl fence | never edited; DRM.jl main now 77513aa0 (#577 root fix, #599 echo validator) by that lane's own merges |
| CI (2026-09-02 night) | main ce273991b: R CMD check GREEN (ubuntu release + os-matrix); the pkgdown workflow RED because the two new exports were not in `_pkgdown.yml`'s reference index — fixed by #1121 (merged 0ceb77eb0); a wake-up watches R-CMD-check + the pkgdown site run on that head. Earlier:  main after #1112; wave-1 #1119; #1114 @ 28cf21ff5 (mergeable_state clean). Both PRs await the owner's merge, #1114 first |

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
- **CI has no Julia, no DRM.jl checkout, and Linux LAPACK.** Locate fixtures through `DRM_JL_PATH` and skip when absent; keep refuse/contract tests synthetic; guard numeric edge cases on `pdHess`; keep R source ASCII (R CMD check warns on a section sign in a string). Run the touched test files once with `env -u DRM_JL_PATH -u DRMTMB_JULIA_TESTS` before pushing.
- **Two whole-file pins on the bridge file.** DRM.jl's echo (#599) requires labels for EVERY block a
  fit reports, including `phylocov` and `sd`/`sd_phylo` (design 258 §7.5); and the lss-tip-identity
  receipt (`tools/check-julia-phylo-labels-receipt.R --current`) pins the whole of `R/julia-bridge.R`,
  so regenerate it LAST, after every R edit (`tools/run-julia-phylo-labels-public.R <DRM.jl clone>
  <new.json> tree`, then copy over; it refuses to overwrite).
- **CI runs Python ledger guards `devtools::test()` never sees.** Touching `R/drmTMB.R`, `R/methods.R`,
  `src/drmTMB.cpp` or `tests/testthat/test-zero-one-beta.R` stales the C17 model-15 receipt (whole-file
  pin); clear it with `R_PROFILE_USER=/dev/null python3 tools/recertify-c17.py --label <slug>` (refuses if
  any number moves; ~80 s) and run `python3 -m unittest tools/tests/test_capability_ledger.py` before pushing.

## Next immediate steps (OWED)

1. Confirm main's CI on 8fda9b017 (a wake-up was armed at merge time; if red, read the job's own
   remediation text first — the ledger guards print the exact command). #1120 (receipt regenerated on main) is merged as ce273991b.
2. Post-merge housekeeping: `python3 DRM.jl/tools/parity_ledger.py --drmtmb . --ref origin/main`
   (re-run at merge time: CLOSURE PASS, four rows now `partial` on the bridge axis; it also lists TWO
   drmTMB exports with no DRM.jl twin — `objective_at()` and `drm_provenance()` — which need an
   "accounted for in writing" line in DRM.jl `tools/parity_ledger.py` (handed to that lane 2026-09-02:
   counterpart `drm_bridge_objective_at`; build-provenance stamp), not a port); delete the merged
   child branches on origin when Shinichi says so (`claude/rev-parity-*` except `handover`, which
   carries docs not yet on main — land those via a docs PR, then delete it too).
3. Re-pin A4/A5 whenever DRM.jl main moves (one SHA in `R/julia-bridge.R` + the receipt script; re-run
   leaf-a4/a5 with `OPENBLAS_NUM_THREADS=1`); regenerate the lss-tip-identity receipt LAST after any
   R edit (it pins all of R/).
4. Next engineering slices, each its own gate: extend `coef_labels` to the structured/joint/xfam payload
   builders and retire the legacy predict-time rewrite (design 258 §7.4); widen `objective_at()`/`start=`
   labels to `rho12` and the q4 phylo covariance block; a deterministic indefinite-Hessian test for B2;
   the reverse-gap issues #1115–#1118 (both-ways rule, symbolic alignment table first); project the
   `Non-Gaussian phylogenetic location-scale` board row as scope-limited.
5. P2–P5 arcs (G3 inference qualification on Totoro pilots, G4 threading, G5 warm grid on Totoro,
   G6/G7 docs) per the programme estimate, each behind its own D-139 gate.

## Compute (Shinichi, 2026-09-02: "make good use of DRAC + Totoro")

Propose the target WITH the estimate, do not wait to be asked: P2 pilots and the P4 warm grid on
Totoro (≤150 cores, BLAS pinned; the P4 pre-run is <10 min and under the line); multi-seed campaigns
on DRAC job arrays (nibi or trillium, `--time` from `seff`); never GitHub Actions (D-50). Fleet facts:
vault `projects/SLURM-AND-THE-FLEET.md`.

## CI cost note (vault OQ-32, proposed not decided)

drmTMB's `ubuntu-latest (release)` job takes ~45 min and ran four times on 2026-09-02 (two of them
on #1112 alone). The GLLVM.jl lane filed vault OQ-32: Totoro as a self-hosted runner for the twins'
PACKAGE-CHECK CI only (campaigns stay off Actions, D-50). Caveat that travels with it: these repos are
public with `on: pull_request`, so self-hosted only for push/workflow_dispatch, fork PRs on hosted
runners, ephemeral containerised runner, no-sudo, no secrets. Free wins needing no decision: shard the
suite across parallel hosted jobs; drop coverage on routine runs. Details: vault
`memory/OPEN_QUESTIONS.md` OQ-32 · `projects/COMPUTE-PLAYBOOK.md` §Proposed.

## How to resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-02-claude-true-parity-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
