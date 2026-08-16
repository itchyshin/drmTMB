# 255 — What `interval_feasible` claims: shape, location, or both

**Status:** DECISION MEMO for the package owner. Nothing in this document changes code,
tests, or a ledger row. It states a question the repository currently answers two
incompatible ways, shows which answer each part of the repository is using, prices both,
and recommends one. The recommendation is a recommendation; the tier is a published
contract and the choice is Shinichi's.

**Author:** Fisher (statistical-inference review) · 2026-08-15
**Worktree:** `claude/lane-irc-legacy-evidence` at `313021f42`, base `origin/main`.
**Reader:** the package owner, and whoever would be asked to fund the 40–70 h programme
scoped in `docs/dev-log/2026-08-15-rerun-73-scoping.md`.

Every count in this memo was re-derived from `docs/dev-log/dashboard/capability-ledger/`
at the commit above. Where my re-derivation disagrees with a number in the dev-log, both
are given and the disagreement is named. Claims about code carry `file:line`. Inferences
are labelled **INFERENCE**. Things I could not settle are labelled **NOT ESTABLISHED**.

---

## 0. The short version

1. `interval_feasible` has never been defined as a tier. It has been defined **four times,
   per cohort, by four different standards**, two of which are mutually incompatible and
   were approved four days apart. **§2** is the evidence. This is the finding.
2. The two positions are not evenly matched in provenance. Position 1 (shape) is what the
   **largest** owner-approved promotion cohort said in writing (108 cells,
   `docs/dev-log/after-task/2026-08-01-b4-ci-c2-canonical-integration.md:28`) and what the
   **shipped user-facing surface** says today
   (`vignettes/includes/capability-ledger-summary.md:99`). Position 2 (location) is what
   the **most recent** pre-registered campaign said (`…/2026-08-05-135-trace-campaign/
   PREREGISTRATION.md:20-22`, clause 8 at `:88-89`) and what the standing CI guard enforces
   (`tools/tests/test_profile_truth_gate.py:244-265`).
3. The choice moves fewer cells than the framing suggests. **80** of the 185
   `interval_feasible` cells lack a location verdict, not 105, and of those 80 only **26**
   are cells whose disposition genuinely turns on the answer. §3 shows the arithmetic.
4. **The 42 code-cited cells fail under *both* readings**, and not for the reason the audit
   supposed. Their interval evidence asserts the *labels* on a `confint()` data frame, not
   that its endpoints are finite or ordered — so they do not meet Position 1's own
   operative standard either (§3.2). That is the cleanest defect this audit has surfaced
   and it does not wait on the decision.
5. The 7 demotions of 2026-08-15 were **correct under both readings**, but the reason given
   is only valid under Position 2. Under Position 1 they are still correct, for a different
   and better reason: the fixture misspecification destroys the **point** permission the
   tier grants, not just the interval (§3.3).
6. **Recommendation (§5): neither position as stated. Adopt Position 1 as the tier's
   definition and make the location fact a separate, mandatory, three-valued field** —
   the same move the project already made, for the same reason, when it refused to turn
   comparator agreement into a tier (`docs/design/242-external-comparator-evidence-class.md:26-35`).

---

## 1. The two positions, steelmanned

### Position 1 — SHAPE ONLY

**The claim.** `interval_feasible` asserts that a named interval method runs to completion
on this exact cell and returns a well-formed interval — finite, ordered, unclamped, from a
converged fit with a positive-definite Hessian. It asserts nothing whatever about where
that interval sits. Location is a *calibration* question, and the tier explicitly withholds
every calibration claim.

**Where the code says it.** `tools/capability_ledger.py:3225-3231`:

```python
    if row["evidence_tier"] == "interval_feasible":
        return (
            "Yes — this exact model route is implemented.",
            "Yes — report the point estimate with the stated caveat.",
            f"No — {interval_method} is available, but there is no calibrated "
            "interval-reporting permission.",
        )
```

The interval permission is a flat **No**. The word "available" is a statement about the
method, not about the interval's contents.

**Where the shipped documentation says it.** The one `interval_feasible` cell that reaches
the user-facing reader summary is `mc-0186`, and its card reads
(`vignettes/includes/capability-ledger-summary.md:99`):

