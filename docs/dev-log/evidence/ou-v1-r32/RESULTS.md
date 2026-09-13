# R3.2 exact relative-profile diagnostic

R3.2 compares the *ordering* of four fixed independent-OU rate/amplitude
cells, not their parameter recovery. Native Laplace and the retained
nine-node stationary-tip quadrature have the same **observed approximation**
rank order:

| rank | rate pair | amplitude pair | Laplace NLL | direct NLL |
| ---: | --- | --- | ---: | ---: |
| 1 | ridge | ridge | 4.66645 | 4.73996 |
| 2 | interior | ridge | 4.79966 | 5.02083 |
| 3 | ridge | interior | 5.72479 | 5.88417 |
| 4 | interior | interior | 5.80587 | 6.21236 |

The direct-versus-Laplace objective offsets differ by cell, but they do not
reverse an ordering at nine nodes. The retained 7-to-9 refinements are 0.0220
(interior/interior), 0.00010 (interior/ridge), 0.13690 (ridge/interior), and
0.00014 (ridge/ridge). The unresolved ridge/interior cell continues to fall:
5.88417 (nine nodes), 5.80571 (eleven), and 5.76440 (thirteen), with a
0.04131 final refinement. Fisher therefore rejects an exact four-cell rank
claim: this is not an error bound, and interior/interior is also not fully
converged. The only supported statement is that the observed q9/q11/q13
direction has not yet reversed. R3.2 is an unresolved direct-integration
receipt, not support for an estimator repair, recovery redesign, G15, or any
public OU claim.
