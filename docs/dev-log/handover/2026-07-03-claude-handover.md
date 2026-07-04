# Session Handoff: Twin-package code-review backlog → solve all open issues

**Meta:** 2026-07-03 · from Claude Code · to **Claude** (next session) · TARGET=claude, AUTHOR=claude
**Companion report (durable, in-repo):** [`2026-07-03-twin-review-report.md`](2026-07-03-twin-review-report.md) — all 50 filed issues verbatim, rebuilt from the GitHub trackers.
**Issue → finding map:** the review-report file is indexed by issue number; every finding also lives in its GitHub issue body.

---

## Critical Context

You are **Claude, picking up a two-package program**: `drmTMB` (R + TMB C++) and its twin `DRM.jl`
(Julia port). The previous session ran a deep multi-agent **static** code review of *both* packages
and filed **50 GitHub issues** carrying 85 verified findings. **No package code was changed** — the
review's only output was the issues + the companion report in this folder.

**The maintainer's instruction for you:** *"start solving all the issues together, including the
other issues that are in there for the two packages."* So your job is to work the **entire open-issue
backlog across both repos** — the 50 new review bugs first (they are concrete and have proposed fixes
in-hand), then the pre-existing enhancement/roadmap issues.

Two hard constraints you must respect:
1. **You (Claude) cannot run the live toolchain in-container** (no TMB compile / `R CMD check` /
   Julia fits). You **draft** code + tests + docs; **Codex runs the live validation.** The standard
   loop is: *Claude drafts a themed branch → Codex compiles/fits/checks → Claude reviews the diff.*
   Do not claim a fix "works" without engine evidence — mark it "drafted, awaiting Codex validation".
2. **Twin parity is the cross-cutting theme.** Several findings are drmTMB↔DRM.jl divergences
   (Student-t `sigma` semantics, NB2 dispersion convention, hard `eta` clamps, duplicated bivariate
   NLL). For any such issue, fix **both** packages in lockstep and add a **cross-package parity
   fixture**; decide one convention per family and enforce it.

---

## What Was Accomplished (this session)

- Ran a Workflow of **24 subsystem finders** across ~70k lines (drmTMB `R/` + `src/*.cpp`, DRM.jl
  `src/`) + a cross-package parity pass, each finding checked by an independent adversarial verifier.
  **95 candidates → 85 kept** (49 CONFIRMED, 36 PLAUSIBLE); 10 refuted and dropped.
- Filed **50 issues**, labeled `bug` (or `documentation` for doc-only), all title-tagged `[review]`:
  - **drmTMB #690–713** (24): 7 high + 11 medium individual, 6 low thematic-batch issues.
  - **DRM.jl #301–326** (26): 2 high + 19 medium individual, 5 low thematic-batch issues.
- Rebuilt the consolidated report into this repo from the filed issues (authoritative source).

**Severity legend:** CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully
confirmable by static reading (kept deliberately, recall-biased). All need engine confirmation.

---

## Goals / Mission

- **Durable why:** finish and harden the two twin packages (`drmTMB` = univariate/bivariate
  distributional regression on TMB; `DRM.jl` = the Julia twin). Keep `sigma` (not `tau`), `rho12`
  for residual bivariate correlation, `meta_V(V=V)` for meta-analysis; one formula per dpar;
  univariate/bivariate scope only (higher-D belongs to gllvmTMB). **No CRAN push** (maintainer rule).
- **This program's why:** clear the open-issue backlog on both trackers, starting with the review
  bugs, keeping the twins in parity, with Rose/Gauss/Noether/Fisher review before any status claim.

## Plans / Roadmap — prioritized by leverage

**Phase 1 — Twin-parity family conventions (do first; cross-cutting, unblocks correctness downstream).**
Decide and enforce one convention per family across both packages, add a parity fixture:
- Student-t `sigma` = scale vs SD contract — drmTMB **#700** (doc-only label; but it's a real
  spec/impl mismatch that also affects DRM.jl `student.jl`). Touches `docs/design/03-likelihoods.md`.
- NB2 dispersion slot convention — DRM.jl **#315** (mixed_family vs univariate diverge) + **#316**
  (docstring inverts recovery). Pick `size = exp(-2·coef)` everywhere.
