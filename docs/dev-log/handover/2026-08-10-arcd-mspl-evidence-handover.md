# Session Handoff: probit/cloglog shipped · MSPL evidence · three self-corrections

Meta: 2026-08-09 → 2026-08-10 · from Claude to Claude · **cite by branch + SHA, never by path**

> **Filename note.** Deliberately NOT `2026-08-10-claude-handover.md` — that path is already taken by
> `claude/07-hash-ledger` ("0.7.0 readiness handoff", `55ae95a3`), a **different lane**. Adding a
> second would repeat a collision that has already caused real ambiguity in this repo twice.

## The one-paragraph version

`binomial(link = "probit")` and `binomial(link = "cloglog")` **now fit in drmTMB**, targeting 0.7.0
by owner decision, with both local gates green and a PR open. MSPL gained a link-general Jeffreys
helper internally while its **entry point stays logit-only**. A 60,000-fit pre-registered SE
calibration campaign ran on Totoro. Along the way five drmTMB defects were found and fixed, three of
my own claims were retracted, and an exchange with the gllvmTMB team corrected our reading of the
literature twice.

## Lanes

| Lane | Branch @ SHA | State |
|---|---|---|
| Arc D | `claude/binomial-link-generalisation` | **PR [#973](https://github.com/itchyshin/drmTMB/pull/973) OPEN, mergeable**, local gates green, **CI red — see blocker below** |
| MSPL evidence | `claude/mspl-binomial-inference-promotion` | pushed, **no PR — yours** |

`DESCRIPTION` is **0.6.0** on both. No ledger, no census, no release rung moved.

## THE ONE BLOCKER — 2 minutes, needs your hands

PR #973's CI fails on a **Python ledger validator**, not R:

```
SystemExit: mc-0568: current source blob differs for R/drmTMB.R
```

Cells `mc-0568/0569/0576` are certified against blob hashes of five files; Arc D changed two. **I ran
the re-certification with the repo's committed runner — it PASSES 4/4 on all three cells** (mean τ
relative error 0.099 / 0.166 / 0.061), proving Arc D does not change zero_one_beta model-15
behaviour. Output is in the worktree.

**I did not wire it into the ledger.** `AGENTS.md` fences that surface and the permission classifier
blocked it — I stopped rather than route around. Exact steps:
`scratchpad/2026-08-10-c17-recertification-BLOCKED.md` (in the links worktree).

## Landing State — `handoff_gate.sh` FAILS; everything unlanded is declared here

Both branches are **committed and pushed**. The gate fails only on untracked working notes, declared
below per option (b). Nothing is silently uncommitted.

| Artifact | Landed | State |
|---|---|---|
| `claude/binomial-link-generalisation@2c60abb1f` | pushed | **CARRIED-OVER** — PR #973 open, not merged. Resume: `cd /Users/z3437171/local-scratch/worktrees/drmTMB-links` |
| `claude/mspl-binomial-inference-promotion@7cacd1a68` | pushed | **CARRIED-OVER** — no PR, Shinichi's call. Resume: `cd /Users/z3437171/local-scratch/worktrees/drmTMB-mspl-inference` |
| `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1/` | **NO** | **CARRIED-OVER — the C17 re-certification evidence (PASS 4/4).** Untracked deliberately: it is ledger-adjacent, `AGENTS.md` fences that surface, and the permission classifier blocked writes there. **Do not delete.** Rename to a truthful `2026-08-10-…` date when wiring it in. |
| `scratchpad/*.md` (both worktrees) | **NO** | **CARRIED-OVER** — working notes, `Rbuildignore`d, conventionally untracked here. Contains the two scout reports, the brain-lessons draft, the gllvmTMB reply draft, and the C17 blocker writeup. Read before assuming anything is missing. |
| PR #973 · #977 · #983 · #984 | — | open |
| gllvmTMB PR #952, `codex/mspl-binomial-glmm-experimental`, five repo stashes, primary checkout | — | **PROTECTED** — foreign lanes; do not touch |

## What shipped, verified

| Gate | Arc D | Phase B |
|---|---|---|
| `--as-cran` | **0 / 0 / 1** ("New submission") | **0 / 0 / 1** |
| `NOT_CRAN` full suite | **zero failures** | **zero failures** |