> A REML bivariate-Gaussian residual-correlation interval at 150 observations is
> **numerically well formed**. Coverage and calibration have not been evaluated, so it is
> not a calibrated reporting claim.

"Numerically well formed" is Position 1, published, in a vignette include.

**Where the shipped R code says it.** `R/associate-pairs-sandwich.R:33-46` assigns
`capability_tier = "interval_feasible"` **at runtime, per fit**, whenever a Godambe
sandwich covariance is computable and its diagnostics pass, with
`validation_domain = "fit-specific numerical interval feasibility; coverage uncalibrated"`
(`:45`). No DGP, no truth, and no location check is even *possible* at that point in the
call stack. This is the strongest single argument for Position 1: the package itself emits
this tier as a runtime verdict on numerical well-formedness.

**Where the largest promotion cohort said it.** The B4-CI Lane B integrations C1–C4
promoted 24 + 25 + 36 + 23 = **108 cells** to `interval_feasible` under an explicitly
approved allowlist, and each after-task report states the standard verbatim:

- `docs/dev-log/after-task/2026-08-01-b4-ci-c1-rebase-canonical-integration.md:27` —
  "one finite, ordered, unclamped profile interval"
- `docs/dev-log/after-task/2026-08-01-b4-ci-c2-canonical-integration.md:28` —
  "a finite, ordered, unclamped profile interval only. No coverage, calibration,
  inference-ready … claim is introduced."
- `docs/dev-log/after-task/2026-08-01-b4-ci-c3-canonical-integration.md:91`
- `docs/dev-log/after-task/2026-08-02-b4-ci-c4-canonical-integration.md:13`

Not one of the four mentions truth, bracketing, or a DGP value.

**Where the ledger's own gate table says it.** The capability-ledger contract defines the
parallel gate on the missing-response axis as
(`docs/dev-log/dashboard/capability-ledger/README.md:57`):

> | G4 | finite correctly named interval at a known-DGP point |

and `tools/capability_ledger.py:3860` maps `G4 = interval feasible`. "Finite correctly
named … **at** a known-DGP point" is a shape test evaluated on known-DGP data, not a test
that the interval contains the DGP's value.

**What the tier's own work queue says.** Of the 185 `interval_feasible` cells, **141**
`next_gate` values name coverage or calibration as the outstanding obligation and
**zero** name bracketing, truth, or a location check. Re-derived from `cells.tsv`. The
project's own machine-readable statement of what remains owed at this tier does not
include a location check.

**The steelman.** On this reading the tier is a *runtime* fact with a genuine engineering
content: `tmbprofile()` completes, the trace crosses the likelihood-ratio threshold on both
sides, no endpoint hits the clamp, the Hessian is positive definite. Those are not
nothing — they are exactly the failures that make an interval unusable *before* anyone can
ask whether it is calibrated. Publishing that fact, with the interval permission set to
**No**, tells a user "the machinery works here; you still may not report the interval."
That is an honest and useful statement, and it is one the package can make at runtime for
routes where no DGP exists.

### Position 2 — LOCATION REQUIRED

**The claim.** Every cell at `interval_feasible` or above owes a check that its retained
interval contains its DGP's true value. Shape without location certifies nothing about the
parameter.

**Where the code enforces it.** `tools/profile_truth_gate.py` exists solely to make that
check mechanical; its module docstring (`:2-18`) records that the reconcilers "check
interval SHAPE exhaustively … but historically checked nothing about interval LOCATION",
and that three separate cells reached review holding an interval that excluded their own
true value, caught only by a human reading the prose (`:15-18`). The Arc 7b after-task
report puts the full count at five, of which two shipped as `interval_feasible`
(`docs/dev-log/after-task/2026-08-03-arc7b-profile-truth-gate.md:22-25`).
The gate rule is at `:26-43`, with the two arms implemented at `:210-225`
(`MISS_MAGNITUDE_TOL = 0.05` at `:71`, `MISS_COUNT_TOL = 1` at `:75`).

