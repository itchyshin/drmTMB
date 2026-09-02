```
🎯 GOAL
Solo platform: Claude (this session; PLATFORM read from tools/session_ownership.sh = Claude Code)
Deliverable: drmTMB's half of TRUE R<->Julia parity landed and provable: the 18 rev-parity branches pushed and staged for one PR behind #1112; the coefficient-name contract implemented on the R side (base-R canonical, fail-closed producer); the cross-engine objective wrapper (A4/A5) and the q4 SE-axis receipt built so the last held rows can be promoted; a decision map that says what parity still means and what it never will. Julia-side work is HANDED TO the DRM.jl lane, never edited here.
HEADLINE: the label-map producer (ARC C2). It is the one gap that makes engine="julia" output differ from TMB output for real users, and DRM.jl's construct suite measures it at 1 pass / 6 fail.
IN PARALLEL: push + decision record + draft PR; post-#1112 integration branch with the start/multi_start guard; q4 SE-axis receipt script; findings memo to the DRM.jl lane.
DEFER (fenced): promotion wave 1 (fires only after #1112 merges); A4/A5 (need #1112 + DRM.jl reml_objective_at reachable); P2-P5 arcs (G3 inference qualification, G4 threading, G5 Totoro performance grid, G6/G7 docs) each behind its own D-139 gate; the reverse gap (Julia-only accessors) until the decision map's first ticket is answered; anything touching DRM.jl files; merges, releases, D-164 CRAN hold.
DISCIPLINE: verify=unlazy ledger .unlazy/true-parity/, gate-check --reverify per leaf, Rose adversarial on one passing gate · compute=local only this session (Totoro only for P4, with pre-run + approval) · closure=every leaf gate met or ABANDONED with reason, Melissa reconcile written, handover updated.
```

