```
🎯 GOAL
Solo platform: Claude (this session, drmTMB2 — the JOINT lane over BOTH repos; the DRM.jl3 session is archived and Shinichi said "continue here with one lane")
Deliverable: TRUE R<->Julia PARITY, stated in Shinichi's words (2026-09-05): "make sure all the models can be run in both, and all the models can be run through engine = julia" — both packages at 0.7.0. Concretely: a three-way matrix (native R × native Julia × engine="julia" bridge) with every drmTMB-native model either GREEN on all three axes with same-target receipts, or carrying a WRITTEN permanent boundary citing the decision that fences it. Then BEYOND: the classified to-do list, in order, until the session ends or he stops it.
HEADLINE: the matrix itself. Nobody has built the cross-join; the DRM.jl parity ledger says CLOSURE: PASS while drmTMB's own bridge TSV has 10 of 12 rows below `covered`. Those two facts are both true and describe different things — the matrix is what makes "parity" one measurable claim instead of two ledgers that each pass.
IN PARALLEL: the matrix build (scout, no Julia); the classified backlog; the machinery inventory (reuse, never rebuild receipts).
DEFER (fenced): anything under Out-of-scope below; Totoro campaigns until their D-139 pre-run; any collaborator message until the D-221/D-222 trigger; CRAN / registration (D-164, D-181).
DISCIPLINE: verify = unlazy ledger per arc, gate-check --reverify, every negative gate red-controlled · compute = local first, Totoro (384 cores, idle, load 0.12, socket LIVE pid 9961) for anything >30 min with a pre-run · closure = every gate met or ABANDONED with reason; checkpoint.md overwritten per arc; LOOP kit on disk so compaction cannot lose the goal.
```

## Context — why now, and why this shape

Shinichi's direction on 2026-09-05, after a full day in which this session and the DRM.jl lane each caught the other's errors: keep going HERE as one lane over both repos, reach true parity, then work the backlog. Method by his preference: ultra-plan for the WHAT, unlazy ledgers for proof, wayfinder for the decisions that are still fog, arc-loop to run it without him.

What today established that the plan rests on:
- The DRM.jl parity ledger (`tools/parity_ledger.py`) reports CLOSURE: PASS — 12 rows, 10 covered, 0 export gaps. But drmTMB's `inst/extdata/julia-capabilities.tsv` has 10 of 12 bridge rows below `covered` (4 partial, 6 experimental). Both are true. The first measures export/capability coverage; the second measures whether the BRIDGE has same-target receipts. "Parity" has never been stated as one matrix.
- Every wrong claim today (six of mine, three relayed) came from reasoning about a repo or interface not in front of the session. One lane over both repos removes that surface by construction — D-220 already did this for the gllvmTMB twin.
- The receipts survive because the pin's identity is committed (`e0a65f96b` inside the tip-identity receipt on main). The other lane lost 28 gate files to a /private/tmp purge. Everything durable in this plan lives in the repos or ~/local-scratch, never /tmp.

