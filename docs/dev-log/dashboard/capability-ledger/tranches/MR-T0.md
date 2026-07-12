# MR-T0 capability-ledger baseline

_Generated; do not hand-edit._

| Tranche | Routes | Backlog | Implemented unverified | Verified | Next gate |
|---|---:|---:|---:|---:|---|
| MR-T0 baseline | 18 | 12 | 6 | 0 | Execute MR-T1 only after Shinichi reviews this surface |

## Route accounting

| Route | Runtime state | Evidence gate | Work state | Next gate |
|---|---|---:|---|---|
| `gaussian` | implemented | G1 | implemented unverified | MR-T1: complete the shared G2/G3 audit. |
| `biv_gaussian` | implemented | G1 | implemented unverified | MR-T1: complete the shared G2/G3 audit. |
| `student` | rejected | G0 | backlog | MR-T2: design and implement this route before G2/G3 validation. |
| `lognormal` | rejected | G0 | backlog | MR-T2: design and implement this route before G2/G3 validation. |
| `gamma` | rejected | G0 | backlog | MR-T2: design and implement this route before G2/G3 validation. |
| `poisson` | implemented | G1 | implemented unverified | MR-T1: complete the shared G2/G3 audit. |
| `nbinom2` | implemented | G1 | implemented unverified | MR-T1: complete the shared G2/G3 audit. |
| `zi_poisson` | rejected | G0 | backlog | MR-T6: design and implement this route before G2/G3 validation. |
| `zi_nbinom2` | rejected | G0 | backlog | MR-T6: design and implement this route before G2/G3 validation. |
| `beta` | implemented | G1 | implemented unverified | MR-T1: complete the shared G2/G3 audit. |
| `truncated_nbinom2` | rejected | G0 | backlog | MR-T5: design and implement this route before G2/G3 validation. |
| `hurdle_nbinom2` | rejected | G0 | backlog | MR-T6: design and implement this route before G2/G3 validation. |
| `cumulative_logit` | rejected | G0 | backlog | MR-T4: design and implement this route before G2/G3 validation. |
| `beta_binomial` | rejected | G0 | backlog | MR-T4: design and implement this route before G2/G3 validation. |
| `zero_one_beta` | rejected | G0 | backlog | MR-T3: design and implement this route before G2/G3 validation. |
| `tweedie` | rejected | G0 | backlog | MR-T3: design and implement this route before G2/G3 validation. |
| `skew_normal` | rejected | G0 | backlog | MR-T2: design and implement this route before G2/G3 validation. |
| `binomial` | implemented | G1 | implemented unverified | MR-T1: complete the shared G2/G3 audit. |

## Does not cover

MR-T0 does not implement a family route, validate sentinel invariance, repair extractors, add recovery evidence, or change any model inference tier.
