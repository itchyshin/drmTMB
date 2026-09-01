# Public Julia LSS bootstrap receipt — ordinary batch, shuffled REML and masks

## Earned public result

The successful ordinary `Rscript` route ran with
`DRMTMB_JULIA_TESTS` explicitly unset. It calls public
`drmTMB(..., engine = "julia", REML = TRUE)` followed by public
`confint(method = "bootstrap")`, and compares each target with direct Julia
rebuilt from the sorted bridge payload under the same seed.

The 32-tip / 128-row input is deliberately shuffled. The receipt verifies that
the bridge payload is tree-tip ordered and that its `row_order` maps exactly to
that shuffled input. It also manually refits one actual marginal-simulator
bootstrap draw under REML, rather than merely refitting the original data.

| public target | used / failed | public 90% interval | direct Julia |
|---|---:|---:|---:|
| `fixef:mu:x` | 6 / 0 | [0.42212321528474883, 0.52198194059443914] | identical |
| `fixef:sd_phylo:z` | 6 / 0 | [0.35847444084192287, 0.80370273780476198] | identical |

The second target is an admitted LSS **fixed-effect** coordinate. It is not a
scalar random-effect-SD wrapper.

A response-include companion masks one four-row tip block. It retains REML,
payload mask and row map; public and direct B = 4 `fixef:mu:x` calls both use
four draws with zero failures and `nobs = 124`.

## Command, resources and provenance

```sh
Rscript --vanilla tools/run-julia-lss-bootstrap-public.R \
  /private/tmp/drm-parity-20260830/DRM.jl \
  /private/tmp/drm-parity-20260830/lss-bootstrap-public-004
```

The 180-second watchdog was not reached: the runner reports
`JULIA_LSS_BOOTSTRAP_PUBLIC_PASS elapsed=31.791`. Julia and BLAS each report
one thread. Recursive R/Julia source manifests match before and after.

Receipt runner SHA-256:
`dfa8fb6946e3469af910eedaea952d774bc7bed9ea451339baa74d13bfce02de`.

Durable result hashes:

```text
97418ccbf4fe8dde726b259e602f3826404d00f535ccca78b559a0a5ddedf999  public-004.json
8805ddff47abd0c855a6d9e7be3876d50f8fd95082f1f69becf390403941599d  public-004.rds
0a2868422104d97d169a37236154641d5d9ce165de753a97216d1cc2254a08dd  public-004.log
```

The loaded development DLL SHA-256 is
`37ecda8a20e59c7309717865948928fc186bca853cda65b2c23c27805de60174`.
The receipt retains active R and Julia worktree statuses, including foreign
development bytes, so it is not a clean-final-head qualification.

## Boundaries

This B = 6/B = 4 dispatch check does not establish bootstrap coverage,
native-R interval parity, scalar random-effect-SD wrapper coverage, broad
profile failure statuses, sparse or large-tree efficiency, all 1/2/4/8 thread
policy cells, final clean-source integration, or any whole-programme G0-G8
claim. Strict raw-coefficient losses and all native missing-predictor
obligations remain open.

## Independent review

Rose (Sol/high) independently approved all143 current source hashes, retained
full-data row mapping, target endpoints/counts and ordinary batch provenance.
The masked payload is not saved: its row/mask claims rely on runtime assertions,
while its interval/count/nobs agreement can be recomputed from the receipt.
Terra/high Melissa retains all programme obligations; this is a bounded
integration receipt, not a coverage or final-source qualification.

## Executable receipt check

`python3 tools/check-julia-lss-bootstrap-receipt.py docs/dev-log/evidence/julia-r-parity/lss-bootstrap-contract/public-004.json --self-test`
passes, recomputing143 current source hashes, payload ordering and numerical
accounting. Six damaged receipts are rejected (endpoint, count, permutation,
ordinary batch, masked REML and forged matching source manifests). The first
checker run exposed a row-record versus column-dictionary JSON assumption;
checker-001/002/003 logs are retained. Gate G6 was independently rerun by root.
This check requires the recorded source bytes; later revisions need a new run.