Reviews: **Emmy GO**-with-conditions (3 of 4 met, 1 deferred with a written audit showing no live
defect) · **Noether SOUND**-with-fixes, all applied · **Melissa 0 drift**.

Comparison against `glm`, `lme4::glmer`, `glmmTMB` across all three links: drmTMB and glmmTMB agree
to **every printed digit**; glmer diverges only on the non-canonical links (1.2e-3 probit, 3.6e-3
cloglog), the known lme4-vs-TMB difference.

**Published artifact — keep and update, do not re-create:**
https://claude.ai/code/artifact/919665ed-56fc-4604-8f46-5ab766572d15
Source: `binomial-link-comparison.html` in this session's scratchpad. It carries both comparison
tables, the separation panel, and the "can we get to the truth" argument. Revised 2026-08-10 after
the literature corrections — **its earlier text conflated existence with the softness bounds.** To
update from a future session, pass that URL as `url` to the Artifact tool, or it will mint a new
one.

## Five defects fixed

1. **Bivariate branch had no `link_code`** — 223+ errors, every bivariate fit dead. `make_tmb_data_core()`
   has **19** model_type declarations, not 17; the bivariate one uses `switch()`, so the grep that
   found the rest missed it.
2. `test-phylo-utils.R` hand-built data list, same cause — 6 errors.
3. `predict_parameters_inverse_link_derivative()` had no probit/cloglog arm — every probit SE would
   have aborted.
4. **`binomial_start()` hardcoded logit** — probit started ~70% too far out. Found by Emmy from
   inspection alone.
5. **cloglog weight returned `+Inf`** (wrong sign) below `η = −745.13`. Found by Noether.

Plus `mspl_penalty_components()` silently using the logit default, and `print()` not naming the link.

**The unifying lesson, now in the brain:** *grep finds what NAMES a contract, not what ASSUMES the
old one.* Enumerate by behaviour — "who reads this value?" — not by pattern.

## The campaign — and its retraction

60,000 fits, pre-registered before any replicate.
`docs/dev-log/simulation-artifacts/2026-08-09-mspl-se-calibration/`

**Licensed:** MSPL standard errors are calibrated in the **identified regime**, `R ∈ [0.93, 1.05]`,
bootstrap MCSE ≈ 0.02. Logit only, tested grid only.

**Retracted in `VERDICT.md`:** my first headline said "zero anti-conservative failures; deep
separation is conservative, harmless." Both halves failed. "Conservative" was **estimator collapse** —
at `η_d = −10`, 996/1000 replicates take essentially one value, so `sd(β̂)` measures atom-hopping.
And a cell was **silently dropped**, violating the pre-registration's own §8 rule 5, so the count
covered 14 of 15. Caught by Fisher, verified against raw replicates, re-analysed paired.

**Real structure the first pass hid:** every degenerate cell is **q1**; **no q2 cell degenerates**.

