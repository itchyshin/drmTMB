# Handover to the next Claude session — drmTMB + DRM.jl finish-plan

You are **Ada**, continuing an autonomous, push-held run to finish the drmTMB (R)
package, its DRM.jl (Julia) twin, and the R-Julia bridge. Read this whole file
first; it lets you inherit the goal, the plan, the mission-control widget, the
boundaries, and the exact resume point. Repo state is authoritative — rerun
`git status`/`git diff` before editing.

## 0. Identity, team, posture

- Speak and orchestrate as **Ada** (integrator). Standing review lenses you
  spawn as agents/workflows: **Rose** (claim-boundary gate — the most important
  guardrail), **Fisher** (inference), **Gauss** (TMB/numerics), **Noether**
  (math consistency), **Boole** (formula grammar), **Emmy** (R API), **Curie**
  (simulation), **Florence** (figures), **Pat/Darwin** (reader/biology),
  **Grace** (CI/repro), **Jason** (cross-package).
- **Ultracode is on**: prefer Workflow orchestration for substantive tasks;
  token cost is not the constraint, correctness is.
- The owner (Shinichi) is mostly away and wants continuous, defensible progress
  "one slice at a time, by agents." **Do all work as local commits on the
  branches below; HOLD all pushes/PRs/merges for his review** unless he says
  otherwise.

## 1. The goal (inherited)

Active `/goal`: *"look at the broader plan and try to finish the package(s) —
look at the widget (mission control too)."* Operationally: keep advancing the
finish plan one defended evidence slice at a time, **reduce the partial/planned
cells**, and keep the mission-control widget honest. The hard-won discipline:
**partial/planned falls only to NEW EVIDENCE (recovery/coverage/parity sims),
never to status-flips.** Every promotion is Rose+Fisher-verified and scoped.
Do **not** mark the long-running Big-4 goal "complete."

## 2. Workspaces and branches (PUSHES HELD)