**Where the scoping is explicit.** `tools/tests/test_profile_truth_gate.py:87-93` defines
`tier_rank()` against the ledger's own `TIER_ORDER` and sets
`GATED_FROM = tier_rank("interval_feasible")`; the standing guard at `:244-265` skips a
cell only when `tier_rank(...) > GATED_FROM`. The docstring at `:247-255` gives the reason,
and it is a good one: an equality filter on `"interval_feasible"` would let a gate-failing
cell escape by being **promoted**, and an adversarial reviewer demonstrated exactly that —
all 19 tests passed with all three gate-failing cells moved up to
`inference_ready_with_caveats`.

**Where the most recent campaign said it.** The 135-trace pre-registration, committed
before any fit, states the tier's content in one sentence
(`docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/PREREGISTRATION.md:20-22`):

> This campaign claims **interval existence + truth-bracketing at the tested design**. It
> does **not** claim coverage, calibration, inference-ready, supported, or CRAN-readiness.

Its ten-clause contract makes bracketing clause 8 (`:88-89`, "**Every** seed's interval
contains the true value") and adds clause 10, "Independent Fisher location review
(shape ≠ location)" (`:91`). The decision rule at `:66-67` is unambiguous: "**4/5
truth-bracketing is a BLOCK**, not an 80% pass." Five cells were promoted under it and
nine siblings withheld (`tools/capability_ledger.py:665-668`, `:702-710`).

**Where the ledger already refuses promotion on location grounds.**
`tools/capability_ledger.py:2704-2709` hard-fails the build if `mc-0292` is ever promoted to
`interval_feasible`, with the stated reason "seed-303 receipt excludes the true 0.7". The
comment at `:522-526` records the same for `mc-0424`, and `:533-539` for `mc-0409`. Three
separate cells are pinned below this tier **because their intervals missed truth**. That
is Position 2 operating as a promotion criterion, in the ledger, today.

**The steelman.** `evidence_tier` is described by the project as "a single **ordered**
scale of inferential strength — point recovery, then interval feasible, then
coverage-verified" (`docs/design/242-external-comparator-evidence-class.md:28-29`). A rung
on a scale of *inferential* strength that certifies only that code ran is a category
error — the ledger already has `capability_status = implemented` for that. Worse, the
ordering comment at `tools/capability_ledger.py:815-819` justifies ranking
`interval_feasible` **above** `point_fit_recovery` on the grounds that "a well-formed
profile … > a recovery test". Under Position 1 that is backwards as *evidence about the
parameter*: a recovery test is measured against a known truth, and a shape check is not
measured against anything. Position 2 removes the inversion.

---

## 2. Was this ever decided? — the finding

**NOT ESTABLISHED as a tier-level decision.** I searched the design corpus, the ledger
contract, the schema, the dev-log and the git history. There is no document, decision
record, issue, or review that states what `interval_feasible` means as a tier and binds
future cohorts to it. What exists is four cohort-scoped standards, adopted at different
times, never reconciled with each other.

**The schema declines to define it.** `docs/dev-log/dashboard/capability-ledger/schema.json`
lists `evidence_tier` as a bare enum of nine strings with no semantics attached. The
directory's own README calls itself "the source of truth for drmTMB's generated capability
surface" and then defines only the *missing-response* G-gates
(`…/capability-ledger/README.md:51-58`), a different axis.

**The one design doc that lists the ladder does not define this rung.**
`docs/design/218-structured-q-series-completion-map.md:62-78` gives the ordered tier list
and then defines exactly two of them — `diagnostic_only` and `blocked` (`:75-78`).
`interval_feasible` is named and left undefined.

**The chronology.**

| date | event | standard actually applied | cells |
|---|---|---|---:|
| 2026-06-27 | first promotions to `interval_feasible` (`after-task/2026-06-27-interval-feasible-promotion.md:8-12`) | **empirical coverage** — the boundary quotes g=8 coverage of ~0.91–0.93 and certifies at g≥32 (`:26`, `:54-60`) | 4 |
| 2026-07-11 | ledger migration `095409c0` imports the predecessor board verbatim (`transitions.tsv`, reason "MR-T0 import of the unchanged 668-cell census") | **none** — tier carried across, no promotion event | 44 |
| 2026-07-28 → 2026-08-02 | B4-CI Lane B C1–C4 canonical integrations | **shape**: "finite, ordered, unclamped profile interval only" | 108 |
| 2026-08-03 | Arc 7b builds the truth gate; demotes `mc-0424`, `mc-0260m` | **location**, applied to contract cells, scoped by tier rank from `interval_feasible` up | −2 |
| 2026-08-05 | 135-trace pre-registered campaign | **shape + location**: "interval existence + truth-bracketing", clause 8 mandatory | 5 |
| 2026-08-15 | interval-truth audit; 7 spatial cells demoted | **location**, applied universally | −7 |

The two positions did not accrete quietly out of neglect. They were each written down,
each reviewed, and each approved — **four days apart**, by cohorts that never referenced
one another. The Lane B standard (2026-08-01) and the 135-trace standard (2026-08-05) are
in direct contradiction about what the same token means, and both are still in force over
their own cells.

**One further asymmetry worth naming.** The first promotions ever made to this tier
(2026-06-27) required *more* than either position now asks: they quote measured coverage
numbers. So the tier has drifted **down** in evidential content over its lifetime, from
coverage-informed, through shape-plus-location, to shape-only, to inherited-without-a-run.
That drift is not recorded anywhere as a decision either.

**What I could not establish.** Whether Shinichi was ever asked the tier-definition
question as such — as opposed to approving individual cohort allowlists whose standards he
was shown. The Lane B reports record "explicit cohort-2 approval"
(`…/2026-08-01-b4-ci-c2-canonical-integration.md:13-15`) and the 135-trace pre-registration
records a "locked owner decision" on its disclosure wording (`:39`), but neither is an
approval of a general definition. **NOT ESTABLISHED.**

---

## 3. What each reading costs

### 3.1 The current census, re-derived

At `313021f42`, over 740 ledger rows:

| tier | cells |
|---|---:|
| `inference_ready_with_caveats` | 41 |
| `interval_feasible` | 185 (180 `model_surface`, 5 `association`) |
| `point_fit_recovery` | 65 |
| `legacy_fit_supported` | 4 |
| `diagnostic_only` | 81 |
| `none` | 364 |
| `supported` | **0** |

Two facts have changed under the audit's feet and both shrink the problem:

- **`supported` is empty.** Commit `395772f18` split the legacy board label into its own
  token, so the four cells the audit flagged as "top tier with no run"
  (`docs/dev-log/2026-08-15-supported-tier-claims-question.md`) are now
  `legacy_fit_supported`, which ranks *below* `point_fit_recovery`
  (`tools/capability_ledger.py:823-826`) and is therefore outside Position 2's rank filter
  entirely. Those 4 cells are no longer owed anything by either reading.
- **All 41 `inference_ready_with_caveats` cells now carry a `coverage_study` evidence
  row**, as of `313021f42`. Verified: 41 of 41. A coverage campaign brackets by
  construction, so under either reading these are class (b) — checked by a stronger
  instrument — and owe no separate location check.

So the claiming population is 226, and the unresolved part of it is **185
`interval_feasible` cells and nothing else**.

### 3.2 How many of the unchecked become defects

Of the 185, **105** have had a location instrument applied (85 re-check verdicts from
`scratchpad/recheck-verdicts.json`, plus the 30-row derived manifest, overlapping).
**80** have not. Their composition decides everything:

| group | cells | under Position 1 | under Position 2 |
|---|---:|---|---|
| **A.** 2026-07-11 import; primary evidence is a source/test citation; no promotion transition; no profile receipt anywhere | **44** (42 `model_surface` + 2 others) | **defect** — see below | **defect** |
| **B.** `association` axis, Godambe-Wald sandwich intervals | **5** | not a defect | **unclosable** — no profile mechanism applies |
| **C.** 135-trace cohort `mc-0568/0576/0595/0596/0653` | **5** | not a defect | **not a defect** — bracketing was clause 8 of their pre-registration; they are location-checked, just not through the manifest |
| **D.** profile receipt on disk, truth not recoverable from a frozen contract | **26** | not a defect | **defect** — a real, ~26-cell fixture-and-contract job |

**So the honest price of Position 2 over Position 1 is 26 cells plus the 5 association
cells relabelled, not 105.** Group A is a defect either way and group C is a defect
neither way. The 40–70 h estimate in `docs/dev-log/2026-08-15-rerun-73-scoping.md:60-70`
was scoped over 47 `interval_feasible` cells in the "re-run" partition; my partition of
the *unverdicted* population is smaller because it excludes the 5 association cells, the
5 already-bracketed 135-trace cells, and cells that did receive a verdict. **INFERENCE:**
the marginal cost attributable to choosing Position 2 is materially below 40–70 h. I have
not re-costed it and I am not asserting a number.

**Group A — the 42 code-cited cells — fail under Position 1 too, and this is the finding
that does not wait on the decision.** Take `mc-0025` (`beta_binomial`, `mu`, fixed,
`interval_feasible`). Its entire evidence row points at
`tests/testthat/test-beta-binomial.R:72-107`, and the interval-relevant part of that test
is (`:93-107`):

```r
  ci <- confint(fit)
  expect_equal(ci$parm, c("fixef:mu:(Intercept)", "fixef:mu:x",
                          "fixef:sigma:(Intercept)", "fixef:sigma:z"))
  expect_equal(ci$tmb_parameter, c("beta_mu", "beta_mu", "beta_sigma", "beta_sigma"))
  expect_true(all(ci$conf.status == "wald"))
```

That asserts the **row labels** and the **method string**. It does not assert that
`conf.low` and `conf.high` are finite, that `conf.low < estimate < upper`, or that no
endpoint is clamped. Position 1's own operative definition — the Lane B standard, "finite,
ordered, unclamped" — is not met. I checked the 13 imported cells whose cited test range
resolves on disk and calls `confint()`: **1 asserts finiteness, 0 assert ordering.** Small
sample, stated as measured.

The cell's `claim_boundary` says as much in its own words: *"`confint()` Wald CI computed
and asserted (conf.status=="wald", correct parm/tmb_parameter labels)"*. It is an honest
record of a weak fact that was then filed under a tier.

**Under Position 1** these 42 do not become "not defects". They become defects of a
different and easier kind: an evidence-strength defect, closable by adding two assertions
to an existing test, with no fixture, no DGP, and no compute. **Under Position 2** they
are the expensive kind, because they have no profile receipt to re-check and no contract
to derive truth from.

### 3.3 The seven demotions of 2026-08-15

`mc-0113`, `mc-0114`, `mc-0115`, `mc-0116`, `mc-0117`, `mc-0118`, `mc-0494` — all
`spatial`, demoted `interval_feasible → diagnostic_only` in commit `8d6840f16`, taking the
census 192 → 185.

**Were they correct under Position 1? Yes — but not for the reason the commit leads with.**

The stated reason is a location failure: relative misses of 21.6% to 235.2%
(`docs/dev-log/2026-08-15-interval-truth-recheck-verdicts.md:39-47`). Under Position 1 that
reason is out of scope, because location is not what the tier claims. The shape evidence is
intact: the commit itself records that the cells' only non-legacy evidence is "a
`contract_test` recording receipt SHAPE (finite ordered endpoints, convergence 0, pdHess
TRUE, no clamp/boundary)". On a strict Position-1 reading, that evidence still stands and
the demotion would be unjustified.

But the commit contains a second argument, and **that argument is valid under Position 1**:

> …the same misspecification means the point estimate was never validly tested against a
> known truth either, so a recovery-backed point-report permission would over-claim.

This is decisive, and it is worth stating plainly because it generalises. `interval_feasible`
grants a **point-report** permission — "Yes — report the point estimate with the stated
caveat" (`tools/capability_ledger.py:3228`). The diagnosed mechanism
(`docs/dev-log/2026-08-15-interval-truth-recheck-verdicts.md:78-110`: the DGP builds the
latent field from `K` with a correlation length under one site, while
`drm_spatial_coords_precision` fixes the fitted range at the median pairwise distance,
~18 — a ~30× mismatch) means the fixture never tested *any* claim about this parameter,
point or interval. Nothing survives that supports the permission the tier grants. Demotion
to `diagnostic_only`, which grants no point permission at all, is right under either
reading.

**So: correct under both, but the published reason should be the point-permission argument,
not the bracketing miss.** Under Position 1 the location check is still a legitimate
*diagnostic of the evidence's validity* — it is what exposed the fixture defect — even
though it is not a *test of the tier's claim*. That distinction is worth preserving in the
wording, because the current commit message reads as though a location check were the
tier's gate, which would prejudge exactly the question this memo poses.

Two related items, flagged not fixed: (a) all seven cells' `claim_boundary` still opens
with the words *"interval_feasible only for the named cell …"* while `evidence_tier` reads
`diagnostic_only`; (b) the demotion rests on **one retained seed each**, where the truth
gate's count arm is structurally unreachable (`profile_truth_gate.py:221`; `1 > 1` is
`False`), so these are magnitude-only screening verdicts — the discipline Arc 7b applied
to its own p-values of 0.017–0.039
(`docs/dev-log/after-task/2026-08-03-arc7b-profile-truth-gate.md:213-221`) applies here
too. The misses are 21–235% of scale, so I do not doubt the direction; I am naming the
instrument's strength honestly.

