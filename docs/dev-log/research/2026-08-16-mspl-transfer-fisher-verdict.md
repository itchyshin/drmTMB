# Should MSPL be generalised to boundary conditions? — Fisher's verdict

**2026-08-16 · inference review · read-only in `.worktrees/cran-07` · feeds the MSPL transfer packet**

## Verdict in one line

**RESEARCH-FIRST, and DECLINE the default.** The shipped penalty demonstrably removes the
boundary pile-up, but on my own measurement it *relabels* more than it *repairs*: it helps only
where the true SD sits below the penalty's implicit anchor at `sd = 1`, it makes bias **worse**
above it, and it is **not scale-equivariant** on a Gaussian response — the same data in different
units gives a different estimate. Two cheap pre-run tests (below) decide whether an option is
worth building; neither has been run at campaign scale, and neither costs more than an hour.

---

## 0. My own probe — exploratory, 400 replicates, laptop, NOT a gate

I ported the *shipped* variance penalty faithfully — `D(t) = -t²/2` for `|t|≤1`, `-|t|+1/2`
otherwise (`R/mspl.R:247-256`; design `docs/design/250-mspl-binomial-logit-alignment.md:161-167`),
applied to `log L11` with `c_n = 2*sqrt(p/n_eff)` (`R/mspl.R:112-128`; design 250:129) — onto the
Gaussian one-way marginal likelihood at the D-117 design (`g = 10`, `n_per = 4`, `sigma = 0.7`,
`p = 2`, so `c_n = 0.447`). Status: **exploratory, un-preregistered, ~1.5 pt MCSE on relative
bias, not evidence for any claim.** It exists to name the pre-run tests, not to pre-empt them.

| `sd_true` | ML rel. bias | MSPL rel. bias | ML frac. `< 1e-3` | MSPL frac. `< 1e-3` | MSPL min |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0.5 | −13.2% | **−6.6%** | 5.5% | **0%** | 0.082 |
| 1.0 | −8.3% | −7.9% | 0.25% | 0% | 0.161 |
| 2.0 | −7.5% | **−8.9%** | 0% | 0% | 0.656 |
| 4.0 | −7.5% | **−9.5%** | 0% | 0% | 1.573 |

**Scale test (300 replicates, same seeds):** fit `y`, then fit `100*y` and divide back.
mean MSPL SD **0.4747** vs **0.3919**; worst per-replicate discrepancy **0.374** — comparable to
the parameter itself. ML is equivariant by construction; MSPL as ported is not.

---

## 1. Would a soft penalty fix the measured coverage problem?

### (a) Pooled coverage — a small gain is plausible; the mechanism is mostly relabeling

It removes the pile-up: 5.5% of ML estimates fell below `1e-3` and **none** under the penalty,
minimum 0.082. Because the penalized objective behaves like `+c_n·log(sd)` as `sd → 0` (linear arm
of `D`), the optimum is strictly interior — the same device as Chung et al. 2013's `blme`, at
**45% of its strength** here, and vanishing as `n` grows.

But the quantity D-117 scores is a *profile interval*, and `profile_boundary ⟺ profile_lower == 0`
exactly (`docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/VERDICT-100K.md:97-98`).
A penalized profile also diverges at `sd = 0`, so the penalized lower endpoint is **always
positive**: the 49.7% boundary incidence in `g10_n04_sd05` (VERDICT-100K.md:99-105) would read as
~0%. **That is not by itself a repair.** The upper endpoint — the only side that can miss at a
boundary replicate — is set by the *likelihood's* decline in a region where `D` is nearly flat, so
it barely moves. The chi-bar arm is the precedent to fear:
`docs/dev-log/simulation-artifacts/2026-08-05-d117-chibar-cutoff-arm/VERDICT.md:93-97` establishes
that the boundary sub-population is a **selection effect, not a calibration error**, and that "no
cutoff choice repairs it". A penalty is not a cutoff, but it attacks the same symptom from the
same side, and its most certain effect is to delete the *flag*, not the *miss*.

**The scoring rule that follows** (non-negotiable in any campaign): conditional coverage must be
computed on the **ML-defined** boundary subset via paired seeds. Scoring MSPL on its own boundary
flag is guaranteed to report a fix that may not exist.

### (b) The 5.7:1 / 2:1 miss asymmetry

