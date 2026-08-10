# gllvmTMB's variational evidence, carried over to drmTMB (Design 160 reference note)

> **⚠ READ THE DECISION FIRST.** On 2026-08-03 the maintainer decided drmTMB will **not**
> implement the GVA — Design 160 stays design-only, and the effort goes to **AGHQ** instead.
> See `2026-08-03-decision-gva-not-implemented.md`.
>
> This note was written as an implementation brief *before* that decision, so its "before you
> write code" framing is now historical. It is kept because its evidence is what informed the
> decision, and because several findings apply to **any** drmTMB integration work — notably §1
> (optimiser flags are not a health signal), §5 (estimand hygiene), §6 (positive controls), and
> §7 (operational traps). Sections §0, §3 and §4 are GVA-specific and are the reasons AGHQ is
> the better route.

**Meta:** 2026-08-03 · Claude Code · reference note on `docs/design/160-gaussian-variational-approximation-gate.md`
**Provenance:** this note was produced in a gllvmTMB session that the maintainer stopped and
redirected here. gllvmTMB has spent roughly three weeks building and measuring a variational
engine (its Design 108 programme). **Most of what it learned is transferable, and most of it is
cautionary.** Reading this before writing GVA code should save a substantial amount of work.

Everything below is cited. Where a claim is asserted rather than measured, it says so.

---

## 0. The one thing to change in the design before writing code

Design 160's Standing Review (Gauss) says:

> "GVA bypasses TMB's Laplace; **the variational parameters are ordinary `PARAMETER`s** and the
> data-term quadrature must be numerically stable on the log scale."

That architectural choice is exactly what gllvmTMB implemented — and then had to undo. **The
analysis of *this repo's* Design 160 route already exists in gllvmTMB's Design 106 §4.3**
(`gllvmTMB/docs/design/106-va-structural-extension.md:565-635`), which is explicitly about
drmTMB's GVA, not gllvmTMB's:

> "What IS binding at this scale is the optimiser, not the covariance shape... A dense
> quasi-Newton stores an O(P²) approximation."

| Outer-problem size P | Dense quasi-Newton | L-BFGS |
|---|---|---|
| 53,970 | **~23 GB** | ~4 MB |
| 80,950 | **~52 GB** | ~6 MB |

gllvmTMB then measured the same thing on its own engine and found nlminb's PORT workspace is
O(P²), matching `n(n+27)/2` doubles **to 2% at n = 16,000** — which at its target scale meant
**1,127 GB at N = 5,000 and 4,508 GB at N = 10,000**. Not slow: *arithmetically impossible*.

**Why this bites drmTMB specifically.** Design 160's first slice is a univariate random-intercept
GLMM with a **scalar latent per group**, so `P ≈ 2 × n_groups` (each group contributes `m` and a
parameterised `s`). At a few hundred groups that is invisible. At 25,000 groups you are at
P = 50,000 and in the 23 GB row of the table above. The wall is not exotic — it is a
moderately large longitudinal or multi-site dataset.

**The fix is known and proven.** gllvmTMB's "R3" work profiles the variational block out of the
outer problem, collapsing it from `114N + 206` coordinates to **206, constant in N**. Measured
peak-RSS scaling exponent went **1.70 → 0.966**; at N = 8,000 the joint route exceeded 6,460 MB
and failed to finish three iterations in 23 minutes, while the profiled route used 1,697 MB and
finished in **12.5 s**.

And it was not merely cheaper — it was *more correct on the original objective*. Testing the
gradient of the **unprofiled joint** objective at the profiled solution gave a max of
**6.28e-5**, whereas the joint route failed that same test in **4 of 12 cells (5.70e-3)**.

> **Recommendation:** design the profiling/collapse route in from the first slice rather than
> retrofitting it. Keep the joint route as the byte-identical reference for small problems, and
> gate the profiled route behind a flag defaulting to the reference until SEs are settled (§4).

---

## 1. Measure the motivating premise before building on it

Design 160 §Why rests on a specific, testable claim: Laplace is **biased, not merely imprecise**,
for non-Gaussian random effects with little information per group.

That is well supported in the literature (Ormerod & Wand 2012; the PQL bias line), and the note
cites it properly. But gllvmTMB's experience is that this class of premise **erodes when you
measure it on your own engine**:

