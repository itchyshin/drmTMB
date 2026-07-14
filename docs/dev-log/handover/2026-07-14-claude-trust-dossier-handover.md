# Session Handoff: Trust Dossier #1 — drmTMB vs metafor vs glmmTMB (meta-analysis)

Meta: 2026-07-14 · from Claude · planning session (no code executed) · TARGET = Claude lane

## Critical Context
- This is a **HELD, plan-only** handoff. **Nothing has been executed** — no R was run, no drmTMB code
  written. The job is to produce the first **evidence artifact** of the *Trust-by-Evidence* program
  (converting AI-skeptics by evidence, not rhetoric).
- **The capability almost certainly ALREADY EXISTS — confirm, do not rebuild.** drmTMB already exports
  `meta_V`, `meta_known_V`, `meta_vcov_bivariate`; has `vignettes/meta-analysis.Rmd` and
  `tests/testthat/test-comparators.R`; location–scale (`sigma ~ x`, RE-in-dispersion) is native. A prior
  ad-hoc drmTMB vs `rma.mv` smoke is on record. **S0 is a smoke GATE that confirms this; if it doesn't
  reproduce metafor, THAT is the real gap — stop and report.**
- **Authoritative plan lives in the brain (durable):**
  `~/shinichi-brain/memory/trust-by-evidence-dossier1-plan.md` — open it and paste its `🎯 GOAL` block.
  Program doctrine: `TRUST-BY-EVIDENCE.md`; how-to: `trust-by-evidence-playbook.md`.

## What Was Accomplished (this session — all planning, in the brain vault)
- Diagnosed the skeptic problem and wrote the **Trust-by-Evidence** doctrine + playbook (Trust Ladder,
  Trust Card, dossier spec, red-team protocol) and a published one-pager artifact.
- Ingested the source paper: **Williams, McGillycuddy, Brooks, Bolker, Mizuno, Yang, Viechtbauer, Warton,
  Nakagawa, "Meta-analysis with the glmmTMB R package"** (arXiv **2604.04084**). It adds `equalto` to
  glmmTMB and **validates by producing estimates identical to metafor**. **Wolfgang co-authored it and
  liked it** — so its comparison design is a standard he already endorses. (Apology to Wolfgang re earlier
  over-eager emails already sent 2026-07-14.)