PREFLIGHT (Shannon, both repos, this session):
- drmTMB: `** FOREIGN LANE ACTIVE (codex) **` — 4 open codex PRs (#1112/#1111/#1110/#1033), 23 lanes live. LANE TAKEN: `claude/rev-parity-*` (own files: `R/objective-at.R`, `R/provenance.R`, `R/check.R`, `R/control.R`, `R/julia-coefficient-labels.R`, `tests/testthat/test-{objective-at,start-contract,stored-gradient,check-conditioning,provenance,coefficient-labels}.R`, `docs/design/258*`, `docs/dev-log/**/2026-09-02-*`). Never the main checkout (on `feat/bridge-lss-reml-row12`, 45 behind).
- DRM.jl: `** FOREIGN LANE ACTIVE (codex) **` — 11 lanes live, newest handover hands to Cursor; two draft PRs (#579 exact REML gradient, #576 scoreboard) from the other overnight Claude session. Shinichi confirms a DRM.jl lane exists. VERDICT: read-only; every Julia item below is `HANDS TO: DRM.jl lane` via `claude/rev-parity-drmjl-findings`.
- Overlap surfaced (D-87): `R/control.R` + `man/drm_control.Rd` between #1112 and `integration-all`. Owner decided: #1112 lands first.

## Sweep receipt (Phase 0.25; every line cites what ran)
- repo git state → `git for-each-ref refs/heads/claude/rev-parity-*` (18 branches, heads match handover; `handover` +1 commit `8fca011f1`); `git ls-remote --heads origin 'claude/rev-parity-*'` = 0; `git worktree list` (13 rev-parity worktrees + ~60 foreign); `gate-check --status --scope rev-parity` = 44 met / 11 unmet (a4 ×4, a5 ×5, b3 ×2, all HELD) → **resume `claude/rev-parity-integration-all`**, nothing to rebuild.
- twin repo → DRM.jl `HEAD f4778964` unmoved (`git log f4778964..HEAD` empty); `python3 tools/parity_ledger.py --drmtmb drmTMB --ref origin/main` = **CLOSURE: PASS**, 12 rows: 10 covered, 1 partial (by design D-179 #3), 1 unsupported (engine_control_surface = #1112's row); 0 drmTMB exports without a twin; 21 Julia-ahead exports accounted for in writing. Row 12 (`location_scale_scale`) flipped by PR #1101 (merged 2026-08-29) → DRM.jl's 2026-08-28 handover step 4 is DONE. `docs/src/capabilities.md:278-281` stale (contradicted by #559) → **co-opt DRM.jl's ledger tool as the closure oracle; hand the stale doc to its lane**.
- sibling lane in drmTMB → PR #1112 worktree `/private/tmp/drmtmb-control-audit`: `2026-09-02-claude-handover-575-fixed.md`, `plan/2026-09-01-parity-programme-estimate.md` (P1-P5, ~92-159 agent-h), `plan/2026-09-01-bridge-promotion-wave1.md` (4 rows ready, q4 deferred on SE receipt), `objective-at-bridge-note.md` (= slice A4 design) → **reuse all three; do not re-plan P1-P5, extend them**.
- brain → MCP `search_notes("drmTMB rev-parity naming authority PR 1112 cov.fixed objective_at push decision", search_all_projects=true)` → no decision on the five questions; deterministic greps: `grep -in parity memory/AGENT_LOG.md` (3 unrelated hits), `grep -n "^### D-1[78]" memory/DECISIONS.md` → **D-179** (six roadmap decisions: gradient 1e-6, response_mask experiment, cross_family permanent boundary, interval fences permanent, #471 deferred, v0.1.0 tag) and **D-181** (mi() fenced for v1.0, intervals permanent-permanent, #471 out, registration open), `grep -in parity memory/OPEN_QUESTIONS.md` = none, `projects/deep-research/README.md` = none → **reuse D-179/D-181 as fixed boundaries; nothing to research externally**.
- Verdict → genuinely new = (1) the label-map producer (both sides half-built), (2) the post-#1112 `start` guard (found this session), (3) the q4 SE-axis receipt, (4) the decision map answering "is parity one-directional?". Everything else is resume-or-reuse.

## WHAT SHINICHI TOLD US (Phase 0.4, this session) — DECISIONS LOCKED
1. Push all 18 `claude/rev-parity-*` branches now; no merge.
2. PR #1112 lands first; this lane rebases onto it and opens one PR after.
3. Confirmed: `obj$he()` removed, conditioning from `sdr$cov.fixed`; `objective_at()` uses the unpenalized `logLik()` convention.
4. Naming authority = base-R spelling (drmTMB canonical; DRM.jl fixtures translate).
5. "Keep going for me"; another session may be pushing the same branches → push only what the remote lacks, never force.
6. "There is a lane for DRM.jl too" → DRM.jl is read-only for this plan.
Record: one vault decision entry (next free number checked at write time; D-199/200/201 exist) + AGENT_LOG line, local commit only (D-37); repo copy `docs/dev-log/2026-09-02-rev-parity-owner-decisions.md`.

## WHAT THE TEAM RAISED
```
TEAM RAISED
  Rose   — the other overnight lane and this one both claim "nothing merged, nothing pushed" while colliding on R/control.R; a silent post-merge regression (start= ignored under engine="julia") already exists · why: it is the exact "silently ignored" class A2 removed · rec: guard lands with whichever branch is second · default: on integration-post1112.
  Boole  — base-R canonical must be produced from model.matrix() names sent in the payload and echoed back, never regex-translated (design 258 §3, row 7 proves order can differ) · rec: fail closed when the engine returns no map · default: abort with the engine name.
  Fisher — "true parity" per the programme = capability + point/SE parity, intervals stay "capability parity, not coverage" (D-179 #4, D-181 #2); a bridge speed number over unmatched optima is not a benchmark · rec: q4 SE receipt before any promotion of q4; P4 only after P2 · default: as the estimate doc sequences it.
  Gauss  — cov.fixed conditioning equals cond(H) to 6 digits and survives readRDS; keep it · rec: no further conditioning design this arc.
  Ada    — extend the existing P1-P5 programme rather than replace it; the new material is C2, the guard, the SE receipt, and the decision map; Julia items hand off.
```

## DECISION MAP (wayfinder; Phase 0.6 said "map" because two slices contained "depends what we decide")

**Destination.** When this effort is done: every capability row admissible under D-179/D-181 is `covered` on the ledger with same-target point AND SE receipts on both engines; the `engine = "julia"` route shows a user exactly the coefficient names TMB shows, verified by DRM.jl#467's construct suite at 7/7; a cross-engine dispute is settled by committed functions on both sides (`objective_at()` in R, `reml_objective_at` in Julia, bridged); the promotion bar (experimental → partial on the bridge axis) has been applied with owner sign-off to every row that has receipts; drmTMB states in one visible place what it does not cover (intervals: capability parity, not coverage; mi(): R-only for v1.0; cross-family: permanent boundary). Releases and registration are separate owner ceremonies (D-164, D-183).

**Decisions so far.** D-179 (six roadmap answers) · D-181 (mi fenced, intervals permanent, #471 out) · D-183 (twin versioning v0.7.0) · this session's four (push; #1112 first; cov.fixed + objective_at convention; base-R naming) · #575 mechanism = FD gradient noise, fixed on DRM.jl #579 (draft).

**Not yet specified (the fog).**
- Is true parity ONE-directional (R workflows → Julia, the programme's definition) or TWO-directional (DRM.jl's `chibar_pvalue`, `lrt_boundary`, `heritability`/`icc`/`repeatability`, `aicc`, coevolution accessors also owed to drmTMB)? `decide-with-Shinichi`. Default if "use your judgment": one-directional for this arc; file the reverse gap as drmTMB issues.
- The `Non-Gaussian phylogenetic location-scale (mu + log sigma)` board row exists in DRM.jl and not on drmTMB's board: implemented, rejected, or unprojected? `task` (ledger read), then decide.
- Promotion authority: is Ada's Rose-scanned draft PR sufficient, or does each row need Shinichi's sentence? `decide-with-Shinichi`. Default: draft PR, owner merges = sign-off.
- Student-t `nu` start labels and `vcov()` abort on `sdreport` failure: widen or record? `decide-with-Shinichi`, not blocking.
- Whether DRM.jl echoes the label map or drmTMB reconstructs it positionally: `research` in the DRM.jl lane's hands (they own `src/bridge.jl`).

**Out of scope (with reason).** Native mixed-family bivariate in TMB (ARC E scout: new integration path; D-179 #3 made the row a permanent boundary) · interval coverage campaigns (D-181 #2) · mi() in Julia (D-181 #1) · `biv_student` structured markers (D-181 #3) · CRAN / Julia General registration (D-164, D-181 #4) · any edit under `/Users/z3437171/Dropbox/Github Local/DRM.jl`.

## SLICE TABLE (this session + the next; Phase 1-2)

| id | slice | member | model+effort | dispatch | time | files / output | dep |
|---|---|---|---|---|---|---|---|
| S0 | RECON (done inline this session: git state, ledger, DRM.jl scout via Explore/Haiku-class, parity_ledger run) | Jason | Haiku low | claude/model | done | this file's sweep receipt | — |
| S1 | Push 18 branches (skip any already on remote, never force); record decisions (vault + repo doc); draft PR from `integration-all` marked "after #1112" | Ada (me) | Fable (session) | inline | 30 min | remote refs; `docs/dev-log/2026-09-02-rev-parity-owner-decisions.md`; PR URL | — |
| S2 | Branch `claude/rev-parity-integration-post1112` = merge(`integration-all`, `90f61f3da`); add `start`,`multi_start` to the unsupported loop in `drm_julia_translate_control()` (`R/julia-bridge.R:693-705` on #1112) + RED test in `test-julia-bridge.R`; run filtered tests | Gauss | Sonnet medium | claude/model, worktree | 45 min | branch + test | S1 |
| S3 | ARC C2 — design 258 addendum (producer contract) + drmTMB half: payload sends per-dpar `model.matrix()` names; `bridge_formula_labels_v1` validated on return; fail-closed abort when absent; RED tests for the 10 constructs with a stub map, then wiring | Boole (design) → Gauss (build) | Sonnet high | claude/model, worktree | 3-4 h | `docs/design/258` §7; `R/julia-bridge.R` payload; `R/julia-coefficient-labels.R`; `tests/testthat/test-coefficient-labels.R` | S1 (lease) |
| S4 | q4 SE-axis receipt: extend `q4-fixture-bridge-parity-v3.R` to compare `vcov()`/SEs same-draw; write receipt | Curie | Sonnet medium | claude/model | 1-2 h (fits are minutes) | `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-q4-se-receipt.md` | needs #1112 worktree scripts (read) |
| S5 | Findings memo to the DRM.jl lane: echo the label map in `drm_bridge` (contract from S3), re-key fixtures, `capabilities.md:278-281` stale, fate of `feat/575-objective-at` | Ada | Fable | inline | 20 min | append to `claude/rev-parity-drmjl-findings` | S3 design |
| S6 | Promotion wave 1 (4 rows experimental → partial) per the prepared plan — FIRES ONLY when #1112 is merged; Rose forbidden-claim scan | Gauss + Rose | Sonnet low + Opus (the one ceiling child) | claude/model | 1 h | `claude/bridge-promotion-wave1` draft PR | #1112 merged |
| S7 | A4 `drm_julia_reml_objective_at()` + A5 pinned-ref receipt — after #1112 and DRM.jl `feat/575-objective-at` reachable | Gauss | Sonnet high | claude/model | 3 h | `R/julia-bridge.R`; `test-julia-bridge.R`; leaf-a4/a5 gates | #1112, DRM.jl |
| S8 | MECHANICAL-VERIFY: `gate-check --reverify` every leaf; remote SHA = local head ×18; PR exists | Rose (mech) | Haiku low | claude/model | 15 min | ledger EVIDENCE lines | S1-S4 |
| S9 | Adversarial: try to break S3's fail-closed path (map missing / reordered / duplicated) and S2's guard | Rose | Opus high (counts as the ceiling child if S6 has not fired) | claude/model | 45 min | refutations in ledger | S3 |
| S10 | RECONCILE plan vs actual | Melissa | Sonnet low | claude/model | 20 min | `docs/dev-log/plan-actual/2026-09-02-true-parity.md` | close |
| S11 | After-task report + handover | Rose | Sonnet medium | claude/model | 30 min | `docs/dev-log/after-task/2026-09-02-true-parity-arc.md`; handover | close |

PARALLEL: {S2, S3, S4} after S1. SEQUENTIAL: S5←S3, S8←S1..S4, S9←S3, S10/S11 last. S6, S7 wait on #1112.
FAN-OUT BUDGET: checkpoint=true-parity-1 · new children ≤5/6 · scout=S0 (done) + S8 · build=S2,S3,S4 · ceiling=1 (S9 or S6's Rose scan, not both without a new checkpoint) · reuse: same Gauss child for S2→S3 repair loops.
SCOUT SUITABILITY: yes — S0 ran (Explore agent), S8 is Haiku.
CONTEXT BRAKE: parent input ≈ large after rehydration; the build slices run in fresh children with self-contained briefs; if this session compacts once, scope freezes to S1-S5.
ESTIMATE: this checkpoint ≈ 5-7 h wall-clock, 5 children, fits one session for S1-S5,S8-S11; S6/S7 are a later session unless #1112 merges today. Programme remainder stays ~92-159 agent-h (estimate doc), unchanged.
MODELS: per row above; session model Fable; Opus used once.
SEARCH: none (no novelty claim; external evidence not needed).
REVIEW (before execution): Rose + Boole critique of this decomposition = the TEAM RAISED block; Rose confirms the sweep receipt is non-vacuous (each line cites its command).

## ACCEPTANCE LEDGER (Phase 2.5; created at `.unlazy/true-parity/` on approval, before any dispatch; `.unlazy/` already git-excluded)

GATES.md OWNS: `R/julia-bridge.R` (payload + translate_control only), `R/julia-coefficient-labels.R`, `R/control.R`, `tests/testthat/test-coefficient-labels.R`, `tests/testthat/test-julia-bridge.R`, `docs/design/258*`, `docs/dev-log/**/2026-09-02-*`. Fences: no DRM.jl edit; no r_bridge_status change outside S6; no merge; no release.

- leaf-s1: G1 remote count — CHECK `git ls-remote --heads origin 'claude/rev-parity-*' | wc -l` EXPECT `18`; G2 every remote SHA equals local head (node script, prints `ALL_MATCH`); G3 PR exists and body contains "after #1112" (`gh pr view --json body`).
- leaf-s2: G1 `drmTMB(..., engine="julia", control=drm_control(start=list(...)))` aborts with the unsupported-setting message (testthat, prints `GUARD_OK`); G2 RED CONTROL: with the two names removed from the loop the same test FAILS (`GUARD_RED_OK`); G3 filtered suite `julia-bridge|start-contract|objective-at` 0 failures.
- leaf-s3: G1 ten constructs from 258 §2 produce base-R public labels through a stub map (`LABELS_10_OK`); G2 absent map aborts naming the engine (`FAIL_CLOSED_OK`); G3 reordered/duplicate raw names abort via the existing validator (`VALIDATOR_OK`); G4 no punctuation-based translation exists (`grep -c 'gsub.*__bridge' R/ = 0`); G5 design 258 §7 committed with the payload field names.
- leaf-s4: G1 receipt file non-empty with SE abs/rel deltas on the same draw (`SE_RECEIPT_OK`); G2 both engines report converged; G3 no promotion edit in this leaf (`git diff --stat -- inst/extdata/julia-capabilities.tsv` empty).
- leaf-s5: G1 findings appended and pushed on `claude/rev-parity-drmjl-findings`; G2 zero DRM.jl working-tree changes (`git -C DRM.jl status --short` = the one pre-existing toml only).
- leaf-s6 (held until #1112 merges): the four rows' `r_bridge_status` = partial with claim_boundary citing receipts; TSVs regenerated by tool, not hand-edited; Rose scan clean.
- leaf-s7 (held): pinned objectives reproduce within 2e-4; pinned SHA missing ⇒ ABANDON not skip.
- Node gates: N1 every leaf reverifies (`--reverify --jobs 1`); N2 filtered suites pass (full suite NOT re-run unless R/ code outside the guard changes — it passed 2026-09-01, ~45 min, D-139); N3 Rose refuted ≥1 passing gate; N4 Melissa file exists.

## Pre-authorisation envelope
```
PRE-AUTHORISED AFTER G0: scoped edits in the OWNS globs; worktree creation (serial); filtered devtools::test runs (minutes);
local commits on claude/rev-parity-* branches; lane lease claim/release; vault local commit for the decision record.
OPTIONAL REMOTE AUTHORITY: push the 18 existing claude/rev-parity-* branches + the new integration-post1112 and
drmjl-findings updates (decided by Shinichi this session); create ONE draft PR from integration-all; never merge.
MUST STOP: merging anything; any DRM.jl edit or PR/issue comment there; promotion edits (S6) before #1112 merges;
full-suite or Totoro runs (>30 min) without a D-139 estimate + approval; any change to R/julia-bridge.R outside the
payload/translate_control hunks; evidence that changes the decision map's destination.
```

## Compute targets (Shinichi, 2026-09-02: "make good use of DRAC + Totoro")
- P2 (G3 profile/bootstrap qualification): Totoro pilots, ≤150 cores, `OPENBLAS_NUM_THREADS=1`; D-139 estimate + pre-run per cell family.
- P3 (G4 threading/determinism): Totoro.
- P4 (G5 warm-workflow grid): Totoro; the designed pre-run (1 cell × 2 engines × 3 reps, <10 min) is under the 30-min line and runs without a separate approval once matched optima exist; the full grid needs the estimate + Shinichi's go.
- Any multi-seed coverage/recovery campaign the reverse-gap or interval work ever needs: DRAC job arrays (nibi 3 d, or trillium — widest and least used), `--time` sized from `seff`, never GitHub Actions (D-50).

## Verification and closure
- Every leaf: `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root <drmTMB> --cwd <worktree> --reverify --jobs 1 .unlazy/true-parity/gates/leaf-<id>.md` — exit 0 required; `--status` is not evidence.
- Full `devtools::test()` only if S3 touches code paths beyond the Julia payload (then: estimate ~45 min first, pre-run `filter="julia"`).
- Melissa reconcile → `docs/dev-log/plan-actual/2026-09-02-true-parity.md`; Rose after-task → `docs/dev-log/after-task/2026-09-02-true-parity-arc.md`; handover updated with LANE: CONTINUE HERE or START A FRESH TASK and the exact resume prompt.
- Reverse-gap items and the two fog decisions are written into the decision map file `docs/dev-log/2026-09-02-true-parity-decision-map.md` (repo) and linked from the vault, so they are asked once, not re-derived.

---
## Overnight envelope (D-208, Shinichi 2026-09-02 evening; verbatim answers)
Merge anything green · priority = label contract for structured routes · Totoro ≤150 cores with pre-run · delete merged branches (done: 17 deleted, 6 unmerged kept).
Arc list for the night: LOOP/arcs.md (N0–N6). Ledger: `.unlazy/night/` in the main repo (git-excluded run state).
