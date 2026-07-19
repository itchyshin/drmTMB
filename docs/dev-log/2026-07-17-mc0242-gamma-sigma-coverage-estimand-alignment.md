# mc-0242 Gamma σ-RE coverage — S0 gate spec (rev 2, PLAN-REVIEW RATIFIED)

**Status:** Pre-compute S0 estimand freeze. Fisher (method) + Rose (scope) plan-review both returned
**CONDITIONAL-DONE**; every required fix is folded in below. No compute has run. Aligned to the
**mc-0017 methodology** (2026-07-17 beta-phylo arc), the current standard this arc "reuses exactly."

**Lane goal:** a D-43-passed evidence-tier verdict for `mc-0242` — either
`inference_ready_with_caveats` with a certified M-floor and an honestly-scoped claim_boundary, or a
documented non-promotion — ledger/docs/after-task consistent.

**Cell today:** `mc-0242` = gamma / model_type 5 / dpar **sigma** / `ordinary_re_intercept`, tier
**`point_fit_recovery`** (Arc 2c), at `cells.tsv` line 246 (**key edits by cell_id — line numbers
are branch-dependent**; line 247 is the REML-rejection sibling mc-0243, do NOT touch it). Siblings
promoted with this methodology: lognormal `mc-0382` (Arc 4a), beta-phylo `mc-0017` (mc-0017 arc).

---

## 1. Coverage estimand + SCALE CONTRACT (corrected per Fisher)

Target: the **population SD of the σ random intercept**, true value **0.40**, being the SD of the
simulated `u` where `sigma_i = exp(-0.6 + u[id])` and `sigma` = Gamma coefficient of variation
(shape = 1/σ², scale = μ·σ², log link; ledger mc-0238). `u` lives on the **log-CV (= log-sigma)**
scale, so 0.40 is a log-CV-scale SD.

**Scale of comparison — the interval is scored on the NATURAL RE-SD scale, not the internal log-SD
scale:** `confint(fit, parm="sd:sigma:(1|id)", method="profile")` carries `transformation="exp"`
(R/methods.R:4309), so its endpoints are `[exp(L_int), exp(U_int)]` — a monotone back-transform of
the internal `log_sd_sigma`. The Wald arm likewise exp()s the sdreport estimate
(generate-profile.R:263-264). Both arms are compared to the truth **0.40 on that same natural RE-SD
scale**; **an exp back-transform IS applied to the interval, and 0.40 is already on the
post-transform scale.** (mc-0382's ~0.93 coverage from the identical call confirms this empirically —
a log-scale mismatch would give coverage ≈ 0.)

| quantity | scale | value |
|---|---|---|
| truth (SD of `u`) | natural RE-SD, log-CV units | 0.40 |
| interval endpoints | natural RE-SD = `exp(internal log_sd_sigma)` | `[exp(L_int), exp(U_int)]` |
| comparison | `0.40 ∈ [exp(L_int), exp(U_int)]` | — |

**Type distinction from mc-0017.** mc-0017's target was an *unbounded fixed coefficient* (Wald ≈
profile). **mc-0242's is a realised RE-SD bounded at 0** — the Arc-4a situation: profile genuinely
matters (Wald-on-log-SD → ∞ upper at small M; profile allows the SD=0 boundary and returns finite
intervals), and the realised-vs-population trap applies → the DGP must be **iid uncentered** (§2).
Both arms are still reported side by side; superiority is claimed only if the data show it.

## 2. DGP (Gamma, log link) — iid uncentered

Family-swap of the lognormal coverage spec (generate-profile.R:175-199):

```r
gamma_sigma = list(
  true_sd = 0.4, sdrow = "log_sd_sigma", sd_parm = "sd:sigma:(1 | id)",
  fit = function(d) drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = Gamma(link = "log"), data = d),
  sim = function(M, ne, seed) {
    set.seed(seed)
    id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
    x  <- stats::rnorm(n)
    u  <- stats::rnorm(M, sd = 0.4)          # IID, UNCENTERED (Arc 4a correction; §1)
    mu <- exp(0.2 + 0.5 * x)
    cv <- exp(-0.6 + u[id])                   # Gamma's own recovery baseline (CV ~ 0.55)
    data.frame(y = stats::rgamma(n, shape = 1/cv^2, scale = mu * cv^2), x = x, id = id)
  }
)
```

**Grid:** M ∈ {8, 16, 32, 64}; n_each = 12; **N = 1200/cell** (MCSE ≈ 0.007 at coverage ≈ 0.93);
seeds reused across cells (`SEED_BASE + 1:NSIM`), identical to the lognormal/binomial harness.

