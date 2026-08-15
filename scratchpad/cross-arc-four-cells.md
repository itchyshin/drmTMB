# Cross-arc receipt — the four overlap cells (mc-0595, mc-0596, mc-0321, mc-0653)

Read on 2026-08-15 from `codex/response-missing-formula-surface` (`a075ff2d0`, landed, unmerged),
**not** from `origin/main`, per the arc's standing rule. Source:
`docs/dev-log/dashboard/capability-ledger/response-mask-formulas.tsv` on that branch.

## Finding 1 — the two arcs measure ORTHOGONAL things. There is no verdict conflict to resolve.

That arc's verdicts for these cells are **response-mask formula** verdicts — G2/G3 observed-data
objective equality against a dense oracle (1e-8) plus central-difference gradient equality (2e-5).
They say nothing whatever about whether a profile interval brackets its true value.

| cell | that arc's `formula_status` | its gate | what it validated |
| --- | --- | --- | --- |
| `mc-0595` | `formula_validated` | fam G5 / form G3 | zero_one_beta `sigma` × relmat, objective+gradient |
| `mc-0596` | **`needs_formula_evidence`** | fam G5 / form **G1** | *refused on measurement* — see Finding 3 |
| `mc-0321` | `formula_validated` | fam G5 / form G3 | gaussian `mu` × phylo_interaction, objective+gradient |
| `mc-0653` | `formula_validated` | fam G3 / form G3 | zi_nbinom2 `sigma` × phylo_interaction, objective+gradient |

**Consequence.** The "do not demote a cell that arc just re-evidenced" rule is satisfied trivially:
nothing this arc does to their *interval* claims contradicts anything that arc concluded about their
*formula* claims. Equally — and this is the part that matters — **that arc confers no protection on
their interval claims.** It did not check location.

## Finding 2 — `mc-0321` is already covered; it is not in this arc's workload.

`tools/profile-truth-manifest.tsv` already carries it:

```
mc-0321  mc-0321::sd:mu:phylo_interaction(1 | plant:pollinator)  sd:mu:phylo_interaction(...)
         0.6  fixture_builder  tools/arc3-phylo-interaction-fixtures.R  fx$sd_pair
```

Truth is **derived** from a fixture builder, as required. It is one of the 27 covered cells, so it
never entered the 210-cell uncovered set — the plan's overlap warning is moot for this cell.

## Finding 3 — `mc-0596` is a genuine tension worth surfacing, and it is NOT mine to resolve.

`cells.tsv` on `origin/main` records `mc-0596` at `evidence_tier = interval_feasible`,
`work_status = verified`, on `ev-mc-0596-135trace-profile`, boundary: *"A profile-likelihood interval
exists and is well-formed under ML for zero_one_beta sigma spatial q1 (true SD 0.45). Five-seed
Totoro 135-trace campaign."*

The landed response-mask arc, measuring the same cell, recorded: *"Attempted and refused on
measurement, not deferred by policy: the outer fit reports convergence 0, but the sentinel helper's
independent nlminb re-optimization from that same optimum returns 'false convergence (8)'."*

These are **different instruments** and not formally contradictory — one is a profile-interval
campaign, the other an independent re-optimization from the optimum. But a cell whose optimum a second
optimizer cannot re-confirm is a weak place for an `interval_feasible` claim to stand. Recorded for
the checkpoint; per D-87 the disposition is Shinichi's call, not this session's.

## Finding 4 — three of the four are the arc's BEST re-check candidates, not its worst.

`mc-0595`, `mc-0596`, `mc-0653` are all in cohort B, all from the 2026-08-05 135-trace campaign, and
each carries **5 distinct seeds** — the gate's full 3–5-seed calibration, so **both** arms of the rule
(`MISS_MAGNITUDE_TOL`, `MISS_COUNT_TOL`) are reachable for them. The one-seed instrument problem does
not apply here.

Their `claim_boundary` prose even states the true SD (0.45, 0.45, 0.60). **That prose is not usable as
truth.** The manifest invariant is that `true_value` is *derived* from the fixture builder, never
hand-typed or lifted from a claim string — copying it out of the prose would recreate the exact defect
this arc exists to find, one layer up. Wave 2 must derive these from
`tools/profile-fence-fixtures.R` / the 135-trace fixture source and then *check the derived value
against the prose* as a consistency test.