Under ML the asymmetry is 5.72:1 upper-side; REML halves it to 2.03:1 while widening intervals
10.7% (`docs/dev-log/simulation-artifacts/2026-08-15-d117-reml-arm/VERDICT.md:79-86`). REML earned
that by moving the **centre** (bias −10.92% → −4.60%, VERDICT.md:62,79). MSPL moves the centre by a
comparable amount **at `sd_true = 0.5`** (−13.2% → −6.6% in §0) — but by construction that shift is
toward `sd = 1`, and at `sd_true = 1.0` it is essentially **zero** (−8.3% → −7.9%). The D-117 grid
is `sd_mu ∈ {0.5, 1.0}` (VERDICT-100K.md:99-105). **Both grid points are at or below the penalty's
attractor.** A campaign on that grid cannot distinguish "the penalty corrects bias" from "the
penalty pulls toward 1 and 1 happens to be the truth". This is the rigged-DGP failure mode, and it
would be self-inflicted.

### (c) Point-estimate bias, net direction at g = 10

The honest answer is **truth-dependent, and that is the finding**. ML bias is downward; the
penalty's push is upward only for `sd < 1`. At `sd_true ∈ {2, 4}` the penalty enters its linear arm
and makes bias **worse** (−7.5% → −8.9% / −9.5%). An estimator whose bias correction changes sign
at `sd = 1` **in the user's own response units** is not a bias correction; it is a prior centred on
an accident of measurement. §0's scale test confirms this operationally: `y` in metres and `y` in
centimetres are different estimators. For binomial the anchor is defensible — the logit latent
scale is fixed — which is exactly why the published route is binomial-only. Generalising to
Gaussian/Gamma/lognormal requires a **new** penalty (e.g. on `log(sd_u/sigma_resid)`), which is a
derivation the Sterzinger–Kosmidis trilogy does not supply.

### (d) The blocker nobody has priced: MSPL has no interval surface at all

`confint()` (`R/profile.R:420`), `profile()` (`R/profile.R:781`), `logLik()`
(`R/methods.R:2612`), `anova()` (`R/methods.R:2707`) and `summary(conf.int = TRUE)`
(`R/methods.R:4158`) all **abort** on an MSPL fit. Design 250:255 states the stored diagnostics are
"not evidence of nominal interval coverage or a universal non-boundary theorem". So the proposal
routes the package's hardest *inference* problem through the estimator with the **least developed
inference machinery**: a penalized profile has no χ²₁ reference distribution off the shelf, and it
would have to be derived, not assumed.

Worse, the one interval-adjacent route MSPL does have is designed to fail in the target regime.
`drm_mspl_wald()` inverts the **unpenalized** observed information at the penalized estimate
(`R/mspl-estimator.R:457-470`, design 251 §2) behind an SPD + `rcond > 1e-12` gate
(`R/mspl-estimator.R:482-510`). Near a variance boundary that unpenalized Hessian is precisely
where positive-definiteness fails, and the method returns NA by design
(`R/mspl-estimator.R:88-97`). Kosmidis & Firth's warning transfers directly: a finite estimate
under a penalty does not imply a calibrated interval.

### (e) One structural cost users will feel

Under the penalty `sd_u = 0` is **unattainable** (§0: minimum 0.082 at `sd_true = 0.5`). Any test
of "is there a random effect?" becomes structurally non-null. That is an inference regression, not
a rounding detail, and it must appear in any pre-registration as a `sd_true = 0` cell.

---

## 2. Estimator identity and comparability

`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/COMPARATOR.md:41-49`
records paired-seed agreement with `lme4::lmer`: point estimates to **~1e-6**, boundary incidence
**4000/4000**, conditional coverage identical to four decimals. That agreement is how D-117
attributes the shortfall to **ML at ten groups** rather than to drmTMB. It is the package's only
independent estimator oracle for this cell.

- **MSPL as default destroys it.** No external package computes this criterion; `blme` is the
  nearest relative and uses a different penalty at a different strength. The attribution argument
  that currently protects drmTMB would have to be rebuilt from scratch, against no comparator.
