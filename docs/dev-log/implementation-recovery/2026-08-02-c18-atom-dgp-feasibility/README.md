# C18 atom-DGP feasibility probe

**DESIGN EVIDENCE ONLY. This directory makes no capability claim and promotes no cell.**
It answers one question before any structured-atom code is trusted: *at what sample sizes is
a group-level latent SD on `zoi` or `coi` actually identifiable?*

Run: 2026-08-02 on Totoro, 90 shards (≤100-core cap), source `a61f23939`.
**28,800 fits, all `fit_ok`** — 1,440 cells × 20 seeds.
Projected serial wall time was **2,390 minutes**; sharded it took roughly half an hour.
That ratio is the justification for using Totoro rather than running locally.

## Method — why this could run before the structured code exists

Ordinary (i.i.d.) `zoi`/`coi` random effects already work in drmTMB. So the probe simulates
a **structured field on a phylogeny** and then fits it with the **existing ordinary
`(1 | species)` route**. That measures whether group-level atom information suffices at all —
the decisive question — without depending on the structured routing being implemented, and
therefore without being confounded by the misrouting bug documented in
`docs/design/248` §3.3. (Those two failure modes are confusable: a misrouted carrier and a
genuinely weak atom SD both show up as a failed recovery on `log_sd_phylo`.)

Grid: `zoi ∈ {.10,.12,.15,.25,.35,.50}` × `n_each ∈ {30,50,100,200}` ×
`coi ∈ {.1,.3,.5,.7,.9}` × `tau ∈ {.3,.55,.8}` × `n_tip ∈ {32,64}`, both atoms, 20 seeds.

## Headline results

**Per-fit pass rate: `zoi` 85.5%, `coi` 59.9%.** The asymmetry is predicted exactly by
`docs/design/248` §2.2: the interior-observation density contains no `coi` term at all, so
`coi` is informed only by boundary observations while `zoi` is informed by every row.

**The separation filter is doing almost all the work.** Cells clearing the bar:

| criterion | `zoi` | `coi` |
| --- | --- | --- |
| C16 bar alone (all 20 seeds ok, mean relative `tau` error ≤ 0.40) | 187 / 720 | 73 / 720 |
| …plus **zero separated groups** | **5 / 720** | **4 / 720** |

This is the load-bearing finding. **The C16 bar on its own would pass many cells in which a
large share of the latent field is driven by the GMRF prior rather than by data** — a group
whose boundary observations all fall on one side contributes nothing to `coi`, yet the fit
converges cleanly because the prior supplies the curvature. Promoting on the unfiltered bar
would therefore certify recovery that the data did not support. The per-group separation
check is not a refinement; it is what makes the gate mean anything for an atom parameter.

**Extreme `coi` is the binding constraint, and raising `zoi` does not rescue it.** Mean
separated-group counts at `n_each = 30`:

| `zoi` | separated groups at `coi = 0.5` | at `coi = 0.1` |
| --- | --- | --- |
| 0.10 | 21.0 | 36.1 |
| 0.25 | 3.5 | 22.4 |
| 0.35 | 0.9 | 17.4 |
| 0.50 | 0.4 | 11.1 |

At `coi = 0.1` even `zoi = 0.50` leaves ~11 separated groups, matching the closed-form
prediction in `docs/design/248` §2.4 that the `coi^k` term dominates once `coi` is far from
0.5.

## Recommended DGP for the C18 recovery scripts

**Use one shared setting for both atoms — it is the only setting that clears the full bar for
both simultaneously:**

```
zoi = 0.50   n_each = 50   coi = 0.50   tau = 0.55   n_tip = 32
```
mean relative `tau` error **0.257** (`zoi` arm) and **0.271** (`coi` arm), all 20 seeds
passing, **zero separated groups** in every seed. `n_each = 50` matches the existing sigma
recovery template and `n_tip = 32` matches the mu template, so the eight C18 scripts stay
uniform with their predecessors.

Per-atom optima, if a tighter margin is ever wanted (at higher cost):

| atom | `zoi` | `n_each` | `coi` | `tau` | `n_tip` | mean rel. err |
| --- | --- | --- | --- | --- | --- | --- |
| `zoi` | 0.25 | 200 | 0.5 | 0.55 | 32 | 0.178 |
| `coi` | 0.50 | 100 | 0.5 | 0.55 | 32 | 0.181 |

## Caveats — read before citing this

- **`coi = 0.5` is the most favourable case, and the recommendation sits on it.** Real
  completion rates are rarely 0.5. This DGP demonstrates that the estimator *can* recover a
  latent SD under favourable conditions; it does not characterise typical use.
- **`zoi = 0.50` means half the observations are on the boundary**, which shrinks the interior
  sample that is the only source of `mu`/`sigma` information. That trade-off is real and was
  raised independently during review.
- This probe used the **ordinary** RE route as a proxy. It bounds group-level information; it
  does not validate the structured precision machinery, which is what the oracle tests in the
  implementation slice exist for.

## Files

`raw-attempts.tsv` — 28,800 rows, one per fit · `summary.tsv` — 1,440 cells with pass flags
under both criteria · `provenance.tsv` — source SHA, runner hash, grid, host ·
`smoke.log` / `timing.log` — the mandatory pre-flight smoke and the timing run that justified
sharding.