**Pre-registered per-M point-bias reporting (Fisher fix F2 — closes the recovery-fixture gap):**
the campaign REPORTS, for every M, the mean point estimate and relative bias of the RE-SD **at the
coverage fixture itself**, computed from the retained raw TSV as
`sd_hat = sqrt(wald_lower · wald_upper) = exp(estimate)`. This measures the Laplace point bias at the
exact iid-uncentered n_each=12 draws for all four M — so the coverage claim rests on the coverage
draws, not on the imported centered/n_each=15/n_id=40 recovery number (which is unmeasured at M=8/16).

## 3. Design decisions (ratified)

| # | Decision | Rationale | Residual (disclosed) |
|---|----------|-----------|----------------------|
| D1 | **iid UNCENTERED** `u ~ N(0,0.4)` | Realised-RE-SD coverage; centering changed the estimand (Arc-4a v1) | Diverges from the Arc-2c recovery DGP (mean-centered `u`); §2 per-M bias reporting repairs the missing measurement, not just discloses it. |
| D2 | **n_each = 12** | Matches mc-0382 + harness default → mc-0242 vs mc-0382 differ only in family | Recovery used n_each=15; claim names n_each=12 (measured directly per §2). |
| D3 | **baseline intercept −0.6** (CV ≈ 0.55) | Gamma's own recovery/test baseline | Lognormal used −0.5; estimand SD=0.4 unchanged. |
| D4 | **true SD = 0.4, single fixture** | Same estimand as mc-0382 | One true-SD, one n_each; claim fences this. |
| D5 | **profile promotes; Wald reported alongside** | σ-RE SD bounded at 0 → profile decisive (§1) | Finite profile *endpoints* at small M unproven → §6 gating smoke. |
| D6 | Venue **Totoro** | Ordinary iid σ-RE, ~4,800 fits, minutes on ≤90 cores | See §6 for the pinning-verification + repro requirements. |

## 4. Pre-registered gate (frozen; from mc-0017 §5) + directional pre-commit

Per cell (M), N replicates, method ∈ {wald, profile}, target `sd:sigma:(1|id)`:
`coverage_hat = (1/N) Σ 1{ 0.40 ∈ [L_r, U_r] }`, reported as **hits/N = rate (MCSE; exact binomial
95% CI)** with below-L / above-U directional-miss counts; interval failures tallied, never dropped.

1. **Finite-profile policy:** `profile_finite_rate` per M — `=1.000` clean · `≥0.99` promote with the
   failure count+rate disclosed and coverage over finite profiles only · `<0.99` **withhold**.
2. **Calibration:** exact-binomial 95% CI of coverage **overlaps `[0.925, 0.975]`**. Over-coverage
   (CI above 0.975) promotes, labelled "conservative." **Withhold** only if the CI lies **entirely
   below 0.925**, or any computability failure.
3. **Directional label (verbatim, naming the WORST M in the promoted range):** "nominal within
   Monte-Carlo error" (CI brackets 0.95) · "mildly anti-conservative" (CI centre <0.95, not
   bracketing) · "conservative" (CI above 0.975).
4. **Certified M-floor:** lowest M clearing 1+2. Report EVERY M incl. failures; never conflate
   "profile removed the ∞-width artifact" with "coverage cleared the band."
5. **Pre-registered directional prediction (Fisher F3):** because the RE-SD is biased LOW under
   Laplace at small M, the profile interval shifts down, so it should under-cover 0.40 by **missing
   ABOVE** — `truth_above_interval` is expected to exceed `truth_below_interval`, worsening as M
   shrinks. A finding of the opposite pattern is a red flag to investigate, not to promote around.
6. **M=8 is exploratory-only, floor expected at M≥16 (pre-declared):** the direct sibling mc-0382
   excluded M=8 and the bias is worst there; M=8's likely non-promotion is declared now, not post-hoc.
   N=1200 gives a CP half-width ~0.015, so any M whose coverage CI straddles 0.925 is reported as
   **borderline, not firmly certified** (a second seed batch could flip it).

D-43 adjudicates **wording, not the band.**

## 5. Process order, claim template, ledger mechanics (corrected per Rose)

**Process:** draft the `claim_boundary` text BEFORE dispatching D-43. **S4 panel:** fresh, memo-blind
contexts (briefed only on campaign evidence + this frozen S0), default NOT-DONE, ≥2 withholds, and
**≥1 lens not used in this plan-review** → since plan-review = Fisher+Rose, **S4 includes Noether**
(and optionally Pat).

