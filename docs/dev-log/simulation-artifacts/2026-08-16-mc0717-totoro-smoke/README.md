# mc-0717 Totoro 27-fit smoke (2026-08-16)

**Cell:** `mc-0717`, ordinary binomial correlated `(1 + x | id)`, ceiling `point_fit_recovery`.  
**Host:** Totoro. **Workers:** 8. **Hard cap:** 16. **SHA:** `5d5048d8d`.  
**Verdict:** **PASS**. This smoke cannot promote the cell, open Wave 2, or authorize merge.

## Files

| File | Role |
| --- | --- |
| `results.tsv` | 27 retained rows (9 draws × 3 methods) |
| `gates.tsv` | scored gates |
| `oracle-agreement.tsv` | drmTMB vs glmmTMB on the same draws |
| `toy.tsv` | 1-fit plumbing check (seed `871000`, not in the denominator) |
| `rejection.tsv` | five neighbours stayed red |
| `joblist.txt` | predeclared 27 jobs |
| `host-provenance.txt` | host / SHA / workers |
| `wall.txt` | 27-fit wall 3 s |
| `logs/launch.log` | launcher stdout |
| `logs/parallel.joblog` | GNU parallel job log |
| `run-mc0717-smoke.R` | per-job runner |
| `launch-mc0717-smoke.sh` | 8-worker launcher with the brief's core guard |

Raw Totoro copy: `~/hsq_work/drmTMB-mc0717/docs/dev-log/simulation-artifacts/2026-08-16-mc0717-totoro-smoke/`. Not a GitHub Actions artifact (D-50).
