# Audit — build specifications c04 through c09, as built

**Auditor:** Gauss (TMB likelihood and numerical reviewer), adversarial, default NOT-DONE.
**Date:** 2026-08-15.
**Worktree:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/phase19`, branch
`claude/phase19-comparator-workflows`, head `8659319cc`.
**Artifacts audited (the built things, not the plan):**
`vignettes/comparing-with-other-packages.Rmd`,
`tests/testthat/test-comparators-phase19.R`.
**Environment:** R 4.6.0; drmTMB 0.7.0 via `devtools::load_all()` (never the installed 0.6.0);
lme4 2.0.1, metafor 5.0.1, metadat 1.6.0, ordinal 2025.12.29, glmmTMB 1.1.14,
palmerpenguins 0.1.1, TMB 1.9.21.

Everything below was re-fitted from scratch in fresh `Rscript` sessions. No number in this
report was copied from the plan, the article, the test file, or any prior round.

---

## 0. Which build ids map to which article comparisons — and which I could not map

The article numbers its comparisons 1–8; the plan uses build ids `c01`…`c10`. The mapping is
stated in the test file's header comment ("article order c08, c04, c05, c06, c07, c01, c09,
c03") and in `PR2-build-plan.md` §1.1's cell table, and the two agree. I confirmed it
independently by matching each build id's dataset + comparator call in §1.1 against the fitted
call in the article chunk:

| Build id | Article comparison | Dataset / comparator | In my assignment? | Audited numerically before? |
| --- | --- | --- | --- | --- |
| c04 | **Comparison 2** | `dat.bcg` / `metafor::rma.uni(method="ML")` | yes | **no — first numeric audit** |
| c05 | **Comparison 3** | `dat.bcg` / `metafor::rma.mv(struct="DIAG")` | yes | **no — first numeric audit** |
| c06 | **Comparison 4** | `ordinal::wine` / `ordinal::clm` | yes | yes (earlier round) |
| c07 | **Comparison 5** | `ordinal::wine` / `ordinal::clmm` | yes | yes (earlier round) |
| c08 | **Comparison 1** | `lme4::cbpp` / `lme4::glmer` | yes | yes (earlier round) |
| c09 | **Comparison 7** | `palmerpenguins::penguins` / `glmmTMB` gaussian on `log(y)` | yes | **no — first numeric audit** |
| c01 | Comparison 6 | `lme4::sleepstudy` / `glmmTMB` `dispformula` | no (outside c04–c09) | yes |
| c03 | Comparison 8 | `glmmTMB::Owls` / `glmmTMB` `dispformula` | no (outside c04–c09) | yes |
| c02 | **none** | `sigma = ~ (1\|Subject)` on `sleepstudy` | n/a | — |
| c10 | **none** | `rho12 ~ species`, `biv_gaussian()` | n/a | — |

**Mapping I could not make, stated plainly.** `c02` and `c10` have no article comparison to
map to. `PR2-build-plan.md` §1.2 and §2.5 record that both were dropped from the article
entirely in rounds 4 and 5 — no fit, no number, no classification sentence. I grepped the
article for both and confirm the absence: no `rho12` fit, no `biv_`, no
`dispformula = ~ (1|Subject)`. Their build ids are therefore unauditable *as article content*,
which is the correct state, not a gap.

**Note on the range.** "c04 through c09" as a build-id range includes `c08` (= article
Comparison 1) and excludes `c01`/`c03` (= article Comparisons 6 and 8). So my assignment is
article Comparisons **1, 2, 3, 4, 5 and 7**, not 4–9. Within it, the three specifications that
were never numerically audited are **c04, c05 and c09** — article Comparisons 2, 3 and 7 —
and those got the deepest treatment. I additionally re-ran c01 (Comparison 6) because
Comparison 7's `sigma` scale rule is stated by contrast with it; I did **not** re-run c03
(Comparison 8), so nothing in this report should be read as covering `nbinom2`.

---

## 1. Reproduction — every displayed number, re-fitted

All six comparisons re-fitted; `fit$opt$convergence == 0` in every case. Full-precision
agreements measured by me:

| Comparison (build id) | Quantity | Measured |absolute difference| |
| --- | --- | --- |
| 1 (c08) | `mu` coefficients (4) | 1.85e-04, 4.14e-04, 4.33e-04, 5.77e-04 |
| 1 (c08) | herd RE SD | 1.90e-04 |
| 1 (c08) | `logLik` | 2.85e-04 |
| 2 (c04) | `mu` intercept | 1.83e-07 |
| 2 (c04) | `tau^2 = exp(2*sigma)` | 1.05e-07 |
| 2 (c04) | `logLik` | 5.77e-13 |
| 3 (c05) | `mu` intercept | 5.29e-08 |
| 3 (c05) | per-level `tau` | 9.02e-08, 2.79e-07, 1.54e-08 |
| 3 (c05) | per-level `tau^2` | 3.37e-08, 3.38e-07, 1.65e-08 |
| 3 (c05) | `logLik` | 1.05e-12 |
| 4 (c06) | slopes (2) | 2.35e-07, 6.65e-07 |
| 4 (c06) | cutpoints (4) | 1.19e-06, 2.04e-06, 8.61e-07, 8.87e-07 |
| 4 (c06) | `logLik` | 3.86e-11 |
| 5 (c07) | slopes (2) | 4.23e-06, 1.53e-05 |
| 5 (c07) | cutpoints (4) | 2.36e-06, 8.65e-06, 6.69e-06, 3.48e-06 |
| 5 (c07) | judge RE SD | 6.44e-06 |
| 5 (c07) | `logLik` | 3.48e-06 |
| 7 (c09) | `mu` coefficients (3) | 8.52e-09, 4.05e-08, 3.21e-08 |
| 7 (c09) | `sigma` coefficients (2) | 9.62e-08, 1.46e-07 |
| 7 (c09) | Jacobian identity `logLik(drm) - logLik(glmmTMB) - sum(-log y)` | 1.55e-11 |

The article's honest tolerance statement for Comparison 1 ("about three decimal places … not
to five or six") is corroborated: the largest coefficient gap is 5.77e-04.

I also ran the shipped test file end to end:

```
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'devtools::load_all("."); testthat::test_file("tests/testthat/test-comparators-phase19.R")'
# [ FAIL 0 | WARN 0 | SKIP 0 | PASS 41 ]
```

and knitted the article against 0.7.0 (`knitr::knit()` after `load_all()`, all 71 chunks
executed, no error outside the two deliberate `error = TRUE` chunks), so every claim below
about "what the reader sees" is from rendered output, not from reading source.

---

## 2. Defect class 1 — a number attributed to the wrong model: **NOT PRESENT in c04–c09**

I checked this directly rather than by reading. Every numeric line in Comparisons 1, 2, 3, 4,
5 and 7 is computed inside its own chunk from the fit object displayed immediately above it;
there is not one transcribed numeric literal in the prose of any of these six comparisons.
Comparison 7 has no random effect at all, so the fixed-effect/random-effect split that
produced the round-2 defect cannot arise there. The two comparisons that *do* carry a
fixed-effect variant (6 and 8) are outside my range, and both label it explicitly in prose
before showing it.

Two specific traps I tested rather than assumed:

- **Comparison 7 uses `type = "link"` for `mu`, and it must.** `predict_parameters(fit7,
  dpar = "mu", type = "link")$estimate` equals `model.matrix(~species, pen) %*% coef(fit7,
  "mu")` to **0.00e+00**, i.e. exactly. `type = "response"` returns `exp(eta)` and differs by
  up to **4894.69**; feeding that to `dlnorm(meanlog = )` would be silently wrong. The article
  chose correctly.
- **Comparison 6 uses `type = "response"` for `mu`, and that is also correct** because
  gaussian `mu` is identity-linked. The two chunks look inconsistent side by side but each is
  right for its family. Worth a builder comment; not a defect.

## 3. Defect class 2 — unqualified "no comparator exists": **NOT PRESENT in c04–c09**

I enumerated every sentence in Comparisons 1–5 and 7 that asserts a limit. There are three,
and all three are qualified:

- Comparison 4: "a scale or discrimination formula for this family is not yet implemented. If
  you need that, `ordinal::clm(scale = ~ ...)` is the tool that already has it." — this runs
  *against* drmTMB and names the comparator that does have it. The opposite of the defect.
- Comparison 1: "`nbinom2()` … is a count family and takes a single-column count response, so
  it is not a substitute here." **Verified**: `drmTMB(bf(mu = cbind(incidence, size -
  incidence) ~ period + (1|herd)), family = drmTMB::nbinom2())` errors. (Aside for the
  package, not this article: the error is `Internal model-frame mismatch in nbinom2 model.`,
  which is not a user-legible rejection of a two-column response.)
- Comparison 7: "a model with one residual SD has no parameter for it" — a statement about a
  model class, not about any package's availability.

The article's own table row (`Residual correlation rho12 with a predictor | none | not
compared here | nothing to classify`) is the structural closure working as intended.

## 4. Defect class 3 — stale line-number citations

I cite by content throughout this report. Note that the **test file** cites the plan by line
number extensively (`PR2-build-plan.md:381-389`, `:412-416`, `:417-423`, `:448-455`,
`:456-463`, `:496-502`, `:505-521`, `:533-536`, `:541-546`, `:574-576`, `:578-608`,
`:616-625`, `:653-660`, `:661-665`, `:692-697`, `:703-708`, `:730-736`), plus
`feasibility-batch-2.md:34-38`, `adversarial-scales.md:145-162`, `:129-135`, `:186-214`.
I spot-checked four of these against the current plan and they still resolve; but they are in
a shipped test file, pinned to a dev-log document that has already been revised five times.
This is the stale-citation class one revision away from firing. Cite the plan by section
heading (`§3, Comparison 2`) instead — the headings are stable, the line numbers are not.

---

## 5. Scale conversions, checked per family

Verdicts against the conversions I was asked to check:

| Rule | Exercised where | My verdict |
| --- | --- | --- |
| gaussian `dispformula` is `log(sigma)`, **no squaring** | Comparison 6 (c01) | **CORRECT.** No-transform comparison agrees to 1.57e-07 / 3.77e-08. The FE density check reproduces `logLik(fit6_fe) = -938.716365658989` with `sd = exp(eta)` to **4e-12**, while `sd = sqrt(exp(eta))` gives `-4647.816851390135`, missing by **3709.10**. The rule is structural, as the prose says. |
| `meta_V` `tau^2 = exp(2*eta)` | Comparisons 2 and 3 (c04, c05) | **CORRECT**, and forced, not merely consistent: the two `logLik`s agree to 5.77e-13 (c04) and 1.05e-12 (c05). Source is `drm_total_obs_sd()` in `R/methods.R`, `sqrt(v_known + sigma^2)`. Omitting the `exp()` or the doubling fails by orders of magnitude (§6, mutants M3–M6). |
| lognormal `sigma` unsquared, `meanlog = eta_mu` | Comparison 7 (c09) | **CORRECT.** `meanlog = mu` reproduces `logLik = -2511.448175272207` to 2.09e-11; `meanlog = mu - sigma^2/2` gives `-2517.471754369` and misses by **6.024**. Matches `stats::dlnorm(y, meanlog = params$mu, sdlog = params$sigma)` in `R/family-dpq.R`. |
| `nbinom2` `theta = 1/sigma^2` | Comparison 8 (c03) | **NOT RE-RUN BY ME** — c03 is outside c04–c09. No coverage claimed. |
| tweedie `disp = 2*coef(fit,"sigma")` | nowhere | **NOT EXERCISED.** `grep -i tweedie` over both artifacts returns exactly one hit, a comment in the test file. |
| beta `phi = 1/sigma^2` | nowhere | **NOT EXERCISED.** No beta comparison exists in the article. |
| `rho12 = 0.999999*tanh(eta)` | nowhere | **NOT EXERCISED.** `grep -Ei 'rho12\|tanh'` returns only the article's coverage-table row saying it is not compared. |

The last three are correctly *absent* rather than wrongly *asserted* — but a reader of this
audit should not take "conversions verified" to cover them.

---

## 6. Mutation testing — can each assertion fail?

I mutated one side of each comparison and re-ran the corresponding assertion verbatim.
"CAUGHT" means the assertion failed as it should.

| # | Mutation | Result |
| --- | --- | --- |
| M1 | c04 comparator left at `rma.uni()`'s **default REML** | CAUGHT on all three (`mu` off by 3.33e-03, `tau^2` by 3.32e-02, `logLik` by 4.63e-01) |
| M2 | c04 drmTMB side **drops `meta_V()`** | CAUGHT (`mu` -0.740650 vs -0.711199) |
| M3 | c04 conversion uses `exp(sigma)` (tau, not tau²) | CAUGHT |
| M4 | c04 no conversion at all (`coef(sigma)` vs `tau2`) | CAUGHT |
| M5 | c05 forgets the contrast (per-level `exp(2*b_k)`) | CAUGHT |
| M6 | c05 forgets the `exp()` | CAUGHT |
| M7 | c05 comparator `struct = "CS"` instead of `"DIAG"` | CAUGHT (`logLik` -12.665076 vs -11.997319) |
| M8 | c05 drmTMB side `sigma = ~1` | CAUGHT |
| M9 | c06 sign-flipped cutpoints | CAUGHT |
| M10 | c06 sign-flipped slopes | CAUGHT |
| M11 | c06 compared to `clm(scale = ~temp)`'s `logLik` | CAUGHT |
| M12 | c07 compares SD to `clmm`'s **variance** (1.279461) | CAUGHT |
| M13 | c07 compares the no-RE fit to `clmm` | CAUGHT |
| M14 | c08 compares SD to `glmer`'s **variance** | CAUGHT |
| M15 | c08 comparator refit at **`nAGQ = 25`** | **NOT CAUGHT by the coefficient assertion** — see F8 |
| M16 | c09 `sigma = ~1` / `dispformula = ~1` on **both** sides | **4 of 5 assertions still pass** — see F3 |

The `expect_error(..., "Unsupported parameter")` in the Comparison 4 test is genuinely
falsifiable: it fires only from `drm_build_cumulative_logit_spec()`'s dpar guard (message
reproduced verbatim in §7, F7), and an unrelated malformed formula (`mu = rating ~
nosuchvar`) errors with `undefined columns selected`, which the regexp would not match.

---

## 7. Findings

### F1 — MEDIUM · Comparison 3 (c05) · article prose is wrong about `rma.mv`

The article says, in the paragraph introducing the `tau_by_level` conversion:

> "each allocation level's value is the intercept plus that level's contrast, with `alternate`
> as the reference **on both sides**."

`rma.mv(..., struct = "DIAG")` has **no reference level**. It estimates one free `tau^2` per
level of the inner factor, with no contrast coding at all. Measured: `cmp3$parms == 4`
(= 1 fixed effect + 3 variance components), `length(cmp3$tau2) == 3`,
`attr(logLik(cmp3), "df") == 4`, and `cmp3$g.levels.f[[1]]` is
`alternate, random, systematic`. The reference-level notion applies only to drmTMB's
contrast-coded `sigma` design matrix. What is actually true of the metafor side, and what the
conversion depends on, is **ordering**: `$tau2` comes back in the inner factor's level order,
which is why `alternate` is first.

This is a mathematical mis-description of the comparator in the one comparison whose whole
point is that two differently-written models are the same model. Suggested repair: *"each
allocation level's value is the intercept plus that level's contrast, with `alternate` as the
reference on the `drmTMB` side; `rma.mv()` estimates the three variances directly with no
reference level, and returns them in factor-level order, `alternate` first."*

The test file gets this right and says so ("`$tau2` is ordered (alternate, random,
systematic), matching the DIAG random-effect factor level order"). The defect is article-only,
and it is a case of the article being *less* accurate than the test that guards it.

### F2 — MEDIUM · Comparison 5 (c07) · ledger tier distance is off by one

The article says of the random-slope cell:

> "A random *slope* on this family is a different cell (`mc-0227`, recorded **a tier lower** at
> `point_fit_recovery`)"

The repo's own canonical ordering is `TIER_ORDER` in `tools/capability_ledger.py`:
`supported`, `inference_ready_with_caveats`, `interval_feasible`, `diagnostic_only`,
`point_fit_recovery`, `none`, `miswired`. `mc-0225` is `interval_feasible` and `mc-0227` is
`point_fit_recovery` (both read from `docs/dev-log/dashboard/capability-ledger/cells.tsv`),
so the gap is **two** tiers, with `diagnostic_only` in between — not one.

Everything else in that paragraph checks out against `cells.tsv`: `mc-0225` is
`cumulative_logit` / `mu` / `ordinary_re_intercept` / `ML` / `interval_feasible`, and the
article's narrowing sentence paraphrases its recorded `claim_boundary` faithfully; `mc-0227`
is `ordinary_re_slope` / `point_fit_recovery`. Repair is one word: "recorded lower, at
`point_fit_recovery`" or "two tiers lower".

### F3 — MEDIUM · Comparison 7 (c09) · the test does not pin the model the section is about

`test_that("Comparison 7 (c09) …")` contains five assertions. I replaced the fitted models on
**both** sides with `sigma = ~1` / `dispformula = ~1` — dropping the `sex` effect that the
section title ("are male penguins more variable in body mass than females?") exists to
demonstrate — and re-ran them:

- `mu` coefficients: still passes (diff 7.6e-09 … 5.97e-08)
- `sigma` coefficients: still passes (diff 9.49e-08)
- density check `meanlog = mu` reproduces `logLik`: still passes
- Jacobian identity: still passes (residual 4.59e-11)
- `expect_gt(abs(ll_meanlog_offset - logLik), 1)`: **fails, 0.51 vs 1**

So exactly one assertion stands between this test and a model that answers a different
question — and it is a magnitude heuristic written for a different purpose (demonstrating the
`meanlog` trap), whose margin under the correct model is 6.02 against a threshold of 1, and
which the mutant clears at 0.51, a factor of 2. Tighten the threshold and the block silently
stops pinning the article's model.

Nothing in the block asserts the *structure* of the fitted design. Every comparison is
`unname()`d, so term identity and naming are never checked; only length and order are, and the
mutant preserves neither of those in a way the test can see (both sides shrink together).

Recommended repair, two lines, no new fits:

```r
expect_named(coef(fit, "sigma"), c("(Intercept)", "sexmale"))
expect_named(coef(fit, "mu"), c("(Intercept)", "speciesChinstrap", "speciesGentoo"))
```

The Comparison 3 test is the counter-example to follow: it indexes by name
(`b[["allocrandom"]]`, `b[["allocsystematic"]]`), so a design-matrix change cannot pass it
unnoticed. Comparisons 1, 2, 4, 5, 6, 7 and 8 all use `unname()` exclusively.

### F4 — LOW-MEDIUM · Comparison 7 (c09) · the Jacobian assertion has ~7 orders of unused headroom

```r
expect_equal(
  as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(fit_glmm)),
  sum(-log(pen$body_mass_g)),
  tolerance = 1e-4
)
```

`sum(-log(y)) = -2772.780261159` and `expect_equal`'s tolerance is relative, so the effective
absolute slack is **0.2773**. The identity actually holds to **1.55e-11**. The nearest
realistic mismatch mutant (drmTMB `sigma = ~1` against the correct glmmTMB fit) breaks the
identity by **0.982** — inside a factor of 3.5 of the slack. Either tighten to `tolerance =
1e-9` (still 2.8e-06 absolute, five orders above the measured error) or assert the residual
against zero with an explicit absolute tolerance. Same reasoning applies to the `logLik`
assertions in Comparisons 4 and 5, where `tolerance = 1e-4` on magnitudes of 86.5 and 81.6
buys 8.6e-03 of slack against measured agreements of 3.86e-11 and 3.48e-06.

### F5 — LOW-MEDIUM · Comparison 3 (c05) · the displayed `tau` labels are misleading

The rendered chunk output is:

```
tau_by_level
#>  alternate.(Intercept)     random.(Intercept) systematic.(Intercept)
#>              0.1870101              0.6058616              0.5333383
```

`sigma3[1]` keeps its own name through `c()`, so every element is suffixed `.(Intercept)`.
On the `random` and `systematic` entries this is actively wrong-reading: those values are
`intercept + contrast`, not intercepts, and the label says otherwise on the very line where
the article is teaching the reader that the conversion requires the contrast. One-line repair:
`sigma3 <- unname(coef(fit3, "sigma"))`, or wrap in `setNames()`.

### F6 — LOW · Comparison 2 (c04) · the strongest evidence renders as a visible mismatch

```
c(drmTMB_tau2 = exp(2 * coef(fit2, "sigma")), metafor_tau2 = cmp2$tau2)
#> drmTMB_tau2.(Intercept)            metafor_tau2
#>               0.2800281               0.2800282
```

Same name-inheritance artefact as F5, plus: at R's default 7 significant digits the two
printed values **differ in the last digit**, on the line whose prose asserts the two packages
"are maximising the same function, not merely landing close to each other". The true gap is
1.05e-07 and the `logLik`s agree to 5.77e-13 — the evidence is much stronger than what the
reader sees. Print the difference, or state the measured 1e-07 in prose so the visible last
digit is explained rather than left to look like disagreement.

### F7 — LOW · Comparisons 4 and 5 (c06, c07) · SEs displayed under a "nothing is compared" banner

The article's boundary paragraph states: "no standard error or confidence interval is compared
anywhere in this article." `summary(fit4)$coefficients` and `summary(fit5)$coefficients` each
render a `std_error` column for the drmTMB side, while the paired comparator chunks show
`coef()` only. Nothing is *compared*, so the sentence stays literally true — but the
asymmetric display invites precisely the comparison the boundary disclaims, and `clm`/`clmm`
SEs are one `summary()` call away for any reader. Comparison 1 avoids this by selecting
`[, c("term", "estimate")]`; Comparisons 4 and 5 could do the same.

For the record, the Comparison 4 rejection renders correctly and matches the article's
surrounding prose:

```
#> ! `cumulative_logit()` models currently support only a `mu` location formula.
#> ✖ Unsupported parameter: "sigma".
#> ℹ Ordinal scale/discrimination formulas are planned after the identifiability
#>   contract is finalized.
```

(Under `load_all()` the rendered error carries a worktree srcref, `at phase19/R/drmTMB.R:…`.
I flag this as **uncertain**: it is very likely an artefact of source-loading and will not
appear when the vignette is built from an installed package. Worth one confirmation on a real
`R CMD build`, because a worktree path in shipped vignette output would be a bad look.)

### F8 — INFORMATIONAL / UNCERTAIN · Comparison 1 (c08) · 1e-3 does not discriminate the integral rule

Refitting the comparator as `glmer(..., nAGQ = 25)` — a genuinely different marginal
likelihood — moves the fixed effects to `-1.399224, -0.991409, -1.127810, -1.579481`, i.e.
**6.96e-04 … 9.30e-04** from drmTMB. The test's coefficient assertion at `tolerance = 1e-3`
**still passes**. The `logLik` assertion in the same `test_that()` does fail, so the block as a
whole catches the mutant and the file is sound at that granularity.

But I do not trust that catch as evidence of real sensitivity, and I say so explicitly: lme4
2.0.1 reports `logLik = -50.005015` at `nAGQ = 25` against `-92.026566` at `nAGQ = 1`, while
the two deviances are `73.373002` and `73.474284` — a 42-unit swing in `logLik` accompanying a
0.10-unit swing in deviance. That reported `logLik` is internally inconsistent, so the
assertion is failing on an lme4 reporting quirk, not on the integral rule. On the deviance
scale the two rules differ by 0.101, against an effective absolute slack of ~0.092 at
`tolerance = 1e-3` on a magnitude of 92 — close enough that a consistently-computed AGQ25
`logLik` might well have passed. **Follow-up worth one command**, not a blocker.

Positively: this same measurement independently corroborates the article's prose that the
1e-3 drmTMB-vs-glmer gap "is the expected size for that comparison" — the Laplace-vs-AGQ25
displacement (~8e-04) is the same order as the drmTMB-vs-glmer displacement (~4e-04).

### F9 — LOW · Comparison 7 (c09) · chunk guards are stricter than the code needs

`comparison7-drmtmb` and `comparison7-mu-check` are gated `eval = has_penguins &&
has_glmmTMB`, but neither chunk calls glmmTMB. On a check machine with `palmerpenguins` and
without `glmmTMB` — both are Suggests, so that is a legitimate configuration — the reader
loses the drmTMB half of Comparison 7 *and* the `E[log y]` vs `log E[y]` demonstration, for no
reason. Comparison 6 handles this correctly (`comparison6-fe-check` and `comparison6-drmtmb`
gate on `has_lme4` only, the comparator chunks on `has_lme4 && has_glmmTMB`). Mirror that.

### F10 — INFORMATIONAL · prose facts, all verified

`wine`: 72 rows, **9** judges × **8** bottles, **5** rating levels — the article's "Nine
judges each rated eight bottles" and "five ordered bitterness ratings" are exact.
`dat.bcg`: **13** trials, `alloc` = 2 `alternate` / 7 `random` / 4 `systematic` — the
article's "two studies, `random` seven, and `systematic` four" is exact. `cbpp`: 56 rows, 15
herds, 4 periods. `penguins` complete cases: n = 333. Comparison 5's "Comparison 4's marginal
slope was smaller than the conditional slope shown here" is true (2.503102 vs 3.063001; the
`contact` slope moves the same way, 1.527797 vs 1.834900). Comparison 7's "Gentoo penguins are
heavier than Adelie on the log scale" is true (`speciesGentoo = +0.324920`) and "males are
noticeably more variable" is true (`sexmale = +0.437410`, `exp() = 1.5487`). Comparison 1's
"`beta_binomial()` adds a dispersion parameter to this same two-column response" is true — it
fits, converges, and reaches `logLik = -88.041647` against binomial's `-92.026282`.
`docs/design/242-external-comparator-evidence-class.md` exists. `metadat` is declared in
`DESCRIPTION` `Suggests`, as the test header claims.

---

## 8. Verdict

**NOT-DONE.**

Nothing I found is a numerical error: all six comparisons reproduce exactly, every scale
conversion that the article exercises is correct for its family, no number is attributed to
the wrong model, and the comparator-absence class did not come back. The three
never-before-audited specifications (c04, c05, c09) survive numeric audit intact — that is the
main result, and it is a good one.

The verdict is NOT-DONE on three items, none of which needs new evidence:

1. **F1** — the article mis-describes `rma.mv(struct = "DIAG")` as having a reference level.
   This is a statement about the comparator's mathematics in the comparison that leans hardest
   on "these are the same model", and it is wrong. Prose fix.
2. **F2** — "a tier lower" is two tiers by the repo's own `TIER_ORDER`. One-word fix.
3. **F3** — the Comparison 7 test does not pin `sigma ~ sex`; a matched mutant clears four of
   five assertions and the fifth by a factor of 2. Two-line fix.

F4–F9 are quality items I would fix in the same pass but would not block on: two label
artefacts the reader actually sees (F5, F6), one tolerance with seven orders of unused
headroom (F4), one display/banner tension (F7), one over-strict chunk guard (F9), and one
flagged-uncertain observation about tolerance sensitivity that needs one command to settle
(F8).

**Not covered by this audit, stated so nobody inherits a false floor:** c03 (article
Comparison 8, `nbinom2`) was not re-run by me; the `theta = 1/sigma^2` conversion is therefore
uncorroborated here. `beta`, `tweedie`, and `rho12` conversions are exercised nowhere in
either artifact. Nothing here speaks to interval calibration, coverage, or small-sample
behaviour — consistent with the article's own boundary paragraph, which I checked and find
accurate.