**Drafted claim_boundary template (fill the ⟨…⟩ from campaign output; frozen fence verbatim):**
> Arc 4b iid-v2: the Gamma sigma random intercept via ML-Laplace has ⟨finite/⟨rate⟩-finite⟩
> profile-interval coverage at true SD 0.40, n_each=12 and exactly M=⟨floor set⟩: ⟨hits/N=rate (MCSE;
> exact 95% CI) per M⟩, with ⟨0 / count⟩ failures. Measured per-M RE-SD point bias ⟨mean %⟩. The
> interval is **⟨directional label §4.3, worst-in-range⟩**, so this is inference_ready_with_caveats
> only — Monte-Carlo-coverage-backed unlike the interval_feasible cells. Residual lever is **AGHQ**
> (non-Gaussian); REML is banned for this family (mc-0243). **The lognormal mc-0382 numbers are NOT
> Gamma evidence.** Excludes M=⟨8 if excluded⟩, untested M/SD/replication designs, sigma slopes,
> labelled blocks, combined mu+sigma random effects, REML, and supported; and the recovery-fixture
> divergence (recovery was mean-centered at n_each=15/n_id=40, coverage is iid-uncentered n_each=12).

**Ledger edit targets (schema — `coverage_status` does NOT exist; caveat lives in `claim_boundary`):**
- `cells.tsv` **cell_id mc-0242** (rewrite `next_gate`/`claim_boundary`/`primary_evidence_id`;
  flip `evidence_tier` point_fit_recovery→inference_ready_with_caveats). **Do NOT touch mc-0243.**
- `evidence.tsv`: add `ev-mc-0242-arc4b` (path → the Gamma iid artifact).
- `transitions.tsv`: add a `verified→verified` row.
- **`tools/tests/test_capability_ledger.py:108`**: point_fit_recovery count **164→163** (and the
  inference_ready_with_caveats expectation +1 if one is asserted) — a promotion WILL break this
  unittest otherwise (Rose blocking catch).
- Regenerate derived outputs for `--check`: `capability-surface.{md,html}`,
  `capability-census/{_master.tsv,_widget_data.json,gamma.tsv}`,
  `vignettes/includes/capability-ledger-family-map.md`. Then `capability_ledger.py --write` + `--check`.
- When rewriting stale prose, **substitute the phrase, do not append** (mc-0017 gotcha).

**Documented non-promotion — pre-committed landing (Rose R3):** if the gate withholds, then
(i) mc-0242 **stays `point_fit_recovery`** (no tier edit); (ii) `next_gate` records the attempted
campaign + the exact per-M coverage that failed the band; (iii) the Gamma artifact is still filed in
`evidence.tsv` as **diagnostic** (not a promoting `primary_evidence_id`); (iv) an after-task
documents the failed band. A rigorous negative satisfies the lane goal.

## 6. Machinery status + gating smoke (corrected per Rose R4 + Fisher)

Code-inspection verified (no compute): `has_sigma_random_effects()` includes gamma
(R/methods.R:5295) · `profile_targets()` gamma `sd:sigma:(1|id)` profile_ready=TRUE (test-arc2c:68
via helper called at :124) · `predict(dpar="sigma")` σ-BLUP test-asserted · `log_sd_sigma` is
ADREPORTed on the gamma path (src, per Fisher) so the harness `sdrow` resolves non-NA. **The
natural-SD scale identity of `confint()` is established by `transformation="exp"` (R/methods.R:4309)
+ the mc-0382 precedent — NOT by the recovery extractor** (a different code path; §1 corrected).

**Gating smoke = the FIRST compute step, bound to the COVERAGE fixture (not the recovery fixture):**
one fit per M ∈ {8,16,32,64} on the exact **iid-uncentered, n_each=12** DGP; **STOP criterion:** every
M must return a finite, in-range `confint(method="profile")` interval AND converge (conv=0, pdHess) —
if any M (esp. M=8, smallest/hardest) fails, HALT and report before scaling. The smoke is filed as
the first `evidence.tsv`/after-task line so it cannot be silently skipped. (The Arc-2c "60/60,
rel-bias −3.0%" is at the *recovery* fixture — n_each=15, centered — and does not establish
convergence at the coverage fixture.)

**Venue/repro (Totoro):** pin `OPENBLAS_NUM_THREADS=1`, ≤90 cores; Totoro is OpenBLAS (not fir's
FlexiBLAS) so the mc-0017 silent-ignore gotcha does not bite — but **verify the pin took** (confirm a
fit does not oversubscribe threads; e.g. check `RhpcBLASctl::blas_get_num_procs()` or top during a
smoke fit) and run a **local-vs-Totoro reproducibility check** (a shared-seed cell agrees to ~1e-4),
storing the result as a `build-repro`-style artifact beside the campaign output.

## 7. Review trail

- **Pre-compute plan-review (this gate):** Fisher (method) + Rose (scope) → both CONDITIONAL-DONE;
  fixes above applied. Noether deliberately **held** as the fresh S4 lens (independence rule).
- **Post-compute S4:** memo-blind Fisher/Rose/**Noether** on the results + this frozen S0; ≥2
  NOT-DONE withholds.
