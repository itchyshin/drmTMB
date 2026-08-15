# Verdict — the D-117 REML arm

**2026-08-15 · Totoro · 400,000 paired replicates · scored against `PREREGISTRATION.md`,
which was committed before any result existed.**

## The answer in one line

**REML closes 85% of the coverage gap and does not close the last 15%.** Pooled profile-interval
coverage moves **0.924800 → 0.946325**; nominal is 0.95. The pre-registered verdict is
**REML NARROWS BUT DOES NOT CLOSE**.

## Primary result

| | coverage | exact 95% CI | vs nominal 0.95 |
| --- | --- | --- | --- |
| ML (control) | **0.924800** | [0.923978, 0.925615] | −0.0252 |
| REML | **0.946325** | [0.945622, 0.947021] | **−0.0037** |

Paired difference **+0.021525**, SE 0.000292, 95% CI [+0.020953, +0.022097] — **73.7 SE from
zero**. The REML CI's upper limit is 0.947021, so it **excludes 0.95**. The shortfall is real, but
it is 15% of what it was.

Every cell improves, and by nearly the same amount:

| cell | `n_per` | `sd_mu` | ML | REML | Δ | Δ SE | vs floor 0.918 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `g10_n10_sd05` | 10 | 0.5 | 0.9255 | 0.9459 | +0.0204 | 0.0006 | clears |
| `g10_n04_sd05` | 4 | 0.5 | 0.9229 | 0.9466 | +0.0237 | 0.0006 | clears |
| `g10_n04_sd10` | 4 | 1.0 | 0.9257 | 0.9466 | +0.0209 | 0.0006 | clears |
| `g10_n10_sd10` | 10 | 1.0 | 0.9251 | 0.9462 | +0.0211 | 0.0006 | clears |

The uniformity matters: the gain is not an artefact of the boundary-heavy corner. It is the same
~2 points whether boundary incidence is 49.7% or 0.09%.

## The harness proved itself before the result was read

The scorer refuses to report a REML verdict until the control passes. It passed **exactly**:

```
[PASS] reml_flag reads back TRUE on REML arm / FALSE on ML arm
[PASS] REML and ML SD estimates differ (identical on 0.0000% of replicates)
[PASS] ML control reproduces banked pooled 0.924800: got 0.924800  (0.00 SE away)
```

Per cell, the ML arm reproduced the 2026-08-09 100k re-gate to **five decimal places on both
coverage and boundary incidence** — deviation `+0.00000` on all eight comparisons. That is
bit-level reproduction, expected because the seed formula and DGP block were copied verbatim and
the same package build ran on the same machine, but it is worth stating: it means this run's REML
numbers sit on a harness demonstrably identical to the one that produced the banked ML gate.

REML engaged on **100,000/100,000** replicates in every cell.

## Prediction outcome

The pre-registration predicted **NARROWS BUT DOES NOT CLOSE**. All four components held:

| predicted | measured | held? |
| --- | --- | --- |
| Δ > 0 in all four cells, pooled Δ in +0.010 to +0.030 | +0.0204 … +0.0237, pooled **+0.0215** | ✅ |
| pooled REML coverage 0.935–0.950, likely below 0.95 | **0.946325**, CI excludes 0.95 | ✅ |
| recovery bias roughly halved | ML −10.92% → REML **−4.60%** (58% reduction) | ✅ |
| conditional-on-boundary coverage stays poor | 0.7420 → **0.8279** — still far below nominal | ✅, but understated |

The fourth deserves the caveat. I predicted the boundary sub-population would be essentially
untouched, reasoning that REML corrects a degrees-of-freedom bias and cannot change the
post-selection character of a profile interval at a variance boundary. Conditional coverage did
stay poor, so the prediction holds as written — but it improved by 8.6 points, and boundary
*incidence* itself fell from 0.1528 to 0.1377. REML pushes estimates away from the boundary, which
I did not anticipate. The mechanism is not purely a df correction.

A prediction that succeeds on every component is weaker evidence than one that fails and is
recorded; this one could have failed and did not.

## Why coverage improved — and it is not just width

| | ML | REML |
| --- | --- | --- |
| pooled SD bias | **−10.92%** | **−4.60%** |
| median interval width | 0.8065 | 0.8932 (+10.7%) |
| misses lower / upper | 4,474 / 25,606 | 7,080 / 14,390 |
| miss asymmetry | **5.72 : 1** | **2.03 : 1** |
| finite intervals | 400,000 / 400,000 | 400,000 / 400,000 |

Width grew 10.7%, so part of the gain is a wider interval. But the centre moved too — the point
estimate's downward bias more than halved — and the decisive signal is the **miss asymmetry
collapsing from 5.72:1 to 2.03:1**. A pure width increase leaves asymmetry roughly where it was;
it does not convert 11,000 upper-tail misses into balanced ones. The interval is better *centred*
under REML, not merely bigger.