- Hard `eta` clamps in DRM.jl but not TMB — DRM.jl **#326**-adjacent / report "both" finding
  (negbinomial/gamma clamp) → make guarding identical (smooth softclamp, off by default).
- Aggregated Gaussian uncentered SS — drmTMB **#701** (twin: same change in `R/gaussian-aggregation.R`
  **and** `src/drmTMB.cpp`).

**Phase 2 — High-severity correctness bugs (the 9).**
drmTMB: **#690** rank-deficient known V only a note · **#691** emmeans vs predict scale
(truncated_nbinom2) · **#692** phylocov Cholesky entries leak into coef table · **#693** q4 bridge
drops tree-depth `sd_scale` (twin) · **#694** `missing='drop'` never drops NA rows for non-Gaussian
phylo/count routes (twin) · **#695** repeatability/heritability denominator omits other variance
components · **#696** silent formula mis-parse (`sigma`/`nu`/… as a response column; touches
`docs/design/01-formula-grammar.md`).
DRM.jl: **#302** Gamma quantile residuals use wrong shape for location-scale fits · **#301**
independent-slope RE start mis-pinned/unidentified.

**Phase 3 — Medium (30).** Numerical guards (PD/logdet/tolerances), inference reporting
(lrtest boundary χ², coeftable meaningless z/p, REML Wald vcov), start-values, profile robustness.
drmTMB #697–707; DRM.jl #303–321. Group by subsystem into focused PRs.

**Phase 4 — Low (46, already batched).** drmTMB #708–713, DRM.jl #322–326. Hardening/cleanup/docs;
knock out per batch issue.

**Phase 5 — Pre-existing enhancement/roadmap backlog** (larger design work, needs its own scoping):
- drmTMB: **#714** matrix-free/Hutchinson REML · #687/#686/#682/#680 methods (CI calibration,
  profile-as-featured-CI, warm starts) · #570 Ayumi rescue · #555 REML speed · #531 corpair()
  latent-RE (needs TMB template change) · #499 engine=julia bridge · #496 GVA engine · #491 R work
  queue · #342 release 0.2.0 · #147 animal()/relmat() · #61 CRAN-readiness · #60/#59/#58 sim/vis
  · #33/#31 tutorials/slopes · #5/#4/#3.
- DRM.jl: **#327** matrix-free REML · #291 REML speed/parity · #280 mixed-family dispatch (GLLVM.jl
  cross-repo) · #270 kernel/sparse-GP relmat · #269 Pagel's λ · #227 scout backlog · #202 non-Gaussian
  phylo loc-scale · #189 coevolution from kernel · #186 q4 PLSM epic · #166 beta-binomial phylo
  · #136 VA/ELBO marginal · #49 FIML/EM missing data · #13 natgrad EM wiring · #9/#8/#7/#5/#3 roadmap.

**Suggested working model:** one themed branch + PR **per cluster per repo**; Claude drafts
code+tests+docs, Codex validates, Claude reviews. For twin clusters, land drmTMB and DRM.jl changes
together with a shared parity test. Keep PRs small (AGENTS.md rule).

---

## Current Working State

- **Working:** all 50 issues filed and verified on GitHub; consolidated report in-repo.
- **In progress:** nothing coded yet — the backlog is defined, not started.
- **Blocked:** every fix needs **Codex** for live validation; you can draft but not confirm.

## Key Decisions & Rationale

- **Filed high+medium as individual issues, low as per-repo thematic batches** (maintainer-approved
  granularity), labeled `bug`/`documentation` (maintainer-approved). Title tag `[review]` makes the
  set searchable: `gh issue list --search "in:title [review]"`.
- **Static review only** (Claude-plans / Codex-runs split, per repo AGENTS.md). Findings are
  code-read, not engine-reproduced — hence the CONFIRMED/PLAUSIBLE labels and the "verify before
  acting" footer in every issue.
- **Report rebuilt from the issues** (not the session scratchpad, which is ephemeral and was cleared).

## Files Created / Modified (this handover; no package code touched this session)

- `docs/dev-log/handover/2026-07-03-claude-handover.md` — this doc.
- `docs/dev-log/handover/2026-07-03-twin-review-report.md` — consolidated report (50 issues verbatim).
- `AGENTS.md` — snapshot pointer: prepended the 2026-07-03 → Claude bullet, demoted the prior one.