---

## 4. The statistical substance

### 4.1 Is "an interval exists and is well-formed" a meaningful published claim?

**It is meaningful, but it is a claim about software, not about a parameter.** It says:
the optimizer converged, the Hessian is positive definite, `tmbprofile()` traced both
sides of the likelihood-ratio threshold, and no endpoint collided with the internal clamp.
Those are real, falsifiable, and frequently false — the 135-trace campaign withheld 9 of
14 candidate cells, and the arc-2 reconcilers exist precisely because shape failures are
common.

The problem is that shape carries **no information about the parameter**, and the
repository has now measured how little. Of the 85 cells for which truth was recoverable,
all 85 had passed every shape check, and **7 (8.2%) missed truth by 21–235% of scale**
(`docs/dev-log/2026-08-15-interval-truth-recheck-verdicts.md:13-15, 39-47`). A 95%
interval is entitled to about 5% misses, but not misses of 235% of scale — those are
mislocations, not sampling noise. So shape-pass is compatible with gross mislocation at a
rate the shape check itself cannot see, and the seven cells that demonstrated it passed
`convergence == 0`, `pdHess == TRUE`, finite, ordered, unclamped, and a complete
two-sided trace.

That number is one-sided and weak: 110 of the 116 re-checkable cells carry one seed or
none, so only the magnitude arm could decide them, and 31 of the 116 yielded no truth at
all. Treat 8.2% as a floor on the shape-passing mislocation rate, measured on a
non-random, receipt-bearing subset. **Do not read it as a coverage estimate.**

