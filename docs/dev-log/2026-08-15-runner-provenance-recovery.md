# Recovering the off-mainline profile runners and campaign contracts

**Arc:** drmTMB interval-claim truth audit · lane `claude/lane-interval-truth-audit` · 2026-08-15
**Authorized by Shinichi:** *"recover the runners onto main"*

## The problem

The interval-truth re-check found that drmTMB's profile evidence was **real but not reproducible from
the mainline**. Of the 116 re-checkable cells, **96 cited a producing runner that did not exist on
`origin/main`**, and **100 of the 101** frozen campaign contracts under
`docs/dev-log/interval-campaign-bindings/` — the files carrying each cell's `true_parameter_scale`,
i.e. the truth a location check needs — were likewise absent. Exactly one contract survived.

Nothing had been deleted. The commits that added these files are simply **not ancestors of
`origin/main`**. Receipts are filed under the producing commit's own sha
(`.../results/3672ce7572feab.../q4-provider-highinfo/mc-0115/`), so each receipt path names the commit
where its runner still lives — which is what made recovery mechanical rather than archaeological.

## What was recovered

| | before | after |
| --- | ---: | ---: |
| re-check cells whose named runner is missing | **96** | **0** |
| campaign contracts present | **1** | **101** |
| files recovered | — | **134** |
| unrecoverable | — | **0** |

134 files over 3 closure rounds: **32 `.R`** (runners, adapters, promotion scripts), **97 `.tsv`**
(campaign contracts, target maps), 4 `.md`, 1 `.txt`.

Recovery ran to **closure**, not just over the cited list: each recovered file was scanned for the
`tools/…` and `docs/dev-log/…` paths it `source()`s or reads, and any of those still missing were
recovered in the next round. Round 1 pulled in 16 further files (the fixture *adapters*, which no
evidence row cites but every runner sources — e.g. `tools/lane-b-q4-provider-highinfo-adapters.R`);
round 2 pulled in 1 more; round 3 was empty. That is the termination condition.

## Verification — four independent checks

1. **Byte-exactness, self-proving.** Two recovered files are themselves hashed inside the contracts:
   `2026-07-27-b1-recovered-subset.tsv` → `93eea48b08c6…` and
   `2026-07-31-structured-q1-target-map.tsv` → `c5958cca6c3a…`. Both recovered files hash to
   **exactly** those recorded values, so the recovery is byte-identical to what the campaigns ran.
2. **`source_map_sha256`: 12 of 12 MATCH.**
3. **Every recovered R file parses** — 32/32, `parse()` clean. (A truncated or partially-written
   recovery would fail here.)
4. **Gates unchanged and green** — `test_profile_truth_gate.py` 24/24 OK;
   `capability_ledger.py --check` OK (31 generated outputs).

## A pre-existing defect found by the verification, NOT introduced here

> **CORRECTION (2026-08-15, overnight).** The paragraph below is half right. The column does not
> hash `binding_source`, but it is not merely "the contract's own digest" either:
> `tools/validate-lane-b-q1-expanded-whole-cell-contracts.R:36,138` defines and ENFORCES it as the
> digest of the shared bindings input file the contract derives from
> (`2026-07-27-b1-recovered-subset.tsv`) — a real provenance guarantee of the derivation base. The
> genuine gap is narrower than stated: the column cannot detect drift in a per-row source file, and
> the NAME misleads. Semantics now documented in `docs/dev-log/interval-campaign-bindings/README.md`;
> the frozen files stay untouched.

`binding_source_sha256` does **not** hash `binding_source`. The single value `93eea48b08c6…` is
recorded as the hash of **seven different paths** (`tools/arc3a-…-recovery.R`,
`tools/b1-breadth-adapters.R`, four `tests/testthat/test-*.R`, …) — a per-file hash cannot do that.
The value is in fact the hash of the *binding TSV itself*. So the column is **mislabelled at source**:
it records the contract's own digest under a name that promises the source file's.

The sibling column `source_map_sha256` **is** correct (it hashes `source_map_path`, 12/12).

This matters because `binding_source_sha256` looks like a provenance guarantee and is not one. It
cannot detect drift in the fixture code a contract points at — which is exactly the class of gap that
`mc-0423`'s known `n_founders` drift falls into. **Recorded, not fixed:** correcting it means either
recomputing the column across 101 frozen contracts or renaming it, and both are claims about frozen
evidence that deserve their own review rather than being folded into a recovery.

## What this does NOT fix

- **8 of the 116 cells still name no runner at all** — `mc-0187`, `mc-0188`, `mc-0203`, `mc-0204`,
  `mc-0405`, `mc-0406`, `mc-0407`, `mc-0408`. Their evidence rows cite no `tools/…` script, so there
  is nothing to recover. That is a different gap and remains open.
- **Recovery is not re-execution.** These runners now exist and parse; **none was run**. Whether each
  still reproduces its retained receipt against current package source is a separate question — and
  the two known blockers say at least some will not: the `runner_sha256` mismatch on the
  `mc-0421/0423/0424` cohorts, and `mc-0423`'s receipts built under `n_founders = 4` against a current
  default of `8`.
- **These files are on the lane branch, not on `main`.** Landing them on `main` needs a push and a
  PR, which is a human gate. The branch is `claude/lane-interval-truth-audit`.
- **No ledger row changed** and no claim was promoted. Recovery restores reproducibility; it does not
  by itself strengthen any cell's evidence.

## Reproduce

```bash
python3 -B tools/tests/test_profile_truth_gate.py   # 24/24 OK
python3 tools/capability_ledger.py --check          # OK (31 generated outputs)
```

Machine-readable manifest of every recovered file and the commit it came from:
`scratchpad/recovery-result.json`.
