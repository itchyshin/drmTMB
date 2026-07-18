# Handover → next Claude (2026-07-18, post mc-0242 Gamma σ-RE promotion + AGHQ/REML scoping)

You are the next **Claude** session picking up drmTMB. This session closed one capability arc
(a promotion, merged), fixed a test-freshness gate (merged), and **scoped — but did not build —
the next big arc** (AGHQ + non-Gaussian REML). Read this, then the linked evidence, then decide
the next arc with Shinichi.

---

## Goals / mission

drmTMB = fast univariate/bivariate distributional regression on TMB, marching toward a v1.0
capability surface. The live programme turns `point_fit_recovery` cells into
**`inference_ready_with_caveats`** with honest, pre-registered coverage evidence, one cell at a
time. Mission north star: usable packages for many (ecology & evolution), not one-off analyses.

## Plans / roadmap (the next big arc — Shinichi's call between two APPROVED directions)

Both are approved; Shinichi has **not** picked which to do first:
1. **AGHQ + non-Gaussian REML arc (Cox–Reid first)** — the *quality/depth* lever. Scoped this
   session with measured, oracle-validated evidence (below). Sequence: **Cox–Reid leg** (validate
   vs `glmmTMB(REML=TRUE)` on binomial → cumulative_logit) → **AGHQ leg** (validate vs
   `glmer(nAGQ=)`) → recombine → **re-score the coverage cells for *nominal*** (not just caveated).
   Each leg has an external oracle, which de-risks it. Lifts the mc-0243 non-Gaussian-REML ban *for
   the approximate Cox–Reid restricted likelihood only*.
2. **4-cell mu random-slope coverage batch** — near-term *breadth* (Option A). Cells
   cumulative_logit `mc-0227`, skew_normal `mc-0464`, tweedie `mc-0539`, zero_one_beta `mc-0575`
   (all `mu ordinary_re_slope`, still `point_fit_recovery`). A pre-compute scout ran (workflow
   `wf_f9d4b5e4-983`; per-family DGP/machinery/estimand in its journal). **Warning:**
   cumulative_logit is the lowest-information family and fights exactly the bias the AGHQ/REML arc
   fixes — expect it to need a high-M grid ({40,80,160,320}) or land as a documented non-promotion.

## What was accomplished

**A) mc-0242 Gamma σ-RE coverage → PROMOTED + MERGED (PR #791).** Gamma sigma random intercept
`(1|id)` → `inference_ready_with_caveats`. Totoro N=1200/cell iid-uncentered profile+Wald campaign
across M∈{8,16,32,64}, zero failures, `profile_finite_rate`=1.000. Certified floor **M≥32**
(nominal within MC error); **M=16** disclosed borderline (CI straddles 0.925); **M=8 excluded**
(20.8% SD=0 boundary pile-up, −12.7% bias). Memo-blind D-43 passed 3/3. Gate was the pre-registered
`[0.925,0.975]` CI-overlap (mc-0017 standard). Full method + gate: the pre-compute gate spec is in
`scratchpad/mc0242-gamma-sigma-gate-spec.md` (rev 2, plan-review-ratified by Fisher+Rose).

**B) Test-freshness gate → MERGED (PR #792).** A pre-existing unittest
(`test_active_qseries_surfaces_keep_debug_only_routes_diagnostic`) failed on a stale git-ignored
`pkgdown-site/llms.txt`. Fixed by gating the test's pkgdown build-artifact assertions on git-tracked
status. Suite is **37/37 green on `main`**. Unrelated to mc-0242.

**C) AGHQ + non-Gaussian REML SCOPING (diagnostic; PR #793, NOT merged).** The small-cluster
non-Gaussian RE-SD bias is **two stacked, orthogonal effects** — measured on cumulative_logit
(M=40, n_each=15, true SD 0.5, 40 seeds), validated against glmmTMB/glmer/lme4 oracles:
- Laplace **−7.3%** → +**AGHQ** (integral error) **−5.0%** → +**Cox–Reid** (ML variance bias)
  **−0.9% ≈ nominal**. **Cox–Reid is the bigger lever (~1.7×).**
- AGHQ node-sweep: converges by ~5 nodes then plateaus dead-flat at −5.0% — nodes cannot cross the
  variance-bias floor; only the restricted likelihood drops it.
- Binomial validated oracle: `glmmTMB REML=TRUE` removes ~42% of ML bias vs `REML=FALSE`;
  `glmer nAGQ=25` removes ~0.1 pt. drmTMB Laplace == glmmTMB ML **exactly** → NOT a bug; ordinal is
  just the lowest-information family. Caveat: Cox–Reid mildly over-corrects at large M (+2.1% at
  M=160) — conservative, safe, to characterise.

**D) Cross-repo map (source-confirmed).** gllvmTMB = **same arc** as drmTMB (`reml_bridge` aborts
for non-Gaussian, no AGHQ). HSquared.jl is **ahead**: `fit_laplace_reml` already IS the Cox–Reid
non-Gaussian REML (integrates β out under a flat prior, Gaussian-validated to `sparse_reml_loglik`);
its gap is the **AGHQ half + coverage certification**. FYI notes left in both repos' dev-logs; a
cross-repo map filed in the vault (`~/shinichi-brain/memory/Two-lever fix…map.md`, committed).