### 4.2 What does a reader actually do with it?

Honestly: very little, and that is the tier's real weakness under Position 1.

The reader surface currently answers three questions per route — can I fit it, can I
report the point estimate, can I report the interval — and at `interval_feasible` the
answers are Yes / Yes-with-caveat / **No**
(`tools/capability_ledger.py:3225-3231`). So the interval fact is published as a
**refusal**. The user learns "`confint()` will return numbers here and they are not
garbage, and you may not use them." The actionable content of the tier is therefore
carried entirely by its **point** permission; the interval half is a negative statement
that mainly serves to pre-empt the question.

That is a defensible thing to publish — it is more informative than silence, and it saves
a user from concluding that a returned interval is endorsed. But it does not need to be a
*rung on an ordered inferential scale* to do that job. And there is a real hazard in
carrying it as one: `confint()` output is labelled `2.5%`/`97.5%`. Format asserts
calibration whether or not the ledger does. A user who reaches the numbers has, in
practice, been handed a probability statement the package declines to stand behind. The
gap between what the object looks like and what the ledger permits is where this tier can
mislead.

### 4.3 The coherent middle position

There is one, and the project has already used it once, for the same reason.

When comparator agreement was proposed as a new tier, review rejected it
(`docs/design/242-external-comparator-evidence-class.md:26-35`), on the grounds that
`evidence_tier` is a single ordered scale of inferential strength while comparator
agreement is **orthogonal** to that scale — "Inserting a parity value into the ordered list
would force a false comparison." It became an `evidence_class` instead.