(The session's substantive output lives on GitHub as issues **drmTMB #690–713** and **DRM.jl
#301–326**, not as a repo diff.)

## Blockers / Open Questions

- **Where does DRM.jl-side work get its handover?** This doc + report live in drmTMB (active repo)
  but cover both. If you start a session against DRM.jl, read this drmTMB doc first. (Optional: mirror
  a pointer into `DRM.jl/AGENTS.md` if the maintainer wants symmetric rehydration.)
- **Fix-ordering within Phase 1** — confirm with the maintainer which family convention is canonical
  (e.g. is Student-t `sigma` meant to be the scale, and docs corrected? or rescale to true SD?). The
  issue proposes both options; the choice is the maintainer's design call.
- **Codex availability / host access** — prior handovers noted intermittent cluster/host auth issues;
  local Codex validation is the near-term path.

## Gotchas & Failed Approaches

- **R invocation:** run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file` — the `.Rprofile`
  R-4.5 lib **segfaults R 4.6** (carried from the 2026-06-28 handover).
- **Do not `git add -A`;** stage explicit paths (repo has had foreign untracked files in the past).
- **Do not revert Codex/human changes** unless explicitly asked (AGENTS.md).
- **Design-doc update rules are enforced:** a likelihood-parameterization change must update
  `docs/design/03-likelihoods.md`; a formula-grammar change must update
  `docs/design/01-formula-grammar.md`; every meaningful change touches `docs/dev-log/check-log.md`;
  completed tasks get an after-task report (`docs/design/10-after-task-protocol.md`).
- **Twin mirror:** `.codex/agents/*.toml` and `.claude/agents/*` are one-to-one — keep in sync.
- **Local checks over CI** (maintainer rule): run `devtools::check()`/`test()` locally (via Codex)
  before pushing; keep CI to workflow_dispatch + PR + Linux until a release.

## How to Resume

**Rehydration recipe (next Claude):**
1. `cd` into `drmTMB`; `git fetch`; read `AGENTS.md` (top snapshot bullet points here).
2. Read this doc, then [`2026-07-03-twin-review-report.md`](2026-07-03-twin-review-report.md) for the
   full findings, and `docs/design/01`–`03` for grammar/family/likelihood contracts.
3. Pull the live backlog: `gh issue list --repo itchyshin/drmTMB --state open` and
   `gh issue list --repo itchyshin/DRM.jl --state open` (review issues tagged `[review]`).
4. Before any public claim, spawn **Rose** (`systems_auditor`); add **Gauss/Noether/Fisher** for
   likelihood/math/inference-touching fixes.
5. Start Phase 1 (twin-parity family conventions). Draft on a themed branch; hand live validation to
   **Codex** (`R CMD check`, fits, sims); review the returned diff.

**One-command resume** (paste in your own authenticated terminal, from the drmTMB repo root):

- Interactive (you steer):
  ```
  claude "Rehydrate from docs/dev-log/handover/2026-07-03-claude-handover.md + the AGENTS.md snapshot, then start solving the twin-package issue backlog beginning with Phase 1 (twin-parity family conventions). Draft fixes + tests; hand live R/TMB + Julia validation to Codex."
  ```
- Autonomous, clean context (hands-off):
  ```
  claude -p "Rehydrate from docs/dev-log/handover/2026-07-03-claude-handover.md + the AGENTS.md snapshot, then execute Phase 1 of the Next Immediate Steps (twin-parity family conventions), drafting fixes + tests for Codex validation." --max-budget-usd 5
  ```

---

## Mission Control

| Repo | Branch / base | CI | What shipped this session | Next by leverage |
| --- | --- | --- | --- | --- |
| **drmTMB** (R/TMB) | handover on `handover/2026-07-03-claude` off `main@14ffab10` | not run (docs-only) | 24 review issues #690–713 | P1 twin-parity (#700/#701) → P2 highs (#690–696) → P3 med (#697–707) → P4 low batches (#708–713) → P5 backlog |
| **DRM.jl** (Julia) | issues only (no branch this session) | n/a | 26 review issues #301–326 | P1 NB2 convention (#315/#316) → P2 highs (#301,#302) → P3 med (#303–321) → P4 low batches (#322–326) → P5 backlog |

**Cross-cutting:** decide one convention per family; add a drmTMB↔DRM.jl parity fixture. Claude drafts;
**Codex runs the live toolchain**; Rose audits before claims.