- Design 108 §0.2 justified a 17–26 day programme partly on Laplace *silently diverging*. When
  finally measured (a 3,600-fit campaign), the rate **decayed monotonically with n** — 18.1% at
  n ≤ 150 down to **0.6% at n ≥ 1600** — and a ridge drove it to ~0 across the whole ladder. At
  the real target scale it was close to a non-problem.
- Worse, **the flags were not lying**: of 511 degenerate fits, **425 (83.2%) reported
  `convergence = 0` AND `pdHess = TRUE`**. A degenerate optimum is a real optimum;
  `convergence` is the optimiser's exit code and `pdHess` a local Cholesky test. **Neither is a
  health signal.** Any drmTMB GVA validation must define "converged" as *recovered against
  planted truth*, not as clean flags.

> **Recommendation:** before the implementation slice, run a cheap Laplace-only bias measurement
> across the exact regime Design 160 targets (cluster size × true random-effect SD). If Laplace's
> SD bias is already small where drmTMB's users actually sit, the first slice should be rescoped.
> This is one afternoon of compute and it either kills or strongly justifies the programme.

---

## 2. The accuracy gain may be smaller than expected — and can be misattributed

gllvmTMB ran the VA-vs-Laplace comparison in June
(`gllvmTMB/docs/design/72-variational-approximation-feasibility.md`, Phase 1, PR #431):

- VA converged on **every** cell, including all those where Laplace's inner Hessian went
  non-PD — it is a genuinely **convergence-robust fallback**.
- **But wherever the model was identifiable (n ≥ 30), VA matched Laplace point estimates to
  ~2 significant figures.** No accuracy edge.
- Critically: **the small-n collapse was under-identification, not a mean-field artefact.** The
  inference "a richer variational covariance will cure the collapse" was explicitly *not*
  motivated by the evidence.
- Maintainer decision: **PARKED**.

Design 160 targets precisely the small-cluster / little-information-per-group regime — i.e. the
regime where gllvmTMB found the two effects are **easy to confuse**. A design that cannot
separate *"Laplace is biased here"* from *"the model is under-identified here"* will produce an
uninterpretable result.

> **Recommendation:** add an identifiability diagnostic to the ADEMP plan as a **third axis**
> alongside cluster size and true SD, and report cells where the model is under-identified
> separately rather than pooling them into the bias estimate.

---

## 3. Do not infer accuracy from the ELBO gap

Design 160's Validation Plan lists, under Estimands: *"and (for reporting) the
marginal-likelihood / ELBO gap."* Keep that strictly as reporting.

gllvmTMB's Design 109 (`109-bound-tightness-vs-recovery.md`) proves, on that engine's own
objective, that **bound tightness does not imply better recovery**:

- The bias of a bound-maximiser depends on the **gradient** of the gap, not its **level**.
  Tightness is a level statement; bias is a derivative statement; **no inequality connects
  them.** "Tighter bound ⇒ better estimates" is false in general, with a constructive
  counterexample.
- Empirically the **looser** bound recovered the target covariance **better** than the tighter
  one on **20 of 20 paired seeds**, after clearing optimiser and starting-value artefacts.
- Scope caveat: that empirical result is binomial-**logit**. It does not transfer to probit, and
  it should not be quoted as if family-general. Only the theorem is family-independent.

> **Consequence:** an ELBO-gap measurement and an accuracy measurement are **separate results**.
> Never let one stand in for the other in a claim.

---

## 4. Variational SEs are the open risk, and gllvmTMB has not solved them

Design 160 already says the right thing (Fisher: *"variational SEs are labelled as such and not
conflated with Laplace + `sdreport`"*). Reinforcing it with what gllvmTMB found:

- Its profiled route **defaults to off** specifically because **`sdreport()` across the profiled
  block is untested**. The default remains byte-identical to the joint route.
- Design 72 §0.4 records that **VA variance components are biased downward**, and that AIC/LRT
  are not comparable across methods.
- But Design 106 §6.4(6) is explicit that the **direction** of mean-field bias on the *point
  partition between variance components* is **NOT established** and must not be asserted.

So: downward bias is a real prior for variance components, and an **open question** for how the
bias distributes across components. Do not let any drmTMB doc assert a direction for the latter.

---

## 5. Estimand hygiene — the single most expensive class of bug

Two concrete instances from gllvmTMB, both of which cost real days:

1. **Score the estimand your protocol defines, on both sides.** Its recovery campaign defined
   the target as `Lambda Lambda'` but scored `Lambda Lambda' + diag(psi)`. Fixing only the truth
   side while the fit side still returned the total **inflated the error metric 2.3×**
   (measured: 0.7179 → 1.6360). Both sides must move together.
2. **Keep the variational posterior covariance and the prior covariance strictly apart.** In
   Design 160's notation that is `S` (the variational `q(u) = N(m, S)`) versus `Sigma(theta)`
   (the random-effect prior). gllvmTMB's own warning: *"the whole result turns on keeping them
   apart."*

And the framing rule that generalises both: **"agreement between two approximations is not
accuracy."** On a toy seed, *both* engines under-recovered the planted truth. So the outcome
space is not {GVA wins, Laplace wins} — it includes **neither is adequate**, which may be the
most consequential result available.

Design 160's plan already gets this right by naming a gold standard (high-order adaptive GH or
`tmbstan`/MCMC). **Keep that; it is the load-bearing part of the validation plan.** Compare
against planted truth and the gold standard, never engine-to-engine.

---

## 6. A positive control that must recover at every cell

gllvmTMB's campaign protocol makes this non-negotiable, and it earned its keep: the campaign
**stalled at its own positive-control gate** rather than producing a wrong headline. The control
plateaued instead of decaying with N, which correctly withheld every downstream number until the
cause was found (it was an estimand mismatch, §5).

Two implementation details worth copying:

- The gate must be **unanimous** — every control cell clean, no partial credit — and checked
  *before* any other column is read.
- Guard against a **vacuous pass**: if the control arm lacks a column the other arms have, a
  NULL-guard can silently turn its metric into `NA` and the gate passes having checked nothing.

---

## 7. Practical / operational carry-over

- **Smoke-first, always.** Before any campaign: one cell, tiny n, one rep; confirm non-empty,
  non-NA, in-range output; then read the **first** cell of the real run early and abort on
  garbage rather than waiting for the grid. gllvmTMB records this paying for itself three times
  in one session.
- **Compute on Totoro or DRAC, never GitHub Actions** (D-50), and campaign results stay **local**
  — never GitHub artifacts. Totoro is 384 cores, no queue; cap use at ≤100.
- **`R_LIBS_USER` REPLACES the user library.** Setting it to a private lib hid every dependency
  and would have failed all 3,600 cells identically. Prepend the full path list instead.
- **Per-worker TMB recompilation.** If a GVA campaign is parallelised, note that TMB templates
  keyed on `tempdir()` recompile **once per worker** — minutes each, unaffordable at scale. The
  clean fix is `R CMD INSTALL` the package (compiled once at install) rather than
  `devtools::load_all()` in each worker; gllvmTMB needed an elaborate DLL-stash workaround only
  because its prototype template compiles at runtime.
- **`pgrep -f "<pattern>"` matches its own command line** — cost 45 minutes once. Split the
  literal.

---

## 8. Suggested first steps for the implementer

1. **Re-open Design 160 §Parameterization Of S and §Engine API** and add the profiled/collapsed
   outer-problem route (§0). This is a design change, so it needs the maintainer's sign-off
   before code.
2. **Cheap premise measurement** (§1): Laplace-only SD-bias sweep over cluster size × true SD, on
   Totoro. One afternoon. Decides whether the first slice is worth building as scoped.
3. **Then** the first slice as written — univariate `mu` random-intercept, `poisson(log)` +
   Bernoulli/binomial, scalar latent, 1-D adaptive GH — with the gold standard wired in from the
   start, the positive control gated (§6), and the identifiability axis added (§2).
4. Keep GVA **non-default and fenced** until recovery evidence exists — Design 160's Rose row
   already requires this.

## Status of this note

Advisory. It changes no drmTMB code and makes no claim about drmTMB's engine — every measured
number above is from **gllvmTMB's** engine and is cited as such. Its value is that gllvmTMB has
already walked most of this path, and its Design 106 §4.3 had *already analysed drmTMB's chosen
GVA architecture* before this note existed.

Written as an untracked file so it does not disturb the uncommitted work currently on
`claude/handover-freshness-0718`; commit it explicitly by path when convenient.

Source lane (closed, redirected):
`gllvmTMB/docs/dev-log/handover/2026-08-03-claude-lane-closed-misrouted.md`.