**Shape and location stand in exactly that relation.** Shape is a computational property
of the run; location is an inferential property of the estimator. Neither dominates the
other, and forcing them onto one axis is what produced two irreconcilable definitions of
one token. The middle position is therefore:

- `interval_feasible` **is** the shape claim (Position 1), stated as such;
- a separate, **mandatory**, three-valued field records the location fact:
  `location_checked ∈ {passed, failed, not_applicable}` with the instrument named;
- `not_applicable` is a real answer for the association cells and any route where no DGP
  target exists — it is a scope statement, not an exemption;
- the tier **above** (`inference_ready_with_caveats`) requires `location_checked = passed`,
  which is already true de facto now that all 41 carry a `coverage_study` row.

This is strictly more informative than either position alone. Under pure Position 1 the
7 spatial mislocations would have had nowhere to be recorded. Under pure Position 2 the
association cells and every runtime-assigned tier become permanently unearnable, and the
package's own `R/associate-pairs-sandwich.R:33-46` emits an unearnable claim on every fit.

---

## 5. Recommendation

**Adopt Position 1 as the definition of `interval_feasible`, and add a mandatory
`location_checked` field. Do not adopt Position 2 as the tier's meaning.**

Reasons, in order of weight:

1. **It is what the largest owner-approved cohort actually decided.** 108 of the 185 cells
   were promoted under a written standard of "finite, ordered, unclamped profile interval
   only". Reinterpreting that token retroactively converts an approved decision into a
   backlog of ~100 defects by redefinition rather than by evidence. Position 2's own
   discipline forbids the mirror-image move — *"the gate's tolerance is NEVER adjusted to
   keep a cell"* — and the same discipline should forbid tightening a definition to
   manufacture failures.
