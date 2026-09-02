# After-task — drmTMB true-parity checkpoint 1 (Claude lane, 2026-09-02)

**Reader:** Shinichi, and the next session on this lane. **Purpose:** what landed today toward the
true R<->Julia parity destination, what was verified by re-running, what was deliberately not done,
and the two envelope crossings the reconciliation flagged. Plan of record:
`~/.claude/plans/piped-dancing-floyd.md`; ledger `.unlazy/true-parity/` (27 gates).

## 1. Goal

Land drmTMB's half of true parity behind PR #1112: push the reverse-parity lane, take the four owed
owner decisions, implement the base-R coefficient-name contract on the R side, build the q4 SE
receipt, hand the Julia half to the DRM.jl lane, and write the decision map that says what parity
still means. Julia files untouched.

## 2. What was done

| slice | result | where |
|---|---|---|
| S0 recon | rehydration reconciled; DRM.jl ledger `CLOSURE: PASS` at `origin/main` (10 covered · 1 partial by D-179 · 1 unsupported = #1112's row) | plan sweep receipt |
| S1 land | 18 branches on origin (found already pushed by another session, SHAs identical, nothing forced); draft PR #1114 "lands after #1112"; D-202 in vault; decision record + decision map on `claude/rev-parity-handover` | `docs/dev-log/2026-09-02-rev-parity-owner-decisions.md`, `…-true-parity-decision-map.md` |
| S2 guard | `drm_control(start=, multi_start=)` under `engine="julia"` now aborts; red control shown; filtered suites pass | `claude/rev-parity-integration-post1112` @ 89bfd210a |
| S3 producer | design 258 §7; payload `coef_labels` (fixed-effect part only); existing validator wired; map-path cross-check against drmTMB's own names; no-vacuity rule; absent map fails closed; 10 constructs + Rose's 7 attacks green; legacy predict-time `gsub` kept and scoped | `claude/rev-parity-c2-label-producer` @ f0b7c4da9 |
| S4 receipt | same-draw q4 REML receipt vs DRM.jl `cda42b8c`: coef/logLik agree (|Δ logLik| 1.9e-05), TMB SEs finite; Julia SE axis is the fixture's recorded fence (`wald_unavailable`, DRM.jl #495) | `claude/rev-parity-q4-se-receipt` @ 996870366 |
| A4/A5 wrapper + receipt | `drm_julia_reml_objective_at()` (internal) first reached DRM.jl's primitive via five private names (1291772bc, pinned `dc3ce190`); the same day DRM.jl merged a supported entry (`drm_bridge_objective_at`, #590) and the shim now calls it with zero private names (7afa28b62, pinned main `e4647333`). Receipt at the fixed engine: TMB@TMB −219.613986 · DRM.jl@TMB −219.620688 · TMB@Julia −219.616013 · DRM.jl@Julia −219.614005; anchors 0 and 6e-09. Before the fix (kept in the receipt): DRM.jl@Julia −219.630326, the 0.0096 mode-finder gap that was #575. Diagnosis only, no promotion | `claude/rev-parity-a4-objective-at-bridge` @ 7afa28b62 |
| S5 handoff | five items to the DRM.jl lane, incl. the verbatim §7 contract and the SE-receipt correction | `claude/rev-parity-drmjl-findings` (HEAD) |
| S9 Rose | see §4 | scratch verdict, summarised below |
| S10 Melissa | 7 deviations: 4 adaptive · 2 drift · 1 unclear | `docs/dev-log/plan-actual/2026-09-02-true-parity.md` |
| alignment | one shared "where we are heading" page sent to DRM.jl3, gllvmTMB1, GLLVM.jl3; filed as vault `TWIN-PARITY-SHARED-PAGE`; all three confirmed no contradiction | vault |

## 3. Verification (re-run by the coordinator, not read from reports)

- Final ledger (`.unlazy/true-parity/`, re-run at close by the coordinator, each leaf in its own worktree): leaf-s1 5/5, leaf-s2 4/4, leaf-s3 12/13 + 1 ABANDONED with reason (S3-G4, the scoped legacy predict path), leaf-s4 4/4, leaf-s5 3/3; node gates N1–N5 all met. Totals after A4/A5: 43 met · 1 abandoned · 0 unmet (leaf-a4 6/6, leaf-a5 4/4; N1 re-run over all seven leaves).
- Six oracle corrections recorded in the ledger after seeing output (S1-G1 exact-18 count; S1-G2 new lane branches counted as missing; S1-G3 GraphQL rate limit → REST; S3-G6 bare formula, then a shell-mangled regex; S5-G1 a count regex that breaks past 9; N1 ran leaves against the main checkout and exceeded the checker's 120 s cap → per-worktree runner with a freshness-checked receipt). All were oracle defects; no requirement moved, and each correction is written beside its gate.
- DRM.jl fence: `DRMJL_FENCE_HELD`; HEAD still `f4778964`.
- Full suite and `--as-cran` NOT re-run today (D-139; both passed 2026-09-01 on the integration tree; today's R/ edits are covered by the filtered suites named in the gates).

## 4. Adversarial pass (Rose, Opus, one child)

Rose (fresh context, Opus, ~8 min): **7 refuted / 11 survived / 1 untestable here.**

- **Claim B (S2 guard) SURVIVED every attack**: double `multi_start = 1`, bare-list control,
  `optimizer = list(start=)`, every Julia entry point reaches the translator.
- **Claim A (S3 label producer) NOT MET as first shipped**, although all six of its gates read
  green: (A2b, worst) a bare `(1 | g)` reached `model.matrix()`, which parsed `|` as logical OR and
  fabricated the label `1 | gTRUE`, shipped it to DRM.jl, and aborted a supported random-intercept
  bridge fit blaming DRM.jl; (A2) phylo dpars were exempt from the check; (A1, A5) empty labels and
  unlabelled engine blocks passed by vacuity; (A3, A3c) the map path never cross-checked the
  engine's public names against drmTMB's own, so a permutation or invented names were accepted —
  inverting D-202; (A10) the coordinator's `gsub` removal hit live structured-route callers.
- **Action:** S3-G4 ABANDONED with reason; seven new gates (S3-G7..G13) written from Rose's own
  attack scripts before dispatch; repair loop sent to the same producer (fixed-effect-only label
  construction reusing the predict-time helper; map-path cross-check; no-vacuity rule; legacy
  `gsub` restored and scoped; design 258 §7.1/§7.3/§7.4 corrected). Outcome: repaired at f0b7c4da9; my own re-run: 12/13 gates met, S3-G4 abandoned with reason; Rose's A2b/A2 scripts re-run by the coordinator now yield fixed-effect-only labels.
- **Second finding, from the DRM.jl lane's measurement:** the `coef_labels` field was built into the payload but the Julia call carries only formula/family/data/tree/options, so it never reached the engine. Fixed at a17306295 (`options$coef_labels`), tests re-pinned (f0b7c4da9), gate S3-G14 added. Design 258 row 7 corrected to base R's six reduced-coding columns (both lanes measured), which makes DRM.jl#467's failures stale fixture keys, not a missing producer.
- **Lesson recorded:** six green gates measured the tests the producer wrote, not the claim. The
  adversarial verifier is not optional (D-43, D-81).


## 5. Decisions taken (owner) and relayed

Owner, this session (D-202): push all 18 · #1112 first · `cov.fixed` conditioning and unpenalized
`objective_at()` confirmed · base-R naming authority. Relayed by sibling sessions and recorded as
relayed (D-203 by DRM.jl3; gllvmTMB1): one-directional for this arc vs "both ways for user-facing"
as standing rule — a tension left for one sentence from Shinichi; promotion = Rose-scanned draft PR
+ owner merge; Julia half carried by the Claude DRM.jl lane.

## 6. Envelope crossings (disclosed; both reversible, both on unmerged branches)

1. **`R/julia-bridge.R:4400` predict-time `gsub` removed by the coordinator** on the S3 branch
   (5b77eb691), outside the envelope's named hunks, on the premise it was dead code. Rose proved the
   premise false (live structured-route callers). **Restored in the repair (f0b7c4da9)**, scoped as
   the documented legacy path for routes not yet under §7; S3-G4 ABANDONED with that reason. Net
   effect on the tree: none beyond a comment. Lesson kept: a caller census, not a comment, decides
   whether code is dead.
2. **Three child branches pushed** (`integration-post1112`, `c2-label-producer`, `q4-se-receipt`)
   beyond the branches the envelope named. Reason: the DRM.jl lane needed citable SHAs the same
   hour. All are draft-PR-less lane branches; deleting them from origin is one command.

## 7. Not done, and why

- S6 promotion wave 1: held, needs #1112 merged. A4/A5 were built after all (on top of the
  post-#1112 branch, DRM.jl pinned at `dc3ce190`); they stay internal and depend on five DRM.jl
  private names until that lane exposes a supported entry or folds its branch into a merging ref.
- Found by A5, not fixed (A2/A3 lane): `objective_at()`'s label vocabulary does not reach
  `biv_gaussian`'s `rho12` fixed effect or the q4 phylo covariance block (`beta_rho12` carries no
  names; `log_sd_phylo`/`theta_phylo` sit outside `spec$random`); the receipt addresses those by
  internal TMB parameter name. Recorded in the decision map as a limitation.
- Reverse-gap issue list: drafted in the decision map, NOT filed — public posting waits for
  Shinichi's word in this repo's session.
- Board projection of `Non-Gaussian phylogenetic location-scale`: measured as scope-limited
  (nbinom2, zero_one_beta implemented; ten families rejected by design); not yet projected onto the
  board.
- P2–P5 arcs (G3 inference qualification, G4 threading, G5 Totoro grid, G6/G7 docs): untouched,
  each behind its own D-139 gate.

## 8. Risks and open questions for Shinichi

- ANSWERED the same day (D-204): both ways for user-facing; keep the scoped legacy rewrite; reverse-gap
  issues filed as #1115–#1118.
- Merge order stands: #1112 → then replace PR #1114's head with `integration-post1112`.

## 9. Files created / modified (this lane, today)

Repo (all on lane branches, none on main): the five slice branches above; `.unlazy/true-parity/`
(git-excluded run state). Vault: `memory/DECISIONS.md` (D-202), `memory/TWIN-PARITY-SHARED-PAGE.md`,
`memory/AGENT_LOG.md` (two entries). PR #1114 body updated twice.

## 10. Time and routing

Children: 3 Sonnet builds (S2, S3, S4), 1 Sonnet reconcile (S10), 1 Opus adversarial (S9), 1
Explore scout (S0). Wall clock ≈ 5 h. No compute beyond local fits of seconds.

## 11. Handover

LANE: CONTINUE HERE for S6/S7 once #1112 merges; otherwise START A FRESH TASK with:
"Read AGENTS.md and docs/dev-log/handover/2026-09-02-claude-handover.md (rev-parity) plus
docs/dev-log/2026-09-02-true-parity-decision-map.md; #1112 status decides S6/S7."
