# After-task: interval-reliability rung — the slope/sigma evidence ladder is complete (profile, g=32)

Meta: 2026-06-27 · Claude (ultracode) · the last evidence rung.

## Goal

Measure the interval-reliability rung (the one evidence gate still unmeasured
before `supported`) for the slope/sigma cells, from the existing certification
grid replicates (no new grid needed).

## Result — all 8 cells pass the rung (profile channel, g=32, 500 reps)

Computed from the per-rep `profile_lower`/`profile_upper`/`estimate` columns of the
g=32 certification replicates:

| lane | target | finite% | width CV | symmetry | profile cov |
|---|---|---|---|---|---|
| sigma | phylo sigma:(Int) | 100% | 0.11 | 1.46 | 0.948 |
| sigma | phylo sigma:x | 100% | 0.08 | 1.37 | 0.954 |
| sigma | relmat sigma:(Int) | 100% | 0.11 | 1.47 | 0.948 |
| sigma | relmat sigma:x | 100% | 0.09 | 1.39 | 0.958 |
| q2 | phylo mu1:x | 100% | 0.12 | 1.50 | 0.948 |
| q2 | phylo mu2:x | 100% | 0.12 | 1.50 | 0.956 |
| q2 | relmat mu1:x | 100% | 0.13 | 1.51 | 0.950 |
| q2 | relmat mu2:x | 100% | 0.12 | 1.51 | 0.952 |

Against Fisher's pre-specified bar (finite ≥95%, width CV stable / not exploding,
symmetry ~0.5–2, coverage ~nominal): **all 8 pass.** The ~1.4–1.5 symmetry is the
profile interval *correctly* capturing the right-skew of an SD sampling
distribution (bounded below by 0) — healthy, not pathological. Width CV ~0.1 means
the intervals are tightly calibrated, not the exploded-width pathology seen on the
sigma *Wald* channel at small g.

## What this completes

The full **evidence** ladder is now met for the slope + sigma lanes via the
**profile channel at g=32**:
point-fit ✓ → extractor ✓ → fixture-parity ✓ → coverage (certified nominal, MCSE
~0.01) ✓ → **interval reliability ✓**.

The only remaining gate to `supported` is **not evidence** — it is the DESIGN
decision (Fisher / Rose): the support cells are g-agnostic, and Fisher ruled a bare
"supported for g≥N" inappropriate. The honest promotion framing must state the
channel (profile, not Wald) and the small-sample character (near-nominal at low g,
nominal at adequate g). That is a maintainer/Rose call, not a measurement.

## Boundary

Diagnostic interval-reliability evidence, derived from the already-banked g=32
certification replicates. It does NOT itself promote `interval_status` or
`coverage_status` (those are coordinated support-cell + test + validator edits
gated on the design decision); it records that the evidence bar is met. The
deployment g=8 profile intervals are a documented high near-miss (~0.91); the
nominal result is at g=32. Wald is NOT the supportable channel (it under-covers at
small g). Scale-side q4 and the relmat-Q bridge are untouched.

## Next (the actual promotion, a coordinated change)

1. Design decision (Rose/maintainer): the honest channel-and-g framing for a
   slope/sigma `supported` claim.
2. Then the coordinated promotion: support-cell `coverage_status` +
   `interval_status` + the hardcoded `expect_equal(..., "planned")` contract tests
   + the validator cross-checks, run live with testthat (now installed).

## Team learning

The interval-reliability rung looked like a separate grid run; it was actually
already in the data — the certification replicates carry per-rep bounds, so
width/symmetry/finite-rate are a derived computation. The lesson repeats: before
running more, check whether the existing artifacts already answer it. The slope
lanes are now evidence-complete; what remains is a decision, not an experiment.
