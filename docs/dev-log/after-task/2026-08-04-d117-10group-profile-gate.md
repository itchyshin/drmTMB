# After-task — D-117, the 10-group profile RE-SD coverage gate

**Date:** 2026-08-04 · **Platform:** Claude (Claude Code), solo — Claude ran the
live R/TMB and Totoro compute · **Lane:** drmTMB D-117 gate, reassigned to Claude
this session · **Foreign lane:** codex draft PR #858; its files untouched.

## 1. Goal

Produce the number D-117 requires — a fixed-seed 10-group coverage figure for the
**profile** random-effect SD interval — with an immutable receipt and a written
verdict. **The deliverable was the measurement, not a pass.** drmTMB 0.7.0 had
been held since 2026-08-03 until this number existed.

## 2. Outcome

**PASS**, by a rule frozen and committed before any production fit ran.

| Cell | N | truth | coverage | exact 95% CI | verdict |
|---|---:|---:|---:|---|---|
| `g10_n04_sd05` **worst corner** | 40 | 0.5 | **0.9140** | (0.8949, 0.9306) | PASS |
| `g10_n04_sd10` | 40 | 1.0 | 0.9290 | (0.9113, 0.9441) | PASS |
| `g10_n10_sd10` | 100 | 1.0 | 0.9310 | (0.9135, 0.9459) | PASS |
| `g10_n10_sd05` *reproduction* | 100 | 0.5 | 0.9370 | (0.9201, 0.9513) | PASS |

The corner is **not materially worse than D-97's pooled 0.9368**. The failure mode
D-117 feared is real but belongs to the **marginal** route (0.829 at 10 groups);
the profile route does not inherit it. Full detail and caveats in
`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/VERDICT.md`.

## 3. What the prior-work sweep changed

The sweep is why this arc cost ~40 minutes of compute instead of a campaign build.
A deterministic grep of `projects/deep-research/README.md` surfaced **`dr20`**
(~90 sources, 2026-08-03) — an external prior-art harvest done *for this gate* —
so no literature sweep was re-run. A grep of `DECISIONS.md` surfaced D-97's
pooled figure and, critically, that **a 10-group profile measurement already
existed** on the unpushed local branch `codex/sd-bootstrap-r999-diagnosis`.

That reframed the arc: not "build a campaign" but "**the gate was answered from
one cell out of four**". The A1 grid crosses `n_per ∈ {4, 10}` with
`sd_mu ∈ {0.5, 1.0}`, so the 10-group corner has four cells and only
`n_per = 10, sd_mu = 0.5` had been measured — leaving **`n_per = 4` (N = 40), the
genuinely worst corner, unmeasured**. Measuring the three missing cells was the
real gap.

Also corrected: `claude/profile-coverage-remeasure-20260718`, cited in the brain's
`DECISIONS.md:1628`, **does not exist**.

## 4. Pre-registration — and why it still mattered

`PREREGISTRATION.md` was committed (`e9bccb26b`) **before any production fit**, so
git history proves the rule preceded the number. It disclosed honestly that I was
**not blind** to the already-banked cell, and scored with the repo's own two-tier
gate (`ss_floor(10) = 0.918`, tested as `coverage + 2·MCSE ≥ floor`) rather than a
rule invented for the occasion. It fixed PASS / BORDERLINE / FAIL and bound four
anti-rationalisation clauses, including *"`n_per = 4` is not exempt"* and *"the
floor is not re-tuned if the answer lands borderline."*

None of those clauses had to be invoked — but that is only knowable afterwards,
which is the point of writing them first.

## 5. The finding that corrected me

At smoke time, two of three replicates showed `profile_lower = 0`, and I expected
a zero-pinned lower bound to cover any positive truth **trivially** — i.e. that
boundary contact would *inflate* coverage. **The full data says the opposite.**

| Cell | at boundary | coverage \| boundary | coverage \| non-boundary |
|---|---:|---:|---:|
| `g10_n04_sd05` | **495 / 1000** | 0.8566 | 0.9703 |
| `g10_n04_sd10` | 41 | **0.0732** | 0.9656 |
| `g10_n10_sd05` | 63 | 0.2540 | 0.9829 |

When the variance component collapses, the **whole** interval shrinks toward zero,
so `[0, small]` misses the truth from **above**. At `sd_mu = 1.0` boundary cases
cover only 7% of the time. At N = 40 with `sd_mu = 0.5`, **half of all fits** land
on the boundary, and coverage holds at 0.914 only because the non-boundary half
covers at 0.970.

This is why the pre-registration made the boundary diagnostic mandatory
*regardless of verdict*: the headline number is fine, and the mechanism underneath
it is not what a reader would assume.

## 6. Honest caveats carried into the verdict

- **The worst corner's point estimate (0.9140) is BELOW the 0.918 floor.** It
  passes because the gate tests *"not significantly below"*, not *"at or above"*.
  The pass comes from the confidence margin.
- **Upper-miss asymmetry in every cell** (71:15, 63:8, 53:10, 60:9). Expected
  small-`g` skew under the two-tier doctrine — `INFERENCE_READY` passes,
  `SUPPORTED` fails. **This arc claims no `supported` tier.**

## 7. Verification

- **Smoke before scale**, twice: locally, then on Totoro. Both inspected *past the
  guards* — actual `estimate_sd`, interval endpoints, and boundary flags per
  replicate, not just summary counts.
- **Cross-platform reproducibility:** the three smoke replicates agree between
  macOS and Totoro to ~1e-12 on `estimate_sd`.
- **Harness validation:** `g10_n10_sd05` reproduces the 2026-07-26 banked result
  **exactly — 0.9370 vs 0.937** — same seed family, different platform, package
  eight days newer. Per `PREREGISTRATION.md` §8, failure here would have stopped
  the arc before the new cells were reported.
- 1000/1000 finite ordered intervals in every cell; convergence and `pdHess`
  1.000 throughout.

## 8. Provenance

Totoro, 90 cores (≤100 cap), `OPENBLAS_NUM_THREADS=1`; **D-50 honoured** — never
GitHub Actions, results local and in this dev-log. Package rsynced from the arc
branch to an isolated path and loaded with `pkgload::load_all`, so no stale
installed build could shadow it — the existing `~/drm_work/drmTMB` checkout was
found in a broken state (git root resolving to `$HOME`, no commits on `main`) and
deliberately **not** used. Seeds `20260727 + 100000 × cell_i + r`, new indices
4/5/6 so none collides with banked cells. SHA-256 of all four result files
recorded in `VERDICT.md`.

## 9. Scope held

**Census unchanged: 182 `interval_feasible` / 60 `point_fit_recovery`.** No ledger
cell promoted, D-97 not reopened. DEFER fence held — the 135-trace interval
campaign, the `predict()` scale-axis defect, the CI job split, the B4-CI
`SOURCE_COMMIT` port, and mc-0282's runner contract were all left untouched.

## 10. Open for the owner

1. **Publication of 0.7.0.** D-117 held it until this number existed. It exists.
   The decision is D-93 / CI-17 and remains Shinichi's.
2. **Whether this gate covers the 14 newly-reachable Prong B routes.** This arc
   measured the A1 **scalar Gaussian** corner; the Prong B routes are count and
   zero-one-beta families. Still unresolved.
3. **The 2026-07-26 evidence is still unpushed** on
   `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`), on no remote. This arc
   independently reproduces its headline number, which reduces the cost of losing
   it — but does not back it up.
