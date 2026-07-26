# After Task: Arc C — A5 clamp ordering, A7 anchor hygiene, F5 reverted

**Date:** 2026-07-25 · **Author:** Claude (Opus 5) · **PR:** #845 ·
**Branch:** `claude/arc-c-hardening`

## 1. Goal

Repair three Arc B numerical findings that the audit reported and deliberately left
unfixed: **A5** (beta `mi()` called with unclamped `log_sigma`), **F5** (`sd()` regression
takes `exp()` of an unbounded predicted log-SD), **A7** (rotted line-number citations).
**F9** was explicitly out of scope — the audit's own verdict is that the 12 dead `sigma_i`
locals are evidence *against* drift.

Owner sequencing decision (2026-07-25): **defects before capability**, licensed by the
fact that `0.7`, not `0.6`, is the first CRAN submission (brain `D-86`) and there is
therefore runway.

## 2. Implemented

**A5 — shipped.** Which order is correct was established by audit rather than by mirroring
the sibling. Of the three `mi()`-capable families, `model_type == 1` clamps at `:690`
before its `mi()` density at `:1151`, and `model_type == 7` clamps at `:3606` before
`:3633`. **Beta alone did not.** The clamp now runs once at the top of the
`model_type == 10` branch, before the `mi()` 2-point sum. The old post-loop site is
**removed**, not left in place: `drm_softclamp_log_sigma` is exactly identity inside the
band but saturating outside it, so a second application would compress an already-clamped
value rather than acting as a no-op.

**A7 — shipped, and rescoped.** Nineteen rotted citations, not the six the audit listed.
Rather than re-pin numbers, each citation dropped its fragile line range and kept the
`model_type == N` label it already carried; the two with no label now name
`model_type == 1`, and the three `methods.R` citations name the function
(`drm_dpar_link()`, `simulate.drmTMB()`). **19 line-numbered citations → 0**; all 15 cited
branches verified present in `src/drmTMB.cpp`.

**F5 — attempted, then reverted.** Full record: `docs/design/245-f5-sd-regression-clamp-and-identifiability.md`.

## 3. Mathematical contract

A5 changes **no** likelihood for any fit whose `log_sigma` lies inside the clamp band —
the soft clamp is identity there. It changes the objective only where the band binds, and
only by making the `mi()` leaf agree with the main loop about the dispersion, which is the
defect. A7 is documentation. F5, having been reverted, changes nothing.

**No new estimator, family, interval method, or capability tier.** Nothing is promoted.

## 4. Why F5 was reverted — the arc's main result

Clamping the `sd(g) ~ x` predictor at all nine sites made
`test-phase18-meta-v-lss-runner.R`'s *"Arc 7B dense LSS sentinel retains incomplete
direct-SD profiles"* pass. That test is a **negative control** pinning the known K=12
degeneracy, so passing it was the failure, not the success.

| `logsigma_clamp` | profile for `sd(study):z_study`, dense K=12 |
| --- | --- |
| `c(-12, 12)` (clamp active) | finite `[-4.1428, 27.7859]`, `conf.status = profile` |
| `c(-200, 200)` (clamp off) | `profile_failed`, `NA` |

Widening the bound restores the non-identification, so the finite endpoint is an artifact
of the bound. On a log-SD slope, an upper endpoint of 27.79 means the study SD multiplying
by ~`1e12` per unit `z_study` — finite and vacuous, and **more dangerous than the
`[0, Inf]` it replaced** because it passes any gate that asks only whether an interval is
finite.

Fisher's framing at the completion gate sharpened it: the real defect is not clamping per
se, it is that `interval_status` cannot distinguish *ok because identified* from *ok
because clamped*. That is Arc D's question.

## 5. Verification

**Every figure below names the commit it was measured on.** Omitting that is the defect
this session hit three separate times, and it recurred here — the first draft of this
section stated these numbers with no hash at all, and was caught at the completion gate.

- **Local full suite — measured on the Arc C code tree, i.e. `a7caf7ab` (identical code
  content to its pre-rebase commit `742a1c43`):** **39755 pass / 0 fail / 0 error /
  125 skip**. `0209351d` changes only `AGENTS.md` and this report, so it does not move
  these numbers; the code diff between `a7caf7ab` and `0209351d` is empty.
- **The negative control F5 broke** (`test-phase18-meta-v-lss-runner.R`), same tree:
  **47/47**, restored.
- **Arc B's own conformance suites**, same tree: numeric-kernel oracle **376**, FD-vs-AD
  gradient conformance **36** — unaffected.
- **CI `ubuntu-latest (release)`:** **pass, 34m56s on the tip `0209351d`**
  (run `30183930665`, `conclusion=success`, head sha matching the PR exactly). An earlier
  green — pass, 31m55s, run `30181477078` — was on `7b50aec2`, i.e. **before** the banner
  and this report existed; it is not evidence for the tip and is recorded here only so the
  two runs are not confused.
- The `+1` skip vs baseline is exactly the new test (`skip_on_cran()`); under
  `NOT_CRAN=true` it runs **9 assertions**.

**Test honesty.** `tests/testthat/test-arc-c-clamp-hardening.R` states in its header that
it does **not** falsify: rebuilt against pre-repair source, it passes there too, because
the beta density saturates identically whether it receives the raw or the clamped
dispersion. A5 therefore rests on the structural argument in §2, not a behavioural proof.
An earlier draft of both tests fitted models and asserted on the result — and passed
pre-repair, because the optimizer chose tame coefficients and never reached the defect.
They were rewritten to drive the compiled kernel at hand-set parameters.

## 6. Known limitations

- **A5 has no falsifying test.** Open work: find an input separating the two clamp
  orderings, or record that none exists and why.
- **F5 is not repaired.** The nine sites remain unbounded; the audit's overflow hypothesis
  (`PLAUSIBLE`, Low-Med, "no fit run to drive `eta_sd > 709`") is untested either way.
- **A7's durability is improved, not proven.** `model_type == N` labels cannot rot the way
  line numbers do, but they are coarser: a citation that pointed at a specific sub-line now
  names a whole branch.

## 7. Consistency audit

`AGENTS.md`'s "Latest — start here" banner previously instructed the next session to fix
F5 by *"reuse `drm_softclamp_log_sigma()` … do not invent a second bound"* — the exact
approach now falsified — and stated "six rotted anchors". Both corrected here; without
that fix, merging this PR would have left the repo's entry point directing a fresh session
at a proven-wrong repair. Caught by Rose at the completion gate.

The Arc B audit report is deliberately **unchanged**: it correctly labels F5 `PLAUSIBLE` /
Low-Med, and rewriting a dated audit to match a later result would destroy the record.

## 8. Files changed

`src/drmTMB.cpp` (A5) · `R/family-dpq.R` (A7, 19 citations) ·
`docs/design/245-f5-sd-regression-clamp-and-identifiability.md` (new) ·
`tests/testthat/test-arc-c-clamp-hardening.R` (new) · `AGENTS.md` · this report.

## 9. Next

**Arc D** — decide what a scale clamp may do to an interval endpoint, with Fisher, before
any code. It blocks the interval-grade campaign (177 `point_fit_recovery` cells), because
coverage evidence gathered while a clamp may silently shape endpoints measures the clamp
rather than the estimator.
