| Route | Runtime state | Evidence gate | Work state | Next gate |
|---|---|---:|---|---|
| `gaussian` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `biv_gaussian` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `student` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `lognormal` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `gamma` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `poisson` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `nbinom2` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `zi_poisson` | rejected | G0 | backlog | MR-T6: design and implement this route before G2/G3 validation. |
| `zi_nbinom2` | rejected | G0 | backlog | MR-T6: design and implement this route before G2/G3 validation. |
| `beta` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `truncated_nbinom2` | rejected | G0 | backlog | MR-T5: design and implement this route before G2/G3 validation. |
| `hurdle_nbinom2` | rejected | G0 | backlog | MR-T6: design and implement this route before G2/G3 validation. |
| `cumulative_logit` | rejected | G0 | backlog | MR-T4: design and implement this route before G2/G3 validation. |
| `beta_binomial` | rejected | G0 | backlog | MR-T4: design and implement this route before G2/G3 validation. |
| `zero_one_beta` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `tweedie` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `skew_normal` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |
| `binomial` | implemented | G3 ✓ | verified | G4/G5 interval and coverage evidence are outside this arc. |

A ✓ appears only at G3 recovery or above. Missing-response evidence does not change the model's separate inference tier.
