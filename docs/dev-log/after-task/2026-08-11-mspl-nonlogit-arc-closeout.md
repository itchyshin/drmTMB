# After-task — MSPL non-logit arc: three gates run, one C++ defect fixed, one wrong recommendation caught

**2026-08-11 · Claude · branch `claude/mspl-nonlogit-evidence` · PR #1012 merged to `main`**

## 1. What was asked

Continue the OWED items from the 2026-08-11 handover, then — on Shinichi's direction — settle whether
MSPL works for probit and cloglog, finish the SE question, and close the arc.

## 2. What was delivered

| gate | question | result |
|---|---|---|
| **G0** | do the R kernels compute the right link-general weight? | PASS — parity with `glm()` IRLS weights (4.8e−8) and an independent Jeffreys determinant (5.6e−10) |
| **G0b** | does the *compiled* objective match them? | PASS after a fix — 3.6e−16 / 5.4e−16 / 1.7e−14 along a separation ray, both tails |
| **G1** | finiteness under TMB-Laplace | probit PASS, cloglog-mirrored PASS, cloglog-standard FAIL (composite endpoint) |
| **G1b** | finiteness, completion and finiteness separated, fresh seeds | **all four PASS — 0 non-finite in 43,972 completed fits** |
| **G3** | are the standard errors calibrated? | **probit and cloglog CALIBRATED** in the identified regime |
| **G2** | does the logit-calibrated `c_n` matter? | **IMMATERIAL** — ~1% of one standard error |

**Total: 460,000 fits** across four campaigns, every one pre-registered before any replicate, on
four distinct seed streams. Wall-clock on Totoro: 7 + 7 + 4.5 + 5 minutes.

## 3. The defect this arc existed to find

`src/drmTMB.cpp` computed the MSPL Jeffreys weight as `log(n) − softplus(η) − softplus(−η)` — the
**logit** weight, hardcoded, with no `link_code` branch — while `R/mspl.R`'s kernels were
link-general. Two implementations of one estimator, disagreeing for probit and cloglog.

Nothing caught it because the entry guard admits only logit, so the disagreement was unreachable from
the public API. **Had the campaign run as originally scoped, every probit and cloglog fit would have
been penalised as logit and returned finite, plausible, wrong numbers** — 176,000 of them.

The link-general primitive already existed, documented *"Used ONLY by the MSPL Jeffreys weight"*
(`src/drm_numeric.h:134`), and had never been called. Fixed in PR #1012 with the logit branch kept
verbatim, so the shipped route is bit-identical — independently confirmed when the C17
re-certification reproduced all three model-15 cells at `|change| = 0.000e+00`.

This is design 253 §7's failure mode, one layer deeper. Its lesson held exactly: the regression test
must assert the penalty **differs by link**, because one that only checks "probit runs" passes
against the broken version.

## 4. The mistake worth recording

After G1, I reported cloglog-standard's FAIL and recommended **documenting a limitation and
abandoning the optimizer work**. That recommendation was wrong, and would have written a false
constraint into the package.

The evidence was already on disk. All 33 losses were optimizer *errors*, none was a non-finite
estimate, and plain ML errored on 33 of the same 33 datasets — one `table()` away. I had even written
*"these are optimizer failures, not demonstrated non-finiteness"* in the verdict, then contradicted it
two steps later.

It was caught only because Shinichi asked **"what is your criterion of fail?"** before acting on the
recommendation.

Root cause: a pre-registered decision rule read as a scientific finding. The NA-as-failure rule is
deliberately one-sided — false FAIL possible, false PASS not — so its verdict means *"not
demonstrated"* until the mechanism is opened. This is rule 1 of
`memory/A simulator can fail in your package's favour` (*"partition failures by mechanism"*), which is
quoted in the hub `AGENTS.md` and was in context throughout. A retrieval-at-point-of-use failure, not
a memory failure: ledgers get consulted when planning, and this class of error happens when
*reporting*. Recorded there as rule 5, with the case.

**What saved it:** the frozen prereg forbade rescoring, so the repair had to be a new prereg on fresh
seeds. The discipline that felt obstructive is what made the correction credible.

## 5. Second self-correction, caught before publishing

G3 initially graded cloglog-mirrored **NOT CALIBRATED**. Before writing that up I checked the
estimand: true `β = 1.0`, and the mirrored arm recovered **−1.54, −1.47, −0.57, −0.55** — not `−1.0`,
and drifting with `η_d`. Fitting `1 − y` under cloglog is fitting the **log-log** link, so the arm was
**model-misspecified** and a model-based Wald SE is the wrong variance estimator there. The paired
check confirmed it: all three engines agreed to three decimals.