- **MSPL as an option is survivable but not free.** The support-cell TSV keys evidence on
  `estimator_requested` / `estimator_effective`
  (`docs/design/218-structured-q-series-completion-map.md:39-52`), and the ladder starts at
  `planned/unsupported` (218:64-65). **No existing coverage or recovery evidence transfers to a new
  token** — this is the lesson `AGENTS.md` records from the AGHQ arc ("a new token would flip the
  family-map slope to 'absent'"). Every MSPL row enters the census empty.
- Note the existing route already forbids `REML` + MSPL (`R/mspl-estimator.R:212-214`), so the
  most promising arm — REML's centre correction *plus* an interior-keeping penalty — **does not
  exist in code today** and is itself an implementation slice.

---

## 3. What evidence would be needed before ANY user-facing claim

**Two pre-run tests first — hours, not compute-days. Both must pass or the arc stops.**

- **PRT-1 scale equivariance.** Fit `y` and `c·y` for `c ∈ {0.01, 100}`; require the back-scaled
  estimate and interval to agree to optimiser tolerance. §0 predicts **failure** for the shipped
  penalty on Gaussian. Failure here is not fatal to the idea, but it forces the penalty to be
  re-derived on a standardised coordinate before any campaign is worth running.
- **PRT-2 anchor sensitivity.** 400 replicates at `sd_true ∈ {0, 0.25, 0.5, 1, 2, 4}`. If the sign
  of the bias change flips across `sd = 1` (as §0 shows), the D-117 grid is unusable as-is.

**Then, and only then, the campaign** — generalising the existing harness
(`.../2026-08-04-d117-10group-profile-gate/d117_profile_gate.R` and
`.../2026-08-15-d117-reml-arm/`), pre-registered before any fit:

- **Arms, paired seeds, 4 × the D-117 cost:** ML (control, must reproduce 0.924800 exactly, the
  discipline at REML VERDICT.md:34-44) · REML (must reproduce 0.946325) · MSPL · REML+MSPL.
- **Cells:** `g ∈ {5, 10, 20, 40}` (does `c_n → 0` leave large-`g` inference unharmed?),
  `n_per ∈ {4, 10}`, `sd_true ∈ {0, 0.25, 0.5, 1, 2, 4}` — the grid must straddle the anchor.
- **Primary endpoint:** pooled profile-interval coverage of `sd:mu:(1 | g)`.
- **Secondary, pre-declared:** conditional coverage **on the ML-defined boundary subset**;
  miss asymmetry; interval width; and recovery bias with the statistic **named in advance** —
  VERDICT-100K.md:171-190 shows statistic choice spans −0.12 to −0.77 on identical data.
- **Recovery criterion:** must be frozen before scoring. D-117 discharged only half precisely
  because the recovery half was never made scoreable (VERDICT-100K.md:243-251).
- **Falsifier stated up front:** if MSPL's conditional coverage on the ML-boundary subset does not
  beat REML's 0.828 (REML VERDICT.md:62), the penalty relabels rather than repairs, and the arc
  stops.

---

## 4. Recommendation, and the attack surface

**RESEARCH-FIRST. Do not implement as a default. Do not ship an option yet.**

Reasoning a reviewer should attack:

1. *"You measured a port, not the package."* True — §0 is my own Gaussian port of the shipped
   penalty, 400 replicates, on a marginal likelihood I wrote. It is exploratory. But the anchor at
   `L11 = 1` and the linear arm of `D` are algebraic facts of `R/mspl.R:247-256` and design 250:161,
   not artifacts of my code, and the scale non-equivariance follows from the penalty being a
   function of an unstandardised `log L11`.
2. *"REML already gets to 0.9463; why keep pushing?"* Because the residual is boundary-mass
   (REML VERDICT.md:62-68: conditional 0.828, incidence still 13.8%). MSPL is a legitimate
   candidate for exactly that residual — which is why the answer is *research-first* and not
   *decline*.
3. *"Usability does not bend — this makes fits 'just work'."* An estimator that changes with the
   units of `y`, that cannot report an interval (§1d), and that makes `sd_u = 0` unreachable (§1e)
   is not a usability win. It is a usability *hazard* wearing a convenience costume.

If the packet must record a single next action: **run PRT-1 and PRT-2, and report both before any
compute is requested.**

> Related: `docs/design/250-mspl-binomial-logit-alignment.md` · `docs/design/251-...` ·
> `docs/design/219-structured-re-small-sample-bias-correction.md:18-33` (the Wald-only,
> structured-only centre shift that already exists and does not reach boundaries) ·
> `R/mspl-estimator.R` · the three D-117 verdicts cited throughout.
