# Session Handoff: binomial links (Arc D) · MSPL+SE · SE-calibration campaign

Meta: 2026-08-09 · from Claude to Claude · three subjects, two live branches, one planned campaign

**Filename note.** This is deliberately NOT `2026-08-09-claude-handover.md` — that path is already
taken by two *different* documents on two branches (`codex/handover-07-candidate-prep-0809` and
`codex/mspl-binomial-glmm-experimental`), each defining a different "Lane 2". That collision caused a
real ambiguity earlier today. **Cite any handover by branch + SHA, never by path alone.**

## Critical context

`origin/main = 8d441a32d` (the #956 merge). Three subjects, in priority order:

1. **Arc D — binomial probit/cloglog.** Mid-flight on `claude/binomial-link-generalisation`
   (`5b6c13197`, pushed). Engine done, R surface not. **The links are NOT reachable from R yet, on
   purpose.**
2. **MSPL + standard errors.** Complete and reviewed on `claude/mspl-binomial-inference-promotion`
   (`b6626e117`, pushed, 6 behind / 12 ahead). **No PR — reserved to Shinichi.**
3. **SE-calibration campaign.** Pre-registered design agreed, nothing built. Needs Totoro.

## Goals

Get MSPL standard errors and (pending a decision) probit/cloglog into drmTMB **0.7.0**, the first
CRAN release, without widening any claim past its evidence.

## What was accomplished

- **Separation lane closed: DEFER.** PR #956 merged at `8d441a32d`; lane 1 notified on #955. The
  0.7.0 candidate freeze is unblocked. Root cause was `lpSolveAPI` silently dropping all-zero
  constraint rows — not a drmTMB defect.
- **MSPL reports standard errors.** `vcov()` and `summary()$std_error` unlocked; `confint`,
  `profile`, `logLik`, `AIC`, `BIC`, `anova` all still error, each verified individually.
  `--as-cran` on the exact final commit: **0 errors / 0 warnings / 1 NOTE** ("New submission").
- **Design 250 amended explicitly** (Phase 4) rather than silently unlocked; design 251 fixes the
  estimand; design 252 scopes the links.
- **Arc D engine**: `link_code` plumbed R→TMB, two C++ primitives, tail-safe `drm_log_pnorm`,
  **Julia bridge re-gated**, CondExp drift guard repaired with its paired continuity test.
- Demo, equivariance test, q2 external oracle, and a scale-free score diagnostic — see below.

## Key decisions and rationale

- **MSPL ships SEs, not intervals.** Enforced in code, not prose. Kosmidis & Firth: Wald intervals
  here *"fail to cover regardless of the nominal level"*, persisting even for profile penalized
  intervals. Second, independent reason: the MSPL estimate maximises the *penalized* criterion, so
  the unpenalized score is not zero at it.
- **MSPL entry point stays logit-only even in 0.7.1.** Kosmidis & Firth's *fixed-effect* finiteness
  generalises across links, but Sterzinger & Kosmidis leave the *mixed-effects* probit/cloglog
  bounds as future work. Extending MSPL to other links is research, not a port.
- **Links were moved 0.7.0 → 0.7.1, then re-opened as "build, don't ship".** Emmy found by
  inspection that widening the guard would silently break the Julia bridge. Owner then asked to
  build it anyway and decide on evidence. **Building does not commit to shipping** — the decision is
  D8 below.
- **Campaign measures SE *calibration*, not coverage.** We ship SEs; a coverage campaign would
  measure a fenced quantity whose failure is already published.
- **Borrow from gllvmTMB is split.** Take the dispatch pattern and `gll_log_pnorm`; **refuse its
  probability clamp** — it is a downgrade against drmTMB's `logspace_add` path.

## Landing state

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main@8d441a32d` (#956) | yes | yes | #956 merged | **LANDED** |
| `claude/binomial-link-generalisation@5b6c13197` | yes | **yes** | none | **CARRIED-OVER** — Arc D mid-flight; D5–D8 owed. Resume: `cd /Users/z3437171/local-scratch/worktrees/drmTMB-links` |
| `claude/mspl-binomial-inference-promotion@b6626e117` | yes | **yes** | none | **CARRIED-OVER** — complete + reviewed; PR is **Shinichi's call** (Doc B). 6 behind main; merge main before any PR. Resume: `cd /Users/z3437171/local-scratch/worktrees/drmTMB-mspl-inference` |
| SE-calibration campaign | no | no | none | **CARRIED-OVER** — design agreed, nothing built. See "Campaign" below |
| `codex/mspl-binomial-glmm-experimental` (43 dirty entries) | no | no | none | **PROTECTED** — the recovery oracle. Never clean, reset, or stage |
| #955, #937, #858, #957–#960 | — | — | open | **PROTECTED** foreign lanes |
| ~13 historical `codex/*` branches with unpushed commits | mixed | no | — | **PROTECTED** — predate this session, untouched |
| five repository stashes | — | — | — | **PROTECTED** — do not pop/drop |

`handoff_gate.sh` **FAILS** on the historical unpushed branches above. They predate this session and
are declared here rather than landed. Both branches this session created **are pushed**.

## Next immediate steps — classify each OWED / DONE / RETRACTED / PROTECTED first

**Arc D, in order. Do not reorder D5 before the Julia check.**

1. **D5 — R surface.** Widen the `drm_family_type()` guard (`R/drmTMB.R:2924-2932`) to admit probit
   and cloglog; make `drm_dpar_link()` (`R/methods.R:5680`) return the fit's actual link instead of
   the constant `"logit"`; **add probit/cloglog cases to `drm_inverse_link()`
   (`R/methods.R:5633-5646`)** — it currently has none and sits on the
   `predict(type="response")` / `summary()` / `confint()` back-transform path. Leave
   `associate-pairs.R:1199-1211` and `missing-data.R:236-244` logit-only, and say so in a comment.
2. **D6 — tests.** `glm()` parity for both links; recovery on a random intercept;
   `predict(type="link")` vs `"response"` round-trip through the new inverse-link; **extreme-η tail
   behaviour showing the log-scale form beats a probability clamp**. **Update, do not delete**,
   `test-binomial-response.R:206-212`. `test-mspl-estimator.R:412-418` **stays a rejection test** —
   MSPL remains logit-only.
3. **D7** — `devtools::document()`, full tests, `--as-cran` (~22 min here).
4. **D8** — fresh Emmy review *against her own "demonstrably under-scoped" objection*, then put the
   **0.7.0-vs-0.7.1 decision** to Shinichi with evidence.
5. **Campaign** — only on Shinichi's GO. Write `PREREGISTRATION.md` **before** any run.
6. **MSPL PR** — only on Shinichi's word; merge `origin/main` in first (6 behind).

## Blockers / open questions

- **Owner decision, D8:** do probit/cloglog go into 0.7.0? Decide on the evidence, not now.
- **Owner decision (design 252 §9):** does a new *link* need its own capability-ledger evidence
  cells, or inherit binomial's? `AGENTS.md` rule 1 covers a new *family*. Gates any ledger movement.
- **Owner decision:** the MSPL PR.
- **No threshold** on the gradient/score diagnostic — open, see below.
- **The separated regime is still unevidenced for SEs** — that is what the campaign is for.

## Gotchas and failed approaches — read these, they cost real time today

- **`bf()` uses NSE.** `bf(fml)` where `fml` is a formula *variable* fails with
  *"inputs must be formulas"*. Pass the formula literally.
- **zsh does not word-split unquoted variables.** `git diff … -- $FILES` passes one giant pathspec
  and silently matches nothing. Inline the list or use an array.
- **Never pipe a long command into `head`.** SIGPIPE killed a `git apply -3` mid-way; git rolled back
  atomically while still printing "Applied patch … cleanly". The tree looked clean and nothing had
  applied. Redirect to a file and read it.
- **A reconcile's verification filter must cover the files *main added since the merge base*, not
  just the files the reconcile touched.** Missing that let `test-reml-binomial-coxreid.R` (new on main
  from #953) break unnoticed.
- **Re-run every sub-agent claim.** One agent fabricated an entire recon report — wrote no files,
  reported its hash check as "pending", invented a measurement table. Another shipped `vcov()` with
  duplicated dimnames and reported clean. Both were caught only by re-running. **A return contract
  that asks for conclusions invites narration; one that asks for pasted command output invites
  execution.**
- **`--as-cran` a *second* time** if commits land after the first run. The first result describes code
  that no longer ships.
- **Semantic brain search missed** the Culcita dataset and the equivariance property entirely; the
  deterministic grep found both. Walk the ladder.

## Evidence worth not re-deriving

- **The oracle.** MSPL SEs match ML `sdreport()` to 0.38 % / 0.01 % (q1) and 0.69 % (q2), converging
  monotonically 10.13 → 0.14 % as `c_n = 2√(p/n_eff)` vanishes. **The convergence is the evidence.**
- **glmer plateaus** at 1–2 % and does *not* converge monotonically — an irreducible implementation
  difference. It is a **sanity** arm with a loose bound; tightening it measures `lme4`.
- **The demo** (`scratchpad/mspl-vs-ml-demo.R`, MSPL lane): on a separated design, ML gives −19.26
  (SE 2195), glmer −33.05 (SE 2.17e6), **MSPL −5.52 (SE 2.29)**. ML and glmer disagree *with each
  other* by 14 log-odds — the tell that no finite MLE exists. Identified coefficients agree across all
  three to two decimals.
- **`unpenalized_gradient_max_abs` is NOT a usable diagnostic** — flat at 0.4082 across the entire
  separation spectrum. An earlier claim that it rises 0.13 → 0.41 compared *different fixtures* and is
  **RETRACTED**. The scale-free `unpenalized_score_distance` = `√(gᵀVg)` does separate the regimes
  (0.28–0.43 identified vs 0.61 separated) but the gap is modest; **no threshold is set.**

## Campaign (planned, unstarted)

**Estimand:** `R_j = mean_r(SE_j) / sd_r(β̂_j)`; `R = 1` is calibrated, `R < 1` anti-conservative
(the hazard). Report `sd` **and** a robust `mad × 1.4826`; **`sd` gates** — choosing the denominator
after seeing both is the failure a pre-registration prevents.

**Grid:** q1 `y ~ trt + (1|block)` with `η_d ∈ {0,−2,−4,−6,−10}` at `G ∈ {12,30}` (10 cells) + q2
`y ~ x + (1+x|block)` same gradient at `G = 30` (5 cells). `n_rep = 1000`, three engines
(drmTMB MSPL, drmTMB ML, `glmer(nAGQ=1)`) ≈ 45,000 fits. Seeds `20260809 + 100000*cell + r`.

**Bands, frozen:** identified `PASS R ∈ [0.95,1.05]`, borderline `[0.90,1.10]`; separated
`PASS [0.90,1.15]`, borderline `[0.80,1.25]` — wider **and asymmetric**, since conservatism is
harmless and anti-conservatism is not. **One anti-conservative FAIL fails the campaign.**

**Paired-reference clause (D-117):** if MSPL under-calibrates, check ML and glmer on the *same*
replicates before claiming any drmTMB defect.

**Compute: Totoro** — live, 384 cores, ControlMaster socket, no Duo. **Never GitHub Actions (D-50).**
**Risk: Totoro runs R 4.5.3, this work is on R 4.6.0** — drmTMB has compiled TMB code and must build
there first. Smoke one cell × 5 reps **on Totoro** before the grid. If it will not build, stop and
report; do **not** quietly fall back to a smaller local run.

Reuse `tools/run-135-trace-totoro.sh` (the `--list` / `--emit-jobs` / `--local-smoke` /
`--launch --cores` shape, gated behind `DRMTMB_TOTORO_GO=1`) and
`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/PREREGISTRATION.md`
(its 8-section structure).

## Environment

```sh
# Arc D (active)
cd /Users/z3437171/local-scratch/worktrees/drmTMB-links
# MSPL (complete, awaiting PR decision)
cd /Users/z3437171/local-scratch/worktrees/drmTMB-mspl-inference

R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::load_all()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::document()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'rcmdcheck::rcmdcheck(args="--as-cran", error_on="never")'
```

Runtime: R 4.6.0, drmTMB 0.6.0, TMB 1.9.21, lme4 2.0.1, glmmTMB 1.1.14, detectseparation 0.4.0.
**Never `git add -A`.** Never stage the dirty primary checkout
(`/Users/z3437171/Dropbox/Github Local/drmTMB`, 96 uncommitted paths, PROTECTED) or
`drmTMB-rose-nit` (the MSPL recovery oracle).

## Resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-claude-arcd-links-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