The arm remains valid for G1/G1b — finiteness is unaffected by misspecification — and is invalid for
calibration. Recorded as a G3 design limitation, not removed from the table. This warning was sent to
gllvmTMB, whose registered both-tail sweep would have hit the same trap.

## 5b. Third self-correction — the "silent NA" does not exist, and I nearly wrote code for it

Asked to implement the `std_error.status` field that issue #977 suggests, I opened the source to find
**it already exists, and so does the typed warning**. Both landed in `1d6cd5330` (2026-08-09), the day
*before* #977 was filed.

`vcov()` raises `drmTMB_mspl_wald_unavailable` — a catchable condition naming the exact gate that
failed (`hessian_not_positive_definite`) — and `summary()` carries a per-coefficient
`std_error.status = "mspl_wald_unavailable"`. Verified on the worst cell, then exhaustively:
**62 of 62 SE-unavailable fits warned, 100%**, across all four conditions and both `q`.

**Why two campaigns missed it.** Both the 2026-08-09 runner and mine call
`suppressWarnings(sqrt(diag(vcov(f))))`. **The harness suppressed the exact signal whose absence it
then reported**, and I repeated the conclusion into a public issue comment and a cross-repo PR before
opening the source.

The measured rates stand — the SE genuinely is unavailable that often. Only the word *silent* was
wrong. Retracted on #977 (recommended for closure), in `VERDICT-G3-SE.md`, and in gllvmTMB PR #955.

**The pattern across all three self-corrections this session is one thing:** I trusted a derived
artefact — a FAIL verdict, a summary table's head, a runner's output — over the primary source it was
derived from. The fix each time was thirty seconds of looking.

## 6. Findings beyond the gates

- **Separation tracks absolute event *count*, not prevalence.** At `n = 4,000` the same `η_d` that
  separates at `n = 120` produces 10–114 events and no divergence at all, so the adversarial corner
  tested small `c_n` but largely *not* under separation. Re-confirms F2 from a second direction.
- **Standard errors unavailable at high rates under deep separation, link-general.** 15 of 60 cells
  return MSPL fits reporting `convergence == 0` whose slope SE is missing — 98.3% in the worst logit
  cell, in all four conditions, all in the separated regime. Added to existing issue **#977** rather
  than filed anew. Two corrections were needed on the way, both mine: I first wrote that all affected
  cells were `q2` (**three are `q1`**), and I described the `NA` as **silent** — see §5b, it is not.
- **The two cloglog orientations need different separation depths** (−5 vs −6, measured) and separate
  into opposite tails. The asymmetry is operational, not just a tail-order remark.
- **`ω(0)` closed forms**, verified to machine precision: `1/4`, `2/π`, `1/(e−1)` → factors 2,
  1.2533, 1.3108. For cloglog `ω(0) ≠ sup ω` (0.5820 vs 0.6476 at `η = 0.4661`) — anchoring on the
  supremum gives the wrong constant.

## 7. State

**Merged to `main`:** PR #1012 (C++ link dispatch + R threading + regression test, 328 tests pass),
plus the C17 re-certification it required.

**On `claude/mspl-nonlogit-evidence`, not for merge:** four pre-registrations, four verdicts, all
runners and scorers, 460,000 rows of raw data, and two evidence-only options
(`drmTMB.mspl_evidence_unsafe`, `drmTMB.mspl_cn_factor_unsafe`) that **must never merge**.

**Cross-repo:** gllvmTMB PR #955, docs-only, cut clean off their `main`.

**Brain:** the failure mode appended to the existing over-coverage lesson as rule 5 (`eec650a`).

## 8. Carried over — all maintainer decisions

| item | state |
|---|---|
| MSPL guard | **closed**; the `c_n` and finiteness objections are now answered on evidence, the decision is not mine |
| SE policy | **undecided** — G3 suggests neither ship-all nor block-all: calibrated where identified, silently absent where not |
| issue #977 | **recommended for closure** — the field and the warning it asks for both already exist (`1d6cd5330`, 2026-08-09). What remains is not signalling but **frequency**: whether "point estimates available, inference not" deserves a documented boundary in the deep-separation `q2` regime |
| the 0–3-event × correlated-RE corner | identifiability wall where ML also fails; a diagnostic message would serve better than an optimizer chase |
| intercept start fix | evidence-branch only; needs its own PR if wanted on `main` |
| 0.7.0 candidate | **stale since #1006** — six shipped-path files differ from the frozen tarball; Codex's lane |
| win-builder | owner's |