- Ran the prior-work sweep (this branch's basis): confirmed drmTMB's existing meta capability + the local
  toolchain, and wrote the runnable ultra-plan.

## Current Working State
- **Working / ready:** local toolchain in the Claude lane — R 4.6.0, `metafor` 5.0.1, `glmmTMB` 1.1.14,
  `metadat` 1.6.0, `TMB` 1.9.21, `lme4` 2.0.1, `drmTMB` 0.6.0.9000 — all installed. This fresh branch
  `claude/trust-dossier-metafor-comparison` off `main` (86df40c9) in worktree `/private/tmp/drmTMB-trust-dossier`.
- **In progress:** nothing — held at the plan.
- **Not started:** S0–S6 (the whole dossier).

## Key Decisions & Rationale
- **Do it in the Claude lane** (Codex low on tokens). Whichever platform is in-session owns the task.
- **Output home = this fresh branch off `main`** (NOT the shared `feature/arc4a-profile-coverage`, which
  carries unrelated in-flight arc4a work from other sessions). Dossier → `inst/trust-dossier/`.
- **Ordering (REFINED 2026-07-14 after Wolfgang's reply — this reverses the earlier "lead with location-
  scale"):** For Wolfgang (a comparator-minded skeptic) **LEAD with airtight comparator parity** — drmTMB ≡
  metafor on his own examples (S1), the part he cannot argue. Present the **location-scale** case (S3) as
  *validated against glmmTMB `dispformula` (+ brms) AND simulation-from-truth* — NOT as "metafor's `rma`
  can't, trust us" (rma's limit is context, not the trust argument).
- **Two ground truths (Wolfgang conceded the TDD+genAI philosophy is valid; the bar is what's left).** His
  bar: *"thousands of tests, not a few illustrative examples"* + a comparator wherever one exists. Answer:
  ground truth is two-tier — *(a) comparator* (metafor for standard, glmmTMB/brms for location-scale — exists
  for nearly all of this dossier) and *(b) simulation from known truth* (recovery + coverage over a broad
  adversarial grid) where no comparator exists. "No comparator" ≠ "unvalidatable".
- **The simulation GRID is the CORE evidence, not a deferred smoke.** The few datasets = the *demo*; the
  broad adversarial DGP grid on **Totoro** = the *validation* Wolfgang asked for. This session proves the
  harness with a 1-rep smoke, then commissions the full grid on Totoro (never GitHub Actions, D-50).
- **Acceptance bar (Wolfgang-co-signed, from the paper's sim):** μ̂ identical to 6 dp, τ̂² to 5 dp,
  SEs match, identical coverage / type-I / power. Equivalence-to-metafor = **L2** badge; an independent
  Wolfgang run = **L3**.

## Landing State
| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| brain `memory/TRUST-BY-EVIDENCE.md` (c6e7fa4) | y | n/a (local-only, D-37) | none | **LANDED** |
| brain `memory/trust-by-evidence-playbook.md` (8bdb15f, f76cd2a) | y | n/a | none | **LANDED** |
| brain `memory/trust-by-evidence-dossier1-plan.md` (9df7b89, 75438fc) | y | n/a | none | **LANDED** |
| brain `memory/OPEN-LOOPS.md` (open-loop entry) | y | n/a | none | **LANDED** |
| one-pager artifact (claude.ai/code/artifact/a706a048-…) | n/a | published (private) | none | **LANDED** |
| `drmTMB` `claude/trust-dossier-metafor-comparison` (this note) | pending this commit | n | none | **CARRIED-OVER** |
| the dossier code/evidence (S0–S6) | n | n | none | **NOT STARTED** — this branch is its home |

- **CARRIED-OVER — why + resume:** intentionally unbuilt (user held execution). Resume = run the plan on
  this branch starting at S0 (below). Nothing to push yet.
- **drmTMB main working dir** stays on `feature/arc4a-profile-coverage` with pre-existing untracked files
  from OTHER sessions — **not part of this job; do not touch or land it.**

## Next Immediate Steps (ordered)
1. Rehydrate: read the brain plan `trust-by-evidence-dossier1-plan.md` (paste its GOAL block) + this note.
2. Work on this branch: `cd /private/tmp/drmTMB-trust-dossier` (or `git worktree add` fresh, or checkout
   `claude/trust-dossier-metafor-comparison`).
3. **S0 smoke GATE:** fit the Normal–Normal random-effects meta-analysis in drmTMB via `meta_V`/`meta_known_V`
   on `metadat::dat.assink2016`; compare μ̂ and τ̂² to `metafor::rma.mv`. Set `REML=TRUE`. Confirm non-NA,
   in-range, matches to tolerance. **If it matches → S1–S4; if not → STOP and report the gap.**
4. Parallel after S0: **S1 (multilevel dat.assink2016 — the Wolfgang-facing headline: comparator parity)**,
   S2 (bivariate dat.bcg), S3 (location–scale, Bangert-Drowns — validated vs glmmTMB/brms + sim), S4 (coverage
   smoke — 1 rep to prove the harness; the full grid is the core evidence → Totoro). Then S5 package, S6 verify.

## Blockers / Open Questions
- None blocking. Open: confirm the exact `meta_V` call signature for the multilevel (study + within-study)
  case against `rma.mv` — the vignette `vignettes/meta-analysis.Rmd` and `test-comparators.R` are the
  starting references.

## Gotchas & Failed Approaches
- **REML:** drmTMB and glmmTMB default to **ML**; metafor defaults to **REML**. Set `REML=TRUE` (drmTMB/
  glmmTMB) to match, or `control=list(REMLf=FALSE)` on `rma.mv` to match likelihoods. logLik/AIC differ by a
  REML constant even when **estimates are identical** — compare estimates, not logLik.
- **Do NOT rebuild `meta_V`** — it exists. Confirm first.
- **Privacy:** the source PDF sits in `~/shinichi-brain/intake/2604.04084v1.pdf` — it is a **public**
  preprint but lives in the fail-closed `intake/` zone: **do not copy, commit, or index the PDF.** Cite the
  arXiv id / the public repo `github.com/coraliewilliams/equalto_sim_study` instead.
- **Compute:** the full 4-measure (SMD/lnRR/OR/IRR) × many-rep simulation grid is DEFERRED to **Totoro/DRAC**
  — never GitHub Actions (D-50). This lane runs a **smoke** coverage sim only.
- **Do not commit into the shared arc4a working tree** — use this branch.

## How to Resume
Paste in an authenticated terminal (clean context):
```
claude "cd /Users/z3437171/Dropbox/Github\ Local/drmTMB && rehydrate for the Trust Dossier job: read ~/shinichi-brain/memory/trust-by-evidence-dossier1-plan.md (paste its GOAL block) and docs/dev-log/handover/2026-07-14-claude-trust-dossier-handover.md on branch claude/trust-dossier-metafor-comparison, then run the S0 smoke gate (drmTMB meta_V vs metafor::rma.mv on dat.assink2016). Do NOT rebuild meta_V; confirm it. Spawn Fisher + Rose to verify before any claim."
```
Read order: (1) brain plan `trust-by-evidence-dossier1-plan.md`; (2) this note; (3) `vignettes/meta-analysis.Rmd` + `tests/testthat/test-comparators.R`; (4) `R/meta-vcov.R`.
