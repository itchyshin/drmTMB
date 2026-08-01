# C12 plan-versus-actual — ZINB sigma-control corridor

| Planned item | Actual result | Disposition |
| --- | --- | --- |
| IID sigma q1 carrier | Implemented and fenced to fixed `mu`, `zi ~ 1`, and `sigma ~ 1 + (1 | group)`. | Complete |
| Oracle and route tests | Objective, AD/FD, boundary, extraction, prediction, profile-fence, and rejection tests pass. | Complete |
| IID then structured recovery | Run 3 retained IID 4/4 before structured 4/4. | Complete |
| `mc-0633` transition | Legacy formula is broader than C12. | Correctly unchanged |
| `mc-0653` transition | Fresh evidence supports point-fit recovery only. | Promoted |
| Generated counts | Recomputed after PR #862 merge: 308 implemented, 369 not implemented. | Complete |

Run 1 remains runner-error provenance; run 2 is repaired intermediate evidence;
run 3 is terminal. No profiles, intervals, bootstrap, coverage, remote compute,
or broader grammar was added.