2. **Position 2 is not applicable to part of its own domain.** `R/associate-pairs-sandwich.R:33-46`
   assigns this tier at runtime with no truth available; the 5 association cells use a
   Godambe sandwich, not `tmbprofile()`, so no profile gate applies at all
   (`docs/dev-log/2026-08-15-rerun-73-scoping.md:54-57`). A definition that a shipped code
   path cannot satisfy is not a definition; it is a standing violation.
3. **It matches the shipped user-facing wording**, which already says "numerically well
   formed" (`vignettes/includes/capability-ledger-summary.md:99`). Position 1 requires no
   change to a published sentence. Position 2 requires re-writing the reader contract and
   would leave that sentence false for whichever cells fail.
4. **It keeps `TIER_ORDER` monotone in reader permission** without a new rung, which is
   pinned by `test_tier_order_is_monotone_in_reader_permission`
   (`tools/tests/test_capability_ledger.py:1078-1108`).
5. **The separate field preserves everything Position 2 is right about.** The location
   defect class is real and proven — five cells reached review with intervals excluding
   their own truth (`docs/dev-log/after-task/2026-08-03-arc7b-profile-truth-gate.md:22-25`)
   and seven more were caught this week.
   Nothing here weakens the gate; the gate keeps running, its verdicts get their own field
   instead of being smuggled into a tier that was defined without them.

**Two things I am explicitly not recommending.** I am not recommending that the truth gate
be relaxed, narrowed, or made optional — it stays exactly as calibrated, including
`MISS_MAGNITUDE_TOL = 0.05`, whose units problem remains an open owner decision
(`profile_truth_gate.py:148-155`). And I am not recommending that any cell be promoted.
The recommendation moves cells *sideways* into a more informative record, or *down*.

**Honest statement of what my recommendation gives up.** It concedes Position 2's best
argument: that a rung on an ordered *inferential* scale which certifies only that code ran
is a category error, and that ranking it above `point_fit_recovery`
(`tools/capability_ledger.py:815-819`) inverts evidential strength, since a recovery test
is measured against a known truth and a shape check is measured against nothing. I think
that argument is correct and I am not able to dissolve it. The mitigation is that the
`location_checked` field restores the missing dimension without re-ranking; the residual
cost is that `TIER_ORDER`'s comment at `:815-819` would need to say honestly that within
the point-only band the ordering is by *reader permission and computational maturity*, not
by evidential strength about the parameter. **If Shinichi weighs that inversion more
heavily than the retroactive-redefinition cost, Position 2 is the defensible choice, and
the honest way to take it is to rename the tier rather than redefine it** — e.g. a new
`interval_located` rung above a demoted `interval_computed`, so no already-approved cohort
has its recorded standard rewritten underneath it.

---

## 6. What would have to change under the recommendation

Listed so the cost is visible before the decision, not discovered after it. **None of this
is implemented by this memo.**