This is the mechanism D-117's own framing predicted and dr20 describes: REML removes the
finite-sample degrees-of-freedom bias from estimating fixed effects. It does not touch the Laplace
integration bias — and for a scalar Gaussian LMM there is none to touch, since Laplace is exact
there. So what is left after REML is not an approximation error this lever can reach.

## What this does and does not settle

**Settles:** the D-93 packet's central open question — *is the one implemented, never-measured
lever worth pulling before deciding?* — now has a number. Ledger row `mc-0265`'s
`claim_boundary` ("coverage and calibration were not evaluated") is no longer true for coverage on
this cell.

**Does not settle:** D-93 itself. Under **Reading A** (nominal-exact) REML does not clear the bar:
0.946325 with a CI excluding 0.95 is still a real shortfall, and the remaining path is design 218's
research-grade bias-correction derivation, on an open timeline. Under **Reading B** (the
`g`-tapered floor) REML was never needed — ML already cleared 0.918 — but it makes the honest
disclosure substantially less severe: a 0.4-point shortfall with 2:1 miss asymmetry reads
differently from a 2.5-point shortfall with 5.7:1.

**The decision is unchanged in kind and improved in substance. It remains Shinichi's.**

## Scope — what this run does not cover

One cell of one family at one group count: **A1 scalar Gaussian, `g = 10`**, ML vs REML, `n_per ∈
{4, 10}`, `sd_mu ∈ {0.5, 1.0}`, `TRUE_BETA = 0.5`, residual `sigma = 0.7`, profile intervals on
`sd:mu:(1 | g)`. It says nothing about other families, providers, slopes, bivariate models, other
group counts, or the `sigma` axis. It advances **no rung**, discharges **neither D-93 nor D-117**,
and no ledger row was edited by this run.

**It also ran on drmTMB 0.6.0**, the campaign library that produced the banked ML gate — chosen
deliberately so the control could reproduce it. It is not a measurement of current `main`
(0.7.0.9000). Nothing in the REML or profile path is known to have changed between them, but that
is an assumption this run does not test.

## Cost and provenance

- **Wall clock 17m19s** (19:11:57 → 19:29:16 UTC), 150 cores, 4 cells sequential, every `rc=0`.
  **My pre-run estimate was ~12 minutes — a 44% overrun.** The timing probe ran on the
  boundary-heaviest cell, which turned out to be *faster* per replicate than the others, so the
  estimate was low. Recorded rather than quietly dropped.
- Totoro, 384 cores, held at ~133 load — inside the 150-core cap (D-143).
- R 4.5.3, drmTMB 0.6.0, TMB 1.9.21, Matrix 1.7.5, `OPENBLAS_NUM_THREADS=1`.
- **Raw per-replicate CSVs are NOT committed** — 4 files, ~220 MB. Retained on Totoro at
  `~/d117_reml/results/` with SHA-256:

  ```
  877e64c596f5992b589726dc074765d8f3aa142a59af80b36375f85734ef0ba9  g10_n04_sd05.csv
  1df7399a348a63984046afdd533f7d9d1b3be2f31ba906c9715efdff83ef461a  g10_n04_sd10.csv
  5bf34f71764900a9c1ccbc48f44af59ac2c288ea8112a74eb51dd31c55eedc21  g10_n10_sd05.csv
  f021d1e10290da7697688714bac21e13f14ffafb58a546d4c1bfc57120959c06  g10_n10_sd10.csv
  0b033b19514f690989a0107f761f312b1c9b5c4870c340cdc959ab8b246def98  SUMMARY.csv
  ```

  Committed here: `results/SUMMARY.csv`, `SCORE-OUTPUT.txt`, `campaign.log`, the runner, the
  scorer, and `PREREGISTRATION.md`.

- Regenerate:

  ```sh
  ssh snakagaw@totoro.biology.ualberta.ca
  cd ~/d117_reml/harness
  OPENBLAS_NUM_THREADS=1 R_LIBS=~/d117_100k/lib R_PROFILE_USER=/dev/null \
    Rscript --no-init-file d117_reml_arm.R --cell=<1|4|5|6> --nrep=100000 --cores=150 \
    --outdir=$HOME/d117_reml/results
  Rscript --no-init-file score_reml_arm.R --results=$HOME/d117_reml/results
  ```

> Related: `PREREGISTRATION.md` ·
> `docs/dev-log/release-audits/2026-08-15-d93-decision-packet.md` §5 and §7 ·
> `docs/dev-log/release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md` ·
> `../2026-08-09-d117-100k-regate/VERDICT-100K.md` (the ML gate this reproduces) ·
> `~/shinichi-brain/projects/deep-research/dr20-reml-vs-aghq-distilled.md`