## Preflight (Shannon, both repos, 2026-09-05)
- drmTMB: FOREIGN LANE ACTIVE (codex) — but the 3 codex PRs (#1111, #1110 docs; #1033) last moved 2026-09-01 / 08-15: DORMANT, not live. 16 duplicate design-number slots (178, 179, 145) — hygiene item, not blocking. LANE TAKEN: `claude/parity-*` on drmTMB.
- DRM.jl: FOREIGN LANE ACTIVE (codex) — codex branches last committed 2026-09-02: DORMANT. The Claude DRM.jl3 lane is ARCHIVED (Shinichi, accidental; he chose not to revive). Its LOOP kit survives at `~/local-scratch/lanes/DRM.jl-overnight-20260902/LOOP/` and its handover is on main. LANE TAKEN: `claude/parity-*` on DRM.jl. **Standing "never edit DRM.jl" is LIFTED by the one-lane decision** — recorded here as the assumption; every DRM.jl edit still goes through a PR merged on green.
- Overlap: none live. The dormant codex branches are left untouched (decide-with-Shinichi whether to close them; not blocking).

## Sweep receipt (Phase 0.25)
- repo git state → drmTMB origin/main @ e455fa135+ (v0.7.0 tag d7eb81fe7; #1159 #1161 merged today); DRM.jl origin/main @ 430ef64cc (#632 #633 #636 #637 merged today). `gh pr list` both repos: nothing of ours open. → nothing to resume; everything landed.
- twin repo → `python3 tools/parity_ledger.py --drmtmb drmTMB --ref origin/main` = CLOSURE: PASS, 12 rows [10 covered · 1 partial · 1 experimental], 0 export gaps, 37 Julia-ahead exports accounted for. → co-opt as ONE of two oracles; the drmTMB TSV is the other.
- brain → D-179 (six roadmap boundaries), D-181 (mi() fenced v1.0; intervals capability-not-coverage; #471 out), D-204 (BOTH WAYS for user-facing capabilities is the STANDING rule), D-213 (four owner answers 2026-09-03: summary rename; q4_vcov OPT-IN; all four follow-ups; one-directional was that ARC's scope), D-220 (gllvmTMB twin → one Cursor lane — the precedent), D-221/D-222 (one collaborator message when fixed; direct instruction overrides). `grep -in parity memory/AGENT_LOG.md` → today's entries only. → reuse all as fixed boundaries.
- prior plans → `docs/dev-log/plan/2026-09-01-parity-programme-estimate.md` (P1–P5, 92–159 agent-h; P1 partly banked by promotion wave 1 + today's REML/gate work), `docs/dev-log/2026-09-02-true-parity-decision-map.md` (destination now largely MET; fog mostly closed), DRM.jl #563 (S1–S17; handover §3/§4 list owed decisions + NOT COVERED). → EXTEND, do not re-plan.
- Verdict → genuinely new: (1) THE MATRIX, (2) classifying the 10 sub-covered rows into finishable vs permanent, (3) the reverse gap ports #1116/#1117/#1118 (#1115 heritability is DONE — closed, 3/3 exported), (4) P2–P4 inference/threading/performance qualification on Totoro. Everything else is resume-or-reuse.

## THE MATRIX (scout result, 43 drmTMB-native capabilities, every cell cited to a file:line)

Sources: native_R = drmTMB `docs/design/capability-status.md`; native_Julia = DRM.jl `docs/design/capability-status.md` (NOT `capability-manifest.md`, which is a 751-row structural denominator of the R surface and carries no Julia statuses); bridge = drmTMB `inst/extdata/julia-capabilities.tsv` (12 route rows) + `R/julia-bridge.R:884-912` `drm_julia_family_tag()` (the admission list).

**Headline numbers.** 43 R-native capabilities. DRM.jl fits **40** of them natively (ahead of R on 8 more). The bridge has a ledger row for **12 routes**; **15 R-native capabilities have NO bridge route at all**. On the `r_bridge_status` axis **0 of 12 rows reach `supported`** (max is `partial`).

### The engine="julia" gap (List A) — what "all models through engine=julia" actually means
| group | capabilities | why blocked | cost shape |
|---|---|---|---|
| A1 · 9 families refused outright by `drm_julia_family_tag()` (`R/julia-bridge.R:908-911`) | ZIP, ZINB, truncated NB2, hurdle NB2, cumulative logit, beta-binomial, zero-one-inflated beta, Tweedie, skew-normal — **all `implemented` natively in BOTH R and Julia** | the bridge refuses to marshal them; only beta-binomial even has a gate row (`julia-gates.tsv:7`); the other 8 are SILENT gaps with neither a capability row nor a gate row | per family: admit in the tag map + payload/labels for that family's dpars + one same-target receipt. The engine already fits each. |
| A2 · 3 ordinary random effects | Gaussian `(1\|g)` mean, random slope, RE on sigma | no TSV row; f1 added two pre-Julia refusals for sigma-bar+REML and mu-bar+sigma-bar (after-task 2026-09-03-f1) | receipts + rows; DRM.jl fits `(1\|g)`; slope and sigma-RE need checking against DRM.jl's admitted set |
| A3 · bridge-side inference | profile CIs, bootstrap CIs | the G3 fence — repeated VERBATIM in 4 TSV rows: "bridge-side inference … remains unqualified (G3)" | ONE piece of work (P2) unblocks 4 rows at once |
| A4 · mi() | missing-predictor imputation | D-181 fence, reaffirmed D-209 | PERMANENT for v1.0 — write, don't build |
| A5 · admitted but UNLEDGERED | Student-t, LogNormal, FE Gamma/Poisson/NB2/Beta | routed at `R/julia-bridge.R:887-897`, zero TSV rows; FE parity numbers parked inside `plain_binomial_nonphylo`'s next_action | rows + receipts only — the code works today |

### The R→Julia gap (List B) — nearly closed
Only 3: missing-response FIML (#49, DRM.jl says "explicitly out of scope", size L), mi() (D-181 fenced), cross-family (planned on BOTH sides; D-179 #3 permanent). **Everything else R fits natively, DRM.jl fits natively.**

### Bridge rows below the top (List C)
- claim_status axis: only 2 below `covered` — `cross_family_latent` (PERMANENT, D-179 #3) and `engine_control_surface` (next_action "design engine_control explicitly" — finishable; AMBIGUOUS because row 10 cites it as the permanent-boundary template).
- r_bridge_status axis: 12/12 below `supported`. **4 rows blocked on the same G3 receipt** (base_gaussian_location_scale, biv_gaussian_residual, gaussian_response_mask, plain_binomial_nonphylo). **1 on a q4 same-target SE receipt** (biv_q4_phylo_reml). **5 maintenance-only** ("interval_status does not move without a coverage campaign") — a coverage campaign is the named finishable price, and D-181 #2 says intervals are capability-parity-not-coverage → these 5 stay where they are BY DECISION.

### Findings the matrix surfaced (each is a plan item)
1. drmTMB's row-count join verification is STALE: says 46 DRM.jl rows / 3 DRM.jl-only; today it is 47 / 4 — the new row `Tweedie random intercept (mean)` (#563 S8) IS a model capability, so R's "algorithm choices, not capabilities" rationale no longer covers it.
2. NAMING TRAP: `phylo_gamma_beta_binomial` = Gamma/Beta/**Binomial**, not beta-binomial. A string-match reader marks beta-binomial covered when it is explicitly refused.
3. `claim_status = covered` co-occurs with `r_bridge_status = experimental` on 6 rows (TSV 4,6,7,8,9,13) — "native-engine-vs-native-engine via JuliaCall, NOT the R bridge". Anything reading only claim_status over-reports bridge coverage by 6 rows. **This is the mechanism behind "two ledgers that each pass."**
4. The design-168 CI guard fails when a REJECTION lacks a registry row but NOT when an ADMISSION lacks one — which is how A5 stayed invisible.

## THE BACKLOG (scout result: 80 open issues, every one classified; sizes S ≤2h · M ≤1d · L multi-day)

Totals: **P parity-blocking = 17** (7 drmTMB, 10 DRM.jl) · **U user-facing port = 3** · D debt = 27 · O out-of-scope/deferred = 33.

**Reconciled against TODAY's merges** (the scout read issue text that predates them):
- #1142 ↔ DRM.jl #624 (REML estimator parity): the drmTMB HALF LANDED today — refusal (#1149), gate widened on measurement + engine-authority cross-check (#1155); DRM.jl delivered #625 (estim_method). REMAINING: the per-route REML table "in one table", mean-only phylo REML (#624 item c), the q4_vcov-on-REML question (D-213 #2 answered: OPT-IN). → downgraded from L to M.
- #1146 (marker-LHS guard at pin 77513aa0): the pin is now **e0a65f96b**, which carries #621's refusal, so the silent mis-fit is no longer reachable. The R-side guard becomes defence-in-depth, not a blocker. → S, no longer first.
- DRM.jl #620: refusal landed (#621, in our pin); the TWO-SD implementation is the owed part. → M, stands.
- DRM.jl #627: #630 (gradient O(n+G)) and #633 (data race) MERGED today; Ayumi's diagnostic script sent. → stays open only for her real-tree run; nothing to build until her number returns.
- DRM.jl #569 ↔ #1108 (route-aware diagnostics): #632 exposed the stored gradient today. → partly closed; the drmTMB consumer side remains.

### P bucket, recommended order (scout's order, with today's reconciliation applied)
| # | item | size | why here |
|---|---|---|---|
| 1 | **A1: admit the 9 refused families through the bridge** (ZIP, ZINB, trunc-NB2, hurdle-NB2, cumlogit, beta-binomial, ZOI-beta, Tweedie, skew-normal) | M each, 9× | BOTH engines fit them natively; the bridge alone refuses. This is the largest single chunk of "all models through engine=julia" and it is not on ANY tracker — the matrix found it. |
| 2 | DRM.jl #467 + #609 factors case | L + M | `factor()` contrasts / `I()` / `poly()` / `^` refused by the bridge — design-matrix disagreement poisons EVERY route's point parity; belongs before receipts, not after |
| 3 | DRM.jl #606 ↔ #1129 — the non-Gaussian precision bar | decide-with-Shinichi, then M | 1.0015e-5 measured vs 4e-6 programme bar; the handover asks the owner to SET the bar before optimizer engineering. `imputed()` off 8.6e-4 is the Gaussian sibling. |
| 4 | DRM.jl #609 varying-scale g_tol | S (handover-sized) | diagnosed, "ran out of night" |
| 5 | A2: ordinary RE rows + receipts (`(1\|g)`, slope, sigma-RE) | M | no TSV row today; DRM.jl fits `(1\|g)`; slope/sigma-RE admission must be MEASURED against DRM.jl (#624's own enumeration says REML only for `(1\|g)`) |
| 6 | #1156 profile_targets discoverability · #1144 ordinal cutpoint polish | S + S | accessor/interval mismatches; P2 territory |
| 7 | **P2 — G3 bridge-side inference qualification** (profile + bootstrap, per route, small convergent cells) | L, Totoro pilots | ONE piece of work that unblocks 4 TSV rows at once; D-139 pre-run per cell family |
| 8 | DRM.jl #620 two-SD Gaussian phylo slope | M | a model drmTMB fits that DRM.jl cannot |
| 9 | DRM.jl #471 structured markers for biv Student/LogNormal | L | after the `cells.tsv` census confirms drmTMB fits them (D-179 #5 deferred past v0.1.0 — check the fence still applies) |
| 10 | DRM.jl #495 q4 Wald coverage 0.827→1.000 | L, UNSIZED | handover: "flagged for an owner call before sizing" — do NOT budget until called |
| 11 | #555 / #570 / #627 — the 10k-tip real workflow | L | scale last; waits on Ayumi's number and #627's real-tree run |

### U bucket (D-204: both ways for user-facing) — all M, all drmTMB, all independent
#1116 `chibar_pvalue()`/`lrt_boundary()` · #1117 `aicc()` + anova/lrtest/weights · #1118 coevolution accessors. (#1115 heritability DONE.)

### Gating D items — not parity, but a green run proves nothing until they land
#1083 (parity test turns ERRORS into skips) · #1081 (0% bridge-glue coverage in CI) · #1150 (receipt checks not in CI). **These three go FIRST**, before any receipt is trusted.

### The three largest L items and their deferral status
1. The programme itself (#563 / #499) — NOT deferred; it IS the destination; 92–159 agent-h.
2. FIML #49 — deferred twice, in writing, "needs its own multi-slice arc"; genuinely parity-shaped (DRM.jl listwise-deletes where drmTMB fits) → **OUT for this effort, by the handover's own deferral; revisit when 1–11 are done.**
3. VA/EVA revival (#496 + #932–#936) — "CLOSED, not deferred … Post-0.7 … Do not start this first" → OUT.

### Mirror pairs (so one fix closes both)
#1142↔#624 · #714↔#327 (duplicate text) · #1146↔#620/#621 · #1129↔#606 · #1108↔#569 · #499↔#563 · #555↔#627 · #1148 is NOT #627 (explicitly different cause) · #1150~#473 (thematic) · #962/#963~#49 (thematic).

## THE MACHINERY (scout result — reuse verbatim, rebuild nothing)

| need | tool that already does it | command | live Julia |
|---|---|---|---|
| **promotion gate** — same-target coef+logLik, tol 1e-4 | DRM.jl `tools/parity_fixture.R` → `parity-fixtures.tsv` | `DRM_JL_PATH=<pin> Rscript tools/parity_fixture.R` | yes |
| SE axis, rtol 1e-3, with in-band negative control | DRM.jl `tools/parity_se.R` → `parity-se.tsv` | same pattern | yes |
| the TSV rows | **generated** by `tools/write-julia-capability-comparison.R` from `drm_julia_capability_comparison()` in `R/julia-bridge.R` — NEVER hand-edited; new rows = edit that function | `Rscript tools/write-julia-capability-comparison.R` | no |
| the gate registry (intentional rejections) | `tools/write-julia-gate-registry.R` → `julia-gates.tsv` | same | no |
| capability ledger integrity | `tools/capability_ledger.py --check` + `tools/check-capability-runtime.R` + `tools/tests/test_capability_ledger.py` | as named | no |
| whole-file receipts | `run-julia-phylo-labels-public.R` + `check-julia-phylo-labels-receipt.R --current --self-test` (pins EVERY R/*.R + every DRM.jl src/*.jl + drmjl_ref); `recertify-c17.py` | as named; regenerate LAST | yes / no |
| export-surface reconciliation | DRM.jl `tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main` (reads via `git show`, never the working tree) | as named | no |
| G3 pipeline check (NOT coverage) | drmTMB `tools/parity-p2-pilot.R --local-prerun / --full-pilot` | as named | yes |
| acceptance ledger | unlazy `gate-check.mjs --root <drmTMB> --cwd <slice worktree> --reverify` | as named | per leaf |
| merge on green, refuse on red | `.unlazy/followup/bin/merge-if-green.sh <PR>` (+ today's DRM.jl variant with the vacuity guard) | as named | no |
| lane kit template | `~/local-scratch/lanes/DRM.jl-overnight-20260902/LOOP/` incl. **`source-pins.json`** {drmjl_base, drmtmb_base, julia_manifest_sha256} | copy the shape | — |

**Design 168's four limbs** (the `covered` definition, `docs/design/168:19-20`): (1) implementation, (2) focused tests, (3) public documentation, (4) relevant diagnostic or interval evidence. Every promotion enumerates them in that order. **Two axes, never conflate**: `r_bridge_status` (evidence) vs `claim_status` (CRAN-facing governance).

**Hard constraints the machinery imposes:**
- **Totoro cannot run the bridge.** `JuliaCall::julia_setup()` segfaults (exit 139) embedding Julia into Totoro's R 4.5.3, all variants tried (p2-pilot prerun receipt, ABANDONED). → all `engine="julia"` work is LOCAL. Totoro is for native-R campaigns and native-Julia suites only.
- **`reverify-all.sh` hardcodes THIS session's scratchpad** — fine while we stay here; a different session gets `NO_LEAF_RE_RUN` (correct failure, not a false pass).
- Every public receipt ships a paired checker with `--self-test` that mutates the receipt and requires each mutation to fail. Keep that convention for every new receipt.
- Totoro's `run_suite.sh` is NOT version-controlled (lives only at `~/s7b_work/` on Totoro). Vendor it into DRM.jl `tools/` in arc 0.

**STALENESS THAT CHANGES THE PLAN:** the pin `e0a65f96b` is **18 commits behind DRM.jl main `430ef64cc`**. Three matter: #630 (gradient O(n+G) — every timing receipt now pessimistic), **#631 (profile endpoints — changes NUMBERS; any interval-parity receipt at the old pin is suspect)**, #632 (bridge forwards options + exposes gradient — touches `drm_julia_translate_control`). → **Arc 0 is a re-pin, repeating f7's protocol.** Two older baselines must not be read as the pin: `.unlazy/rev-parity/drmjl-baseline.txt` (f4778964) and the DRM.jl LOOP `source-pins.json` (f4778964).

---

## WAYFINDER — the decision map (4 sections, in this order)

### Destination
When this effort is done: **the matrix is green.** Every one of the 43 drmTMB-native capabilities is either (a) fit natively in R, fit natively in Julia, AND reachable through `engine = "julia"` with a same-target coef+logLik receipt (tol 1e-4) and an SE receipt (rtol 1e-3) at a committed pin — or (b) carries a WRITTEN permanent boundary naming the decision that fences it, in one visible place. The matrix itself is a committed, regenerable document, and the two ledgers that "each pass" are joined by it. Then: the P/U backlog worked in the order above until it is empty or Shinichi stops it. Releases, tags, CRAN, registration, and collaborator messages are separate owner ceremonies (D-164, D-181 #4, D-221/D-222).

### Decisions so far (fixed; cite, don't re-litigate)
D-179 #1–#6 (gradient 1e-6; response_mask experiment; cross_family PERMANENT; interval fences PERMANENT; #471 deferred past v0.1.0; v0.1.0 tag rule) · D-181 (mi() fenced v1.0; intervals = capability parity NOT coverage; #471 out; registration open) · D-183 (twin versioning 0.7.0) · D-203/D-204 (both ways for user-facing = STANDING; engine-internal accounted in writing; bridge stays one-way R→Julia) · D-209 (merges on green; Totoro caps) · D-213 (summary rename; q4_vcov OPT-IN; four follow-ups; one-directional was that arc only) · D-220 (one lane per twin — precedent) · D-221/D-222 (one collaborator message when fixed; direct instruction overrides; relay is not authority) · today: REML refuses (#1149), gate widened on measurement with engine authority (#1155), pin e0a65f96b (f7), v0.7.0 released, **"continue here with one lane"** (Shinichi 2026-09-05) which LIFTS the never-edit-DRM.jl fence.

### Not yet specified (the fog) — each a ticket; default applies if he says "use your judgment"
| ticket | kind | default |
|---|---|---|
| The non-Gaussian precision bar: measured 1.0015e-5 vs the programme's 4e-6 (DRM.jl #606 ↔ #1129). Fix by optimizer engineering, or accept and document? | decide-with-Shinichi | **accept 1e-5 as the non-Gaussian bar, document it, keep 4e-6 for Gaussian** — the handover's own reading is "optimizer/tolerance engineering, not an oracle re-run"; D-139's usability-first rule says an accuracy gain that costs a week loses by default |
| The 5 "maintenance-only" TSV rows (interval_status frozen "without a coverage campaign") — confirm they stay by D-181 #2 | decide-with-Shinichi | they STAY; write the boundary into the matrix, spend nothing |
| DRM.jl #495 (q4 Wald coverage 0.827→1.0) — the handover says "owner call before sizing" | decide-with-Shinichi | **OUT of this effort** (it is a coverage campaign; D-181 #2) |
| D-179 #5 deferred #471 (biv Student/LogNormal structured markers) "past v0.1.0" — DRM.jl is at 0.7.0; does the fence still hold? | decide-with-Shinichi | still deferred; the `cells.tsv` census (handover UNSURE 3) is the prerequisite either way — run the census (task), decide after |
| The 6 dormant codex branches (3 per repo, last moved 2026-09-01/02): merge, close, or leave? | decide-with-Shinichi (not blocking) | leave; list them in the handover |
| Which of A2's three ordinary-RE shapes does DRM.jl actually fit? (#624's enumeration admits REML only for `(1\|g)`; ML support for slope and sigma-RE is unmeasured) | task | measure with the #625 `estim_method` oracle in arc 4 before writing any row |
| `engine_control_surface` row: finishable (next_action) or permanent (row 10 cites it as the template)? | task → decide | draft the narrow contract from #1108 (core already banked by #1112), then he decides whether it closes the row |
| The Ayumi real-tree number (root-to-tip spread vs 1.49e-8 × height) | external — waits on her | when it arrives it either closes #627 or reopens it; nothing to build before |

### Out of scope (with the reason)
FIML #49 — deferred twice in writing, "needs its own multi-slice arc" (revisit after the P list) · VA/EVA #496 + #932–936 — "CLOSED, not deferred … post-0.7" · cross-family bivariate — D-179 #3 PERMANENT · mi() in Julia — D-181 #1 · interval COVERAGE campaigns incl. #495 — D-181 #2 · CRAN / Julia General registration — D-164, D-181 #4 · the 33 O-bucket issues (parked/idea/post-0.7 by their own text) · any message to Ayumi outside the D-221 trigger · any release or tag.

---

## ARC PROGRAM (the arc-loop list; each arc = one unlazy leaf; reversible arcs run unattended)

| arc | slice | who | model·effort | est | compute | files (OWNS, disjoint) | gate before |
|---|---|---|---|---|---|---|---|
| **A0** | **RE-PIN** to DRM.jl `430ef64cc` (f7 protocol: probe clone, Project.toml identical → copy Manifest, PRECOMPILE, full 37-file sweep, convert any expected breakage, regenerate tip-identity receipt LAST; vendor Totoro `run_suite.sh` into DRM.jl `tools/`; write `source-pins.json`) | Gauss | Sonnet high | 2 h | local | drmTMB: tests/testthat/test-julia-*.R (only if a breakage), evidence/lss-tip-identity, NEWS; DRM.jl: tools/run_suite.sh | none |
| **A1** | **CI trust**: #1083 (errors→skips), #1081 (0% bridge glue), #1150 (receipt checks in CI, detect-not-regenerate) | Grace | Sonnet medium | 3 h | local | .github/workflows/*, tests/testthat/test-julia-tmb-parity.R (the Route-C skip), tools/ (a receipt-staleness CI script) | A0 |
| **A2** | **THE MATRIX as a generated artefact**: `tools/write-parity-matrix.R` joining drmTMB capability-status × DRM.jl capability-status × TSV × gate registry → `docs/design/parity-matrix.md`; fix the stale 46→47 join (Tweedie RE row); rename-guard for the `phylo_gamma_beta_binomial` trap; a test that fails when an ADMITTED family lacks a TSV row (closes finding 4) | Ada→Boole | Sonnet high | 4 h | local | tools/write-parity-matrix.R, docs/design/parity-matrix.md, docs/design/capability-status.md (join section), tests/testthat/test-parity-matrix.R | A0 |
| **A3** | **A5 rows**: ledger the 6 admitted-but-unledgered routes (Student-t, LogNormal, FE Gamma/Poisson/NB2/Beta) — rows via `drm_julia_capability_comparison()` + `parity_fixture.R`/`parity_se.R` receipts each | Curie | Sonnet medium | 4 h | local | R/julia-bridge.R (comparison fn only), DRM.jl evidence/parity-*.tsv | A0, A2 |
| **A4.1–A4.9** | **ADMIT THE 9 REFUSED FAMILIES** through the bridge — one leaf per family, in this order (cheapest payload first): Tweedie, skew-normal, ZOI-beta, beta-binomial, ZIP, ZINB, trunc-NB2, hurdle-NB2, cumulative logit (ordinal last: cutpoints + #1144). Each: family tag admission (`drm_julia_family_tag`), dpar payload + coef_labels (design 258 contract), the four limbs, `parity_fixture.R` + `parity_se.R` receipts, TSV row, RED control (refusal restored → test fails) | Gauss ×3 parallel children on disjoint families | Sonnet high | 9 × ~5 h ≈ 45 h; **~2 days wall with 3 children** | local | R/julia-bridge.R (family-scoped hunks — coordinate via OWNS by function), tests/testthat/test-julia-family-<f>.R (new per family), docs/design/258 §8 addendum | A0, A2, A3 (rows exist first) |
| **A5** | **A2 ordinary RE**: measure DRM.jl's ML/REML support for `(1\|g)`, slope, sigma-RE with the estim_method oracle; rows + receipts for what verifies; written boundary for what doesn't | Curie | Sonnet medium | 4 h | local | R/julia-bridge.R (comparison fn), evidence | A0 |
| **A6** | DRM.jl **#467 + #609 factors**: `factor()`/`I()`/`poly()`/`^`/`-` through the bridge with R-contrast fidelity; this poisons every route's design matrix if wrong, so it precedes A7 | Gauss (DRM.jl side) + Boole (contract) | Sonnet high | 1.5 d | local | DRM.jl src/bridge.jl (formula parsing), src/formula.jl; drmTMB R/julia-bridge.R payload (model.matrix names — design 258) | A0 |
| **A7** | **U ports**, three independent leaves: #1116 chibar/lrt_boundary, #1117 aicc + anova/lrtest, #1118 coevolution accessors — port from DRM.jl (it has them), same-target tests vs the Julia originals | Gauss ×3 parallel | Sonnet medium | 3 × 6 h | local | R/lrt-boundary.R, R/model-comparison.R, R/coevolution-accessors.R (new files each) + tests + NAMESPACE + man | A0 (independent of A4) |
| **A8** | **P2 — G3 bridge-side inference qualification** (profile + bootstrap through engine="julia", per route, small convergent cells, boundary honesty on unbounded endpoints; this is what unblocks 4 TSV rows at once) | Curie + Fisher review | Sonnet high + Opus (Fisher) | 2 d | **local only** (Totoro segfaults on JuliaCall); D-139 estimate per cell family, cells ≤30 min | tools/parity-p2-pilot.R (extend), evidence/p2-*, TSV rows 2/3/5/12 promotion partial→supported | A0, A1, A6 |
| **A9** | remaining P: DRM.jl #620 two-SD slope (M) · #609 varying-scale g_tol (S) · #1156 profile_targets union (S) · #1144 cutpoint polish (S) · #569/#1108 route-aware diagnostics consumer (M) | Gauss | Sonnet medium | 2 d | local | per issue | A0 |
| **A10** | **P4 — warm-workflow performance grid**: native R (Totoro) + native Julia (Totoro, vendored run_suite) + bridge (LOCAL); the designed pre-run (1 cell × 2 engines × 3 reps <10 min) runs first; full grid only after the pre-run receipt + Shinichi's go | Curie | Sonnet medium | pre-run 1 h; grid ≤3 h Totoro | Totoro ≤150 cores, BLAS pinned; **D-139 GATE** | DRM.jl tools/warm_timing*, evidence/warm-workflow-registry | A8 (matched optima first — a speed number over unmatched optima is not a benchmark) |
| **A11** | **P5 closure**: regenerate the matrix; scoreboard; capability-status join; NEWS on both; the handover; Melissa plan-vs-actual; Rose after-task | Rose + Melissa | Sonnet medium | 4 h | local | docs/ both repos | all |

PARALLEL: A1 ‖ A2 ‖ A3 after A0 · A4.x three-at-a-time on disjoint families · A7's three leaves ‖ A4 · A5 ‖ A6. SEQUENTIAL: A0 first, alone · A8 after A6 · A10 after A8 · A11 last.
FAN-OUT BUDGET: checkpoint per arc; ≤4 live children; one Opus child total (Fisher on A8); reuse a child across A4.x repairs.
ESTIMATE (D-139): **~9–12 working days of lane time**; A4 dominates (≈45 agent-h). Nothing over 30 min runs without its own estimate line in the leaf; A10 is the only Totoro campaign and is gated.
MODELS: session = Fable; children Sonnet; Opus once. SEARCH: none (no novelty claim; the tools exist).

---

## ACCEPTANCE LEDGER (unlazy; `.unlazy/parity/` — created on approval, before any dispatch)

GATES.md OWNS: both repos, on `claude/parity-*` branches; node gates: N1 every leaf `--reverify` in its own worktree; N2 `parity_ledger.py` = CLOSURE PASS at the new pin; N3 `write-parity-matrix.R` regenerates byte-identically from committed inputs; N4 Rose refutes ≥1 passing gate per arc; N5 every negative gate has a red control recorded. Fences: no DRM.jl edit lands except via PR merged on green; no collaborator message; no tag/release; no coverage campaign; never `--admin` unless `src/` is byte-identical to the base (today's rule).

Per-leaf pattern (from leaf-f7): `WORKTREE:` · `OWNS:` · `Scope:` · gates with `CHECK:`/`EXPECT:` success-only markers · `EVIDENCE:` with verbatim numbers · RED CONTROL as its own gate · "scope held" gate diffing `-- R src` against origin/main · receipt regenerated LAST · PR merged green.

A4.x leaf template (the one that repeats 9×): G1 RED — the family currently REFUSES (`drm_julia_family_tag` abort quoted) · G2 admitted + payload builds (no Julia) · G3 `parity_fixture.R` same-target coef+logLik ≤1e-4 at the pin · G4 `parity_se.R` SE rtol ≤1e-3 with the negative-control row reading SE_FAIL · G5 coef_labels echo validates (design 258) · G6 TSV row generated, `capability_ledger.py --check` green, the new admitted-needs-row test green · G7 RED CONTROL — admission reverted, G3 fails · G8 scope held · G9 tip-identity receipt regenerated LAST · G10 PR merged green.

---

## PRE-AUTHORISATION ENVELOPE (G0 = this approval)
```
PRE-AUTHORISED: scoped edits in both repos on claude/parity-* branches; worktrees (serial); filtered devtools::test / Julia test runs (minutes); local live-bridge runs (each ≤30 min, estimate stated in the leaf); PRs on both repos; MERGE ON GREEN on both repos (D-208/D-209 precedent, today's practice); local vault commits; the A10 PRE-RUN (<10 min) on Totoro over the live socket, ≤150 cores, BLAS pinned.
MUST STOP FOR: the A10 full grid (D-139: pre-run receipt + explicit go); any fog ticket marked decide-with-Shinichi when its default would be irreversible; any tag, release, CRAN or registration step; any message to Ayumi or any collaborator (D-221/D-222); `--admin` merge where src/ differs from base; anything that reopens D-179/D-181; a genuine surprise that invalidates this plan (→ back to G0, not improvised).
```

## THE 24-HOUR BURN (Shinichi, 2026-09-05: usage resets in ~24 h; "burn it" on drmTMB/DRM.jl; ULTRACODE; Totoro + DRAC + cloud; target 0.7.1)

**This overrides the arc timing above, not the arcs, the gates, or the fences.** Same destination; maximum parallel throughput; nothing irreversible without the owner.

**Reading confirmed by the owner's words:** "ultra cold paralleling" = ULTRACODE — explicit opt-in to multi-agent orchestration (Workflow tool). Fan-out guideline raised from ≤15 to what the dependency graph allows, because the owner asked for that scale in his own words.

### Why A4 is the burn's centre of mass
A4 (admit the 9 refused families) is ≈45 agent-h and every family is independent of every other — it is the single largest parallelisable chunk, and it is EXACTLY "all the models through engine=julia". One serial risk: all nine touch `R/julia-bridge.R`. → **A0.5 (new, serial, 1 h): split the family admission into per-family files** (`R/julia-family-<f>.R`, one function each, dispatched from `drm_julia_family_tag()`), so nine children own nine disjoint files. Small refactor, huge unblock.

### Schedule (wall-clock hours from approval)
| hours | phase | what runs | parallelism | where |
|---|---|---|---|---|
| 0–2 | **FOUNDATION** (serial) | A0 re-pin to 430ef64cc (f7 protocol, full sweep, receipt last) → A0.5 per-family file split → `.unlazy/parity/` ledgers + LOOP kit + `source-pins.json` committed | 1 (me + 1 child) | local |
| 2–14 | **THE FAN-OUT** (ultracode workflow) | A4.1–A4.9 (9 families) ‖ A7.1–A7.3 (3 U ports) ‖ A1 (CI trust) ‖ A2 (the matrix) ‖ A3 (6 unledgered rows) ‖ A5 (ordinary RE) ‖ A6 (factors/#467) — **17 leaves**, each its own worktree + branch + leaf ledger + PR; an INTEGRATOR merges on green in dependency order (A3 rows before A4 rows; A2 last so it regenerates over everything) | up to 12 live children (3 Opus reviewers rotate as Rose) | local (bridge) · native-Julia suites on Totoro via vendored run_suite · native-R full `devtools::test()` per PR on **cloud/remote sessions** so 17 CI-equivalents do not queue on GitHub |
| 14–20 | **QUALIFICATION** | A8 G3 inference (local, D-139 per cell family) ‖ A9 remaining P (#620, #609, #1156, #1144, #569) ‖ A10 PRE-RUN on Totoro (<10 min) → if the pre-run receipt is clean, the full grid runs under the standing cap (≤150 cores, ≤3 h) — **the one owner gate: I will ask before the full grid** | 6 | local + Totoro |
| 20–24 | **CLOSURE + 0.7.1 PREP** | A11: matrix regenerated, scoreboard, capability-status join, NEWS on both repos, DESCRIPTION → 0.7.1 (**PREPARED, NOT TAGGED** — tagging stays the owner's), Melissa reconcile, Rose after-task, handover with RESUME line; the pin recorded in `source-pins.json` and the tip-identity receipt | 3 | local |

### Compute routing for the burn (D-139 / D-50 / D-64 / D-143)
- **Bridge (engine="julia") work: LOCAL ONLY.** Totoro's R segfaults on JuliaCall (measured, ABANDONED receipt). No exceptions.
- **Totoro** (384 cores, load 0.12, socket live): native-Julia full suites per DRM.jl PR (vendored `run_suite.sh`), the A10 native-R and native-Julia timing grid, ≤150 cores, BLAS pinned, ≤3 h per campaign.
- **Cloud / remote sessions** (`Agent isolation: "remote"`): drmTMB full `devtools::test()` + `R CMD check` per fan-out PR, so local CPU stays free for the bridge work and GitHub's 4-shard queue is not the bottleneck. If a remote env lacks Julia, it runs the no-Julia lane only — which is what CI runs anyway.
- **DRAC**: NOT used. Nothing here is a multi-seed coverage campaign (D-181 #2 fences those out), and job-array turnaround is hours — wrong tool for a 24 h burn. Named so it is not re-proposed.
- Every run >30 min gets its estimate line in its leaf BEFORE it starts; a run that overruns stops and re-reports.

### What could go wrong, and what catches it
- Nine children editing near each other → A0.5's file split + OWNS-by-file + serial integration; conflict = the integrator's job, never a child's.
- A relayed "done" that is not landed → every leaf's last gate is "PR MERGED green", read from GitHub, not from the child's report.
- Empty-set-is-success (bit twice today) → every negative gate carries a red control; every watcher requires ≥1 completed check.
- A malformed test producing a confident wrong claim (today's `gaussian()` vs `biv_gaussian()`) → every A4 leaf's G1 is "read how the test suite builds a working fit for this family natively FIRST, then use that call shape".
- Context: the LOOP kit is on disk and committed; compaction re-reads GOAL → checkpoint → arcs.

## VERIFICATION AND CLOSURE
- Every leaf: `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root <drmTMB> --cwd <slice worktree> --reverify --jobs 1 .unlazy/parity/gates/leaf-<id>.md` exit 0; `--status` is not evidence.
- The matrix regenerates from committed inputs and every cell cites a file:line or a receipt id; a cell with neither is a plan defect, not a pass.
- `parity_ledger.py` CLOSURE: PASS at the new pin; `capability_ledger.py --check` green; both receipt checkers `--self-test` pass.
- Full drmTMB `devtools::test()` once per major arc (~45 min, D-139 line: estimate first, pre-run `filter="julia"`).
- LOOP kit at `~/local-scratch/lanes/parity-joint-20260905/LOOP/` (GOAL.md, arcs.md, checkpoint.md, ultra-plan.md = this file, source-pins.json) — committed in drmTMB `docs/dev-log/loop/` so compaction and /tmp purges cannot lose it. checkpoint.md overwritten per arc.
- Close: Melissa `docs/dev-log/plan-actual/2026-09-05-parity-joint.md`; Rose `docs/dev-log/after-task/2026-09-05-parity-joint.md` on BOTH repos; handover with the exact RESUME line.