- **drmTMB (R)**: `/Users/z3437171/.codex/worktrees/540b/drmTMB`, branch
  **`shannon/overnight-audit-gaps-20260619`** (off clean `origin/main`
  `bd1f3e46`, PR #636).
- **DRM.jl (Julia)**: `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`,
  branch **`shannon/overnight-audit-verify-20260619`** (off clean DRM.jl
  `origin/main` `f46035d`, PR #295).
- **cwd hazard**: subagent/Bash shells default to the STALE primary checkout
  `/Users/z3437171/Dropbox/Github Local/drmTMB` (`b4a4d7be`, dirty, 159 commits
  behind). Ignore it. ALWAYS pin absolute `540b` paths; tell spawned agents to
  do the same (two prior synthesis agents got confused by this).

## 3. The plan (inherited) — canonical docs to read

- `docs/dev-log/recovery-checkpoints/2026-06-20-overnight-ada-handover.md` —
  terse resume checkpoint (local, gitignored).
- `docs/design/177-big4-finish-plan-2026-06-19.md` — the Big-4 block plan.
- `docs/design/157-capability-completion-worklist.md` — dependency-ordered
  capability tiers (A–G).
- `docs/design/168-r-julia-finish-capability-matrix.md` — the canonical claim
  matrix (source of truth for the widget).
- `docs/dev-log/2026-06-20-status-reconciliation.md` — **the prioritized
  evidence-path to reduce partial/planned** (read this to pick the next slice).
- `docs/dev-log/2026-06-20-bridge-parity-verification.md` — bridge state + the
  exact path to promote a bridge cell.
- `docs/dev-log/check-log.md` (newest entries first) and
  `docs/dev-log/after-task/2026-06-19*/2026-06-20*` — the full evidence trail.

## 4. Mission control (inherited)

- Source: `docs/dev-log/dashboard/status.json` (+ `sweep.json`, `index.html`,
  `julia-capabilities.tsv`, `julia-gates.tsv`).
- Served live at **`http://127.0.0.1:8765/`**; refresh with
  `tools/start-mission-control.sh --background`.
- Validate after ANY dashboard edit: `python3 tools/validate-mission-control.py`
  (must print `mission_control_ok`). It enforces: metrics == slice statuses, 17
  matrix rows, 11 finish rows, 15 Julia gate rows, 9 capability rows, plus the
  release-ready / engine_control / accelerator claim lints.
- Current metrics: **25/68 banked_or_verified, 1 active, 0 blocked, 1 deferred.**
  Promoting a matrix *cell* (covered/partial/planned) does NOT change these
  slice metrics or row counts, so the validator stays green — but update
  status.json AND design 168 together.

## 5. State and what was done (committed on the branches)

- Validation: `devtools::check` 0/0/0 (1 env NOTE = ~455s test time); full
  `devtools::test` green; `pkgdown::check_pkgdown` clean; validator green.
  DRM.jl full `test/runtests.jl` green (228 testsets) + Aqua 10/10.
- R: Wave 1 docs/widget; Wave 2 native correctness (high-4 pdHess→`non_pd_hessian`,
  high-6 link registry, high-11 figure; **high-2 atomic::logdet was REVERTED** —
  it perturbs weakly-identified spatial q4, needs supervised adjudication);
  7 doc-completeness slices; 5-lens review 0 blocking.
- **Two evidence-earned promotions**: binomial fixed-effect **profile** intervals
  (`planned→covered`) and the lead-novelty **`rho12 ~ predictors` recovery**
  (point/wald/simulation `partial→covered`), each scoped to fixed-effect with
  honest caveats and a banked artifact.
- Julia/bridge: DRM.jl verified; bridge parity verified (Routes B/C
  `engine="julia"==engine="tmb"` ≤1e-6; Route A is a tracked bug); Rose+Fisher
  confirmed **0** honest bridge-cell promotions (statuses correctly conservative).

## 6. IN FLIGHT — resume exactly here

`docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-fe-recovery-calibration/`
is a clean **pilot** (50 reps, 6 families poisson/nbinom2/Gamma/lognormal/beta/
student; 0/1200 errors, pdHess 100%, near-unbiased, Wald 0.90–0.98). Next:

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-fe-recovery-calibration/run.R 500
```

(~12–15 min). If 500-rep coverage holds ~0.93–0.97 across all six families,
Rose+Fisher-verify, then promote the "Non-Gaussian models" matrix **point** cell
`partial→covered` (scoped: fixed-effect mu recovery, implemented one-response
families); only promote **wald** if all families are clean. Write the README,
commit, refresh widget, after-task. See that artifact's README for the contract.

## 7. After that — the evidence-path queue (from the reconciliation)

In leverage order, each is a "produce evidence → Rose+Fisher verify → promote
scoped cell" slice: (a) the non-Gaussian 500 run above; (b) a binomial coverage
**visual** (Florence-gated); (c) **high-2** re-land after adjudicating the q4
convergence change; (d) bridge promote-path — Route C **interval** parity
(profile/bootstrap CI endpoints native vs `engine="julia"`) → `base_gaussian`
`covered`; a `rho12 ~ x` **coefficient** parity test + a new non-phylo rho12
bridge row → Route B; (e) genuinely blocked / owner-gated: q8 method, rho12
random effects, structured/q4 recovery, missing-data design gates, DRM.jl #9
Documenter pin + #8 logdet ridge (maintainer-owned).

## 8. Boundaries (Rose enforces — non-negotiable)

No bridge-row promotion without per-cell parity evidence; no q4/q8 or plain
non-phylo binomial bridge parity; no release/CRAN claim; no recovery/coverage/
power claim without a sim that measures it; no selectable Julia `engine_control`;
REML/AI-REML Gaussian-only; missing-data vs complete-case kept separate; keep
**native R/TMB ↔ direct DRM.jl ↔ Julia-via-R** evidence in separate lanes (a
green DRM.jl suite does NOT promote a bridge or native cell).

## 9. Working method

Per slice: produce/verify evidence → Rose+Fisher (or the relevant lens) verify
→ apply scoped edits → `validate-mission-control.py` + `git diff --check` →
narrow per-slice commit (`Co-Authored-By: Claude Opus 4.8`) → update check-log +
after-task + widget activity. Re-grep every code line reference before editing
(the 2026-06-12 audit's line numbers are stale for this tree). The R-Julia
bridge only runs via the callr-isolated test harness with
`DRM_JL_PHYLO_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main
JULIA_HOME=/Users/z3437171/.juliaup/bin` — an in-process `engine="julia"` call
after `load_all()` fails.

Hand off the same way (recovery checkpoint + this kind of note) when your context
fills. Good luck.
