# D-117 verdict — the 10-group profile RE-SD coverage gate

**Verdict: PASS**, by the rule frozen in `PREREGISTRATION.md` and committed
(`e9bccb26b`) **before any production fit ran**.

**The 10-group corner is not materially worse than the pooled figure.** Coverage
across the four cells runs **0.914 – 0.937** against D-97's accepted pooled
**0.9368**. The failure mode D-117 was created to catch is real, but it belongs to
the **marginal** route (0.829 at 10 groups, 171 upper misses); the profile route
does not inherit it.

**This discharges the measurement D-117 required. It does not decide publication**
— that remains Shinichi's call (D-93 / CI-17).

## Results

All cells: `n_groups = 10`, `n_rep = 1000`, Gaussian scalar A1 DGP, estimand
`sd:mu:(1 | g)`, nominal 95%, all-attempt coverage.

| Cell | N | truth | coverage | exact 95% CI | cov+2·MCSE | floor | verdict |
|---|---:|---:|---:|---|---:|---:|---|
| `g10_n04_sd05` **worst corner** | 40 | 0.5 | **0.9140** | (0.8949, 0.9306) | 0.9317 | 0.918 | PASS |
| `g10_n04_sd10` | 40 | 1.0 | 0.9290 | (0.9113, 0.9441) | 0.9452 | 0.918 | PASS |
| `g10_n10_sd10` | 100 | 1.0 | 0.9310 | (0.9135, 0.9459) | 0.9470 | 0.918 | PASS |
| `g10_n10_sd05` *reproduction* | 100 | 0.5 | 0.9370 | (0.9201, 0.9513) | 0.9524 | 0.918 | PASS |

Every cell returned **1000/1000 finite ordered intervals**; convergence and
`pdHess` were 1.000 throughout.

**The harness is validated.** `g10_n10_sd05` reproduces the 2026-07-26 banked
result **exactly — 0.9370 against 0.937** — using the same seed family on a
different platform and a package eight days newer. Per `PREREGISTRATION.md` §8,
failure to reproduce would have stopped the arc.

## The honest caveats

These are reported because the pre-registration required them regardless of
verdict, and because two of them cut against the clean headline.

**1. The worst corner's point estimate sits BELOW the floor.** `g10_n04_sd05`
measured **0.9140** against a floor of **0.918**. It passes because the repo's
gate tests *"not significantly below the floor"* (`coverage + 2·MCSE ≥ floor`),
not *"at or above"*. That is the established convention and it was frozen before
the number existed — but a reader should see that the point estimate is under the
line and the pass comes from the confidence margin.

**2. Boundary contact is severe at N = 40, and it DEPRESSES coverage rather than
inflating it.** This corrects a hypothesis formed during the smoke: seeing
`profile_lower = 0` on two of three smoke replicates, I expected a lower bound
pinned at zero to *trivially* cover any positive truth. The full data says the
opposite.

| Cell | profile at boundary | coverage \| boundary | coverage \| non-boundary |
|---|---:|---:|---:|
| `g10_n04_sd05` | **495 / 1000 (49.5%)** | 0.8566 | 0.9703 |
| `g10_n04_sd10` | 41 / 1000 | **0.0732** | 0.9656 |
| `g10_n10_sd05` | 63 / 1000 | 0.2540 | 0.9829 |
| `g10_n10_sd10` | 0 / 1000 | n/a | 0.9310 |

The mechanism: when the variance component collapses toward zero the **whole
interval** shrinks toward zero, so `[0, small]` misses the truth from **above**.
It is not a free pass at the lower end — it is a systematic high-side miss. At
`sd_mu = 1.0` this is stark: boundary cases cover only 7% of the time.

At N = 40 with `sd_mu = 0.5`, **half of all fits** land on the boundary. Coverage
holds up at 0.914 only because the non-boundary half covers at 0.970. This is a
regime characteristic worth knowing before anyone reads 0.914 as "roughly fine".

**3. The directional-miss asymmetry persists in every cell** — upper misses
outnumber lower by 71:15, 63:8, 53:10, 60:9. Under the repo's two-tier doctrine
this is `SUPPORTED = FAIL` while `INFERENCE_READY` passes; at small `g`, upper-tail
skew is *expected*, not a defect. **This arc therefore does not claim `supported`,**
and nothing here promotes a ledger cell.

## What this licenses — and does not

- Licenses a statement about the **10-group corner of the A1 scalar Gaussian RE-SD
  profile interval**, over the four tested `(n_per, sd_mu)` combinations. Nothing
  broader.
- Does **not** revise D-97's accepted pooled figure, promote any capability-ledger
  cell, or move the census — **182 `interval_feasible` / 60 `point_fit_recovery`
  is unchanged.**
- Does **not** claim `supported` (see caveat 3).
- Per `dr20` (~90 sources, 2026-08-03), the literature has no interval-coverage
  benchmark for a variance component below M ≈ 10–15, so this is novel evidence
  rather than a replication — a reason to report it carefully, not to overclaim.

## Provenance

- **Compute:** Totoro, 90 cores (≤ 100 cap), `OPENBLAS_NUM_THREADS=1`. D-50
  honoured — never GitHub Actions; results local and in this dev-log.
- **Package source:** rsynced from the arc branch at `7c1f98020` (package code
  identical to `main` `5a9662110`; the branch's own commits are docs-only), loaded
  with `pkgload::load_all` from an isolated path so no stale installed build could
  shadow it.
- **Seeds (fixed, as D-117 requires):** `20260727 + 100000 × cell_i + r`, with new
  cell indices **4, 5, 6** so no seed collides with banked cells 1–3; index 1
  reused deliberately to reproduce the banked cell.
- **Cross-platform check:** the three smoke replicates agree between macOS and
  Totoro to ~1e-12 on `estimate_sd`.
- **Result hashes (SHA-256):**
  - `g10_n04_sd05.csv` `e8e31cc418cd8a7a9584a3cce8341eb35af12570b34f2a845695930447437d24`
  - `g10_n04_sd10.csv` `ceba24d2918db1ee8fec5fef500a86bc7f41ba6ec6d87455f4cfcff02e5adb8b`
  - `g10_n10_sd05.csv` `c419d05e8255700114f0b14b3d16b5c024ed31fbe754c76a698ee784d35703ae`
  - `g10_n10_sd10.csv` `c3a22e7bf61019070a120e23821fac9344f2e1147eeb129ff13de825fa299512`
- **Scoring:** `score_d117_gate.R`, applying the frozen rule. It does not recompute
  or re-tune the rule.

## Open, for the owner

1. **Publication of 0.7.0** — D-117 held it until this number existed. It exists.
   The publish decision is D-93 / CI-17 and remains Shinichi's.
2. **Whether the gate covers the 14 newly-reachable Prong B profile routes.** This
   arc measured the A1 *scalar Gaussian* corner. The Prong B routes are count and
   zero-one-beta families. Carried forward, still unresolved.
3. **The banked 2026-07-26 evidence remains unpushed** on
   `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`), on no remote. This arc
   independently reproduces its headline number, which reduces the risk of losing
   it — but does not back it up.