## Current working state

- **Done / merged:** mc-0242 (PR #791), llms test-freshness (PR #792). `main` @ `55a8b626`+, suite green.
- **Open, NOT merged:** PR #793 (`claude/aghq-reml-scoping`) — AGHQ/REML scoping evidence, **docs-only**.
- **Scoped, not built:** the AGHQ + non-Gaussian REML arc; the 4-cell mu-slope batch.
- **Carried-over (from an earlier session's close-out, NOT resolved here):** the parked worktree
  `drmTMB-wt-surface` on `claude/capability-surface-aghq-parity` holds an UNCOMMITTED AGHQ-generator
  + `capability-status.md` change, blocked by a stale `.git/index.lock` in *that worktree's* git dir.
  **Do NOT `git worktree prune drmTMB-wt-surface`** until it's landed — that change lives only there.
  (The canonical checkout's own stale lock was cleared this session.)

## Key decisions & rationale

- mc-0242 gate = pre-registered `[0.925,0.975]` CI-overlap (the mc-0017 precedent), frozen before
  compute; DGP iid-**uncentered** (centering changes the estimand — the Arc-4a v1 failure); profile is
  the promotion method (σ-RE is bounded at 0, so profile matters, unlike mc-0017's unbounded coeffs).
- AGHQ vs REML are **orthogonal** levers; REML is the bigger one for low-information families → build
  Cox–Reid first. Both have external oracles (glmmTMB / glmer) → validate against them.
- Handover + snapshot land on the scoping branch so they travel with PR #793.

## Files created / modified (this session's durable artifacts)

On `main` (merged): mc-0242 ledger + evidence + docs (PR #791); `tools/tests/test_capability_ledger.py`
gate (PR #792).
On `claude/aghq-reml-scoping` (PR #793):
- `docs/dev-log/2026-07-18-cumlogit-laplace-diagnosis-and-aghq-next-arc.md` (diagnosis + queued-arc plan)
- `docs/dev-log/simulation-artifacts/2026-07-18-cumlogit-laplace-vs-aghq/{reml-scoping-binomial.tsv,
  reml-scoping-cumlogit-40seed.tsv, cumlogit-laplace-vs-aghq.tsv}`
- `docs/dev-log/handover/2026-07-18-claude-handover.md` (this doc) + `AGENTS.md` (snapshot refresh)

Vault (local-only, committed `485f0fa`): `memory/Two-lever fix…map.md`; board `status/drmTMB.json` (already landed).
Other repos (UNTRACKED, for their sessions): `gllvmTMB/docs/dev-log/2026-07-18-two-lever-…-news-from-drmTMB.md`;
`HSquared.jl/docs/dev-log/2026-07-18-two-lever-news-fit-laplace-reml-is-the-cox-reid-lever.md`.
Scratchpad (never-commit): `mc0242-gamma-sigma-gate-spec.md`, `cumlogit_reml_scoping.R`,
`cumlogit_reml_part2.R`, `aghq_node_sweep.R`, `reml_binom_only.R`.

## Next immediate steps

1. **Ask Shinichi which arc first** — AGHQ+REML build (depth) or the 4-cell batch (breadth). Do not pick for him.
2. If **AGHQ+REML**: ultra-plan it; **Cox–Reid leg first** against the `glmmTMB(REML=TRUE)` oracle
   (binomial → cumulative_logit), pre-registered gate, memo-blind D-43. The scratchpad probes are a
   runnable starting point but are **diagnostic scaffolds, not the package implementation.**
3. If **4-cell batch**: consolidate one batch S0 gate-spec (the `[0.925,0.975]` gate + finite-profile
   policy + ledger mechanics carry over from mc-0242 unchanged; only the 4 family DGPs are new — see the
   scout journal `wf_f9d4b5e4-983`), Fisher+Rose plan-review, then STOP for compute approval.
4. Either way: **stop for explicit compute approval before any Totoro run** (standing gate).

## Blockers / open questions

- Which arc first (Shinichi's call).
- The parked `drmTMB-wt-surface` AGHQ-generator/`capability-status.md` commit is still lock-blocked
  and unlanded — separate cleanup.
- The `claude-opus-4-8` safety classifier was intermittently unavailable all session (throttled
  Bash/gh/Workflow) — retry, don't abandon.

## Gotchas / failed approaches

- **`rm` is sandbox-blocked** in this session — use **scoped git staging** to exclude unwanted files
  rather than deleting (a stale 4-seed `reml-scoping-cumlogit.tsv` remains untracked in the artifacts
  dir; deliberately not committed).
- **Totoro's *installed* drmTMB is stale (0.1.4)** — always run campaigns **from source** via
  `pkgload::load_all` off a fresh `main` clone. A working clone is at `~/drmTMB_work/drmTMB-gamma-cov`
  (a9b2633c). Pin `OPENBLAS_NUM_THREADS=1` (Totoro is OpenBLAS, not fir's FlexiBLAS).
- **Brain MCP per-project write routing is flaky** — `write_note` landed in `symbolizer-docs` by
  mistake; fixed by moving the file to the vault filesystem. Write brain notes to the vault FS directly,
  or verify the resolved project.
- The mission-control `status/drmTMB.json` **auto-commits** via a sync — no explicit commit needed.
- Don't reuse the 4-seed smoke TSVs as evidence — the full local run died before its final `write.table`;
  the authoritative numbers are the 40-seed `reml-scoping-*-40seed`/regenerated files.

## How to Resume (TARGET = claude)

1. From the repo root, read the `AGENTS.md` "▶ Latest — start here" snapshot, then THIS doc, then the
   diagnosis note (`docs/dev-log/2026-07-18-cumlogit-laplace-diagnosis-and-aghq-next-arc.md`).
2. `git fetch`; confirm PR #791/#792 merged to `main`, PR #793 open (docs-only). Suite green:
   `python3 -m unittest tools.tests.test_capability_ledger` → 37/37.
3. Before any capability CLAIM, spawn the mandatory review lens (Rose / systems_auditor), default NOT-DONE.
4. Claude runs the live R/TMB toolchain here (this session did); Totoro reachable via the ControlMaster
   socket (`SOCK=$(ls ~/.ssh/cm-*totoro* | head -1)`). Compute → Totoro/DRAC, never GitHub Actions (D-50).
5. Plan the chosen arc with `ultra-plan`; if a coverage campaign, plan-review the gate BEFORE compute and
   STOP for Shinichi's approval.

**One-command resume (paste in your authenticated terminal, from the repo root):**
```
claude "Rehydrate from docs/dev-log/handover/2026-07-18-claude-handover.md + the AGENTS.md snapshot, then ask me which arc to start — the AGHQ + non-Gaussian REML build (Cox-Reid first) or the 4-cell mu-slope coverage batch — and proceed with a pre-compute plan-review; stop for my approval before any compute."
```

## Mission-control summary

| Lane | Branch / PR | State | What shipped | Next by leverage |
|---|---|---|---|---|
| Gamma σ-RE coverage (mc-0242) | `main` / **PR #791** merged | Done | mc-0242 → inference_ready_with_caveats; Totoro N=1200 coverage; D-43 3/3 | — (closed) |
| Ledger test-freshness gate | `main` / **PR #792** merged | Done | git-tracked gate on stale pkgdown artifacts; suite 37/37 | — (closed) |
| AGHQ + non-Gaussian REML | `claude/aghq-reml-scoping` / **PR #793** | Scoped, NOT built | two-lever diagnosis (Cox–Reid > AGHQ), oracle-validated | **Build — Cox–Reid leg first** (Shinichi's call vs batch) |
| 4-cell mu-slope coverage batch | — | Not started | pre-compute scout done (`wf_f9d4b5e4-983`) | Batch S0 gate → plan-review → compute approval |
| Cross-repo (gllvmTMB, H2) | — | FYI notes left | gllvmTMB same arc; H2 has Cox–Reid, needs AGHQ+coverage | Each repo's own session decides |