**Open issues filed:** [#977](https://github.com/itchyshin/drmTMB/issues/977) (MSPL returns
`convergence = 0` with `NA` SE), [#983](https://github.com/itchyshin/drmTMB/issues/983)
(`estimator` reports `"ML"`, accepts only `"ml"`), [#984](https://github.com/itchyshin/drmTMB/issues/984)
(`n_eff` substitution).

## The literature question — settled, after three wrong answers

`docs/design/253-mspl-nonlogit-links-derivation.md` carries the full trail. Final position:

| result | link-general? |
|---|---|
| Jeffreys barrier / fixed-effect finiteness | **YES, proved** — KF2021 Thm 1, §3.1, Table 1 |
| composite existence, **exact** likelihood | **YES** — 2023 p. 6 |
| **softness scaling `c = 2√(p/n)`** | **NO — logit delta-method at β = 0** |
| composite existence under **Laplace** | numerical evidence only, and it is **glmer's** |

**Two independent reasons the MSPL guard stays.** (1) `c_n = 2√(p/n_eff)` is the **wrong constant**
for probit/cloglog — probit's `ω(0) = 2/π` gives `c ≈ 1.25√(p/n)` — link-specific, genuine open
research. (2) **No drmTMB-Laplace evidence for any link** — link-independent, and owed for logit too.

**I got this wrong three times in three days**, each round confidently stated: original derivation
(no papers) → Addendum 1 (2023 + 2026) → Addendum 2 (+ KF2021) → Addendum 3 (+ gllvmTMB's review).
The failure mode was **asserting the negative** — "the authors do NOT defer this" — from sources
that were *silent* rather than contrary.

## E1 probe — HALTED before grading, deliberately

`docs/dev-log/simulation-artifacts/2026-08-09-mspl-nonlogit-finiteness/INSTRUMENT-FINDING.md`

The logit control failed, which by the prereg's own rule means the harness is wrong. Inspecting a ray
showed worse: **the frozen rule cannot be evaluated as written** — past `t ≈ 10³` every weight
underflows and there is no number left to test monotonicity against. Rescoring that as "descent"
would flip every fixture FAIL → PASS, which is the same post-hoc reinterpretation Fisher had caught
hours earlier. **Halted rather than adjusted.** Addendum 3 additionally retires rebuilding it against
the 2026 Theorem 4.1, which is not transportable to a GLMM.

## Owed / next

1. **Wire the C17 re-certification** (above) → CI green → merge #973 if you want it.
2. **Send or discard the gllvmTMB reply** — `scratchpad/2026-08-10-message-to-gllvmTMB.md`. It raises
   a real divergence: they hold that finite estimates license **neither** Wald SEs nor intervals;
   drmTMB ships SEs and blocks intervals. Our own campaign evidence arguably supports their stricter
   line. **Worth deciding — it is a public-surface question.**
3. **TMB-Laplace finiteness evidence** — the only remaining technical gap, owed for logit too.
4. **Emmy condition 1** — remove the `= 0` default at `src/drm_response_kernels.h:27`; deferred with
   an audit showing 0 binomial call sites rely on it.
5. **MSPL PR** — unchanged, yours.

## Do NOT

- Do not open the MSPL guard. Two independent reasons now, both documented.
- Do not quote the retracted "conservative/harmless" reading, the unpaired engine ratios, or the
  first-pass MCSE.
- Do not treat the E1 halt as a failure to be worked around — the criterion needs revising, not the
  data reinterpreting.

## MSPL — every lesson, in one place

Consolidated because this arc's knowledge is scattered across three design docs, two campaigns and
an external exchange. **Read this section before touching MSPL.**

### CAN WE GET TO THE TRUTH? — the epistemic point, and the one most easily lost

Under **complete separation the data carry no information about the slope.** Every value above some
threshold fits the observations equally well. The truth (0.8 in our fixture) is **not identified by
that dataset**, so *no* estimator can recover it — not MSPL, not a better optimiser, not more
compute. This is a property of the data, not a deficiency of any method.

**So the question is not "which estimator gets closest to the truth."** It is *"which estimator says
honestly that the truth is out of reach."*

| engine | behaviour under complete separation | honest? |
|---|---|---|
| ML, `glmer` | refuse to fit | **yes** — unhelpful but unmistakable |
| `glmmTMB` | returns intercept 13.955 with **SE 6 146 177**; `NaN` SEs under quasi-separation | **no** — looks like a result |
| **MSPL** | 214.051 with **SE 177.812** | **yes** — SE ≈ estimate says *no information* |

**Read the ratio, never the point estimate.** MSPL's contribution is not a better number; it is a
finite, interpretable, honestly-labelled *non-answer* where the alternatives either refuse or
mislead. Anyone reporting an MSPL slope from separated data as an effect size has misread it, and
that is the single most likely way this estimator gets misused.

This also settles the earlier unease about the magnitude: **214 is not failed shrinkage.** KF2021
Thm 2 shows shrinkage is toward equiprobability under an information metric, not toward zero in
Euclidean terms, so *"only typically, rather than always, smaller in absolute value."*

### What MSPL is and is not

- **Guarantees** an estimate in the *interior* of the parameter space when no finite MLE exists.
- **Does not guarantee a small estimate.** The penalty is deliberately *soft* — scaled to vanish as
  information accumulates so ML asymptotics survive (2023 abstract). Under separation you get
  **finite but arbitrary magnitude**: measured 177→745 (complete) and 83→3 197 (quasi-complete)
  across five seeds, every fit reporting `convergence = 0`.
- **Shrinkage is toward equiprobability under an information metric, not toward zero in Euclidean
  terms** (KF2021 Thm 2). So a slope of 214 is not failed shrinkage — reading the point estimate as
  an effect size is the error. **The honest signal is the ratio**: SE ≈ estimate ⇒ *no information*.
- **Quasi-complete separation gives LARGER estimates than complete**, systematically. Counter-intuitive
  but reproducible.

### The literature, settled

| result | link-general? | source |
|---|---|---|
| Jeffreys barrier / fixed-effect finiteness | **YES, proved** | KF2021 Thm 1 + §3.1 + Table 1 |
| condition on the link | **`ω(η) = g(η)²/[G(η){1−G(η)}] → 0` as `η → ±∞`**; only X full rank needed; any penalty power `a > 0` | KF2021 §3.1 p. 76 |
| composite existence, **exact** likelihood | **YES** — second half turns only on the likelihood being a pmf | 2023 p. 6 |
| variance-component penalty | **link-free** — acts on the Cholesky | 2023 eq. 5 |
| **softness scaling `c = 2√(p/n)`** | **NO — logit delta-method at β = 0** (`ω(0)=¼`). Probit's `ω(0)=2/π` ⇒ `c ≈ 1.25√(p/n)` | 2023 §7 p. 7 |
| composite existence under **Laplace** | **numerical evidence only, and it is glmer's** | 2023 p. 6 |

### Why the guard stays — two independent reasons

1. **`c_n = 2√(p/n_eff)` is the WRONG CONSTANT for probit/cloglog**, not merely unproved.
   Link-specific; genuine open research.
2. **No drmTMB-Laplace finiteness evidence for ANY link.** Link-*independent* — **we owe this for
   logit too.** The estimator we ship rests on the authors' numerics, obtained on lme4/glmer.

### Implementation facts worth not rediscovering

- The Jeffreys weight is the **EXPECTED (Fisher)** information. Expected and observed coincide *only*
  for canonical logit, so **only a non-canonical link can catch a drift** to observed information.
- cloglog's `log μ` needs a **two-branch** form: the direct `log(-expm1(-exp(η)))` returns **`+Inf`**
  (wrong sign) below `η = −745.13`. Series branch: `η + log1p(-exp(η)/2)`.
- **Never `stats::make.link()`** in the penalty: it clamps to `[eps, 1−eps]` and `cloglog$mu.eta`
  floors at `.Machine$double.eps`, which changes the penalty *value*. Fine for *starting values*.
- `n_eff = Σ(trials × frequency)` substitutes for the paper's `n` — equal for single-trial Bernoulli
  only ([#984](https://github.com/itchyshin/drmTMB/issues/984)).
- MSPL can return `convergence = 0` with an **`NA` standard error**
  ([#977](https://github.com/itchyshin/drmTMB/issues/977)).
- Internals are **not exported**: on an installed package use `drmTMB:::`, unlike `load_all()`.

### The open design question — genuinely undecided

drmTMB ships MSPL **Wald SEs** and blocks intervals. **gllvmTMB holds that finite estimates and a
finite penalized Hessian license *neither*.** KF2021 §2.1 condemns the *intervals*; whether reporting
an SE invites the user to build the failing interval is a judgement call. **Our own campaign evidence
arguably supports their stricter line.** Draft reply awaiting Shinichi:
`scratchpad/2026-08-10-message-to-gllvmTMB.md`.

### Process lessons this arc paid for

- **Grep finds what NAMES a contract, not what ASSUMES the old one.** Enumerate by behaviour.
- **Asserting the negative from a silent source** is how three successive corrections all went wrong.
  "The authors do not defer this" was inferred from papers that were quiet, not contrary.
- **A frozen decision rule protects against choosing the statistic, not against the statistic being
  the wrong one.** `R > 1` was graded against bands without asking whether `R` was *meaningful*.
- **Re-run every sub-agent claim.** One fabricated a file it never wrote; two over-reported defects.

## Environment

```sh
cd /Users/z3437171/local-scratch/worktrees/drmTMB-links          # Arc D
cd /Users/z3437171/local-scratch/worktrees/drmTMB-mspl-inference # MSPL
# Totoro: ~/drmtmb_se_cal (package built in ~/R/lib)
```

**Totoro gotchas paid for twice:** an *installed* package hides internals (`drmTMB:::` needed, unlike
`load_all()`), and local fixes do not reach the cluster — redeploy and rebuild. **Never `git add -A`.**
The primary checkout stays PROTECTED and dirty. A second Claude session was active in
`drmTMB-missing-data-0809` — its work landed as #972; do not touch that worktree.


## Resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-10-arcd-mspl-evidence-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