1. **Write the definition down, once, where it binds.** A `## Evidence tiers` section in
   `docs/dev-log/dashboard/capability-ledger/README.md` defining all nine tokens — the
   file that already calls itself the ledger's contract and currently defines only the
   missing-response gates (`:51-58`). A `schema.json` enum without semantics is how this
   happened.
2. **Add `location_checked` to the cell schema** (`schema.json` enums + `cells.tsv`
   header + `capability_ledger.py` field validation), mandatory for every cell at
   `interval_feasible` or above, with the instrument named. Backfill: `passed` for the 78
   re-check passes and the 30 manifest cells and the 5 135-trace cells; `failed` for the 7
   demoted; `not_applicable` for the 5 association cells; blank-and-owed for the 26
   receipt-bearing unverdicted and the 42 code-cited.
3. **Re-scope the standing guard.** `tools/tests/test_profile_truth_gate.py:244-265`
   currently gates on tier rank; it would gate on `location_checked` instead. Note that it
   already iterates only over cells with a reconciler contract
   (`(set(self.arc2_contracts) | set(self.arc1)) - UNGATED`, `:256`) — the universal
   obligation is the audit's extrapolation from a contract-scoped guard, not something the
   guard asserts. The rank filter must **not** simply be deleted: it is what stops a
   gate-failing cell escaping upward (`:247-255`), so its replacement must preserve that
   property against `inference_ready_with_caveats` and `supported`.
4. **Fix the 42 (independent of the decision).** Either add finiteness and ordering
   assertions to the cited tests, or re-tier the cells to `point_fit_recovery` — which
   their own claim boundaries already support, since they cite point-recovery bounds. This
   is the cheapest real defect on the board and it is owed under either reading.
5. **Repair the 7 demoted cells' stale `claim_boundary` prose**, which still opens
   "interval_feasible only for …" under `diagnostic_only`, and restate the demotion reason
   as the point-permission argument (§3.3).
6. **Decide the 5 association cells explicitly**, as `not_applicable` with a named reason,
   rather than leaving them looking unexamined
   (`docs/dev-log/2026-08-15-rerun-73-scoping.md:89-90`).
7. **Regenerate and re-check.** `python3 tools/capability_ledger.py --check`, the six
   Python suites, `Rscript tools/emit-profile-truth-manifest.R --check`. The vignette
   include is currently generated at "2026-08-11" and reports 180 interval-feasible against
   today's 185 — it needs regenerating regardless.

---

## 7. What this memo does not establish

- **Whether the owner ever ruled on the tier's definition.** NOT ESTABLISHED (§2). Four
  cohort standards exist; no general one does.
- **The exact provenance of the "112 verdicted / 105 unchecked" split** in the task brief.
  My re-derivation at `313021f42` gives 105 verdicted / 121 unchecked over all 226 claiming
  cells, or 126 / 100 if the 21 class-(b) cells are counted as verdicted. I could not
  reproduce 112 / 105 from the on-disk artifacts and have used my own figures throughout,
  restricted to the 185 `interval_feasible` cells where the question actually lives
  (105 / 80). The `recheck-verdicts.json` on disk is the pre-correction 77/8 split; the
  corrected 78/7 is in `docs/dev-log/2026-08-15-interval-truth-recheck-verdicts.md:17-20`.
- **The marginal cost of Position 2.** §3.2 argues it is below the 40–70 h scoped for a
  larger partition; I did not re-cost it and no fixture was built.
- **Whether the 26 group-D cells are even fittable at a useful information rung.** Unknown,
  as `docs/dev-log/2026-08-15-rerun-73-scoping.md:96-98` says; some may be weakly
  identified in the way the spatial cells were.
- **Anything about calibration or coverage.** Nothing here licenses a coverage,
  calibration, inference-ready, or CRAN statement for any cell.

## Provenance

Ledger counts re-derived from `docs/dev-log/dashboard/capability-ledger/{cells,evidence,
transitions}.tsv` at `313021f42`. Verdict counts from `scratchpad/recheck-verdicts.json`
and `tools/profile-truth-manifest.tsv`. Cohort sizes from the four B4-CI after-task
reports. No file outside `docs/design/` was read for state and none was modified.
