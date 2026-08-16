# interval-campaign-bindings — what these files are, and one column that needs care

These TSVs are **frozen campaign contracts**: per-cell registries binding a profile campaign to its
exact fixture, seed, rung, and declared `true_parameter_scale`. They are written once, at campaign
approval, and never edited afterwards — reconcilers and CI compare retained receipts against them
byte-for-byte. **Do not edit a frozen contract**; supersession is recorded in a dated companion note
(see `docs/dev-log/dashboard/2026-08-15-sr475-results-supersession.md` for the pattern).

## `binding_source_sha256` does NOT hash `binding_source`

The name misleads, and it has already misled one audit (2026-08-15). The column's actual, enforced
semantics:

- `binding_source` names the **per-row** origin of a cell's derivation (a fixture builder, a test
  file, a runner) — for humans.
- `binding_source_sha256` is the digest of the **shared bindings input file** the whole contract was
  derived from — for example `2026-07-27-b1-recovered-subset.tsv` — not of the per-row
  `binding_source`. That is why one value legitimately appears on many rows citing different
  `binding_source` files.

This is not a guess: `tools/validate-lane-b-q1-expanded-whole-cell-contracts.R:36,138` computes
`sha256(paths$bindings)` with `bindings = .../2026-07-27-b1-recovered-subset.tsv` and fails the
contract if the column disagrees. The column **is** a provenance guarantee — of the derivation base,
not of the per-row source. What it therefore **cannot** detect is drift in a per-row source file
(e.g. `mc-0423`'s fixture `n_founders` change), which is a separate, known gap.

By contrast, `source_map_sha256` **does** hash its named `source_map_path` (verified 12/12 on
2026-08-15).

**If you add a new contract**: keep these semantics, or — better — name a new column honestly
(`bindings_input_sha256`) rather than extending the misleading one. Do not rename the column in the
frozen files.
