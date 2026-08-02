# C17-C2 to C14 current-source compatibility

This retained Totoro run authenticates the C17-C2 candidate source at
`ac86a6429f67b738d9b2e21072b109c9c7681b79` against the three ordinary
zero-one-beta routes whose immutable C14 receipts remain in force. It does not
rewrite, supersede, or reinterpret those historical receipts or their frozen
fingerprint.

All 12 attempts passed the current-source compatibility contract:

| Cell | Route | Passed | Mean relative SD error |
|---|---|---:|---:|
| `mc-0568` | ordinary `sigma` random intercept | 4/4 | 0.0990 |
| `mc-0569` | ordinary `zoi` random intercept | 4/4 | 0.1661 |
| `mc-0576` | same-symbol ordinary `sigma` random slope | 4/4 | 0.0613 |

Every accepted attempt had convergence code 0, `pdHess = TRUE`, maximum
gradient at most 0.01, a non-boundary SD, mode correlation above 0.45, its
route-specific support diagnostic, and zero active `coi` random-effect terms.
The recorded dirty state contains only output directories created by the
preceding authenticated Totoro smoke; every source blob used by this run is
listed in `provenance.tsv`.

This bridge is compatibility evidence only. It promotes no cell and preserves
the immutable C14 receipt set and target fingerprint.
