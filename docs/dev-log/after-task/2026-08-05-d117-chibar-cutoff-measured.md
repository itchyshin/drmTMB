# After-task — the χ̄² boundary cutoff, measured and rejected

**Date:** 2026-08-05 · **Platform:** Claude (Claude Code), solo ·
**Lane:** drmTMB D-117 follow-up — measuring the chi-bar-square cutoff hypothesis ·
**Foreign lane:** codex, draft PR #858 — no overlap.

## 1. Goal

Answer one question with a measurement rather than an argument: does replacing drmTMB's χ²₁
profile cutoff with a Self–Liang χ̄² mixture move conditional coverage at a variance boundary from
**0.0732** toward nominal? Produce the decision record either way. Promote nothing.

## 2. Outcome

**No — it moves it to 0.0488, away from nominal.** Conditional coverage got worse in all three
cells where a boundary occurs (−9.1, −2.4, −23.8 pp) and overall coverage got worse in all four
(−5.0 to −7.0 pp). The χ̄² interval was strictly nested inside the shipped one on **4000/4000**
replicates.

Verdict and evidence:
[`2026-08-05-d117-chibar-cutoff-arm/VERDICT.md`](../simulation-artifacts/2026-08-05-d117-chibar-cutoff-arm/VERDICT.md).

## 3. The measurement was cheap because of an identity

The endpoint solver's interval is a pure level set (`out$nll - nll_hat - cutoff`,
`R/profile.R:3356`) with `cutoff = qchisq(level, 1)/2` (`:3117`). The χ̄² correction replaces
`qchisq(level, 1)` with `qchisq(2·level − 1, 1)`, which at 0.95 is `qchisq(0.90, 1)`.

**So the χ̄²-corrected 95% interval *is* the ordinary 90% interval.** Both arms come from calling
`confint()` at two levels — no prototype, no feature flag, no change to `R/`. The planned
"prototype the cutoff behind a flag" slice was therefore unnecessary and was dropped.

## 4. Harness validation

The χ²₁ arm reproduces D-117 **exactly** on all four cells: boundary counts 495/41/63/0 and
conditional coverage 0.8566/0.0732/0.2540, identical to the banked run. Same DGP, same seeds, same
target, copied verbatim from `d117_profile_gate.R`. Reproducing the reference arm before trusting
the new one is what makes the comparison interpretable.

## 5. Decisions

1. **Do not implement the χ̄² cutoff.** Measured, not argued.
2. **Do not re-open D-117's attribution.** The challenge was specific and falsifiable; the data
   went the other way, so "not a drmTMB defect" is now stronger than before.
3. **Confirm the PR #924 warning as the remedy**, since the boundary sub-population provably
   cannot be given a nominal interval by changing the cutoff.
4. **Leave issue #680 alone.** Its `qt²` recalibration is a *larger* cutoff — the opposite
   direction — and a different problem. D-12 separates them.

## 6. Verification

- Nesting check per replicate: **4000/4000** — the inequality coverage(χ̄²) ≤ coverage(χ²₁) is
  guaranteed replicate-by-replicate, so the direction does not rest on the small conditional cells.
- Reference arm reproduces D-117 to the exact integer boundary counts and 4-dp coverage.
- Smoke-first: 5 replicates on 1 core before any grid, confirming non-empty in-range output.
- Census **182 / 60** unchanged; `capability_ledger.py --check` OK.

## 7. Deviations, recorded honestly

- **No separate pre-registration file.** The goal's discipline asked for one. Instead the predicted
  direction and reasoning were **committed before the run** (`b89ea4e55`, 06:55:09, merged in
  `e430d408a`); the measurement ran ~07:07. A time-stamped public prediction that precedes the data
  serves the same purpose, but this is a deviation from D-117's pattern and is marked **adaptive**,
  not silent.
- **Ran locally, not on Totoro.** The goal named Totoro. 16 replicates took 1.66 s on 8 cores, so
  the full grid is ~4 minutes; deployment would have exceeded the compute. Totoro was verified
  reachable (384 cores, load 2.69) and simply not needed. D-50 is satisfied — nothing ran on
  GitHub Actions and results stayed local. Marked **adaptive**.
- **Two planned slices dropped** (prototype-behind-a-flag; adversarial verify of a positive
  result). The identity in §3 removed the need for the first, and the second had nothing to
  adversarially verify once the result was negative and provable. Marked **adaptive**.

## 8. Test-suite result

No `R/` change was made, so the package suite is untouched from `e430d408a`, where it last ran
green (308 files, 0 failures). This arc adds only `docs/`.

## 9. Deferred, explicitly

Unchanged and untouched: the 135-trace interval campaign; `predict()` scale-axis (its gate test
**pins** current behaviour and must fail when `predict()` is fixed); the CI guard/check split; the
B4-CI `SOURCE_COMMIT` port; mc-0282 (PROTECTED). Also not started: the REML-interval-coverage arc,
which remains the recommended next arc.

## 10. Open for the owner

- **Is D-117 discharged?** My recommendation is now firmer: **yes**. The adverse conditional
  finding is understood, correctly attributed, and has survived a *measured* mechanistic challenge.
  The withheld PASS stays withheld regardless — it is a separate object and should not be
  reinstated.
- **The next arc is unchanged:** whether REML's centre fix buys interval coverage. No repo has
  measured that, and it follows directly from D-117's actual mechanism (a centre biased 9.1–16.9%
  low) rather than from a cutoff.

## 11. Reusable lesson

An investigation that ends by **confirming what it set out to challenge** is a success when it is
cheap and the challenge was genuine. This one cost about ten minutes of compute and produced a
falsifiable, reproducible negative that closes a line of enquiry permanently — instead of leaving
"maybe the cutoff is wrong" as a standing doubt. The enabling move was finding the **identity**
(χ̄² at 0.95 = χ²₁ at 0.90) that turned a proposed prototype-and-campaign into two `confint()`
calls. Look for that identity before building the flag.
